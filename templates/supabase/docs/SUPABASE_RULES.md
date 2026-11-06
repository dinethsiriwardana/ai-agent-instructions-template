# SUPABASE_RULES.md - Database, RLS, Auth, Storage, Edge Functions & Realtime Rules

> Read together with `AGENTS.md`. This file defines **how Supabase resources (PostgreSQL schemas, RLS policies, Auth hooks, Storage buckets, Edge Functions, and Realtime channels) are written and secured** for **{{PROJECT_NAME}}**.

---

## 1. PostgreSQL Schema & DDL Conventions

### 1.1 Schema Separation (`public` vs `private`)
- **`public`**: Tables and views exposed to the Supabase Data API (PostgREST). **Every table in `public` must have Row Level Security (RLS) enabled.**
- **`private`**: Internal helper functions (`SECURITY DEFINER`), audit tables, background queues, and materialized views that must **never** be callable or readable directly via PostgREST.
- **`auth`, `storage`, `realtime`, `supabase_migrations`, `extensions`**: Managed by Supabase. Never create application tables inside managed schemas.

```sql
-- Always create the private schema in your initial migration
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to postgres, service_role;
```

### 1.2 Standard Table Template
Every application table in `public` follows this baseline structure:
- `snake_case` plural table name.
- `uuid` primary key (`default gen_random_uuid()`).
- Explicit foreign key references with `on delete cascade` / `restrict` / `set null` AND an explicit B-tree index on every foreign key column.
- `created_at` and `updated_at` (`timestamptz not null default now()`).
- `alter table ... enable row level security;` immediately after `create table`.

```sql
create or replace function private.handle_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  owner_id uuid not null references public.profiles(id) on delete restrict,
  name text not null check (char_length(name) between 1 and 120),
  status text not null default 'active' check (status in ('draft', 'active', 'archived')),
  budget_minor bigint not null default 0 check (budget_minor >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Mandatory: Index every foreign key and frequent filter column
create index if not exists idx_projects_organization_id on public.projects (organization_id);
create index if not exists idx_projects_owner_id on public.projects (owner_id);

-- Mandatory: Attach updated_at trigger
drop trigger if exists set_projects_updated_at on public.projects;
create trigger set_projects_updated_at
  before update on public.projects
  for each row execute function private.handle_updated_at();

-- Mandatory: Enable RLS in the same migration
alter table public.projects enable row level security;
```

### 1.3 User Profiles Synchronization (`auth.users -> public.profiles`)
Never query `auth.users` from client code or expose it via a view. Sync user records into `public.profiles` via a `SECURITY DEFINER` trigger:

```sql
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email, full_name, avatar_url)
  values (
    new.id,
    coalesce(new.email, ''),
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do update set
    email = excluded.email,
    updated_at = now();
  return new;
end;
$$;

revoke all on function private.handle_new_user() from public, anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();
```

---

## 2. Row Level Security (RLS) Rules & Performance

### 2.1 Policy Granularity & Role Targeting
1. **Never use `FOR ALL` for write policies**: Write explicit policies for `SELECT`, `INSERT`, `UPDATE`, and `DELETE`.
2. **Always specify `TO authenticated` or `TO anon`**: Omitting `TO <role>` defaults to `PUBLIC` (both anonymous and authenticated users) and wastes evaluation cycles for unauthenticated requests.
3. **Always include both `USING` and `WITH CHECK` on `UPDATE`**:
   - `USING` controls which existing rows the user is allowed to target.
   - `WITH CHECK` validates the new row state (preventing a user from changing `owner_id` or `organization_id` to someone else's).

### 2.2 High-Performance RLS Optimization Patterns

1. **Wrap `auth.uid()` and `auth.jwt()` in `(select ...)`**:
   Bare `auth.uid()` is evaluated once **per row**. Wrapping it in `(select auth.uid())` causes the PostgreSQL planner to evaluate it once **per query** as an `InitPlan`:
   ```sql
   -- GOOD: Cached per query via InitPlan
   create policy "authenticated_select_own_profile"
     on public.profiles for select
     to authenticated
     using ((select auth.uid()) = id);

   create policy "authenticated_update_own_profile"
     on public.profiles for update
     to authenticated
     using ((select auth.uid()) = id)
     with check ((select auth.uid()) = id);
   ```

2. **Use `private` `SECURITY DEFINER` Helpers for Multi-Tenant Joins**:
   When checking membership in `public.organization_members`, avoid direct correlated subqueries if `organization_members` itself has complex RLS. Define a `stable` `SECURITY DEFINER` helper in `private`:
   ```sql
   create or replace function private.user_organization_ids()
   returns setof uuid
   language sql
   security definer
   stable
   set search_path = ''
   as $$
     select organization_id
     from public.organization_members
     where user_id = (select auth.uid())
   $$;

   revoke all on function private.user_organization_ids() from public, anon;
   grant execute on function private.user_organization_ids() to authenticated;

   create policy "org_members_select_projects"
     on public.projects for select
     to authenticated
     using (organization_id in (select private.user_organization_ids()));
   ```

3. **Views Must Use `security_invoker = true`**:
   In PostgreSQL 15+, views execute with the permissions of the view creator by default, bypassing RLS! Every view in `public` **must** enable `security_invoker = true`:
   ```sql
   create or replace view public.active_projects_view
   with (security_invoker = true) as
     select id, organization_id, name, budget_minor, created_at
     from public.projects
     where status = 'active';
   ```

---

## 3. Authentication, JWT Claims & RBAC

1. **Never Trust `user_metadata` for Authorization**:
   - `raw_user_meta_data` (`user.user_metadata`) can be updated directly by any signed-in user calling `supabase.auth.updateUser({ data: { ... } })`.
   - Use `raw_app_meta_data` (`user.app_metadata`) or a database table (`public.organization_members` / `public.user_roles`) for roles, permissions, and subscription tiers.
2. **Custom Access Token Hook (RBAC in JWT)**:
   - If encoding roles or tenant IDs into JWT claims, register a Postgres Custom Access Token Hook (`private.custom_access_token_hook(event jsonb)`) granted only to `supabase_auth_admin` and read claims in RLS via `((select auth.jwt()) -> 'app_metadata' ->> 'role')`.
3. **Server-Side Token Validation**:
   - Always call `await supabase.auth.getUser()` (which verifies the JWT with the Auth server / JWKS) on the server or in Edge Functions. Never rely on `getSession()` on the server.

---

## 4. Storage Rules (Buckets, Paths & Policies)

1. **Bucket Provisioning in SQL Migrations**:
   Never create buckets manually without recording them in `supabase/migrations/`. Always set `public = false` (unless strictly public CDN assets) and enforce `file_size_limit` + `allowed_mime_types`:
   ```sql
   insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
   values (
     'project-attachments',
     'project-attachments',
     false,
     10485760, -- 10 MB max
     array['application/pdf', 'image/png', 'image/jpeg', 'image/webp']
   )
   on conflict (id) do update set
     public = excluded.public,
     file_size_limit = excluded.file_size_limit,
     allowed_mime_types = excluded.allowed_mime_types;
   ```
2. **Deterministic Path Prefix Convention (`{owner_id}/{category}/{uuid}.{ext}`)**:
   - Prefix every uploaded object key with the owning `user_id` or `organization_id` so `storage.objects` RLS policies can verify ownership via `(storage.foldername(name))[1]`:
   ```sql
   create policy "authenticated_read_own_attachments"
     on storage.objects for select
     to authenticated
     using (
       bucket_id = 'project-attachments'
       and (storage.foldername(name))[1] = (select auth.uid())::text
     );

   create policy "authenticated_upload_own_attachments"
     on storage.objects for insert
     to authenticated
     with check (
       bucket_id = 'project-attachments'
       and (storage.foldername(name))[1] = (select auth.uid())::text
     );

   create policy "authenticated_delete_own_attachments"
     on storage.objects for delete
     to authenticated
     using (
       bucket_id = 'project-attachments'
       and (storage.foldername(name))[1] = (select auth.uid())::text
     );
   ```
   - Never use raw user-provided filenames as storage keys; generate a UUID (`${userId}/invoices/${crypto.randomUUID()}.pdf`).

---

## 5. Edge Functions (`supabase/functions/`)

1. **Runtime & Dependency Rules (Deno)**:
   - Import packages using pinned `npm:` or `jsr:` specifiers (`import { createClient } from "npm:@supabase/supabase-js@2"`). Never use unpinned `https://deno.land/x/` URLs.
   - Keep each function's `index.ts` under 80 lines by wrapping it with `createEdgeHandler` from `supabase/functions/_shared/handler.ts` and delegating business logic to `<name>.service.ts`.
2. **Response Envelope**:
   Every Edge Function returns the same JSON envelope:
   - Success: `{ "success": true, "data": { ... } }`
   - Error: `{ "success": false, "error": { "code": "BAD_REQUEST", "message": "...", "details": null } }`
3. **Webhooks & Background Work**:
   - Verify cryptographic webhook signatures against `await req.text()` before parsing JSON.
   - Use `EdgeRuntime.waitUntil(promise)` only for non-critical post-response tasks (e.g., logging/analytics); use durable queues (`pgmq` / Supabase Queues) for critical background jobs with retries.

---

## 6. Realtime Channels (`Broadcast`, `Presence`, `postgres_changes`)

1. **Prefer `Broadcast` with Realtime Authorization over `postgres_changes`**:
   - `postgres_changes` checks RLS per subscribed user on a single database replication thread and does not scale to thousands of concurrent listeners.
   - Prefer `Broadcast` channels (`topic: "org:${orgId}:events"`) secured with RLS policies on `realtime.messages` (`private: true` channel config on client).
2. **Subscription Hygiene**:
   - Always pass an explicit `filter` when using `postgres_changes` (`filter: "organization_id=eq.${orgId}"`).
   - Always unsubscribe and call `supabase.removeChannel(channel)` on teardown.

---

## 7. Localization & Error Dictionary (`locales/`)

All error messages, validation descriptions, auth messages, and storage error strings live in `locales/{lang}.json` (`locales/en.json`, `locales/es.json`).
- Never hardcode user-facing error strings in Edge Functions, repositories, or services.
- Map PostgreSQL / PostgREST error codes (`23505` unique violation, `23503` foreign key violation, `42501` RLS violation, `PGRST116` not found) through `src/lib/errors.ts` to localized messages.

