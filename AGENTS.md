# AGENTS.md - Template Repository Guidelines

> Read this file before making changes to this multi-stack template repository.

---

## 1. Repository Purpose

This repository is a **multi-stack starter template** designed to bootstrap the documentation, architecture rules, workflows, and CI configurations for three stacks:
1. **Next.js** (`templates/nextjs/`)
2. **NestJS** (`templates/nestjs/`)
3. **Flutter** (`templates/flutter/`)

It contains **architecture rules, documentation templates, and CI configs** only (no pre-scaffolded application code).

---

## 2. Structure & Responsibilities

- **`core/`**: Shared documents and GitHub configurations copied to every generated project:
  - `docs/PROJECT_GUIDELINES.md`: Generic branching, PR conventions, 10-minute blocker protocol.
  - `docs/ISSUES.md`: Blocker tracking log.
  - `docs/ai/STYLE_AND_SKILLS.md`: Developer skills, habits, code style rules, and learned preferences.
  - `docs/ai/REQUEST_LOG.md`: User requests grouped by category (Feature, Bugfix, Refactor, Architecture, DevOps).
  - `.github/pull_request_template.md`: Shared PR checklist with `{{QUALITY_GATE}}` placeholder.
- **`templates/<stack>/`**: Stack-specific files:
  - `AGENTS.md`: Mandatory coding and architecture standards for that stack.
  - `docs/`: Stack-specific project plan, task list, ADR log, and UI or API rules.
  - `README.md`: First steps guide and scaffolding instructions for that stack.
  - `stack.conf`: Shell variable definitions (`STACK_LABEL`, `QUALITY_GATE`) used during template initialization.
- **`scripts/init-template.sh`**: The generator script that copies `core/` + `templates/<stack>/` to a target folder and replaces placeholders.

---

## 3. Rules for AI Agents Modifying this Repository

1. **Keep Stack Separation Clean**:
   - Stack-agnostic workflows belong in `core/`.
   - Stack-specific architecture, linting, quality gates, and libraries belong in `templates/<stack>/`.
   - Never introduce framework-specific conventions into `core/`.
2. **Preserve Template Placeholders**:
   - `{{PROJECT_NAME}}`: Product name.
   - `{{ONE_LINE_DESCRIPTION}}`: One-line pitch.
   - `{{OWNER_NAME}}`: Project / plan owner.
   - `{{STACK_LABEL}}`: Injected from `stack.conf`.
   - `{{QUALITY_GATE}}`: Injected from `stack.conf`.
   - `YYYY-MM-DD`: Date placeholder automatically replaced with current date on initialization.
   - Do not escape or modify GitHub Actions expressions (`${{ ... }}`) in workflow files.
3. **Verification Before Committing**:
   - Always verify the generator script against a clean temporary directory:
     ```bash
     T=$(mktemp -d)
     for s in nextjs nestjs flutter; do
       bash scripts/init-template.sh --stack $s --target "$T/$s" --name "Test App" --description "Desc" --owner "Agent"
     done
     rm -rf "$T"
     ```
   - Ensure no unhandled `{{...}}` placeholders remain in markdown or yaml files after generation.
4. **Version Tracking**:
   - Increment `TEMPLATE_VERSION` in [README.md](file:///Users/dinethsiriwardana/Downloads/nextjs-template/README.md) and record changes when modifying templates.
   - Update [AI Agent History.md](file:///Users/dinethsiriwardana/Downloads/nextjs-template/AI%20Agent%20History.md) after significant modifications.
