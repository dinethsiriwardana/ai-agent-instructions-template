# {{PROJECT_NAME}}

{{ONE_LINE_DESCRIPTION}}

Supabase backend & data platform (PostgreSQL, Row Level Security, Auth, Storage, Edge Functions, Realtime, and typed TypeScript SDK). This repository follows a documented architecture and workflow. Start with the documents below.

## Documentation

| File | Purpose |
|---|---|
| [AGENTS.md](./AGENTS.md) | Architecture and coding rules (read first, also for AI agents) |
| [docs/SUPABASE_RULES.md](./docs/SUPABASE_RULES.md) | SQL schema, RLS performance, Auth, Storage, Edge Functions & Realtime rules |
| [docs/PROJECT_PLAN.md](./docs/PROJECT_PLAN.md) | Scope, domain model, RLS tenancy overview, roadmap |
| [docs/PROJECT_GUIDELINES.md](./docs/PROJECT_GUIDELINES.md) | Branching (`dev-test` -> `dev` -> `main`), PRs, commits, safe DB migrations |
| [docs/TASK_LIST.md](./docs/TASK_LIST.md) | Progress tracker |
| [docs/DECISIONS.md](./docs/DECISIONS.md) | Architecture decision records |
| [docs/ISSUES.md](./docs/ISSUES.md) | Parked blockers |
| [locales/en.json](./locales/en.json) | Centralized dictionary for all words, validation & error messages |

## First steps

1. Initialize Supabase CLI and TypeScript tooling in this folder (if not already scaffolded by `init-template.sh`):
   ```bash
   npx supabase init
   pnpm add @supabase/supabase-js zod
   pnpm add -D supabase typescript tsx vitest @types/node eslint prettier
   ```
2. Start the local Supabase stack (requires Docker):
   ```bash
   pnpm sb:start
   ```
3. Create your first migration, reset the local DB, and generate TypeScript types:
   ```bash
   pnpm db:migration:new init_schema
   pnpm db:reset
   pnpm db:types
   ```
4. Create the `main`, `dev`, and `dev-test` branches (see `docs/PROJECT_GUIDELINES.md`) and start your first feature branch:
   ```bash
   npm run branch:start -- feat/initial-schema "Initial Supabase schema and RLS policies"
   ```
5. Fill in `docs/PROJECT_PLAN.md`, record decisions in `docs/DECISIONS.md`, then work through `docs/TASK_LIST.md` from Phase 0.

## Quality gate

```bash
pnpm typecheck && pnpm lint && pnpm test && pnpm build
```

Run this quality gate locally (along with `pnpm db:lint && pnpm test:db` when modifying SQL/RLS) before opening pull requests to `dev-test`.

