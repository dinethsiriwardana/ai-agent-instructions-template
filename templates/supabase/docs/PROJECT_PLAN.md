# {{PROJECT_NAME}} - Project Plan

**Version:** 0.1 (draft)
**Date:** YYYY-MM-DD
**Owner:** {{OWNER_NAME}}
**Status:** Draft | Approved | In progress | Released

> How to use this document: replace every text in `[square brackets]`, delete the guidance lines starting with `>` once a section is filled in, and keep the change log (section 17) current. This plan is the source of truth for scope. `docs/TASK_LIST.md` tracks execution.

---

## 1. Project Overview

[Two to four sentences: what the product is, who it is for, and the main value it delivers.]

> Guidance: state what makes it different from existing tools, not only what it does.

**One-line pitch:** {{ONE_LINE_DESCRIPTION}}

**Target users:** [primary persona], [secondary persona]
**First release audience:** [who gets v1]

## 2. Problem Statement

[Describe the problem users face today, why current solutions fall short, and what happens if it stays unsolved.]

## 3. Objectives and Success Metrics

| # | Objective | Measure of success |
|---|---|---|
| 1 | [Objective] | [Metric and target, for example "80% of users complete onboarding"] |
| 2 | [Objective] | [Metric and target] |
| 3 | [Objective] | [Metric and target] |

## 4. Proposed Solution

[Describe how the product solves the problem at a high level: main concepts, main data flows, and core backend capabilities.]

## 5. Users, Roles and Permissions (RLS Tenancy Model)

| Role | Description | Can do (RLS Policy Scope) | Cannot do |
|---|---|---|---|
| `anon` | Unauthenticated guest | [Read public catalog / invoke public auth endpoints] | [Read or write any private tables or buckets] |
| `authenticated` (member) | Signed-in standard user | [Select/Insert/Update own rows or organization rows] | [Access other users' or tenants' rows] |
| `authenticated` (admin) | Organization / System Admin | [Manage tenant members, settings, and billing] | [Bypass cross-tenant isolation] |

> Guidance: decide single-user (`user_id = (select auth.uid())`) vs multi-tenant (`organization_id in (select private.user_organization_ids())`) ownership here. This choice drives every table schema and RLS policy.

## 6. Core Features

Describe each feature with user value, main behavior and acceptance criteria.

### 6.1 [Feature name]

- **User value:** [why it matters]
- **Behavior:** [tables, RLS policies, RPCs/Edge Functions, Storage buckets, Realtime events]
- **Acceptance criteria:**
  - [ ] [Given / when / then statement]
  - [ ] [RLS verified for `anon`, `User A` (owner), and `User B` (non-owner)]
- **Priority:** Must | Should | Could

### 6.2 [Feature name]

[Repeat the structure above for each feature.]

## 7. Domain Model & Database Schema

| Table (`public.*`) | Purpose | Key columns | Ownership / RLS Strategy |
|---|---|---|---|
| `profiles` | Public user profile synced from `auth.users` | `id`, `email`, `full_name`, `avatar_url`, `created_at` | `id = (select auth.uid())` |
| `[table_name]` | [purpose] | [columns] | [RLS policy summary] |

> Guidance: all tables live in `supabase/migrations/`. Money uses integer minor units (`bigint`); timestamps use `timestamptz` in UTC. Every foreign key has an explicit B-tree index.

## 8. System Architecture

### 8.1 Technology stack

| Component | Technology | Responsibility |
|---|---|---|
| Database | Supabase PostgreSQL 15+ | Persistent relational storage, triggers, views, RPCs |
| Authorization | Row Level Security (RLS) + `private` helpers | Fine-grained per-row access control enforced in DB |
| Authentication | Supabase Auth (GoTrue) + Custom Access Token Hooks | Sign-up, sign-in, OAuth, MFA, JWT issuance |
| Storage | Supabase Storage | S3-backed object buckets with RLS policies on `storage.objects` |
| Serverless Compute | Supabase Edge Functions (Deno + TypeScript) | Third-party webhooks, custom workflows, external API orchestration |
| Realtime | Supabase Realtime (`Broadcast` & `Presence`) | Low-latency live updates and presence rooms |
| Client / Data Layer | `@supabase/supabase-js` + generated TypeScript types + Zod | Type-safe repositories, services, and schema validation |
| Testing | `pgTAP` (`supabase test db`) + Vitest | Database/RLS policy verification and service/function unit tests |

### 8.2 Layered architecture

```text
Client / Webhook Caller
  |
  +-- Direct Data API / Storage / Realtime (Anon Key + User JWT)
  |     |
  |     v
  |   PostgREST / Storage / Realtime --> RLS Policies ((select auth.uid())) --> PostgreSQL
  |
  +-- Edge Functions (supabase/functions/<name>/index.ts)
        |
        v
      createEdgeHandler (CORS, Auth getUser(), Zod validation, Error envelope)
        |
        v
      Services (business rules) --> Repositories (typed Supabase client) --> PostgreSQL / External APIs
```

Full rules: `AGENTS.md` and `docs/SUPABASE_RULES.md`.

### 8.3 External Integrations & Webhooks

| Integration | Purpose | Trigger / Entrypoint | Auth method | Docs link | In v1? |
|---|---|---|---|---|---|
| [Stripe / Resend / etc.] | [Purpose] | [Edge Function / DB Webhook] | [Webhook signature + API key] | [URL] | [Yes / No] |

## 9. Non-Functional Requirements

| Area | Requirement |
|---|---|
| Query Performance | Indexed RLS policies (`(select auth.uid())`); p95 read queries under 100ms; Edge Functions p95 under 400ms |
| Availability | [For example: 99.9% monthly uptime] |
| Connection Pooling | Supavisor Transaction Mode (port 6543, `?pgbouncer=true`) for serverless/app queries; Direct (port 5432) for migrations |
| Security | 100% RLS coverage on `public` schema; see section 12 |
| Scalability | [Expected active users, row growth, storage volume, Realtime concurrent connections] |
| Observability | Structured JSON logs in Edge Functions, `pg_stat_statements` query monitoring |

## 10. Localization & Error Copy

- **Default locale:** `en` (`locales/en.json`)
- **Additional locales:** `es` (`locales/es.json`)
- **Rule:** All error codes, validation messages, and user-facing strings are resolved from `locales/{lang}.json`.

## 11. Scope

### Included in Version 1

- [Feature]
- [Feature]
- [Feature]

### Excluded from Version 1

- [Feature deferred]
- [Feature deferred]

## 12. Security and Privacy

Baseline requirements for every Supabase project:

- Row Level Security (RLS) enabled on every table in `public`, verified with `pgTAP` tests for `anon`, `User A`, and `User B`.
- Views in `public` created with `with (security_invoker = true)`.
- `SECURITY DEFINER` functions placed in `private` schema with `set search_path = ''` and `REVOKE ALL FROM public, anon`.
- Authorization roles stored in `app_metadata` or RLS-protected tables—never in user-editable `user_metadata`.
- `SUPABASE_SERVICE_ROLE_KEY` restricted strictly to server/Edge secrets, never exposed to client bundles.
- Storage buckets private by default with explicit `file_size_limit`, `allowed_mime_types`, and path-prefix RLS policies.
- Automated daily database backups / Point-in-Time Recovery (PITR) with a tested restore procedure.

A user must never be able to read, insert, update, or delete another user's or tenant's data.

## 13. Development Roadmap

| Phase | Main activities | Estimated duration |
|---|---|---|
| 0. Discovery | Requirements, domain modeling, tenancy design, acceptance criteria | [x weeks] |
| 1. Foundation | Repo, Supabase CLI init (`supabase/`), env config, base schemas, CI quality gate | [x weeks] |
| 2. Auth & Profiles | `public.profiles` sync trigger, Auth providers, RBAC claims/tables, RLS tests | [x weeks] |
| 3. Core Schema & Storage | Domain migrations, RLS policies, Storage buckets & policies, generated types | [x weeks] |
| 4 to N. Feature Phases | Repositories, services, RPCs, Edge Functions, Realtime channels per feature | [x weeks each] |
| N+1. Quality & Release | `pgTAP` audit, performance index review (`supabase inspect db`), production release | [x weeks] |

## 14. Testing and Quality Assurance

- `pgTAP` tests (`supabase/tests/*.test.sql`) for every table's RLS policies, constraints, and triggers (`pnpm test:db`).
- Unit & integration tests (Vitest) for repositories, services, Zod schemas, and Edge Function handlers (`pnpm test`).
- SQL lint checks (`supabase db lint`) and schema diff checks.
- Quality gate for every PR: `pnpm typecheck && pnpm lint && pnpm test && pnpm build`.

## 15. Deployment and Environment Promotion (`dev-test` -> `dev` -> `main`)

- **Local (`dev-test`)**: Local Supabase CLI stack (`supabase start`, `supabase db reset`) + `.env.development`.
- **QA / Staging (`dev`)**: Supabase Preview Branch / Staging Project; auto-applies `db:migrate:dev` on push to `dev`.
- **Production (`main`)**: Supabase Production Project; auto-applies `db:migrate:prod` **only on merge to `main`**.

## 16. Risks and Future Enhancements

### Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Unindexed foreign key or slow RLS subquery | Med | High | Mandatory B-tree index rule + `(select auth.uid())` + `pgTAP` / `EXPLAIN ANALYZE` check |

### Future enhancements (post v1)

- [Idea]
- [Idea]

## 17. Open Questions and Change Log

### Open questions

| # | Question | Owner | Due | Resolution |
|---|---|---|---|---|
| 1 | [Question] | [Name] | [Date] | [Pending] |

### Change log

| Version | Date | Change | Approved by |
|---|---|---|---|
| 0.1 | YYYY-MM-DD | Initial draft | {{OWNER_NAME}} |

