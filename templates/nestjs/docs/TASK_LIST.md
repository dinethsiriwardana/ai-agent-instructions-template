# Master Task List: {{PROJECT_NAME}} (NestJS API)

Tracks end-to-end implementation progress. Source documents: [PROJECT_PLAN.md](./PROJECT_PLAN.md), [PROJECT_GUIDELINES.md](./PROJECT_GUIDELINES.md), [API_RULES.md](./API_RULES.md), [AGENTS.md](../AGENTS.md).

## How to use this list

- Status: `[ ]` not started, `[~]` in progress, `[x]` done, `[!]` blocked (link the entry in `ISSUES.md`).
- Each task has an ID (`P1.2`), a branch name when active, and a one-line acceptance criterion.
- One task = one branch = one PR. Tick the box in the same PR that completes the work.
- Add feature phases from `PROJECT_PLAN.md` section 6. Do not add work that is not in the plan without updating the plan.
- A phase is done only when the quality gate passes: `pnpm typecheck && pnpm lint && pnpm test && pnpm test:e2e && pnpm build`.

---

## Phase 0: Discovery and Planning

- [ ] **P0.1 Requirements**
  - [ ] Complete `docs/PROJECT_PLAN.md` (overview, objectives, roles, scope in and out).
  - [ ] Acceptance criteria and endpoint list for every core feature.
- [ ] **P0.2 API design**
  - [ ] Draft resources, payloads and error cases following `docs/API_RULES.md`.
- [ ] **P0.3 Technical decisions**
  - [ ] Record auth approach, hosting, database/queue provider and tenancy in `docs/DECISIONS.md`.

## Phase 1: Project Foundation and Architecture

- [ ] **P1.1 Repository and tooling**
  - [ ] Create repo with `main` and `dev` branches; protect both.
  - [ ] Scaffold NestJS (TypeScript strict, pnpm); configure ESLint, Prettier, path aliases.
  - [ ] Add scripts: `start:dev`, `build`, `typecheck`, `lint`, `test`, `test:e2e`, `db:generate`, `db:migrate`.
- [ ] **P1.2 Folder structure and core helpers**
  - [ ] Create the layout from `AGENTS.md` section 3.
  - [ ] `config/env.ts` (Zod) and `.env.example`.
  - [ ] `common/errors/app-error.ts`, `AllExceptionsFilter`, `ResponseInterceptor`, `ZodValidationPipe` wiring.
  - [ ] Pino logger with request id; `helmet`, CORS, throttler.
  - [ ] Pagination schema and helper; CRUD base repository/service.
  - [ ] Integration `http-client` base.
- [ ] **P1.3 Database**
  - [ ] Provision dev, staging and production databases separately.
  - [ ] Drizzle client module, base schema, first migration verified on a clean database.
- [ ] **P1.4 CI/CD and hosting**
  - [ ] GitHub Actions workflow (typecheck, lint, unit, e2e with Postgres service, build).
  - [ ] Container image build; staging from `dev`, production from `main`.
  - [ ] Health endpoints (`/health/live`, `/health/ready`), graceful shutdown.
  - [ ] PR template and branch protection active.

## Phase 2: Authentication and Authorization (`src/auth/`)

- [ ] **P2.1 Authentication**
  - [ ] Password hashing (argon2id or bcrypt), login, token/session issuance, refresh and logout.
- [ ] **P2.2 Account flows**
  - [ ] Registration, password reset (if in scope), rate limiting on auth endpoints.
- [ ] **P2.3 Authorization**
  - [ ] Global auth guard (private by default), `@Public()`, `@Roles()`, `@CurrentUser()`.
  - [ ] Ownership checks in services; test that user A cannot read user B data.
- [ ] **P2.4 Seed data**
  - [ ] Seed script for a demo user and sample data (development only).

## Phase 3: Platform Services

- [ ] **P3.1 API contract**
  - [ ] OpenAPI generated and published (non-production); error and pagination schemas documented.
- [ ] **P3.2 Background work (if in scope)**
  - [ ] Queue module, one sample job, retry and dead-letter policy.
- [ ] **P3.3 Observability**
  - [ ] Error tracking, metrics or tracing, uptime check.

## Phase 4 to N: Feature Phases (one block per module)

> Copy this block for every feature from `PROJECT_PLAN.md` section 6.

- [ ] **P4.1 [Module]: data layer**
  - [ ] Zod schemas (`create`, `update`, `listQuery`) and DTOs.
  - [ ] Drizzle table and migration (owner column, indexes on foreign keys).
  - [ ] Repository and service with ownership checks.
  - [ ] Unit and integration tests.
- [ ] **P4.2 [Module]: API**
  - [ ] Controller, module wiring, OpenAPI decorators, roles.
  - [ ] e2e tests for success, validation failure, forbidden and not found.
- [ ] **P4.3 [Module]: verification**
  - [ ] Acceptance criteria demonstrated; client team notified of contract changes.

## Phase N+1: Quality Assurance, Security and Release

- [ ] **QA.1 Automated checks**
  - [ ] Typecheck, lint, unit, e2e and build pass with zero errors and warnings.
  - [ ] Coverage at least 80% on services and domain engines.
- [ ] **QA.2 Security review**
  - [ ] Security checklist in `AGENTS.md` section 10 passed for every endpoint.
  - [ ] `pnpm audit` reviewed; secrets scan clean; Swagger protected in production.
- [ ] **QA.3 Performance**
  - [ ] Load test against targets in `PROJECT_PLAN.md` section 9; slow queries indexed.
- [ ] **QA.4 Release**
  - [ ] Backups configured and a test restore performed.
  - [ ] Staging validated; release PR `dev` -> `main` merged; version tagged.
  - [ ] Changelog updated; smoke test on production; rollback plan confirmed.

## Phase N+2: Post-release Maintenance (recurring)

- [ ] Weekly: triage `docs/ISSUES.md` and GitHub issues; check CI health.
- [ ] Monthly: dependency updates on `chore/*` branch; `pnpm audit`; review logs and errors.
- [ ] Quarterly: framework and major dependency upgrades; backup restore test; review `AGENTS.md` and `API_RULES.md` for drift.

---

## Progress Summary

| Phase | Status | Notes |
|---|---|---|
| 0. Discovery | Not started | |
| 1. Foundation | Not started | |
| 2. Authentication | Not started | |
| 3. Platform services | Not started | |
| 4 to N. Features | Not started | |
| N+1. QA and release | Not started | |
