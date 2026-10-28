# Master Task List: {{PROJECT_NAME}}

Tracks end-to-end implementation progress. Source documents: [PROJECT_PLAN.md](./PROJECT_PLAN.md), [PROJECT_GUIDELINES.md](./PROJECT_GUIDELINES.md), [UI_RULES.md](./UI_RULES.md), [AGENTS.md](../AGENTS.md).

## How to use this list

- Status: `[ ]` not started, `[~]` in progress, `[x]` done, `[!]` blocked (link the entry in `ISSUES.md`).
- Each task has an ID (`P1.2`), a branch name when active, and a one-line acceptance criterion.
- One task = one branch = one PR. Tick the box in the same PR that completes the work.
- Add feature phases (Phase 4 and beyond) from `PROJECT_PLAN.md` section 6. Do not add work that is not in the plan without updating the plan.
- A phase is done only when every item passes the quality gate: `pnpm typecheck && pnpm lint && pnpm test && pnpm build`, plus a mobile check for UI work.

---

## Phase 0: Discovery and Planning

- [ ] **P0.1 Requirements**
  - [ ] Complete `docs/PROJECT_PLAN.md` (overview, objectives, roles, scope in and out).
  - [ ] Write acceptance criteria for every core feature.
- [ ] **P0.2 UX**
  - [ ] User flows for the main journeys.
  - [ ] Wireframes for key screens at mobile and desktop widths.
- [ ] **P0.3 Technical decisions**
  - [ ] Record stack, auth approach, hosting and database provider in `docs/DECISIONS.md`.
  - [ ] Decide tenancy and data ownership model.
  - [ ] Choose brand primary color, font and icon set.

## Phase 1: Project Foundation and Architecture

- [ ] **P1.1 Repository and tooling**
  - [ ] Create repo with `main` and `dev` branches; protect both (PR required, no direct pushes).
  - [ ] Scaffold Next.js (App Router, TypeScript strict, Tailwind 4, pnpm).
  - [ ] Configure ESLint, Prettier, path aliases (`@/features`, `@/shared`, `@/server`, `@/config`).
  - [ ] Add scripts: `dev`, `build`, `typecheck`, `lint`, `test`, `db:generate`, `db:migrate`.
  - [ ] Set up Vitest and Playwright.
- [ ] **P1.2 Folder structure and core helpers**
  - [ ] Create the folder layout from `AGENTS.md` section 3.
  - [ ] Implement `config/env.ts`, `config/routes.ts` and `.env.example`.
  - [ ] Implement `server/http/` (`createHandler`, `createAction`, `errors`, `response`).
  - [ ] Implement `server/lib/logger.ts`.
  - [ ] Implement `shared/lib/api-client.ts` and `shared/lib/format.ts`.
  - [ ] Implement `createCrudService` and `createResourceHooks` factories.
- [ ] **P1.3 Design tokens and styling**
  - [ ] Semantic color tokens and `*-soft` tints in `src/app/globals.css`.
  - [ ] Radius, shadow and spacing tokens; font via `next/font`.
  - [ ] Token search check: no raw hex or arbitrary colors outside `globals.css`.
- [ ] **P1.4 Database**
  - [ ] Provision database (dev, staging, production separately).
  - [ ] Install Drizzle ORM and Drizzle Kit; create `server/db/client.ts`.
  - [ ] Base schema and first migration; verify migrate on a clean database.
- [ ] **P1.5 CI/CD and hosting**
  - [ ] GitHub Actions workflow running typecheck, lint, test, build.
  - [ ] Preview deployments for PRs; staging from `dev`; production from `main`.
  - [ ] Set environment variables in each environment.
  - [ ] PR template and branch protection rules active.

## Phase 2: Authentication and Authorization (`server/auth/`)

- [ ] **P2.1 Session management**
  - [ ] Implement `getSession()`, session cookies (HttpOnly, Secure, SameSite) and logout.
  - [ ] Password hashing (argon2id or bcrypt) and credential validation.
- [ ] **P2.2 Account flows**
  - [ ] Registration, login, logout, password reset (if in scope).
  - [ ] Real-time form validation with shared Zod schemas.
  - [ ] Rate limiting on auth endpoints.
- [ ] **P2.3 Authorization**
  - [ ] Route protection in `proxy.ts` and layouts.
  - [ ] Role checks via `createHandler({ auth })`.
  - [ ] Ownership checks in services; test that user A cannot read user B data.
- [ ] **P2.4 Seed data**
  - [ ] Seed script for a demo user and sample data (development only).

## Phase 3: Design System and App Shell (`src/shared/components/`)

- [ ] **P3.1 Primitives (`ui/`)**
  - [ ] `Button` (primary, secondary, ghost, icon, loading).
  - [ ] `Input`, `Select`, `Textarea`, `Checkbox`, `DatePicker`.
- [ ] **P3.2 Composites (`common/`)**
  - [ ] `Card`, `CardHeader`, `StatCard`, `TrendBadge`, `Badge`, `StatusBadge`.
  - [ ] `ProgressItem`, `ActivityItem`, `ChartCard`, `InsightBanner`.
  - [ ] `DataTable` (pagination, skeleton, empty state, mobile scroll or card stack).
  - [ ] `Modal`, `ConfirmDialog`, `Toast`.
  - [ ] `EmptyState`, `StateBoundary`.
- [ ] **P3.3 Forms and templates**
  - [ ] `FormWrapper`, `FormField`, `FormSelect` (React Hook Form + Zod resolver).
  - [ ] `PageTemplate`, `ListPageTemplate`, `DetailPageTemplate`.
- [ ] **P3.4 App shell**
  - [ ] `DashboardLayout` with sidebar and mobile drawer.
  - [ ] Top bar with search, notifications indicator and user menu.
  - [ ] Zero horizontal overflow at 320px; tap targets at least 44px.

## Phase 4 to N: Feature Phases (one block per feature group)

> Copy this block for every feature group from `PROJECT_PLAN.md` section 6.

- [ ] **P4.1 [Feature name]: data layer**
  - [ ] Zod schemas (`create`, `update`, `listQuery`).
  - [ ] Drizzle table and migration (owner column, indexes on foreign keys).
  - [ ] Repository and service with ownership checks.
  - [ ] Unit and integration tests.
- [ ] **P4.2 [Feature name]: API**
  - [ ] Route handlers via `createHandler` (or Server Actions via `createAction`).
  - [ ] Client `api.ts` and query hooks.
- [ ] **P4.3 [Feature name]: UI**
  - [ ] List, detail and create/edit views with loading, empty and error states.
  - [ ] Mobile layout verified (320px, 375px, tablet, desktop).
- [ ] **P4.4 [Feature name]: verification**
  - [ ] Acceptance criteria from the plan demonstrated.
  - [ ] E2E test for the main flow.

## Phase N+1: Dashboards, Reporting and Analytics (if in scope)

- [ ] **Dashboard**
  - [ ] Greeting, stat cards, main and side columns, attention items.
- [ ] **Reports and charts**
  - [ ] Charts wrapped in `ChartCard` using chart tokens.
  - [ ] Period filters, empty and error states.

## Phase N+2: Quality Assurance, Security and Release

- [ ] **QA.1 Automated checks**
  - [ ] `pnpm typecheck`, `pnpm lint`, `pnpm test`, `pnpm build` all pass with zero errors and zero warnings.
  - [ ] Coverage at least 80% on `server/` and `features/*/server/`.
  - [ ] E2E suite passes on CI.
- [ ] **QA.2 Manual audits**
  - [ ] Mobile audit (320px to 430px): no horizontal overflow, tap targets at least 44px.
  - [ ] Keyboard and screen-reader pass on forms and dialogs.
  - [ ] Contrast check (4.5:1 for body text).
- [ ] **QA.3 Security review**
  - [ ] Security checklist in `AGENTS.md` section 10 passed for every endpoint.
  - [ ] Dependency audit (`pnpm audit`) reviewed.
  - [ ] Security headers verified; secrets not present in client bundles.
- [ ] **QA.4 Performance**
  - [ ] Bundle size reviewed; large client components lazy-loaded.
  - [ ] Core pages meet the targets in `PROJECT_PLAN.md` section 9.
- [ ] **QA.5 Release**
  - [ ] Backups configured and a test restore performed.
  - [ ] Staging validated; release PR `dev` -> `main` merged; version tagged.
  - [ ] Changelog updated; smoke test on production; rollback plan confirmed.

## Phase N+3: Post-release Maintenance (recurring)

- [ ] Weekly: triage `docs/ISSUES.md` and GitHub issues; check CI health.
- [ ] Monthly: dependency updates on `chore/*` branch; `pnpm audit`; review logs and errors.
- [ ] Quarterly: framework and major dependency upgrades; backup restore test; review `AGENTS.md` and `UI_RULES.md` for drift.

---

## Progress Summary

| Phase | Status | Notes |
|---|---|---|
| 0. Discovery | Not started | |
| 1. Foundation | Not started | |
| 2. Authentication | Not started | |
| 3. Design system and shell | Not started | |
| 4 to N. Features | Not started | |
| N+1. Analytics | Not started | |
| N+2. QA and release | Not started | |
