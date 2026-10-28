# Developer Profile: Skills, Style and Preferences

> **For AI Agents:** Read this file at the start of every session. Align all generated code, architecture proposals, and refactorings with the preferences and style documented here. When the user corrects you or expresses a new preference, immediately record it in **Section 4 (Learned Preferences & Corrections)**.

---

## 1. Developer Profile & Skill Set

*Document your engineering background, favorite tools, and comfort levels so the AI tailors its explanations and recommendations.*

- **Primary Languages:** [e.g., TypeScript, Dart, Python, Go]
- **Primary Frameworks:** [e.g., Next.js, NestJS, Flutter]
- **Experience Level:** [e.g., Senior Full-Stack / Staff Architect / Mobile Specialist]
- **Focus Areas:** [e.g., High-throughput APIs, clean UI/UX micro-interactions, robust domain modeling]
- **Preferred Tone & Interaction:**
  - Keep explanations concise, practical, and action-oriented.
  - Skip boilerplate introductory and closing pleasantries.
  - Offer direct solutions with pros and cons when architectural decisions are needed.

---

## 2. Code Style & Design Habits

*The AI must write code as if you wrote it yourself.*

### 2.1 Syntax & Paradigm Habits
- **Paradigm:** [e.g., Functional-first where practical; immutability; pure domain functions]
- **Control Flow:** Prefer early returns and guard clauses over nested `if/else` blocks.
- **Naming Conventions:**
  - Descriptive, self-documenting variables and functions.
  - Avoid single-letter variable names (except index variables in trivial loops).
  - Explicit boolean names: `isLoading`, `hasPermission`, `canSubmit`.
- **Functions:** Small, single-responsibility functions (keep under ~30-40 lines).
- **Types & Null Safety:**
  - Strict typing: zero tolerance for `any` or loose casts.
  - Rely on schema inference (`z.infer`, `freezed`) rather than manual duplicate types.
  - Defensive null handling without non-null assertions (`!`).

### 2.2 Error Handling & Resilience
- Errors as values where supported (e.g., `Result<T>` or explicit error classes).
- Never catch and swallow exceptions silently.
- User-facing error messages must be sanitized and friendly; system logs must be structured with error context.

### 2.3 Comments & Documentation
- Self-explanatory code > excessive comments.
- Only write comments for non-obvious "why" decisions, edge-case workarounds, or complex math/regex.
- Do not write trivial comments that restate what the code does (e.g., `// set loading to true`).
- Strictly **no emojis** in code comments, logs, or commit messages.

---

## 3. Disliked Patterns & Anti-Preferences

*Patterns the AI must NEVER use without explicit user request.*

- [ ] Giant "god" files or classes exceeding ~250 lines.
- [ ] Magic numbers and hardcoded string literals (extract to constants, tokens, or enums).
- [ ] Placing network calls, database queries, or business calculations inside UI components or widgets.
- [ ] Over-abstraction on first use: do not extract utils or components until the **second** use.
- [ ] External UI component libraries (MUI, Chakra, Ant) unless explicitly requested.
- [ ] Mutable global singletons for application state.

---

## 4. Learned Preferences & Corrections Log

> Whenever you correct the AI during a conversation (e.g., *"Don't use X, use Y"* or *"I prefer this structure"*), the AI must record it here so it never repeats the mistake in future sessions.

| Date | Topic / Context | What the AI Did | Developer's Preferred Way |
|---|---|---|---|
| YYYY-MM-DD | Initial Setup | Default baseline | Follow guidelines in `AGENTS.md` and this profile |
<!-- Append new learned rules below -->
