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

[Describe how the product solves the problem at a high level: main concepts, main user flow, and the core mechanism (for example a rules engine, marketplace, workflow, or content platform).]

## 5. Users, Roles and Permissions

| Role | Description | Can do | Cannot do |
|---|---|---|---|
| [Anonymous] | [Not signed in] | [View public pages] | [Everything else] |
| [User] | [Signed-in standard user] | [Manage own data] | [Access other users' data] |
| [Admin] | [Operator] | [Manage users and settings] | [-] |

> Guidance: decide single-tenant, multi-tenant or per-user data ownership here. This choice drives the schema (owner column) and every authorization check.

## 6. Core Features

Describe each feature with user value, main behavior and acceptance criteria.

### 6.1 [Feature name]

- **User value:** [why it matters]
- **Behavior:** [what it does]
- **Acceptance criteria:**
  - [ ] [Given / when / then statement]
  - [ ] [Given / when / then statement]
- **Priority:** Must | Should | Could

### 6.2 [Feature name]

[Repeat the structure above for each feature.]

## 7. Domain Model

| Entity | Purpose | Key fields | Relations |
|---|---|---|---|
| `users` | Accounts | id, email, role, created_at | owns many [entity] |
| `[entity]` | [purpose] | [fields] | [relations] |

> Guidance: keep this at entity level. Table definitions live in `src/server/db/schema/`. Money uses integer minor units; timestamps are UTC.

## 8. System Architecture

### 8.1 Technology stack

| Component | Technology | Responsibility |
|---|---|---|
| Frontend | Next.js (App Router) + TypeScript | UI and navigation |
| Styling | Tailwind CSS 4 with design tokens | Responsive UI (`docs/UI_RULES.md`) |
| Backend | Next.js route handlers and server services | Business logic and data processing |
| Database | PostgreSQL [provider] | Persistent data |
| ORM | Drizzle ORM | Queries and migrations |
| Validation | Zod | Schemas and inferred types |
| Authentication | [Auth.js / custom session / provider] | Registration, login, sessions |
| Hosting | [Vercel / Azure / other] | Deployment |
| Email / storage / payments | [provider or "not in v1"] | [responsibility] |

### 8.2 Layered architecture

```text
User
  |
  v
Next.js app (app/ routes, Server Components)
  |
  +-- Client: hooks (TanStack Query) -> feature api.ts
  |
  v
API routes / Server Actions  (createHandler / createAction)
  |
  v
Services (business rules)  <-- pure domain engines (no framework imports)
  |
  v
Repositories --> Drizzle ORM --> PostgreSQL
  |
  +--> server/integrations/* --> external APIs
```

Full rules: `AGENTS.md`.

### 8.3 Integrations

| Integration | Purpose | Auth method | Docs link | In v1? |
|---|---|---|---|---|
| [Name] | [Purpose] | [API key / OAuth] | [URL] | [Yes / No] |

## 9. Non-Functional Requirements

| Area | Requirement |
|---|---|
| Performance | [For example: p75 LCP under 2.5s; API p95 under 500ms] |
| Availability | [For example: 99.5% monthly] |
| Accessibility | WCAG 2.2 AA target; keyboard operable; contrast at least 4.5:1 |
| Responsiveness | Works from 320px up; no horizontal page overflow |
| Security | See section 12 |
| Browser support | [Latest two versions of Chrome, Safari, Firefox, Edge] |
| Scalability | [Expected users, data volume, growth] |
| Observability | Structured logs, error tracking, uptime check |

## 10. Localization (optional)

- **i18n enabled:** Yes | No
- **Default locale:** [for example en]
- **Other locales:** [list]
- **Register for customer-facing text:** [formal / neutral]
- **Currency and date formats:** [config values used by `src/shared/lib/format.ts`]

## 11. Scope

### Included in Version 1

- [Feature]
- [Feature]
- [Feature]

### Excluded from Version 1

- [Feature deferred]
- [Feature deferred]

> Guidance: any request outside "Included" goes to section 16 (future enhancements) or to the change log as an approved scope change.

## 12. Security and Privacy

Baseline requirements for every project:

- Secure authentication and session management (HttpOnly, Secure, SameSite cookies).
- Authorization check on every user-owned resource in the service layer.
- Zod validation of all inputs; output shaped through DTOs.
- Secrets only in environment variables and the host secret store.
- Rate limiting on auth, public and expensive endpoints.
- Database backups with a tested restore procedure.
- Privacy policy and data-retention rules: [describe].
- Personal data stored: [list]. Data deletion and export approach: [describe].

A user must never be able to read or modify another user's data.

## 13. Development Roadmap

| Phase | Main activities | Estimated duration |
|---|---|---|
| 0. Discovery | Requirements, user flows, wireframes, acceptance criteria | [x weeks] |
| 1. Foundation | Repo, tooling, design tokens, database, CI, deployment | [x weeks] |
| 2. Authentication | Registration, login, sessions, roles | [x weeks] |
| 3. Design system and shell | Shared components, app shell, mobile navigation | [x weeks] |
| 4 to N. Feature phases | One phase per core feature group | [x weeks each] |
| N+1. Quality and release | Testing, security review, performance, deployment | [x weeks] |

**Indicative total:** [x to y weeks]. Phases may overlap; this is a planning estimate, not a commitment.

## 14. Testing and Quality Assurance

- Unit tests for services, schemas, helpers and domain engines (domain engines get the most coverage).
- Integration tests for repositories against a test database.
- E2E tests (Playwright) for critical flows: [sign up, core action, checkout or equivalent].
- Manual checks: mobile viewports (320 to 430px), tablet, desktop; keyboard navigation.
- Key scenarios to cover:
  - [Scenario 1]
  - [Scenario 2]
  - [Scenario 3]
- Quality gate for every PR: `pnpm typecheck && pnpm lint && pnpm test && pnpm build`.

## 15. Deployment and Portability

- Hosting: [provider]; database: [provider].
- Environment-specific configuration managed outside source code (`.env.example` documents all variables).
- Keep business logic independent of hosting-specific services; use standard PostgreSQL features.
- Document deployment steps and migration procedure in the project README.
- Rollback plan: previous deployment plus database backup point.

## 16. Risks and Future Enhancements

### Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| [Risk] | Low / Med / High | Low / Med / High | [Mitigation] |

### Future enhancements (post v1)

- [Idea]
- [Idea]

> Prioritize enhancements by user feedback and demonstrated value, not by novelty.

## 17. Open Questions and Change Log

### Open questions

| # | Question | Owner | Due | Resolution |
|---|---|---|---|---|
| 1 | [Question] | [Name] | [Date] | [Pending] |

### Change log

| Version | Date | Change | Approved by |
|---|---|---|---|
| 0.1 | YYYY-MM-DD | Initial draft | {{OWNER_NAME}} |
