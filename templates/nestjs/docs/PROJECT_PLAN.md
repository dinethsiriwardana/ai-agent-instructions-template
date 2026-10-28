# {{PROJECT_NAME}} - Project Plan (NestJS API)

**Version:** 0.1 (draft)
**Date:** YYYY-MM-DD
**Owner:** {{OWNER_NAME}}
**Status:** Draft | Approved | In progress | Released

> How to use this document: replace every text in `[square brackets]`, delete the guidance lines starting with `>` once a section is filled in, and keep the change log (section 17) current. This plan is the source of truth for scope. `docs/TASK_LIST.md` tracks execution.

---

## 1. Project Overview

[Two to four sentences: what the service does, which clients consume it, and the main value it delivers.]

**One-line pitch:** {{ONE_LINE_DESCRIPTION}}

**API consumers:** [web app, mobile app, third parties]
**First release audience:** [who gets v1]

## 2. Problem Statement

[Describe the problem, why current solutions fall short, and what happens if it stays unsolved.]

## 3. Objectives and Success Metrics

| # | Objective | Measure of success |
|---|---|---|
| 1 | [Objective] | [Metric and target, for example "p95 latency under 300 ms"] |
| 2 | [Objective] | [Metric and target] |

## 4. Proposed Solution

[Main concepts, core flows and the core mechanism (rules engine, workflow, marketplace, content platform).]

## 5. Users, Roles and Permissions

| Role | Description | Can do | Cannot do |
|---|---|---|---|
| [Anonymous] | [Not signed in] | [Public endpoints] | [Everything else] |
| [User] | [Signed-in user] | [Manage own data] | [Access other users' data] |
| [Admin] | [Operator] | [Manage users and settings] | [-] |

> Guidance: decide single-tenant, multi-tenant or per-user ownership here. It drives the schema (owner column) and every authorization check.

## 6. Core Features

### 6.1 [Feature / module name]

- **User value:** [why it matters]
- **Behavior:** [what it does]
- **Endpoints:** [list of `METHOD /api/v1/path`]
- **Acceptance criteria:**
  - [ ] [Given / when / then statement]
  - [ ] [Given / when / then statement]
- **Priority:** Must | Should | Could

### 6.2 [Feature / module name]

[Repeat the structure above for each feature.]

## 7. Domain Model

| Entity | Purpose | Key fields | Relations |
|---|---|---|---|
| `users` | Accounts | id, email, role, created_at | owns many [entity] |
| `[entity]` | [purpose] | [fields] | [relations] |

> Guidance: entity level only. Table definitions live in `src/database/schema/`. Money uses integer minor units; timestamps are UTC.

## 8. System Architecture

### 8.1 Technology stack

| Component | Technology | Responsibility |
|---|---|---|
| Framework | NestJS + TypeScript | HTTP API and modules |
| Database | PostgreSQL [provider] | Persistent data |
| ORM | Drizzle ORM | Queries and migrations |
| Validation | Zod (`nestjs-zod`) | DTOs and inferred types |
| Authentication | [JWT / sessions / provider] | Login and authorization |
| Queue / cache | [BullMQ + Redis / none in v1] | Background jobs, caching |
| API docs | OpenAPI (`@nestjs/swagger`) | Contract for clients |
| Hosting | [provider] | Deployment |
| Email / storage / payments | [provider or "not in v1"] | [responsibility] |

### 8.2 Layered architecture

```text
Client (web / mobile)
  |
  v
Global middleware -> guards -> ZodValidationPipe
  |
  v
Controllers (thin)
  |
  v
Services (business rules)  <-- pure domain engines (no framework imports)
  |
  v
Repositories --> Drizzle ORM --> PostgreSQL
  |
  +--> integrations/* --> external APIs        jobs/* --> queues
```

Full rules: `AGENTS.md`. Contract rules: `docs/API_RULES.md`.

### 8.3 Integrations

| Integration | Purpose | Auth method | Docs link | In v1? |
|---|---|---|---|---|
| [Name] | [Purpose] | [API key / OAuth] | [URL] | [Yes / No] |

## 9. Non-Functional Requirements

| Area | Requirement |
|---|---|
| Performance | [For example: API p95 under 500 ms] |
| Availability | [For example: 99.5% monthly] |
| Security | See section 12 |
| Scalability | [Expected users, requests per second, data volume] |
| Observability | Structured logs with request id, error tracking, uptime and readiness checks |
| Compatibility | URI-versioned API; no breaking change within a major version |

## 10. Localization (optional)

- **Localized API messages:** Yes | No
- **Default locale / other locales:** [list]
- **Currency and date formats:** [ISO 8601 UTC dates; currency codes]

## 11. Scope

### Included in Version 1

- [Feature]
- [Feature]

### Excluded from Version 1

- [Feature deferred]

> Guidance: any request outside "Included" goes to section 16 or to the change log as an approved scope change.

## 12. Security and Privacy

- Authentication and session/token management per ADR-004.
- Authorization check on every user-owned resource in the service layer.
- Zod validation of all inputs; output shaped through DTOs.
- Secrets only in environment variables and the host secret store.
- Rate limiting, `helmet`, restricted CORS, body size limits.
- Database backups with a tested restore procedure.
- Privacy policy and data-retention rules: [describe]. Personal data stored: [list]. Deletion and export approach: [describe].

A user must never be able to read or modify another user's data.

## 13. Development Roadmap

| Phase | Main activities | Estimated duration |
|---|---|---|
| 0. Discovery | Requirements, API design, acceptance criteria | [x weeks] |
| 1. Foundation | Repo, tooling, config, database, CI, deployment | [x weeks] |
| 2. Authentication | Login, tokens/sessions, roles | [x weeks] |
| 3. Platform services | Error pipeline, pagination, logging, health, OpenAPI | [x weeks] |
| 4 to N. Feature phases | One phase per module group | [x weeks each] |
| N+1. Quality and release | Load test, security review, deployment | [x weeks] |

## 14. Testing and Quality Assurance

- Unit tests for services, DTO schemas, helpers and domain engines.
- Integration tests for repositories against a test database.
- e2e tests (Supertest) for critical flows: [sign in, core action].
- Contract check: OpenAPI generated and reviewed for each change.
- Quality gate for every PR: `pnpm typecheck && pnpm lint && pnpm test && pnpm test:e2e && pnpm build`.

## 15. Deployment and Portability

- Hosting: [provider]; database: [provider]; container image built in CI.
- Environment configuration outside source code (`.env.example` documents all variables).
- Migrations run as an explicit deploy step; rollback plan: previous image plus database backup point.
- Keep business logic independent of hosting-specific services; use standard PostgreSQL features.

## 16. Risks and Future Enhancements

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| [Risk] | Low / Med / High | Low / Med / High | [Mitigation] |

### Future enhancements (post v1)

- [Idea]

## 17. Open Questions and Change Log

| # | Question | Owner | Due | Resolution |
|---|---|---|---|---|
| 1 | [Question] | [Name] | [Date] | [Pending] |

| Version | Date | Change | Approved by |
|---|---|---|---|
| 0.1 | YYYY-MM-DD | Initial draft | {{OWNER_NAME}} |
