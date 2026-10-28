# Architecture Decision Records (ADR)

Log of technical decisions for **{{PROJECT_NAME}}** (NestJS). Add a new entry whenever you choose, change or reject a stack component, architectural pattern, vendor or convention. Never rewrite history: if a decision changes, add a new ADR that supersedes the old one and update the old status.

## How to add an entry

Copy the template at the bottom, use the next number, and set the status. Link the ADR from the PR that implements it.

**Statuses:** Proposed, Accepted, Superseded by ADR-XXX, Rejected.

---

## ADR-001: Baseline stack

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Context:** The backend needs a consistent, maintainable foundation that one developer or a small team can own and that serves web and mobile clients.
- **Decision:** NestJS with TypeScript strict, Zod (`nestjs-zod`), Drizzle ORM on PostgreSQL, `@nestjs/config`, `nestjs-pino`, `@nestjs/swagger`, Jest and Supertest, managed with pnpm.
- **Consequences:** Single language with the web client; schemas can be shared; standard PostgreSQL keeps hosting portable. Requires discipline on module boundaries (see `AGENTS.md`).
- **Alternatives considered:** Express/Fastify without a framework (less structure); Prisma or TypeORM (heavier runtime or less SQL transparency); `class-validator` DTOs (duplicate type definitions next to Zod).

## ADR-002: Module-per-feature, layered architecture

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Context:** Business logic mixed into controllers becomes untestable and duplicated.
- **Decision:** Enforce `Controller -> Service -> Repository -> DB`, with pure domain engines in `domain/` and cross-module access only through exported providers or events.
- **Consequences:** More files, each small and testable. Domain engines can be tested without a database or Nest.

## ADR-003: Global validation, error and response pipeline

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Context:** Per-controller validation and error handling produce inconsistent contracts.
- **Decision:** Global `ZodValidationPipe`, `AllExceptionsFilter`, `ResponseInterceptor`, and private-by-default guards; `AppError` is the only error type thrown by features.
- **Consequences:** One response and error shape for all clients (see `docs/API_RULES.md`).

## ADR-004: Authentication approach

- **Status:** Proposed
- **Date:** YYYY-MM-DD
- **Context:** [Describe needs: email and password, OAuth, API keys, roles, token lifetime, mobile and web clients.]
- **Decision:** [JWT access + refresh tokens / cookie sessions / managed provider]. Behind `AuthModule` so the mechanism can be swapped.
- **Consequences:** [Trade-offs, revocation strategy, security responsibilities.]

## ADR-005: Hosting, database and queue provider

- **Status:** Proposed
- **Date:** YYYY-MM-DD
- **Context:** [Budget, region, scale, team skills.]
- **Decision:** [For example: containerized on provider X + managed PostgreSQL + Redis for queues.]
- **Consequences:** [Vendor lock-in risks and portability measures from `PROJECT_PLAN.md` section 15.]

## ADR-006: Tenancy and data ownership

- **Status:** Proposed
- **Date:** YYYY-MM-DD
- **Context:** [Single-tenant, multi-tenant or per-user ownership.]
- **Decision:** [Owner column (`user_id` / `tenant_id`) on every user-owned table; every repository query filters by it.]
- **Consequences:** [Impact on schema, indexes and authorization tests.]

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
