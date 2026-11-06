# Master Task List: {{PROJECT_NAME}}

Tracks end-to-end implementation progress. Source documents: [PROJECT_PLAN.md](./PROJECT_PLAN.md), [PROJECT_GUIDELINES.md](./PROJECT_GUIDELINES.md), [SUPABASE_RULES.md](./SUPABASE_RULES.md), [AGENTS.md](../AGENTS.md).

## How to use this list

- Status: `[ ]` not started, `[~]` in progress, `[x]` done, `[!]` blocked (link the entry in `ISSUES.md`).
- Each task has an ID (`P1.2`), a branch name when active, and a one-line acceptance criterion.
- One task = one branch = one PR targeting `dev-test`. Tick the box in the same PR that completes the work.
- Add feature phases (Phase 4 and beyond) from `PROJECT_PLAN.md` section 6. Do not add work that is not in the plan without updating the plan.
- A phase is done only when every item passes the quality gate: `pnpm typecheck && pnpm lint && pnpm test && pnpm build` (plus `pnpm test:db` for SQL/RLS changes).

---

## Phase 0: Discovery and Planning

- [ ] **P0.1 Requirements & Domain Model**
  - [ ] Complete `docs/PROJECT_PLAN.md` (overview, objectives, roles, tables, scope in and out).
  - [ ] Write acceptance criteria and RLS persona matrix (`anon`, `User A`, `User B`) for every core feature.
- [ ] **P0.2 Technical Decisions**
  - [ ] Record tenancy model (per-user vs multi-tenant orgs), Auth providers, and Edge Function scope in `docs/DECISIONS.md`.

## Phase 1: Project Foundation and Supabase CLI Setup

- [ ] **P1.1 Repository and Branching**
  - [ ] Create repo with `main`, `dev`, and `dev-test` branches; protect `main` and `dev` (PR required, no direct pushes).
  - [ ] Configure TypeScript (`strict`), ESLint, Prettier, Vitest, and path aliases (`@/*`).
- [ ] **P1.2 Supabase CLI & Core Infrastructure**
  - [ ] Initialize `supabase/config.toml`, `supabase/migrations/`, `supabase/tests/`, and `supabase/seed.sql`.
  - [ ] Create initial migration `00000000000000_init_private_schema.sql` (`private` schema + `private.handle_updated_at()` trigger function).
  - [ ] Implement `src/config/env.ts` (with `Dev_*` non-prod fallback) and `.env.example`.
  - [ ] Implement `src/lib/supabase/client.ts` (user-scoped RLS client) and `src/lib/supabase/admin.ts` (`service_role` client).
  - [ ] Implement `src/lib/errors.ts` (`AppError` + `mapPostgrestError` wired to `locales/en.json`).
  - [ ] Implement `supabase/functions/_shared/` (`cors.ts`, `errors.ts`, `handler.ts` with `createEdgeHandler`).

## Phase 2: Authentication, Profiles & RBAC

- [ ] **P2.1 Profiles Table & Auth Sync Trigger**
  - [ ] Create `public.profiles` migration with RLS enabled and `(select auth.uid()) = id` policies.
  - [ ] Create `private.handle_new_user()` trigger on `auth.users` (`set search_path = ''`).
- [ ] **P2.2 Multi-Tenancy / RBAC Setup**
  - [ ] Create organization/role tables (or Custom Access Token Hook) using `app_metadata` / `private` `SECURITY DEFINER` helpers.
  - [ ] Write `pgTAP` tests in `supabase/tests/001_rls_profiles.test.sql` verifying `anon`, `User A`, and `User B` access.
- [ ] **P2.3 Seed Data & Type Generation**
  - [ ] Populate `supabase/seed.sql` with deterministic demo users and sample records for `dev-test`.
  - [ ] Generate `src/types/database.types.ts` via `pnpm db:types`.

## Phase 3: Storage Buckets & Shared Edge Function Helpers

- [ ] **P3.1 Storage Buckets & RLS Policies**
  - [ ] Create private Storage buckets in a migration with explicit `file_size_limit` and `allowed_mime_types`.
  - [ ] Add `storage.objects` RLS policies enforcing `(storage.foldername(name))[1] = (select auth.uid())::text`.
- [ ] **P3.2 Edge Functions & Webhook Pipeline**
  - [ ] Verify `createEdgeHandler` CORS preflight, `supabase.auth.getUser()` verification, and Zod body validation.

## Phase 4 to N: Feature Phases (one block per feature domain)

> Copy this block for every feature group from `PROJECT_PLAN.md` section 6.

- [ ] **P4.1 [Feature name]: SQL Migration & RLS**
  - [ ] Additive migration in `supabase/migrations/` (`CREATE TABLE IF NOT EXISTS`, foreign key B-tree indexes, `updated_at` trigger, `ENABLE ROW LEVEL SECURITY`).
  - [ ] Per-operation RLS policies (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) using `(select auth.uid())` and explicit `TO authenticated` / `TO anon`.
  - [ ] Regenerate `src/types/database.types.ts` (`pnpm db:types`).
  - [ ] Write `pgTAP` RLS tests in `supabase/tests/` covering `anon`, owner, and non-owner personas.
- [ ] **P4.2 [Feature name]: Schemas, Repository & Service**
  - [ ] Zod schemas (`create`, `update`, `listQuery`) in `src/features/<name>/<name>.schema.ts`.
  - [ ] Typed repository (`<name>.repository.ts`) with explicit column selection and pagination.
  - [ ] Service (`<name>.service.ts`) with business rules and error mapping.
  - [ ] Unit and integration tests (`<name>.test.ts`).
- [ ] **P4.3 [Feature name]: Edge Functions / RPC / Realtime (if needed)**
  - [ ] Edge Function via `createEdgeHandler` or `SECURITY INVOKER` database RPC.
  - [ ] Realtime `Broadcast` channel authorization if live updates are in scope.

## Phase N+1: Quality Assurance, Security Audit and Release

- [ ] **QA.1 Automated Quality Gate**
  - [ ] `pnpm typecheck`, `pnpm lint`, `pnpm test`, `pnpm build` pass with zero errors.
  - [ ] `pnpm db:lint` and `pnpm test:db` (`pgTAP`) pass on a clean `supabase db reset`.
  - [ ] Coverage at least 80% on `src/features/` and `src/lib/`.
- [ ] **QA.2 Supabase Security & Performance Audit**
  - [ ] Security checklist in `AGENTS.md` section 10 passed for every table, view, function, bucket, and Edge Function.
  - [ ] Confirm zero tables in `public` without RLS enabled and zero views without `security_invoker = true`.
  - [ ] Confirm all `SECURITY DEFINER` functions set `search_path = ''` and reside in `private`.
  - [ ] Confirm all foreign keys have explicit B-tree indexes.
- [ ] **QA.3 Release (`dev-test` -> `dev` -> `main`)**
  - [ ] Promote `dev-test` -> `dev`; verify staging migration (`db:migrate:dev`) and QA tests.
  - [ ] Merge release PR `dev` -> `main`; verify automatic production migration (`db:migrate:prod`), tag release, and update `CHANGELOG.md`.

## Phase N+2: Post-release Maintenance (recurring)

- [ ] Weekly: triage `docs/ISSUES.md` and GitHub issues; review slow queries and Supabase advisors.
- [ ] Monthly: dependency and Supabase CLI updates on a `chore/*` branch targeting `dev-test`; `pnpm audit`.
- [ ] Quarterly: test database backup restore procedure; review `AGENTS.md` and `docs/SUPABASE_RULES.md` for drift.

---

## Progress Summary

| Phase | Status | Notes |
|---|---|---|
| 0. Discovery | Not started | |
| 1. Foundation & CLI | Not started | |
| 2. Auth, Profiles & RBAC | Not started | |
| 3. Storage & Edge Infra | Not started | |
| 4 to N. Features | Not started | |
| N+1. QA, Security & Release | Not started | |

