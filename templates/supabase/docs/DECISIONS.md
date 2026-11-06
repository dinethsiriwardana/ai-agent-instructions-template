# Architecture Decision Records (ADR)

Log of technical decisions for **{{PROJECT_NAME}}**. Add a new entry whenever you choose, change or reject a stack component, architectural pattern, tenancy model, or convention. Never rewrite history: if a decision changes, add a new ADR that supersedes the old one and update the old status.

## How to add an entry

Copy the template at the bottom, use the next number, and set the status. Link the ADR from the PR that implements it.

**Statuses:** Proposed, Accepted, Superseded by ADR-XXX, Rejected.

---

## ADR-001: Baseline Supabase architecture

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Context:** The project needs a secure, scalable, and type-safe backend-as-a-service and PostgreSQL foundation with declarative migrations, fine-grained authorization, file storage, realtime events, and edge compute.
- **Decision:** Use Supabase CLI (`supabase/`), PostgreSQL 15+ with mandatory Row Level Security (RLS), Supabase Auth, Supabase Storage, Deno Edge Functions, `@supabase/supabase-js` v2 with generated TypeScript types (`database.types.ts`), Zod validation, `pgTAP` for database/RLS testing, and Vitest for TypeScript unit/integration tests.
- **Consequences:** Authorization is enforced directly at the database row level; schema changes are 100% declarative and reproducible via `supabase db reset`; TypeScript types stay synchronized with PostgreSQL schema.
- **Alternatives considered:** Custom ORM-only backend without RLS (requires duplicating authorization checks in every endpoint and prevents safe direct client/Realtime access).

## ADR-002: High-performance RLS with `(select auth.uid())` and `private` schema helpers

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Context:** Naive RLS policies that call `auth.uid()` directly or perform unindexed recursive joins across membership tables degrade query performance at scale.
- **Decision:** Wrap all `auth.uid()` and `auth.jwt()` calls in `(select auth.uid())` so PostgreSQL caches them via `InitPlan`, index every foreign key column, and encapsulate multi-tenant membership lookups inside `stable` `SECURITY DEFINER` functions in the `private` schema with `set search_path = ''`.
- **Consequences:** Consistently fast index-backed RLS execution and zero exposure of internal helper functions over PostgREST.

## ADR-003: Separation of User-Scoped (RLS) and Admin (`service_role`) Clients

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Context:** Using the `service_role` key for normal user requests bypasses all RLS policies and risks cross-tenant data leaks if a service filter is forgotten.
- **Decision:** Provide two distinct client factories: `createUserClient(accessToken)` (uses `SUPABASE_ANON_KEY` + caller's JWT so RLS is enforced) for all user-initiated operations, and `supabaseAdmin` (`SUPABASE_SERVICE_ROLE_KEY`) restricted strictly to verified webhooks, cron jobs, and admin provisioning.
- **Consequences:** Defense-in-depth between application services and PostgreSQL RLS.

## ADR-004: Multi-tenancy and RBAC model

- **Status:** Proposed
- **Date:** YYYY-MM-DD
- **Context:** [Describe whether data is owned per individual user (`user_id`) or per organization/workspace (`organization_id`), and what roles exist.]
- **Decision:** [Per-user ownership via `user_id` / Multi-tenant via `public.organization_members` + `private.user_organization_ids()` + `app_metadata` roles]. Never use `user_metadata` for authorization.
- **Consequences:** [Trade-offs, query patterns, and onboarding flow.]

## ADR-005: Connection pooling and environment promotion (`dev-test` -> `dev` -> `main`)

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Context:** Serverless functions and Edge runtimes can exhaust PostgreSQL connection limits if connected directly on port 5432, and manual dashboard edits cause schema drift across environments.
- **Decision:** Use Supavisor Transaction Mode (`DATABASE_URL` port `6543`, `?pgbouncer=true`) for runtime queries and Direct Mode (`DIRECT_URL` port `5432`) exclusively for migrations. Enforce additive migrations across `dev-test` (Local CLI), `dev` (Staging/Preview), and `main` (Production merge-only).
- **Consequences:** Safe connection scaling and zero-downtime, data-safe schema promotion.

---

## Template

```markdown
## ADR-XXX: Title

- **Status:** Proposed | Accepted | Superseded by ADR-XXX | Rejected
- **Date:** YYYY-MM-DD
- **Context:** What problem or constraint forces a decision?
- **Decision:** What was chosen, stated plainly.
- **Consequences:** Benefits, costs, risks, follow-up work.
- **Alternatives considered:** Options rejected and why.
```

