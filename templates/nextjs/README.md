# {{PROJECT_NAME}}

{{ONE_LINE_DESCRIPTION}}

Next.js web app. This repository follows a documented architecture and workflow. Start with the documents below.

## Documentation

| File | Purpose |
|---|---|
| [AGENTS.md](./AGENTS.md) | Architecture and coding rules (read first, also for AI agents) |
| [docs/PROJECT_PLAN.md](./docs/PROJECT_PLAN.md) | Scope, architecture overview, roadmap |
| [docs/UI_RULES.md](./docs/UI_RULES.md) | Design tokens, components, mobile rules |
| [docs/PROJECT_GUIDELINES.md](./docs/PROJECT_GUIDELINES.md) | Branching, PRs, commits, releases, maintenance |
| [docs/TASK_LIST.md](./docs/TASK_LIST.md) | Progress tracker |
| [docs/DECISIONS.md](./docs/DECISIONS.md) | Architecture decision records |
| [docs/ISSUES.md](./docs/ISSUES.md) | Parked blockers |

## First steps

1. Scaffold the app in this folder:
   ```bash
   pnpm create next-app@latest . --ts --tailwind --app --src-dir --import-alias "@/*" --use-pnpm
   ```
2. Add the dependencies from the stack table in `AGENTS.md`:
   ```bash
   pnpm add zod drizzle-orm @tanstack/react-query react-hook-form @hookform/resolvers server-only
   pnpm add -D drizzle-kit vitest @vitejs/plugin-react playwright @playwright/test prettier
   ```
   Add your database driver (for example `postgres` or `pg`).
3. Add these scripts to `package.json`:
   ```json
   {
     "scripts": {
       "dev": "next dev",
       "build": "next build",
       "start": "next start",
       "typecheck": "tsc --noEmit",
       "lint": "eslint .",
       "test": "vitest run",
       "test:watch": "vitest",
       "test:e2e": "playwright test",
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
pnpm typecheck && pnpm lint && pnpm test && pnpm build
```

Run this quality gate locally before opening pull requests to ensure code quality and build stability.
