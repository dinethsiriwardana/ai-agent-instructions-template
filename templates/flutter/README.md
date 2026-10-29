# {{PROJECT_NAME}}

{{ONE_LINE_DESCRIPTION}}

Flutter app (Clean Architecture, BLoC, go_router, Dio). This repository follows a documented architecture and workflow. Start with the documents below.

## Documentation

| File | Purpose |
|---|---|
| [AGENTS.md](./AGENTS.md) | Architecture and coding rules (read first, also for AI agents) |
| [docs/PROJECT_PLAN.md](./docs/PROJECT_PLAN.md) | Scope, architecture overview, roadmap |
| [docs/UI_RULES.md](./docs/UI_RULES.md) | Theme tokens, shared widgets, responsive and accessibility rules |
| [docs/PROJECT_GUIDELINES.md](./docs/PROJECT_GUIDELINES.md) | Branching, PRs, commits, releases, maintenance |
| [docs/TASK_LIST.md](./docs/TASK_LIST.md) | Progress tracker |
| [docs/DECISIONS.md](./docs/DECISIONS.md) | Architecture decision records |
| [docs/ISSUES.md](./docs/ISSUES.md) | Parked blockers |
| [lib/l10n/app_en.arb](./lib/l10n/app_en.arb) | Centralized ARB dictionary for all words, UI text & error messages |

## First steps

1. Scaffold the app in this folder:
   ```bash
   flutter create . --org com.example --project-name <snake_case_name>
   ```
   Use a valid Dart package name (`snake_case`) and your own organization id.
2. Add the dependencies from the stack table in `AGENTS.md`:
   ```bash
   flutter pub add flutter_bloc bloc_concurrency go_router dio get_it freezed_annotation json_annotation equatable flutter_secure_storage intl
   flutter pub add --dev build_runner freezed json_serializable bloc_test mocktail flutter_lints
   ```
3. Create `env/example.json` (committed) and `env/dev.json` (git-ignored):
   ```json
   { "API_BASE_URL": "https://api.example.com", "FLAVOR": "dev" }
   ```
   Run with `flutter run --dart-define-from-file=env/dev.json`.
4. Generate code after changing annotated models: `dart run build_runner build --delete-conflicting-outputs`.
5. Create the `main` and `dev` branches and enable branch protection (see `docs/PROJECT_GUIDELINES.md`).
6. Fill in `docs/PROJECT_PLAN.md`, record decisions in `docs/DECISIONS.md`, then work through `docs/TASK_LIST.md` from Phase 0.

## Quality gate

```bash
dart format --set-exit-if-changed . && flutter analyze && flutter test --coverage 
```

Run this quality gate locally before opening pull requests to ensure code quality and build stability.
