<!-- BEGIN:supabase-agent-rules -->

# AGENTS.md - Architecture and Coding Guidelines (Supabase)

> Read this file fully before writing or changing any SQL, database migrations, RLS policies, Edge Functions, or Supabase client code.
> These rules are mandatory. If a request conflicts with them, say so and propose the compliant alternative.
> Project name: **{{PROJECT_NAME}}**

---

## 0. Document Map

| Document | Answers |
|---|---|
| `AGENTS.md` (this file) | How Supabase schema, RLS, Auth, Storage, Edge Functions, Realtime & clients are architected |
| `BRANCHES.md` | Active, in-review, and merged branch registry |
| `docs/SUPABASE_RULES.md` | Deep-dive SQL, RLS performance, Storage policy, Auth Hook & Edge Function conventions |
| `docs/PROJECT_GUIDELINES.md` | How work flows (branches, PRs, commits, releases, maintenance) |
| `docs/PROJECT_PLAN.md` | What is being built and why |
| `docs/TASK_LIST.md` | What is done and what is next |
| `docs/DECISIONS.md` | Why a technical choice was made (ADR log) |
| `docs/ISSUES.md` | Blockers parked under the 10-minute rule |
| `docs/ai/STYLE_AND_SKILLS.md` | Developer habits, skills, preferences & learned style |
| `docs/ai/REQUEST_LOG.md` | Categorized request history (Feature, Bugfix, Refactor, etc.) |

Reading order for a new contributor or AI agent: `docs/ai/STYLE_AND_SKILLS.md` -> `PROJECT_PLAN` -> `AGENTS` -> `SUPABASE_RULES` -> `PROJECT_GUIDELINES` -> `TASK_LIST`.

---

## 1. Stack Defaults

| Concern | Choice |
|---|---|
| Platform & CLI | Supabase CLI (`supabase/`), PostgreSQL 15+, Supavisor connection pooler |
| Language & Runtime | SQL (PostgreSQL / PL/pgSQL) + TypeScript `strict` (Edge Functions on Deno & typed SDK) |
| Package manager | pnpm |
| Validation | Zod (single source of truth for Edge Function inputs, webhooks, and client contracts) |
| Client SDK & SSR | `@supabase/supabase-js` v2 (`@supabase/ssr` when paired with SSR web frameworks) |
| Authorization | Row Level Security (RLS) on every `public` table + `private` schema `SECURITY DEFINER` helpers |
| Storage | Supabase Storage (private buckets by default, `{owner_id}/{folder}/{uuid}.{ext}` path convention) |
| Realtime | Supabase Realtime (`Broadcast` & `Presence` with `realtime.messages` RLS authorization) |
| Env | Validated with Zod in `src/config/env.ts` (and `supabase/functions/_shared/env.ts`) |
| Tests | `pgTAP` (`supabase test db` for schema & RLS policies) + Vitest (Edge Functions & client repositories) |

Deviations from this table must be recorded in `docs/DECISIONS.md` before implementation.

---

## 2. Core Principles

1. **RLS is Mandatory on Every `public` Table**: Never create a table in `public` without `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` in the same migration. If a table is backend-only, enable RLS with zero policies (denies all `anon`/`authenticated` Data API access) or place it in the `private` schema.
2. **Optimize RLS for Scale**: Always wrap `auth.uid()` and `auth.jwt()` in `(select auth.uid())` inside RLS policies so PostgreSQL caches the scalar value once per query (`initPlan`) instead of re-evaluating per row. Always specify `TO authenticated` or `TO anon`.
3. **Never Trust `getSession()` on the Server**: In Edge Functions, SSR routes, or backend services, always verify the user token via `await supabase.auth.getUser(jwt)` (or asymmetric JWKS verification)—never `getSession()`, which reads unverified session data.
4. **Never Leak `SUPABASE_SERVICE_ROLE_KEY`**: The `service_role` key bypasses all RLS and must only exist in server-only environment config (`src/config/env.ts` or Edge Function secrets). Never expose it to browsers, mobile apps, or `NEXT_PUBLIC_` variables.
5. **Declarative, Additive Migrations Only**: Never make schema, RLS, bucket, or trigger changes manually in the Supabase Studio dashboard in shared environments. Every change lives in `supabase/migrations/<timestamp>_<name>.sql` using idempotent, non-destructive SQL (`CREATE TABLE IF NOT EXISTS`, `ADD COLUMN IF NOT EXISTS`).
6. **Generated Types + Zod First**: Run `supabase gen types typescript --local > src/types/database.types.ts` after every schema change. Never hand-edit `database.types.ts`. Combine generated row types with Zod schemas for runtime input validation.
7. **Feature-First & Layered Access**: Client applications and Edge Functions never scatter raw `supabase.from(...)` queries across handlers or UI. Wrap table access in feature repositories (`src/features/<name>/<name>.repository.ts`), business rules in services (`<name>.service.ts`), and pure domain logic in pure functions.
8. **Lock Down `SECURITY DEFINER` Functions**: Every `SECURITY DEFINER` function must live in the `private` schema, declare `SET search_path = ''`, fully qualify all references (`public.profiles`, `auth.uid()`), and `REVOKE ALL ... FROM public, anon`.
9. **Views Must Enforce Caller RLS**: Every PostgreSQL view in `public` must be created with `WITH (security_invoker = true)` so it respects the querying user's RLS policies instead of bypassing them as the view owner.
10. **Centralized Copy & Error Dictionary**: Never hardcode user-visible strings, validation messages, or error text in Edge Functions, services, or client helpers. All copy and error messages live in `locales/{lang}.json` (`locales/en.json`, `locales/es.json`).

---

## 3. Folder Structure

```text
locales/                          # Single source of truth for ALL error messages & system copy
├── en.json                       # Default language dictionary (common, auth, storage, validation, errors)
└── es.json                       # Secondary language translation

supabase/                         # Supabase CLI project root
├── config.toml                   # Local development, Auth, Storage, Pooler & Edge Function config
├── seed.sql                      # Deterministic local development seed data (dev-test only)
├── migrations/                   # Timestamped, additive SQL migrations (ordered chronologically)
│   ├── 20260101000000_init_schemas_and_extensions.sql
│   ├── 20260101000001_profiles_and_auth_triggers.sql
│   └── 20260101000002_storage_buckets_and_rls.sql
├── schemas/                      # Optional declarative SQL schema definitions (for `supabase db diff`)
├── tests/                        # pgTAP database & RLS policy test suites (`supabase test db`)
│   ├── 001_rls_profiles.test.sql
│   └── 002_rls_multi_tenant.test.sql
└── functions/                    # Deno Edge Functions (one folder per function)
    ├── _shared/                  # Shared Edge Function infrastructure
    │   ├── cors.ts               # Standard CORS headers
    │   ├── env.ts                # Deno env validation
    │   ├── errors.ts             # AppError + handleEdgeError envelope
    │   ├── handler.ts            # createEdgeHandler wrapper (CORS, Auth, Zod, Error handling)
    │   └── supabase-clients.ts   # User-scoped (RLS) & Admin (service_role) client factories
    └── webhooks-stripe/          # Example Edge Function
        ├── index.ts              # Thin entrypoint using createEdgeHandler
        └── stripe.service.ts     # Idempotent webhook processing logic

src/                              # Typed TypeScript SDK, repositories, services & migration runner
├── config/
│   └── env.ts                    # Zod-validated environment config (local, preview/dev, production)
├── types/
│   └── database.types.ts         # Auto-generated by `supabase gen types typescript --local` (DO NOT EDIT)
├── lib/
│   ├── supabase/
│   │   ├── client.ts             # Public/User-scoped Supabase client (enforces RLS)
│   │   └── admin.ts              # Server-only service_role client (bypasses RLS)
│   ├── errors.ts                 # AppError + PostgrestError / AuthError / StorageError mapper
│   └── logger.ts                 # Structured JSON logger
└── features/                     # One folder per business domain
    └── products/
        ├── products.schema.ts        # Zod schemas + inferred types
        ├── products.repository.ts    # Typed Supabase queries (.from('products').select(...))
        ├── products.service.ts       # Business logic, ownership & domain rules
        ├── products.test.ts          # Co-located unit/integration tests
        └── index.ts                  # Public barrel export
```

### Placement rules

| Artifact is... | Goes in |
|---|---|
| A database table, index, RLS policy, trigger, function, or bucket | `supabase/migrations/<timestamp>_<name>.sql` |
| A `pgTAP` test for RLS policies, constraints, or SQL functions | `supabase/tests/<name>.test.sql` |
| A serverless webhook consumer, Auth Hook, or edge endpoint | `supabase/functions/<function-name>/` |
| Shared Edge Function middleware, CORS, or client factories | `supabase/functions/_shared/` |
| Domain data access, Zod validation, and business rules | `src/features/<name>/` |
| Auto-generated TypeScript database definitions | `src/types/database.types.ts` |

### Import boundaries

- A feature in `src/features/<name>/` may import from `src/lib/`, `src/config/`, and `src/types/`. It must **not** import another feature's internals (use that feature's `index.ts` only).
- `src/lib/supabase/admin.ts` (`service_role` client) must **never** be imported by browser/client bundles or used to service regular user-facing CRUD when RLS should apply.
- `supabase/functions/<fn>/` imports shared utilities only from `../_shared/` and pinned `npm:` or `jsr:` specifiers (never unpinned `https://deno.land/x/` URLs).

---

## 4. Naming Conventions & Size Limits

- **PostgreSQL identifiers**: `snake_case` only, plural table names (`profiles`, `organization_members`, `product_items`), singular column names (`user_id`, `price_minor`, `created_at`).
- **RLS policy names**: descriptive snake_case or sentence naming stating `<role>_<operation>_<table_scope>`, e.g., `"authenticated_select_own_profiles"` or `"org_members_update_projects"`.
- **Indexes**: `idx_<table>_<columns>` (e.g., `idx_products_organization_id`).
- **Migrations**: `YYYYMMDDHHMMSS_<verb>_<subject>.sql` (created via `pnpm db:migration:new <name>`).
- **TypeScript files**: `kebab-case` folders, role suffixes (`*.schema.ts`, `*.repository.ts`, `*.service.ts`, `*.test.ts`).

### Size limits (hard limits, split before exceeding)

| Item | Max lines |
|---|---|
| Any TypeScript source file | 250 |
| Edge Function `index.ts` entrypoint | 80 |
| Service / repository file | 250 (split into `*.queries.ts` and `*.commands.ts` if larger) |
| SQL migration file | 300 (split unrelated domain tables into separate migrations) |
| Function / method | 40 |
| Zod schema file | 150 |
| Test file (`.test.ts` or `.test.sql`) | 300 |

- Generated files (`src/types/database.types.ts`, lockfiles) are exempt and never edited by hand.

---

## 5. Data & Security Flow

```text
Caller (Web / Mobile / Webhook)
  │
  ├── Direct Data API / Storage / Realtime (Anon Key + User JWT)
  │     └── PostgREST / Storage API -> Enforces RLS ((select auth.uid())) -> PostgreSQL
  │
  └── Edge Function / Backend Service
        └── createEdgeHandler (CORS + Auth getUser(jwt) + Zod validation)
              └── Service (business rules)
                    └── Repository (User-scoped client w/ RLS OR Admin client for webhooks)
                          └── PostgreSQL / Supabase Storage / External API
```

- **Never** bypass RLS with the `service_role` client for user-initiated requests. Forward the user's `Authorization` header so PostgreSQL enforces RLS natively.
- **Never** access `auth.users` directly from client queries. Sync needed public fields into `public.profiles` via a `SECURITY DEFINER` trigger on `auth.users`.
- **Always** specify explicit column lists in `.select('id, name, price_minor, created_at')`—never `.select('*')` in production repositories.

---

## 6. Boilerplate Eliminators (use these, do not re-implement)

### 6.1 Dual Supabase Client Factories (`src/lib/supabase/`)

Always separate the RLS-enforcing user client from the RLS-bypassing admin client:

```ts
// src/lib/supabase/client.ts
import { createClient } from "@supabase/supabase-js";
import type { Database } from "@/types/database.types";
import { env } from "@/config/env";

export function createUserClient(accessToken?: string) {
  return createClient<Database>(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: accessToken
      ? { headers: { Authorization: `Bearer ${accessToken}` } }
      : undefined,
  });
}
```

```ts
// src/lib/supabase/admin.ts
import { createClient } from "@supabase/supabase-js";
import type { Database } from "@/types/database.types";
import { env } from "@/config/env";

export const supabaseAdmin = createClient<Database>(
  env.SUPABASE_URL,
  env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { persistSession: false, autoRefreshToken: false } },
);
```

### 6.2 Edge Function Handler Wrapper (`supabase/functions/_shared/handler.ts`)

Handles CORS preflight, JWT verification via `supabase.auth.getUser()`, Zod validation, and standardized JSON error envelopes in one place:

```ts
// supabase/functions/_shared/handler.ts
import { createClient, type SupabaseClient, type User } from "npm:@supabase/supabase-js@2";
import type { ZodType } from "npm:zod@3";
import { corsHeaders } from "./cors.ts";
import { AppError, handleEdgeError } from "./errors.ts";

type EdgeCtx<B> = {
  req: Request;
  body: B;
  user: User | null;
  supabase: SupabaseClient;
};

export function createEdgeHandler<B = unknown>(opts: {
  auth?: boolean | string[]; // true = any signed-in user, string[] = allowed app_metadata.role
  body?: ZodType<B>;
  handle: (ctx: EdgeCtx<B>) => Promise<unknown>;
  status?: number;
}) {
  return async (req: Request): Promise<Response> => {
    if (req.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders });
    }
    try {
      const authHeader = req.headers.get("Authorization");
      const supabase = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SUPABASE_ANON_KEY")!,
        { global: { headers: authHeader ? { Authorization: authHeader } : {} } },
      );

      let user: User | null = null;
      if (opts.auth) {
        if (!authHeader) throw AppError.unauthorized();
        const { data, error } = await supabase.auth.getUser();
        if (error || !data.user) throw AppError.unauthorized();
        user = data.user;

        if (Array.isArray(opts.auth)) {
          const role = user.app_metadata?.role as string | undefined;
          if (!role || !opts.auth.includes(role)) throw AppError.forbidden();
        }
      }

      const body = opts.body ? opts.body.parse(await req.json()) : (undefined as B);
      const data = await opts.handle({ req, body, user, supabase });

      return new Response(JSON.stringify({ success: true, data }), {
        status: opts.status ?? 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    } catch (e) {
      return handleEdgeError(e);
    }
  };
}
```

### 6.3 Centralized Error & PostgREST Mapper (`src/lib/errors.ts`)

Convert `PostgrestError`, `AuthError`, and `StorageError` into typed `AppError` instances mapped to `locales/en.json` so database internals and constraint names never leak to clients:

```ts
// src/lib/errors.ts
import type { PostgrestError } from "@supabase/supabase-js";
import dictionary from "../../locales/en.json";

export type ErrorCode =
  | "BAD_REQUEST" | "UNAUTHORIZED" | "FORBIDDEN" | "NOT_FOUND"
  | "CONFLICT" | "RATE_LIMITED" | "UPSTREAM_ERROR" | "INTERNAL";

export class AppError extends Error {
  constructor(
    readonly code: ErrorCode,
    readonly status: number,
    message: string,
    readonly details: unknown = null,
  ) {
    super(message);
    this.name = "AppError";
  }
  static badRequest(message = dictionary.errors.badRequest, details?: unknown) { return new AppError("BAD_REQUEST", 400, message, details); }
  static unauthorized(message = dictionary.errors.unauthorized) { return new AppError("UNAUTHORIZED", 401, message); }
  static forbidden(message = dictionary.errors.forbidden) { return new AppError("FORBIDDEN", 403, message); }
  static notFound(label: string) { return new AppError("NOT_FOUND", 404, `${label} ${dictionary.common.none.toLowerCase()}`); }
  static conflict(message = dictionary.errors.conflict) { return new AppError("CONFLICT", 409, message); }
  static internal(message = dictionary.errors.internalServerError) { return new AppError("INTERNAL", 500, message); }
}

export function mapPostgrestError(err: PostgrestError, resourceLabel = "Record"): AppError {
  switch (err.code) {
    case "PGRST116": return AppError.notFound(resourceLabel);
    case "23505":    return AppError.conflict(dictionary.errors.conflict);
    case "23503":    return AppError.badRequest(dictionary.errors.badRequest);
    case "42501":    return AppError.forbidden(dictionary.errors.forbidden);
    default:         return AppError.internal();
  }
}
```

### 6.4 Environment Config (`src/config/env.ts`)

```ts
import { z } from "zod";

const envSchema = z.object({
  APP_ENV: z.enum(["development", "preview", "test", "production"]).default("development"),
  SUPABASE_URL: z.string().url(),
  SUPABASE_ANON_KEY: z.string().min(20),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(20),
  DATABASE_URL: z.string().url(),
  DIRECT_URL: z.string().url().optional(),
});

const isProd =
  process.env.VERCEL_ENV === "production" ||
  (!process.env.VERCEL_ENV && process.env.APP_ENV === "production");

export const env = envSchema.parse({
  APP_ENV: process.env.APP_ENV,
  SUPABASE_URL: isProd ? process.env.SUPABASE_URL : process.env.Dev_SUPABASE_URL || process.env.SUPABASE_URL,
  SUPABASE_ANON_KEY: isProd ? process.env.SUPABASE_ANON_KEY : process.env.Dev_SUPABASE_ANON_KEY || process.env.SUPABASE_ANON_KEY,
  SUPABASE_SERVICE_ROLE_KEY: isProd ? process.env.SUPABASE_SERVICE_ROLE_KEY : process.env.Dev_SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY,
  DATABASE_URL: isProd ? process.env.DATABASE_URL : process.env.Dev_DATABASE_URL || process.env.DATABASE_URL,
  DIRECT_URL: isProd ? process.env.DIRECT_URL : process.env.Dev_DIRECT_URL || process.env.DIRECT_URL,
});
```

---

## 7. Database, RLS & Safe Migration Rules

1. **Every Table Has RLS Enabled & Indexed Foreign Keys**:
   - Enable RLS immediately: `alter table public.<table_name> enable row level security;`.
   - PostgreSQL does **not** auto-index foreign keys. Create an explicit B-tree index on every foreign key (`user_id`, `organization_id`, `parent_id`).
2. **High-Performance RLS Policies (`docs/SUPABASE_RULES.md`)**:
   - Always use `(select auth.uid())` and `(select auth.jwt())` instead of bare `auth.uid()`.
   - Always specify `to authenticated` or `to anon`.
   - Write distinct policies per action (`for select`, `for insert`, `for update`, `for delete`). `for update` must specify both `using (...)` and `with check (...)`.
   - For multi-tenant membership checks, use a `SECURITY DEFINER` function in the `private` schema with `set search_path = ''` to avoid recursive RLS joins.
3. **Data-Safe Versioned Migrations**:
   - Author migrations in `supabase/migrations/` via `pnpm db:migration:new <name>`.
   - Use additive, idempotent DDL (`create table if not exists`, `add column if not exists`, `create index if not exists`).
   - Destructive SQL (`drop table`, `drop column`, `truncate`) is strictly blocked unless explicitly approved and annotated with `-- @allow-destructive`.
   - **Local & QA (`dev-test` / `dev`)**: Run `pnpm db:reset` locally or `pnpm db:migrate:dev` on `dev`.
   - **Production (`main`)**: `pnpm db:migrate:prod` runs **only when merging to `main`** in CI and refuses to execute on a local machine.
4. **Money & Timestamps**:
   - Store money in integer minor units (`bigint` cents) or `numeric(12,2)`, never `real`/`float`.
   - Store timestamps as `timestamptz not null default now()` in UTC, with an automated `private.handle_updated_at()` trigger.

---

## 8. Auth, Storage, Edge Functions & Realtime Rules

1. **Auth & RBAC (`app_metadata` vs `user_metadata`)**:
   - `raw_user_meta_data` (`user_metadata`) can be modified by any signed-in user via `supabase.auth.updateUser()`. **Never** store or trust roles, permissions, or billing status in `user_metadata`.
   - Store roles in `raw_app_meta_data` (`app_metadata`) via `service_role` / Custom Access Token Hooks, or in a dedicated `public.organization_members` table protected by RLS.
2. **Storage Buckets & Policies**:
   - Buckets are private (`public = false`) by default and declare explicit `file_size_limit` and `allowed_mime_types` in SQL migrations.
   - Object paths follow `{owner_id}/{category}/{uuid}.{ext}` so RLS policies on `storage.objects` can verify `(storage.foldername(name))[1] = (select auth.uid())::text`.
3. **Edge Functions & Webhooks**:
   - Validate all inbound payloads with Zod. Verify webhook signatures (Stripe, GitHub, Supabase DB Webhooks) against raw request bodies (`await req.text()`) and make handlers idempotent.
   - Set timeouts on outbound `fetch` calls and normalize third-party errors into `AppError`.
4. **Realtime**:
   - Prefer `Broadcast` and `Presence` with `realtime.messages` RLS authorization over high-fanout `postgres_changes`.
   - Always filter subscriptions and clean up channels (`supabase.removeChannel(channel)`) when finished.

---

## 9. Validation, Types & Errors

- Regenerate `src/types/database.types.ts` (`pnpm db:types`) after every migration and commit it in the same PR.
- One Zod schema per operation: `createXSchema`, `updateXSchema = createXSchema.partial()`, `listXQuerySchema`.
- No `any`. Use `unknown` and narrow.
- Never return raw `PostgrestError` objects to callers; map them through `mapPostgrestError` into `AppError`.

---

## 10. Security Checklist (every migration, table & function)

- [ ] `ALTER TABLE public.<table> ENABLE ROW LEVEL SECURITY;` present on every table
- [ ] RLS policies use `(select auth.uid())`, specify `TO authenticated`/`anon`, and include `WITH CHECK` on `INSERT`/`UPDATE`
- [ ] Foreign keys and RLS filter columns have explicit B-tree indexes
- [ ] Views in `public` declare `WITH (security_invoker = true)`
- [ ] `SECURITY DEFINER` functions reside in `private` schema with `SET search_path = ''` and restricted `EXECUTE` grants
- [ ] Authorization checks rely on `app_metadata` or database tables—never `user_metadata`
- [ ] `SUPABASE_SERVICE_ROLE_KEY` is never exposed to clients or used to bypass RLS on user requests
- [ ] Storage buckets set `file_size_limit`, `allowed_mime_types`, and path-ownership RLS on `storage.objects`
- [ ] Edge Functions verify JWT via `supabase.auth.getUser()` and validate inputs with Zod

---

## 11. Performance & Connection Management

- Always paginate list queries (`.range(from, to)` with default limit 20, max 100). Never return unbounded tables.
- Select only required columns (`.select('id, title, status')`), never `.select('*')`.
- Use Supavisor transaction mode (port `6543`, `?pgbouncer=true`, `{ prepare: false }`) for serverless/Edge database connections, and session/direct mode (port `5432`) exclusively for migrations.
- Run `EXPLAIN (ANALYZE, BUFFERS)` on complex RLS policies to confirm index scans and `InitPlan` caching.

---

## 12. Testing (`pgTAP` + Vitest)

- **Database & RLS (`supabase/tests/*.test.sql`)**: `pgTAP` tests verifying table constraints, triggers, and RLS policies across 3 personas:
  1. `anon` (unauthenticated guest)
  2. `authenticated` owner (`User A`)
  3. `authenticated` non-owner (`User B` attempting to read/modify `User A`'s rows)
- **Repositories, Services & Edge Functions (`src/**/*.test.ts`)**: Vitest unit and integration tests covering happy path, validation failure, `FORBIDDEN` / `NOT_FOUND`, and edge cases.

### Mandatory: write AND run tests

- Every new or changed migration, RLS policy, repository, service, or Edge Function **must** ship with tests in the same change. No test, not done.
- After writing code, **run the quality gate yourself**:
  ```bash
  pnpm typecheck && pnpm lint && pnpm test && pnpm build
  ```
  And when local Supabase Docker is running:
  ```bash
  pnpm db:lint && pnpm test:db
  ```
- If anything fails, fix it and re-run until green. Report the final result in your reply.
- If tests cannot be run in the current environment, state so explicitly and list the exact commands for the user to run. Never claim tests passed without running them.

---

## 13. Workflow for the AI Code Writer

When asked to build or change something, follow this order:

0. **Branch first & align with style**: check `BRANCHES.md` and git for an existing branch (`npm run branch:start -- feat/<name> "Description"`). All work branches off and targets `dev-test`. Never work directly on `main` or `dev`. Read `docs/ai/STYLE_AND_SKILLS.md` to adapt to developer preferences.
1. **Locate**: identify the owning feature in `src/features/<name>/` and related SQL migrations in `supabase/migrations/`.
2. **Search for reuse**: check `src/lib/`, `supabase/functions/_shared/`, and `private` SQL helpers before creating new utilities.
3. **Migration & RLS first**: write additive SQL migration (`supabase/migrations/`) with table, indexes, RLS enabled, and `(select auth.uid())` policies -> regenerate `src/types/database.types.ts` (`pnpm db:types`).
4. **Bottom-up**: Zod schema (`*.schema.ts`) -> repository (`*.repository.ts`) -> service (`*.service.ts`) -> Edge Function (`supabase/functions/<name>/index.ts`) or exported SDK method.
5. **Test**: write `pgTAP` RLS tests in `supabase/tests/` and Vitest tests in `src/features/<name>/`.
6. **Verify**: run `pnpm typecheck && pnpm lint && pnpm test && pnpm build` until green. Check size limits (section 4) and the security checklist (section 10).
7. **Document & PR**: tick the matching item in `docs/TASK_LIST.md`; log architectural choices in `docs/DECISIONS.md`; open PR targeting `dev-test` (`npm run branch:pr -- "feat: summary"`).
8. **Log request & learn**: record the request in `docs/ai/REQUEST_LOG.md` and any style corrections in `docs/ai/STYLE_AND_SKILLS.md`.

---

## 14. Anti-Patterns (never do)

- Creating any table in `public` without enabling RLS in the same migration.
- Calling `auth.uid()` or `auth.jwt()` in RLS policies without wrapping in `(select auth.uid())`.
- Omitting `WITH CHECK` on `INSERT` or `UPDATE` RLS policies, or using `TO public` unintentionally.
- Creating views in `public` without `with (security_invoker = true)`.
- Writing `SECURITY DEFINER` functions without `set search_path = ''`.
- Calling `supabase.auth.getSession()` on the server or in Edge Functions to authenticate users instead of `supabase.auth.getUser()`.
- Trusting `user_metadata` (`raw_user_meta_data`) for authorization roles or tenant access.
- Using `SUPABASE_SERVICE_ROLE_KEY` in client code or to bypass RLS for standard user queries.
- Editing `src/types/database.types.ts` by hand or modifying already-merged SQL migrations.
- Making manual schema or policy changes in Supabase Studio without a committed migration file.
- Committing or working directly on `main` or `dev`, or running production migrations locally (`db:migrate:prod`).
- Emojis in error messages, code comments, or commit messages.

---

## 15. Definition of Done

- Follows folder, schema, and layer rules; no import-boundary violations
- Every table has RLS enabled, indexed foreign keys, and `pgTAP` / integration coverage
- Types generated (`database.types.ts`) and paired with Zod schemas end-to-end
- Validated, authorized, and error-handled through `createEdgeHandler` and `mapPostgrestError`
- Tests written for all new or changed SQL policies, repositories, services, and Edge Functions, and **actually run green**
- No file or function exceeds the size limits
- Code committed on a dedicated branch (`feat/*`, `fix/*`, `chore/*`) branched off `dev-test` and tracked in `BRANCHES.md`
- PR opened targeting `dev-test` and approved by user before merge (`npm run branch:finish`)
- `docs/TASK_LIST.md` updated; `.env.example` updated if env changed

---

## 16. Git & Branching Strategy (`dev-test` -> `dev` -> `main`)

> **MANDATORY**: Direct work or commits on `main` or `dev` are strictly forbidden. All feature, fix, chore, and refactor branches originate from and target `dev-test`. Always use `npm run branch:*` commands to maintain `BRANCHES.md`.

| Branch | Role | Supabase Environment & DB Scope |
|---|---|---|
| `main` | Production / stable releases | Supabase Production Project (`SUPABASE_URL` / `DATABASE_URL` Prod only). Auto-runs `db:migrate:prod` on merge. |
| `dev` | QA / Staging releases | Supabase Preview Branch / Staging Project (`Preview & Development` scope or `Dev_*`). Auto-runs `db:migrate:dev`. |
| `dev-test` | Local integration & testing | Local Supabase CLI (`supabase start`) or Dev project via `.env.development`. Primary target for all PRs. |
| `feat/*`, `fix/*`, `chore/*` | Working branches | Branched off `dev-test`, target `dev-test`, tracked in `BRANCHES.md`. |

### Quick Reference Commands
```bash
# 1. Start or resume work (syncs dev-test & updates BRANCHES.md):
npm run branch:start -- feat/your-feature-name "Short description"

# 2. Run verification, push, and open PR to dev-test:
npm run branch:pr -- "feat: your PR title"

# 3. After user testing & approval, mark Merged and return to dev-test:
npm run branch:finish
```

---

## 17. Related Documents

- Detailed SQL, RLS, Storage, Auth Hook & Edge Function rules: [docs/SUPABASE_RULES.md](./docs/SUPABASE_RULES.md)
- Branching, PRs, commits, releases and maintenance: [docs/PROJECT_GUIDELINES.md](./docs/PROJECT_GUIDELINES.md)
- Product scope and architecture overview: [docs/PROJECT_PLAN.md](./docs/PROJECT_PLAN.md)

<!-- END:supabase-agent-rules -->

