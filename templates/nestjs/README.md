# {{PROJECT_NAME}}

{{ONE_LINE_DESCRIPTION}}

NestJS REST API. This repository follows a documented architecture and workflow. Start with the documents below.

## Documentation

| File | Purpose |
|---|---|
| [AGENTS.md](./AGENTS.md) | Architecture and coding rules (read first, also for AI agents) |
| [docs/PROJECT_PLAN.md](./docs/PROJECT_PLAN.md) | Scope, architecture overview, roadmap |
| [docs/API_RULES.md](./docs/API_RULES.md) | URLs, envelopes, pagination, errors, versioning |
| [docs/PROJECT_GUIDELINES.md](./docs/PROJECT_GUIDELINES.md) | Branching, PRs, commits, releases, maintenance |
| [docs/TASK_LIST.md](./docs/TASK_LIST.md) | Progress tracker |
| [docs/DECISIONS.md](./docs/DECISIONS.md) | Architecture decision records |
| [docs/ISSUES.md](./docs/ISSUES.md) | Parked blockers |
| [locales/en.json](./locales/en.json) | Centralized dictionary for all API error messages & status copy |

## First steps

1. Scaffold the app in this folder:
   ```bash
   npx @nestjs/cli new . --package-manager pnpm --strict --skip-git
   ```
2. Add the dependencies from the stack table in `AGENTS.md`:
   ```bash
   pnpm add zod nestjs-zod drizzle-orm @nestjs/config @nestjs/swagger @nestjs/throttler @nestjs/terminus nestjs-pino pino-http helmet
   pnpm add -D drizzle-kit pino-pretty supertest @types/supertest
   ```
   Add your database driver (for example `postgres` or `pg`) and, if needed, `bullmq` or `@nestjs/schedule`.
3. Add or confirm these scripts in `package.json`:
   ```json
   {
     "scripts": {
       "start:dev": "nest start --watch",
       "build": "nest build",
       "typecheck": "tsc --noEmit",
       "lint": "eslint .",
       "test": "jest",
       "test:e2e": "jest --config ./test/jest-e2e.json",
       "db:generate": "drizzle-kit generate",
       "db:migrate": "drizzle-kit migrate",
       "db:studio": "drizzle-kit studio"
     }
   }
   ```
4. Create the `main` and `dev` branches and enable branch protection (see `docs/PROJECT_GUIDELINES.md`).
5. Fill in `docs/PROJECT_PLAN.md`, record decisions in `docs/DECISIONS.md`, then work through `docs/TASK_LIST.md` from Phase 0.

## Quality gate

```bash
pnpm typecheck && pnpm lint && pnpm test && pnpm test:e2e && pnpm build
```

Run this quality gate locally before opening pull requests to ensure code quality and build stability.
