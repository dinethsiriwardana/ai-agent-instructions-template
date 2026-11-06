# Supabase Architecture, Security & Operational Rules

> Mandatory standards for **{{PROJECT_NAME}}** ({{STACK_LABEL}}) when building with Supabase (PostgreSQL, Auth, RLS, Storage, Edge Functions, Realtime, and Local CLI).
> Read this file before creating or modifying database tables, RLS policies, authentication flows, storage buckets, or Edge Functions.

---

## 0. Core Supabase Principles

1. **RLS is Mandatory on Every Table in `public`**: Never leave a table in the `public` schema with Row Level Security disabled. If a table should only be accessed by backend services, enable RLS and create zero policies (denies all `anon` and `authenticated` access via PostgREST).
2. **Optimize RLS for Scale**: Always wrap `auth.uid()` and `auth.jwt()` in `(select auth.uid())` inside RLS policies so PostgreSQL caches the scalar result per query (`initPlan`) instead of re-evaluating per row. Always specify `TO authenticated` or `TO anon` on policies.
3. **Never Trust `getSession()` on the Server**: In SSR/backend contexts, always validate the user token via `supabase.auth.getUser()` (or verify the JWT signature against Supabase JWKS), never `getSession()`, which reads unverified cookie data.
4. **Never Leak `SUPABASE_SERVICE_ROLE_KEY`**: The `service_role` key bypasses all RLS and must only exist in validated server-only environment config (`src/config/env.ts`). Never prefix it with `NEXT_PUBLIC_` or ship it to mobile/web clients.
5. **Declarative, Additive Migrations Only**: Never make schema, RLS, bucket, or trigger changes manually in the Supabase Studio dashboard in shared environments. Author all changes in `supabase/migrations/<timestamp>_<name>.sql` using idempotent, non-destructive SQL.
6. **Generated Types + Zod Validation**: Generate TypeScript/Dart types from the local Supabase schema (`supabase gen types`) and pair them with Zod / `freezed` schemas at the application boundary. Never hand-edit generated database types.
7. **Layered Data Access**: Never call `supabase.from(...)` directly inside UI components, React pages, NestJS controllers, or Flutter widgets. All Supabase calls live inside repositories (`*.repository.ts`) or remote datasources (`*_remote_datasource.dart`).

---

## 1. Environment & Project Isolation (`dev-test` -> `dev` -> `main`)

Align Supabase environments with the 3-stage branching workflow defined in `docs/PROJECT_GUIDELINES.md`:

| Stage | Branch | Supabase Target | Keys & Variables Scope | Migration Execution |
|---|---|---|---|---|
| **Stage 1: Local** | `dev-test`, `feat/*`, `fix/*` | Local Supabase CLI (`supabase start`) or isolated Dev project | `.env.development` / `.env.local` (Local CLI keys or `Dev_*` fallback) | `supabase db reset` or `npm run db:migrate:dev` |
| **Stage 2: QA / Staging** | `dev` | Supabase Preview Branch or Staging Project | `Preview & Development` scope (`NEXT_PUBLIC_SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `DATABASE_URL`) | Auto-runs on push/merge to `dev` (`supabase db push` / `db:migrate:dev`) |
| **Stage 3: Production** | `main` | Supabase Production Project | `Production` scope only | **Merge-only**: Auto-runs ONLY on merge to `main` (`db:migrate:prod`). Blocked locally. |

### 1.1 Environment Variables Standard

| Variable | Exposure | Purpose |
|---|---|---|
| `SUPABASE_URL` / `NEXT_PUBLIC_SUPABASE_URL` | Public (Client & Server) | Supabase project REST, Auth, Realtime, and Storage endpoint |
| `SUPABASE_ANON_KEY` / `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Public (Client & Server) | Publishable anonymous key; enforces RLS for unauthenticated and user-JWT requests |
| `SUPABASE_SERVICE_ROLE_KEY` | **Server-Only (Secret)** | Admin key that bypasses RLS; restricted strictly to server background jobs, webhooks, and admin repositories |
| `DATABASE_URL` | **Server-Only (Secret)** | Transaction pooler connection string (Supavisor port `6543`, `?pgbouncer=true`) for serverless/app queries |
| `DIRECT_URL` / `DATABASE_URL_UNPOOLED` | **Server-Only (Secret)** | Session/direct connection string (port `5432`) used exclusively for migrations (`drizzle-kit` / `supabase db push`) |
| `SUPABASE_JWT_SECRET` / JWKS URI | **Server-Only (Secret)** | Used by custom backends (NestJS) to verify Supabase-issued JWTs |

- **Rule**: Validate all variables at startup in `src/config/env.ts` (Next.js/NestJS) or `lib/core/config/env.dart` (Flutter). Support `Dev_SUPABASE_URL` / `Dev_DATABASE_URL` automatic fallbacks in non-production environments.

---

## 2. Database Schema & Modeling Standards

### 2.1 Naming & Structural Conventions
- **Identifiers**: Always use `snake_case` and plural table names (`users_profiles`, `organization_members`, `order_items`). Never use `camelCase` or quoted mixed-case identifiers in PostgreSQL.
- **Schemas**:
  - `public`: Application tables exposed to the Data API (always protected by RLS).
  - `private` (or `internal`): Internal lookup tables, audit logs, security-definer helper functions, and materialized views **never** exposed over PostgREST.
  - `auth`, `storage`, `realtime`, `supabase_migrations`: Managed by Supabase; **never** modify or add tables directly to managed schemas.
- **Primary Keys**: Use `uuid` (`default gen_random_uuid()`) or ` bigint generated always as identity` for high-throughput append-only tables.
- **Audit Columns**: Every mutable table must include:
  ```sql
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
  ```
  Attach a shared `private.handle_updated_at()` trigger to automatically refresh `updated_at` on `BEFORE UPDATE`.
- **Money & Dates**: Store currency in integer minor units (`price_minor bigint not null check (price_minor >= 0)`) or `numeric(12,2)`, never `real`/`float`. Store all timestamps as `timestamptz` in UTC.
- **Enums vs Check Constraints**: Prefer `text` columns with `CHECK (status IN ('draft', 'active', 'archived'))` or lookup tables over PostgreSQL `CREATE TYPE ... AS ENUM`, because removing or reordering enum values in Postgres is non-trivial in migrations.

### 2.2 User Profiles & `auth.users` Synchronization
Never query `auth.users` directly from client code or expose `auth.users` via views. Maintain a `public.profiles` table linked 1:1 with `auth.users`:

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
    new.email,
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'avatar_url'
  );
  return new;
end;
$$;
```

### 2.3 Foreign Keys & Indexing Rules
- PostgreSQL does **not** automatically index the referencing side of a foreign key. Every foreign key column (`user_id`, `tenant_id`, `organization_id`) **must** have an explicit B-tree index:
  ```sql
  create index if not exists idx_projects_tenant_id on public.projects (tenant_id);
  create index if not exists idx_projects_user_id on public.projects (user_id);
  ```
- Explicitly specify `ON DELETE CASCADE`, `ON DELETE SET NULL`, or `ON DELETE RESTRICT` on every foreign key—never rely on implicit defaults.
- Add partial indexes (`WHERE deleted_at IS NULL`) if soft deletes are required by the domain.

---

## 3. Row Level Security (RLS) Rules & Performance

### 3.1 Mandatory RLS Checklist
- [ ] `ALTER TABLE public.<table_name> ENABLE ROW LEVEL SECURITY;` is present in the same migration that creates the table.
- [ ] Every policy explicitly declares its target role (`TO authenticated` or `TO anon`). Never leave `TO public` unless intentionally allowing unauthenticated guests.
- [ ] Write separate policies for `SELECT`, `INSERT`, `UPDATE`, and `DELETE` (never use `FOR ALL` with only `USING`, as `INSERT` requires `WITH CHECK`).
- [ ] `UPDATE` policies always include **both** `USING` (which existing rows can be updated) and `WITH CHECK` (what the new row state is allowed to look like, preventing ownership hijacking).

### 3.2 High-Performance RLS Patterns

1. **Always Wrap Auth Functions in `(select ...)`**:
   Calling `auth.uid()` or `auth.jwt()` bare forces Postgres to call the function for every single row scanned. Wrapping in `(select auth.uid())` turns it into an `initPlan` evaluated once per query:
   ```sql
   -- GOOD: cached per query via initPlan
   create policy "users_select_own_tasks"
     on public.tasks for select
     to authenticated
     using ((select auth.uid()) = user_id);

   -- BAD: evaluated once per row
   -- using (auth.uid() = user_id);
   ```

2. **Use `SECURITY DEFINER` Helpers in `private` Schema for Multi-Tenant Joins**:
   If a policy checks membership in a join table (`organization_members`), querying that table directly inside RLS can trigger recursive RLS checks and slow nested-loop joins. Instead, create a `SECURITY DEFINER` function in the `private` schema with `SET search_path = ''`:
   ```sql
   create or replace function private.get_user_org_ids()
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

   create policy "org_members_select_projects"
     on public.projects for select
     to authenticated
     using (organization_id in (select private.get_user_org_ids()));
   ```

3. **Views Must Use `security_invoker = true`**:
   In PostgreSQL 15+, views bypass the underlying tables' RLS policies by default (running as the view owner). Always declare views with `security_invoker = true`:
   ```sql
   create or replace view public.active_projects_summary
   with (security_invoker = true) as
     select id, name, organization_id
     from public.projects
     where archived_at is null;
   ```

---

## 4. Database Functions, Triggers & RPCs

1. **Lock Down `search_path`**: Every `plpgsql` or `sql` function—especially `SECURITY DEFINER` functions—must explicitly set `SET search_path = ''` and fully qualify all table and function references (`public.tasks`, `auth.uid()`) to prevent search-path hijacking vulnerabilities.
2. **Default to `SECURITY INVOKER`**: Use `SECURITY INVOKER` (the default) for RPC functions called via `supabase.rpc(...)` so RLS policies still apply. Use `SECURITY DEFINER` only when elevated privileges are strictly required, and revoke execution from `anon` and `public`:
   ```sql
   revoke all on function private.my_privileged_fn() from public, anon, authenticated;
   ```
3. **Keep Business Logic in Services, Not Triggers**: Use database triggers only for data integrity, audit timestamps (`updated_at`), and `auth.users -> public.profiles` creation. Do not hide complex domain workflows or external HTTP calls (`pg_net`) inside database triggers unless explicitly documented in `docs/DECISIONS.md`.

---

## 5. Authentication, Sessions & Authorization (RBAC)

### 5.1 SSR & Token Verification Rules
- **Next.js (App Router)**:
  - Use `@supabase/ssr` (`createBrowserClient` for client components, `createServerClient` for Server Components, Route Handlers, Server Actions, and `proxy.ts` / `middleware.ts`).
  - Refresh the auth token in `proxy.ts` (`middleware.ts`) by calling `await supabase.auth.getUser()` and forwarding updated cookies on both the request and response.
  - **Never** use `supabase.auth.getSession()` inside Server Components, Route Handlers, or Server Actions to check authentication or read user IDs—always use `await supabase.auth.getUser()`.
- **NestJS (API Backend)**:
  - Verify incoming `Authorization: Bearer <access_token>` JWTs in `JwtAuthGuard` using Supabase's asymmetric JWKS endpoint (`<SUPABASE_URL>/auth/v1/.well-known/jwks.json`) or `SUPABASE_JWT_SECRET`.
  - Extract `sub` (`user.id`), `email`, and custom `app_metadata` roles into the typed `@CurrentUser()` request context.
- **Flutter (Mobile Client)**:
  - `supabase_flutter` automatically persists sessions using `flutter_secure_storage` on mobile.
  - Listen to `supabase.auth.onAuthStateChange` inside the Auth datasource/repository and map session events into BLoC states (`Authenticated`, `Unauthenticated`, `PasswordRecovery`).
  - Configure deep links (PKCE auth flow) for magic links, OAuth, and password resets; always exchange codes via `getSessionFromUrl` / PKCE code exchange.

### 5.2 Custom Claims & Metadata Security (`user_metadata` vs `app_metadata`)
- **`raw_user_meta_data` (`user_metadata`) is User-Editable**: Any authenticated user can call `supabase.auth.updateUser({ data: { role: 'admin' } })`. **Never** store or check roles, permissions, subscription tiers, or tenant IDs in `user_metadata`!
- **`raw_app_meta_data` (`app_metadata`) is Server-Controlled**: Only the `service_role` key or a Custom Access Token Hook (`pg_tle` / Postgres Auth Hook) can modify `app_metadata`. Store RBAC roles (`app_metadata.role`) or tenant claims there, or verify permissions against a `public.user_roles` / `public.organization_members` table in PostgreSQL.

---

## 6. Storage Rules (Buckets, Policies & Uploads)

1. **Private Buckets by Default**: Create buckets with `public = false` unless the assets are intentionally public CDN assets (e.g., public marketing images).
2. **Bucket Limits in Migrations**: Always constrain `file_size_limit` and `allowed_mime_types` when creating buckets in SQL migrations:
   ```sql
   insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
   values (
     'user-documents',
     'user-documents',
     false,
     10485760, -- 10 MB
     array['application/pdf', 'image/png', 'image/jpeg', 'image/webp']
   )
   on conflict (id) do update set
     file_size_limit = excluded.file_size_limit,
     allowed_mime_types = excluded.allowed_mime_types;
   ```
3. **Path Prefix Convention (`{owner_id}/{resource}/{uuid}.{ext}`)**:
   - Always namespace uploaded objects by `user_id` or `tenant_id` as the first folder segment so `storage.objects` RLS policies can verify ownership cleanly using `(storage.foldername(name))[1]`:
   ```sql
   create policy "users_manage_own_documents"
     on storage.objects for all
     to authenticated
     using (
       bucket_id = 'user-documents'
       and (storage.foldername(name))[1] = (select auth.uid())::text
     )
     with check (
       bucket_id = 'user-documents'
       and (storage.foldername(name))[1] = (select auth.uid())::text
     );
   ```
   - Never use user-supplied filenames directly as storage keys; generate a UUID or deterministic slug (`${userId}/avatars/${crypto.randomUUID()}.webp`) to prevent path traversal and cache collisions.
4. **Signed Upload & Download URLs**:
   - For sensitive uploads or custom validation flows, validate the request in your backend service first, then generate a short-lived signed upload URL (`createSignedUploadUrl`) or short-lived signed read URL (`createSignedUrl(path, 3600)`).

---

## 7. Edge Functions & Webhooks (`supabase/functions/`)

1. **When to Use Edge Functions vs App Backend**:
   - If the project already has Next.js Route Handlers (`server/`) or a NestJS backend (`modules/`), keep primary business APIs in the main backend to avoid splitting domain logic across runtimes.
   - Use Supabase Edge Functions (Deno) for: Auth Hooks, Database Webhook consumers, low-latency edge tasks, or standalone backends for Flutter-only apps.
2. **Directory Layout**:
   ```text
   supabase/
   ├── config.toml
   ├── seed.sql
   ├── migrations/
   └── functions/
       ├── _shared/              # Shared CORS headers, Supabase client factory, error envelope, Zod schemas
       │   ├── cors.ts
       │   ├── supabase-client.ts
       │   └── errors.ts
       └── stripe-webhook/
           └── index.ts
   ```
3. **Edge Function Security & Standards**:
   - Use `npm:` or `jsr:` specifiers with pinned versions (`import { createClient } from "npm:@supabase/supabase-js@2"`). Never use unpinned `https://deno.land/x/...` URLs.
   - Forward the caller's `Authorization` header when creating the Supabase client inside an Edge Function so RLS is enforced on behalf of the caller:
     ```ts
     const supabase = createClient(
       Deno.env.get("SUPABASE_URL")!,
       Deno.env.get("SUPABASE_ANON_KEY")!,
       { global: { headers: { Authorization: req.headers.get("Authorization")! } } },
     );
     ```
   - Verify inbound third-party webhooks (Stripe, RevenueCat, GitHub) using cryptographic signature verification on the raw request body (`await req.text()`) and ensure idempotency.

---

## 8. Realtime Channels & Broadcast Rules

1. **Prefer `Broadcast` and `Presence` over `postgres_changes` at Scale**:
   - `postgres_changes` evaluates RLS for every subscribed user on every row write, which can bottleneck a single replication thread when thousands of users are connected.
   - For high-fanout live updates, use **Realtime Broadcast** (triggered from the server or database via `realtime.broadcast_changes` / `realtime.send`) with **Realtime Authorization** policies on `realtime.messages`.
2. **Always Scope & Clean Up Subscriptions**:
   - Filter every subscription with an explicit `filter` (e.g., `filter: 'organization_id=eq.${orgId}'`).
   - Always unsubscribe / `supabase.removeChannel(channel)` on component unmount (`useEffect` cleanup in React) or BLoC `close()` in Flutter to prevent memory and socket leaks.

---

## 9. Local CLI Workflow, Migrations & Type Generation

### 9.1 Migration Lifecycle
1. **Create a new migration**:
   ```bash
   npx supabase migration new <descriptive_snake_case_name>
   ```
2. **Write additive, idempotent SQL**:
   - Use `CREATE TABLE IF NOT EXISTS`, `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`.
   - Never edit an already-merged migration file; create a new migration to alter previous objects.
   - Destructive SQL (`DROP TABLE`, `DROP COLUMN`, `TRUNCATE`) is blocked by the project's data-safe migration guard unless explicitly reviewed and annotated with `-- @allow-destructive`.
3. **Apply locally & verify (`dev-test`)**:
   ```bash
   npx supabase db reset   # Replays all migrations + supabase/seed.sql cleanly
   npx supabase db lint    # Checks SQL functions and schema for errors
   ```
4. **Regenerate static types after every schema change**:
   ```bash
   # TypeScript (Next.js / NestJS)
   npx supabase gen types typescript --local > src/server/db/database.types.ts
   ```
   Commit the updated `database.types.ts` in the same PR as the migration.

### 9.2 Database & RLS Testing (`pgTAP` + Integration Tests)
- Test RLS policies explicitly for at least 3 personas:
  1. **Anonymous (`anon`)**: Verify unauthenticated requests cannot read or mutate private rows.
  2. **Authenticated Owner (`User A`)**: Verify `User A` can read/write their own rows.
  3. **Authenticated Other (`User B`)**: Verify `User B` cannot read, update, or delete `User A`'s rows, and cannot insert a row with `user_id = User A`.
- Run `npx supabase test db` (pgTAP in `supabase/tests/*.test.sql`) or repository integration tests against the local Supabase instance before opening a PR to `dev-test`.

---

## 10. Supabase Anti-Patterns (Never Do)

- Creating a table in `public` without `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`.
- Writing RLS policies with bare `auth.uid()` instead of `(select auth.uid())`.
- Omitting `WITH CHECK` on `INSERT` or `UPDATE` RLS policies.
- Creating PostgreSQL views in `public` without `with (security_invoker = true)`.
- Writing `SECURITY DEFINER` functions without `set search_path = ''`.
- Calling `supabase.auth.getSession()` on the server to authenticate requests instead of `supabase.auth.getUser()`.
- Storing or trusting authorization roles in `user_metadata` (`raw_user_meta_data`).
- Exposing `SUPABASE_SERVICE_ROLE_KEY` to the browser or mobile client, or using the service-role client for normal user requests to "work around" RLS.
- Calling `supabase.from(...)` directly inside React components, Next.js pages, NestJS controllers, or Flutter widgets/BLoCs.
- Using port `5432` direct connections in serverless functions instead of the Supavisor transaction pooler (port `6543` with `?pgbouncer=true`).
- Making manual schema or RLS changes in the Supabase Dashboard without committing a SQL migration file.
- Leaving Realtime channels subscribed after a component unmounts or a BLoC closes.

