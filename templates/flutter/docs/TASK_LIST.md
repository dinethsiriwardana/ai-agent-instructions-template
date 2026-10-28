# Master Task List: {{PROJECT_NAME}} (Flutter App)

Tracks end-to-end implementation progress. Source documents: [PROJECT_PLAN.md](./PROJECT_PLAN.md), [PROJECT_GUIDELINES.md](./PROJECT_GUIDELINES.md), [UI_RULES.md](./UI_RULES.md), [AGENTS.md](../AGENTS.md).

## How to use this list

- Status: `[ ]` not started, `[~]` in progress, `[x]` done, `[!]` blocked (link the entry in `ISSUES.md`).
- Each task has an ID (`P1.2`), a branch name when active, and a one-line acceptance criterion.
- One task = one branch = one PR. Tick the box in the same PR that completes the work.
- Add feature phases from `PROJECT_PLAN.md` section 6. Do not add work that is not in the plan without updating the plan.
- A phase is done only when the quality gate passes: `dart format --set-exit-if-changed . && flutter analyze && flutter test --coverage && flutter build apk --debug`, plus a small-phone and tablet check for UI work.

---

## Phase 0: Discovery and Planning

- [ ] **P0.1 Requirements**
  - [ ] Complete `docs/PROJECT_PLAN.md` (overview, objectives, roles, scope in and out).
  - [ ] Acceptance criteria for every core feature.
- [ ] **P0.2 UX**
  - [ ] User flows and wireframes for key screens (compact and expanded widths).
- [ ] **P0.3 Technical decisions**
  - [ ] Record auth, flavors/release pipeline, offline strategy and brand tokens in `docs/DECISIONS.md`.
  - [ ] Confirm backend contract (OpenAPI) with the API team.

## Phase 1: Project Foundation and Architecture

- [ ] **P1.1 Repository and tooling**
  - [ ] Create repo with `main` and `dev` branches; protect both.
  - [ ] `flutter create` with org id and platforms; set minimum OS versions.
  - [ ] Configure `analysis_options.yaml` (strict lints), `dart format`, `build_runner`.
  - [ ] Flavors dev/staging/prod with `env/*.json` via `--dart-define-from-file`; `env/example.json` committed.
- [ ] **P1.2 Folder structure and core helpers**
  - [ ] Create the layout from `AGENTS.md` section 3.
  - [ ] `core/config/env.dart`, `core/result`, `core/error`, `core/usecase`.
  - [ ] `core/network` (Dio client, auth/logging interceptors, error mapper).
  - [ ] `core/di/injection.dart`, `bootstrap.dart` (error handlers, BlocObserver), logger service.
  - [ ] `core/router` with route constants and redirect guard.
- [ ] **P1.3 Theme and design tokens**
  - [ ] Light and dark `ColorScheme`, `AppColors` extension, `TextTheme`, spacing, radius, motion tokens.
  - [ ] Token search check: no raw colors or text styles outside `lib/core/theme/`.
- [ ] **P1.4 Localization**
  - [ ] `gen-l10n` configured with base ARB file; no hardcoded strings.
- [ ] **P1.5 CI/CD**
  - [ ] GitHub Actions workflow (format, analyze, test, build).
  - [ ] Signing setup, beta distribution lane (TestFlight / Play internal / Firebase App Distribution).
  - [ ] PR template and branch protection active.

## Phase 2: Authentication and Session (`features/auth/`)

- [ ] **P2.1 Domain and data**
  - [ ] Entities, repository interface, use cases (sign in, sign out, refresh, current user).
  - [ ] Remote datasource, secure token storage, repository impl with failure mapping.
- [ ] **P2.2 Presentation**
  - [ ] `AuthBloc`, sign-in and sign-up pages, inline validation.
  - [ ] Router redirects for authenticated and guest users; 401 handling logs out.
- [ ] **P2.3 Tests**
  - [ ] Use case, repository, BLoC and widget tests; token refresh edge cases.

## Phase 3: Design System and App Shell (`lib/shared/`)

- [ ] **P3.1 Primitives**
  - [ ] `AppButton`, `AppTextField`, `AppCard`, `AppSnackbar`, dialogs.
- [ ] **P3.2 State and list widgets**
  - [ ] `LoadingView`, `EmptyView`, `ErrorView`, `StateBuilder`, `PaginatedListView`.
- [ ] **P3.3 Layout**
  - [ ] `AppScaffold`, breakpoints, adaptive navigation (bar, rail, drawer).
- [ ] **P3.4 Verification**
  - [ ] Widget and golden tests; verified at 360 dp, tablet, dark theme and 200% text scale.

## Phase 4 to N: Feature Phases (one block per feature)

> Copy this block for every feature from `PROJECT_PLAN.md` section 6.

- [ ] **P4.1 [Feature]: domain**
  - [ ] Entity, repository interface and use cases (pure Dart) with unit tests.
- [ ] **P4.2 [Feature]: data**
  - [ ] `freezed` model + mapper, datasources, repository impl with all failure paths tested.
  - [ ] DI registration in `<feature>_injection.dart`.
- [ ] **P4.3 [Feature]: presentation**
  - [ ] Events, states, BLoC with `bloc_test` coverage.
  - [ ] Page and widgets with loading, empty, error and offline states; route added.
  - [ ] Small phone, tablet, dark theme and large text verified.
- [ ] **P4.4 [Feature]: verification**
  - [ ] Acceptance criteria demonstrated; `integration_test` for the main flow.

## Phase N+1: Quality Assurance, Security and Release

- [ ] **QA.1 Automated checks**
  - [ ] Format, analyze, test and build pass with zero warnings; coverage at least 80% on domain and data.
- [ ] **QA.2 Device testing**
  - [ ] Real devices (low-end Android, recent iPhone), slow and offline network, interruptions.
  - [ ] Profile-mode performance pass (jank, startup, memory).
- [ ] **QA.3 Security review**
  - [ ] Checklist in `AGENTS.md` section 10 passed; release build obfuscated; no secrets in logs.
- [ ] **QA.4 Store readiness**
  - [ ] Icons, splash, screenshots, store listing, privacy labels / data safety form, account deletion flow.
- [ ] **QA.5 Release**
  - [ ] Staging build validated; release PR `dev` -> `main` merged; version tagged.
  - [ ] Staged rollout, crash monitoring, rollback plan confirmed.

## Phase N+2: Post-release Maintenance (recurring)

- [ ] Weekly: triage `docs/ISSUES.md`, store reviews and crash reports; check CI health.
- [ ] Monthly: dependency updates on `chore/*` branch (`flutter pub outdated`); review analytics and crashes.
- [ ] Quarterly: Flutter SDK and major package upgrades; target API level / iOS SDK compliance; review `AGENTS.md` and `UI_RULES.md` for drift.

---

## Progress Summary

| Phase | Status | Notes |
|---|---|---|
| 0. Discovery | Not started | |
| 1. Foundation | Not started | |
| 2. Authentication | Not started | |
| 3. Design system and shell | Not started | |
| 4 to N. Features | Not started | |
| N+1. QA and release | Not started | |
