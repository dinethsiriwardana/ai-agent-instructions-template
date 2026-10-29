# AI Request Log

> **For AI Agents:** After completing every task or user prompt, record the request in the matching category below. Keep each section in reverse chronological order (newest entry at the top of that section). If the request revealed a new preference or correction, also update `docs/ai/STYLE_AND_SKILLS.md`.

---

## Request Categories

- [1. Feature Requests](#1-feature-requests): New user-facing capabilities, API endpoints, or screens.
- [2. Bugfixes & Troubleshooting](#2-bugfixes--troubleshooting): Resolving errors, edge-case bugs, or broken tests.
- [3. Refactoring & Code Quality](#3-refactoring--code-quality): Code reorganization, performance tuning, and DRYing up logic.
- [4. Architecture & Technical Decisions](#4-architecture--technical-decisions): Designing systems, choosing libraries, schema migrations, and contracts.
- [5. Tooling, Config & DevOps](#5-tooling-config--devops): CI/CD pipelines, package upgrades, Docker, env files, and linting rules.

---

### Entry Format Reference

```markdown
### [YYYY-MM-DD HH:MM] Brief Title

- **Task / Goal:** What the user asked for.
- **Summary of Changes:** Concise bullet points of what was modified or added.
- **Files Modified:** Clickable links to relevant files.
- **Learnings & Style Alignment:** Any specific developer pattern followed or newly learned preference.
```

---

## 1. Feature Requests

<!-- Add new feature entries below (newest first) -->

### [2026-10-29 19:30] Centralized Localization, Words, and Error Messages System

- **Task / Goal:** List all words, error messages, and every text in one place with language across all stacks (Next.js, NestJS, Flutter) so developers can easily change language and update text from one place.
- **Summary of Changes:**
  - Added starter language dictionaries for Next.js (`templates/nextjs/locales/en.json`, `es.json`).
  - Added starter language dictionaries for NestJS (`templates/nestjs/locales/en.json`, `es.json`).
  - Added starter ARB resource bundles and `l10n.yaml` for Flutter (`templates/flutter/lib/l10n/app_en.arb`, `app_es.arb`).
  - Updated generator script `scripts/init-template.sh` to copy and replace placeholders in `.json` and `.arb` files.
  - Updated architectural guidelines (`AGENTS.md`) and UI/API rules across Next.js, NestJS, and Flutter prohibiting hardcoded strings and mandating the centralized dictionary.
- **Files Modified:**
  - [templates/nextjs/locales/en.json](file:///Users/dinethsiriwardana/Downloads/nextjs-template/templates/nextjs/locales/en.json)
  - [templates/nextjs/locales/es.json](file:///Users/dinethsiriwardana/Downloads/nextjs-template/templates/nextjs/locales/es.json)
  - [templates/nestjs/locales/en.json](file:///Users/dinethsiriwardana/Downloads/nextjs-template/templates/nestjs/locales/en.json)
  - [templates/nestjs/locales/es.json](file:///Users/dinethsiriwardana/Downloads/nextjs-template/templates/nestjs/locales/es.json)
  - [templates/flutter/l10n.yaml](file:///Users/dinethsiriwardana/Downloads/nextjs-template/templates/flutter/l10n.yaml)
  - [templates/flutter/lib/l10n/app_en.arb](file:///Users/dinethsiriwardana/Downloads/nextjs-template/templates/flutter/lib/l10n/app_en.arb)
  - [templates/flutter/lib/l10n/app_es.arb](file:///Users/dinethsiriwardana/Downloads/nextjs-template/templates/flutter/lib/l10n/app_es.arb)
  - [scripts/init-template.sh](file:///Users/dinethsiriwardana/Downloads/nextjs-template/scripts/init-template.sh)
- **Learnings & Style Alignment:** Centralized localization is the single source of truth for words, button labels, and error messages; never hardcode strings in UI components, controllers, or error types.

---

## 2. Bugfixes & Troubleshooting

<!-- Add new bugfix entries below (newest first) -->

_No bugfix requests logged yet._

---

## 3. Refactoring & Code Quality

<!-- Add new refactoring entries below (newest first) -->

_No refactoring requests logged yet._

---

## 4. Architecture & Technical Decisions

<!-- Add new architecture entries below (newest first) -->

_No architecture requests logged yet._

---

## 5. Tooling, Config & DevOps

<!-- Add new tooling/config entries below (newest first) -->

### [2026-10-28 20:51] Remove All Remaining GitHub Actions Workflows

- **Task / Goal:** Remove all remaining GitHub Actions workflows across all templates.
- **Summary of Changes:** Deleted `templates/nextjs/.github/` and `templates/nestjs/.github/`; updated stack READMEs, root `README.md`, and root `AGENTS.md`.
- **Files Modified:** [templates/nextjs/README.md](file:///Users/dinethsiriwardana/Downloads/nextjs-template/templates/nextjs/README.md), [templates/nestjs/README.md](file:///Users/dinethsiriwardana/Downloads/nextjs-template/templates/nestjs/README.md), [README.md](file:///Users/dinethsiriwardana/Downloads/nextjs-template/README.md), [AGENTS.md](file:///Users/dinethsiriwardana/Downloads/nextjs-template/AGENTS.md).
- **Learnings & Style Alignment:** User prefers templates to stay decoupled from CI providers, focusing purely on local quality gates.

### [2026-10-28 20:46] Remove Flutter CI Workflow

- **Task / Goal:** Remove GitHub Actions workflow from the Flutter template per user request.
- **Summary of Changes:** Deleted `templates/flutter/.github/workflows/ci.yml` and updated `templates/flutter/README.md` and root `README.md`.
- **Files Modified:** [templates/flutter/README.md](file:///Users/dinethsiriwardana/Downloads/nextjs-template/templates/flutter/README.md), [README.md](file:///Users/dinethsiriwardana/Downloads/nextjs-template/README.md).
- **Learnings & Style Alignment:** Keep Flutter template flexible without imposing default GitHub Actions runner environments.
