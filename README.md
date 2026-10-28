# Multi-Stack Starter Templates (Next.js, NestJS, Flutter)

A production-grade, rules-first template repository designed to bootstrap **documentation, architecture guidelines, engineering workflows, and CI configurations** for three modern stacks:

- **Next.js** (Full-Stack Web App)
- **NestJS** (Modular REST API Backend)
- **Flutter** (Cross-Platform Mobile App)

This repository intentionally ships **architecture standards, documentation templates, and CI workflows only** (no decaying application boilerplate). You run the built-in generator, scaffold the latest official framework CLI directly into the folder, and follow battle-tested architectural guardrails that both human developers and AI pair programmers (Antigravity, Cursor, Claude Code, Copilot) can rely on.

---

## 1. Stack Overview & Architecture Comparison

| Concern | Next.js (`templates/nextjs`) | NestJS (`templates/nestjs`) | Flutter (`templates/flutter`) |
|---|---|---|---|
| **Architecture** | Feature-first, layered | Module-per-feature, layered | Clean Architecture, feature-first |
| **Layering** | `UI -> hooks -> route -> service -> repo -> DB` | `Controller -> Service -> Repository -> DB` | `presentation -> domain <- data` |
| **Language / Runtime** | TypeScript `strict` / Node LTS | TypeScript `strict` / Node LTS | Dart 3 (sound null safety) / Flutter Stable |
| **State / Communication** | TanStack Query + Server Components | Stateless services, Redis caching | BLoC (`flutter_bloc`), `bloc_concurrency` |
| **Validation / Contracts** | Zod (single source of truth for types) | Zod (`nestjs-zod`) + OpenAPI / Swagger | `freezed` + `json_serializable` (immutable) |
| **Data Access** | Drizzle ORM on PostgreSQL | Drizzle ORM on PostgreSQL | Dio HTTP client + `flutter_secure_storage` |
| **Styling / UI System** | Tailwind CSS 4 with owned theme tokens | Structured JSON envelopes (`docs/API_RULES.md`) | Theme tokens, Material 3, shared widgets |
| **Testing Suite** | Vitest (unit), Playwright (E2E) | Jest + `@nestjs/testing` (unit), Supertest (E2E) | `flutter_test`, `bloc_test`, `mocktail` |
| **Quality Gate** | `typecheck && lint && test && build` | `typecheck && lint && test && test:e2e && build` | `format && analyze && test && build apk` |

---

## 2. Repository Layout

```
.
├── AGENTS.md                           # Rules for AI agents maintaining this template repo
├── README.md                           # This comprehensive guide
├── AI Agent History.md                 # Change log of modifications made to this template
│
├── core/                               # Shared across EVERY generated project
│   ├── docs/
│   │   ├── PROJECT_GUIDELINES.md       # Branching (main/dev), PR rules, 10-minute blocker protocol
│   │   ├── ISSUES.md                   # Offline blocker log for unresolved issues (>10 min)
│   │   └── ai/                         # Continuous AI learning & personal profile
│   │       ├── STYLE_AND_SKILLS.md     # Developer habits, skills, preferences & learned style
│   │       └── REQUEST_LOG.md          # User requests grouped by category (Feature, Bugfix, etc.)
│   └── .github/
│       └── pull_request_template.md    # Shared PR checklist with {{QUALITY_GATE}} placeholder
│
├── templates/                          # Stack-specific starter kits
│   ├── nextjs/                         # Next.js App Router rules and docs
│   │   ├── AGENTS.md                   # Strict coding and layering guidelines for Next.js
│   │   ├── docs/                       # PROJECT_PLAN, TASK_LIST, DECISIONS, UI_RULES
│   │   ├── README.md                   # First steps and scaffolding guide for Next.js
│   │   └── stack.conf                  # Next.js metadata and quality gate command
│   │
│   ├── nestjs/                         # NestJS REST API rules and docs
│   │   ├── AGENTS.md                   # Strict module and layering guidelines for NestJS
│   │   ├── docs/                       # PROJECT_PLAN, TASK_LIST, DECISIONS, API_RULES
│   │   ├── README.md                   # First steps and scaffolding guide for NestJS
│   │   └── stack.conf                  # NestJS metadata and quality gate command
│   │
│   └── flutter/                        # Flutter mobile rules, docs, and CI
│       ├── AGENTS.md                   # Strict Clean Architecture guidelines for Flutter
│       ├── docs/                       # PROJECT_PLAN, TASK_LIST, DECISIONS, UI_RULES
│       ├── README.md                   # First steps and scaffolding guide for Flutter
│       └── stack.conf                  # Flutter metadata and quality gate command
│
└── scripts/
    └── init-template.sh                # Multi-stack project generator script
```

---

## 3. Quickstart: Generating a New Project

You can use this repository as a **GitHub Template Repository** (click "Use this template" on GitHub), or clone it locally.

### Interactive Mode
Run the generator without flags to choose your stack and enter project details via prompts:

```bash
bash scripts/init-template.sh
```

### Headless / CLI Mode
Pass options directly to automate project creation in scripts or CI:

```bash
bash scripts/init-template.sh \
  --stack <nextjs|nestjs|flutter> \
  --target <target-directory> \
  --name "Project Name" \
  --description "One-sentence pitch" \
  --owner "Owner Name"
```

#### What the Generator Does:
1. **Safety Check**: Ensures the `--target` folder is empty (an existing `.git/` folder is allowed).
2. **Copies Shared Core**: Merges `core/` (`PROJECT_GUIDELINES.md`, `ISSUES.md`, PR template).
3. **Copies Chosen Stack**: Merges `templates/<stack>/` files into the target folder.
4. **Replaces Placeholders**:
   - `{{PROJECT_NAME}}`: Product name.
   - `{{ONE_LINE_DESCRIPTION}}`: Short summary.
   - `{{OWNER_NAME}}`: Plan/project owner.
   - `{{STACK_LABEL}}`: Injected from `stack.conf` (e.g., `Next.js`, `NestJS`, `Flutter`).
   - `{{QUALITY_GATE}}`: Injected from `stack.conf` (the exact verification command string).
   - `YYYY-MM-DD`: Current date injected into `PROJECT_PLAN.md` and `DECISIONS.md`.
5. **Prints Next Steps**: Points you to the newly generated `README.md` in the target folder with precise framework scaffolding commands.

---

## 4. Stack-by-Stack Setup & Scaffolding Guides

After running `init-template.sh`, switch to your target folder and run the commands for your stack:

### A. Next.js (Full-Stack Web)
1. **Scaffold into the target folder**:
   ```bash
   pnpm create next-app@latest . --ts --tailwind --app --src-dir --import-alias "@/*" --use-pnpm
   ```
2. **Install core dependencies**:
   ```bash
   pnpm add zod drizzle-orm @tanstack/react-query react-hook-form @hookform/resolvers server-only postgres
   pnpm add -D drizzle-kit vitest @vitejs/plugin-react playwright @playwright/test prettier
   ```
3. **Add scripts to `package.json`**:
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
4. **Run the Quality Gate**:
   ```bash
   pnpm typecheck && pnpm lint && pnpm test && pnpm build
   ```

---

### B. NestJS (REST API Backend)
1. **Scaffold into the target folder**:
   ```bash
   npx @nestjs/cli new . --package-manager pnpm --strict --skip-git
   ```
2. **Install core dependencies**:
   ```bash
   pnpm add zod nestjs-zod drizzle-orm @nestjs/config @nestjs/swagger @nestjs/throttler @nestjs/terminus nestjs-pino pino-http helmet postgres
   pnpm add -D drizzle-kit pino-pretty supertest @types/supertest
   ```
3. **Verify scripts in `package.json`**:
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
4. **Run the Quality Gate**:
   ```bash
   pnpm typecheck && pnpm lint && pnpm test && pnpm test:e2e && pnpm build
   ```

---

### C. Flutter (Cross-Platform Mobile)
1. **Scaffold into the target folder**:
   ```bash
   flutter create . --org com.yourdomain --project-name your_app_name
   ```
2. **Install core dependencies**:
   ```bash
   # Runtime dependencies
   flutter pub add flutter_bloc bloc_concurrency go_router dio get_it freezed_annotation json_annotation equatable flutter_secure_storage intl

   # Code generation & test tooling
   flutter pub add --dev build_runner freezed json_serializable bloc_test mocktail flutter_lints
   ```
3. **Create Environment Configurations**:
   - Commit `env/example.json`:
     ```json
     { "API_BASE_URL": "https://api.example.com", "FLAVOR": "dev" }
     ```
   - Create local git-ignored `env/dev.json` and run with:
     ```bash
     flutter run --dart-define-from-file=env/dev.json
     ```
4. **Run the Quality Gate**:
   ```bash
   dart format --set-exit-if-changed . && flutter analyze && flutter test --coverage && flutter build apk --debug
   ```

---

## 5. Working with AI Agents (Antigravity, Cursor, Claude Code, Copilot)

Every generated project includes a top-level **`AGENTS.md`** file and a **`docs/ai/`** memory folder. When you open the project in an AI-assisted IDE or pair with an agent:

1. **Mandatory First Read**: Instruct your agent to read `docs/ai/STYLE_AND_SKILLS.md` and `AGENTS.md` before generating or modifying any code.
2. **Adaptive Code Style & Habits (`docs/ai/STYLE_AND_SKILLS.md`)**:
   - Captures your engineering skills, favorite libraries, paradigm habits (e.g., early returns, immutability), and disliked anti-patterns.
   - When you correct the AI during a conversation (e.g., *"Prefer X instead of Y"*), the AI must immediately log the correction in Section 4 so it adapts to your personal style and never repeats the mistake.
3. **Categorized Request History (`docs/ai/REQUEST_LOG.md`)**:
   - Every completed prompt/task is automatically grouped by request type (Feature, Bugfix, Refactoring, Architecture, or DevOps) in reverse chronological order.
4. **Layering Enforced**:
   - In **Next.js**: The agent cannot dump database calls into client components or route handlers. It must follow `UI -> hooks -> route -> service -> repository`.
   - In **NestJS**: The agent cannot put SQL in controllers or skip Zod DTO validation.
   - In **Flutter**: The agent cannot place networking or state logic inside widgets. It must implement Clean Architecture (`domain` interfaces, `data` datasources, and `presentation` BLoC).
5. **The 10-Minute Blocker Protocol**:
   - If an AI agent or developer gets stuck on a bug for >10 minutes, they must stop, document the blocker in `docs/ISSUES.md` (or a GitHub Issue), and pivot to the next task.
6. **Document Upkeep**:
   - Features completed must be checked off in `docs/TASK_LIST.md`.
   - Architectural decisions must be logged in `docs/DECISIONS.md`.

---

## 6. Coordinated Multi-Stack Systems (Monorepo or Polyrepo)

When building a full product consisting of Web + API + Mobile:

```
my-product/
├── apps/
│   ├── web/        <- generated with --stack nextjs
│   ├── api/        <- generated with --stack nestjs
│   └── mobile/     <- generated with --stack flutter
```

- **Single Source of Truth for APIs**: The NestJS project's `docs/API_RULES.md` and `@nestjs/swagger` OpenAPI output define all contracts.
- **Contract Sharing**: Web and mobile clients generate typed API clients directly from the OpenAPI spec, preventing drift.
- **Unified Git Strategy**: All stacks share the identical two-branch strategy (`main` for production, `dev` for active integration), PR review checklists, and Conventional Commit conventions.

---

## 7. How to Add a New Stack (e.g., Go, FastAPI, React Native)

To add another stack to this template:
1. Create `templates/<stack_name>/`:
   - `AGENTS.md`: Architectural rules, folder structure, coding guidelines.
   - `docs/`: Stack-specific planning, tasks, ADRs, and UI/API rules.
   - `README.md`: First steps and CLI scaffolding commands.
   - `stack.conf`: Define `STACK_LABEL` and `QUALITY_GATE`.
2. Add the stack name to `STACKS` array in `scripts/init-template.sh`:
   ```bash
   STACKS=(nextjs nestjs flutter <new_stack>)
   ```
3. Test your new stack generator using a temporary directory:
   ```bash
   T=$(mktemp -d)
   bash scripts/init-template.sh --stack <new_stack> --target "$T/test" --name "Test" --description "Desc" --owner "Owner"
   rm -rf "$T"
   ```

---

## 8. Template Maintenance & Versioning

- Treat these documentation templates as a product. Architectural insights discovered in production projects should be backported here.
- Never commit company-specific or product-specific secrets, URLs, or names to this template repository.
- Verify generator integrity after every edit:
  ```bash
  T=$(mktemp -d)
  for s in nextjs nestjs flutter; do
    bash scripts/init-template.sh --stack $s --target "$T/$s" --name "App" --description "Desc" --owner "Owner"
    grep -RE "\{\{(PROJECT_NAME|ONE_LINE_DESCRIPTION|OWNER_NAME|STACK_LABEL|QUALITY_GATE)\}\}" "$T/$s" && echo "Error: unhandled placeholder in $s"
  done
  rm -rf "$T"
  ```

### Version History

**TEMPLATE_VERSION: 2.2.0**

| Version | Description |
|---|---|
| **2.2.0** | Added `docs/ai/` memory system (`STYLE_AND_SKILLS.md` and `REQUEST_LOG.md`) for continuous AI learning, adaptive code styling, and categorized prompt tracking. |
| **2.1.0** | Comprehensive root documentation, template repo `AGENTS.md`, and clean root directory structure. |
| **2.0.0** | Multi-stack architecture: shared `core/`, stack folders for Next.js, NestJS, Flutter, and stack-aware CLI generator. |
| **1.0.0** | Initial generic Next.js template: unified stack (Zod, Drizzle, TanStack Query), ADR log, and CI workflow. |
