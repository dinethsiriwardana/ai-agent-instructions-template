# Architecture Decision Records (ADR)

Log of technical decisions for **{{PROJECT_NAME}}**. Add a new entry whenever you choose, change or reject a stack component, architectural pattern, vendor or convention. Never rewrite history: if a decision changes, add a new ADR that supersedes the old one and update the old status.

## How to add an entry

Copy the template at the bottom, use the next number, and set the status. Link the ADR from the PR that implements it.

**Statuses:** Proposed, Accepted, Superseded by ADR-XXX, Rejected.

---

## ADR-001: Baseline stack

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Context:** The project needs a consistent, maintainable full-stack web foundation that one developer or a small team can own.
- **Decision:** Next.js (App Router) with TypeScript strict, Tailwind CSS 4, Zod, Drizzle ORM on PostgreSQL, TanStack Query, React Hook Form, Vitest and Playwright, managed with pnpm.
- **Consequences:** Single language across client and server; schemas shared between forms and APIs; standard PostgreSQL keeps hosting portable. Requires discipline on layering (see `AGENTS.md`).
- **Alternatives considered:** Separate backend service (more operational overhead for v1); Prisma (heavier runtime, less SQL transparency).

## ADR-002: Layered architecture with thin routes

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Context:** Business logic mixed into routes and components becomes untestable and duplicated.
- **Decision:** Enforce `UI -> hooks -> API route -> service -> repository -> DB`, with pure domain engines separated from framework code. Routes use `createHandler`; Server Actions use `createAction`.
- **Consequences:** More files, but each is small and testable. Domain engines can be tested without a database.

## ADR-003: Route handlers by default, Server Actions for form mutations only

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Context:** Next.js offers both route handlers and Server Actions; mixing them freely leads to inconsistent validation, auth and error handling.
- **Decision:** Route handlers are the default for client-consumed data. Server Actions are allowed for form mutations when wrapped in `createAction` and calling the same service layer.
- **Consequences:** One validation and error pipeline for both entry points.

## ADR-004: Authentication approach

- **Status:** Proposed
- **Date:** YYYY-MM-DD
- **Context:** [Describe needs: email and password, OAuth, magic link, roles, session length.]
- **Decision:** [Auth.js / custom session with JWT or database sessions / managed provider]. Behind `server/auth/session.ts` so the provider can be swapped.
- **Consequences:** [Trade-offs, migration cost, security responsibilities.]

## ADR-005: Hosting and database provider

- **Status:** Proposed
- **Date:** YYYY-MM-DD
- **Context:** [Budget, region, scale, team skills.]
- **Decision:** [For example: Vercel + managed PostgreSQL.]
- **Consequences:** [Vendor lock-in risks and the portability measures from `PROJECT_PLAN.md` section 15.]

## ADR-006: Brand tokens, font and icon set

- **Status:** Proposed
- **Date:** YYYY-MM-DD
- **Context:** `docs/UI_RULES.md` ships neutral starter values.
- **Decision:** Primary color [hex], font [name], icon set [name], chart library [name].
- **Consequences:** Changing these later means editing tokens in `globals.css` only.

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
