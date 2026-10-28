<!-- BEGIN:flutter-agent-rules -->

# AGENTS.md - Architecture and Coding Guidelines (Flutter)

> Read this file fully before writing or changing any code.
> These rules are mandatory. If a request conflicts with them, say so and propose the compliant alternative.
> Project name: **{{PROJECT_NAME}}**

---

## 0. Document Map

| Document | Answers |
|---|---|
| `AGENTS.md` (this file) | How code is structured and written |
| `docs/UI_RULES.md` | How things look (theme tokens, widgets, responsive and accessibility rules) |
| `docs/PROJECT_GUIDELINES.md` | How work flows (branches, PRs, commits, releases, maintenance) |
| `docs/PROJECT_PLAN.md` | What is being built and why |
| `docs/TASK_LIST.md` | What is done and what is next |
| `docs/DECISIONS.md` | Why a technical choice was made (ADR log) |
| `docs/ISSUES.md` | Blockers parked under the 10-minute rule |
| `docs/ai/STYLE_AND_SKILLS.md` | Developer habits, skills, preferences & learned style |
| `docs/ai/REQUEST_LOG.md` | Categorized request history (Feature, Bugfix, Refactor, etc.) |

Reading order: `docs/ai/STYLE_AND_SKILLS.md` -> `PROJECT_PLAN` -> `AGENTS` -> `UI_RULES` -> `PROJECT_GUIDELINES` -> `TASK_LIST`.

---

## 1. Stack Defaults

| Concern | Choice |
|---|---|
| Framework | Flutter (stable channel), Dart 3 with sound null safety, strict analysis |
| Architecture | Clean Architecture, feature-first (presentation / domain / data) |
| State management | BLoC (`flutter_bloc`); Cubit for simple state, Bloc for event-driven flows |
| Navigation | `go_router` (declarative, typed route constants, redirect-based auth guard) |
| Networking | `dio` with interceptors (auth, logging, retry, error mapping) |
| Dependency injection | `get_it` (+ `injectable` optional) wired in `core/di/` |
| Models | `freezed` + `json_serializable` for immutable models and unions |
| Equality | `equatable` for entities and states when not using `freezed` |
| Local storage | `flutter_secure_storage` (secrets/tokens), `shared_preferences` or `drift`/`isar` (data) behind a datasource |
| Localization | `flutter_localizations` + ARB files (`gen-l10n`) |
| Lint | `flutter_lints` or `very_good_analysis`, treated as errors in CI |
| Tests | `flutter_test`, `bloc_test`, `mocktail`, `integration_test` |

Deviations from this table must be recorded in `docs/DECISIONS.md` before implementation.

---

## 2. Core Principles

1. **Feature-first**: code lives with the feature that owns it. Only truly shared code goes in `core/` or `shared/`.
2. **Dependency rule (Clean Architecture)**: `presentation -> domain <- data`. The **domain layer is pure Dart** (no Flutter, Dio, JSON or storage imports). Dependencies point inward only.
3. **Interfaces in domain, implementations in data**: repositories are abstract classes in `domain/`, implemented in `data/`. Presentation depends on use cases, never on repositories or datasources.
4. **Immutable state**: models, entities and BLoC states are immutable. Change state by emitting a new instance.
5. **One use case, one job**: each use case is a small class with a single `call()` method.
6. **Errors as values**: data layer catches exceptions and returns `Result<T>` (success or `Failure`). Presentation never sees raw `DioException` or platform errors.
7. **Widgets are dumb**: widgets render state and dispatch events. No business logic, no networking, no storage in widgets.
8. **Const and small**: prefer `const` constructors; split large `build` methods into widget classes, not helper methods.
9. **DRY with judgment**: search `core/` and `shared/` before writing anything. Extract on the **second** use.
10. **Portable by design**: platform and vendor SDKs (Firebase, maps, payments) are wrapped behind interfaces in `data/` or `core/services/`.

---

## 3. Folder Structure

```
lib/
├── main.dart                         # Entry: bootstrap() then runApp
├── bootstrap.dart                    # Init: env, DI, error handlers (FlutterError, PlatformDispatcher), bloc observer
├── app.dart                          # MaterialApp.router, theme, localization
│
├── core/                             # App-wide, domain-agnostic
│   ├── config/env.dart               # Typed config from --dart-define / flavors
│   ├── di/injection.dart             # get_it registration (one function per feature)
│   ├── error/                        # failure.dart, app_exception.dart, error_mapper.dart
│   ├── result/result.dart            # sealed Result<T> (Success / Err)
│   ├── network/                      # dio_client.dart, interceptors/, api_endpoints.dart
│   ├── router/                       # app_router.dart, routes.dart (route name/path constants)
│   ├── theme/                        # app_theme.dart, color_tokens.dart, text_styles.dart, spacing.dart
│   ├── usecase/usecase.dart          # abstract UseCase<T, Params>
│   ├── services/                     # logger, analytics, connectivity, secure storage wrappers
│   └── utils/                        # formatters, validators, extensions (pure)
│
├── shared/                           # Cross-feature UI, no domain knowledge
│   ├── widgets/                      # AppButton, AppTextField, AppCard, EmptyView, ErrorView, LoadingView, StateBuilder
│   └── layout/                       # responsive helpers, Breakpoints, AppScaffold
│
├── features/
│   └── products/
│       ├── data/
│       │   ├── datasources/          # products_remote_datasource.dart, products_local_datasource.dart
│       │   ├── models/               # product_model.dart (freezed + json), mapper to entity
│       │   └── repositories/         # products_repository_impl.dart
│       ├── domain/
│       │   ├── entities/             # product.dart (pure Dart)
│       │   ├── repositories/         # products_repository.dart (abstract)
│       │   └── usecases/             # get_products.dart, create_product.dart
│       ├── presentation/
│       │   ├── bloc/                 # products_bloc.dart, products_event.dart, products_state.dart
│       │   ├── pages/                # products_page.dart (route-level screens)
│       │   └── widgets/              # feature-specific widgets
│       └── products_injection.dart   # registers this feature in get_it
│
└── l10n/                             # app_en.arb, app_xx.arb

test/                                 # mirrors lib/ structure
integration_test/                     # critical end-to-end flows
```

### Placement rules

| Code is... | Goes in |
|---|---|
| Used by one feature | `features/<name>/` |
| Used by 2+ features and has no domain knowledge | `core/` (logic) or `shared/` (widgets) |
| A pure business rule | `features/<name>/domain/` (pure Dart) |
| JSON, HTTP, storage code | `features/<name>/data/` |
| A full screen | `features/<name>/presentation/pages/` |

### Import boundaries

- `domain/` imports **only** Dart core, `core/result`, `core/error`, `core/usecase` and its own feature domain. Never `package:flutter`, `dio`, `json_annotation`.
- `presentation/` imports its own feature's `domain/` (entities, use cases), `core/` and `shared/`. It must **not** import `data/`.
- `data/` imports its own feature's `domain/` and `core/`.
- A feature must **not** import another feature's `data/` or `presentation/` internals. Share through `domain/` entities exposed in the feature barrel or move shared pieces to `core/`.
- `shared/` and `core/` never import from `features/`.
- Use package imports (`package:app_name/...`), never deep relative `../../..` imports across layers.

---

## 4. Naming Conventions

- Files and folders: `snake_case`. Classes: `PascalCase`. Members and variables: `camelCase`. Constants: `lowerCamelCase` (Dart style).
- Suffix by role: `*_page.dart`, `*_bloc.dart`, `*_cubit.dart`, `*_event.dart`, `*_state.dart`, `*_model.dart`, `*_repository.dart`, `*_repository_impl.dart`, `*_datasource.dart`, `*_usecase` or verb-named use case (`get_products.dart`).
- One public class per file (private helper widgets may share a file only if under 20 lines).
- Events are past-tense facts (`ProductsRequested`, `ProductDeleted`); states describe the screen (`ProductsLoading`, `ProductsLoaded`, `ProductsFailure`) or use one `freezed` state with a status.
- Route names/paths come from `core/router/routes.dart`, never string literals in widgets.

### Size limits (hard limits, split before exceeding)

| Item | Max lines |
|---|---|
| Any source file | 250 |
| Widget file (`build` heavy) | 150 |
| `build` method | 60 (extract widget classes beyond that) |
| BLoC / Cubit file | 200 |
| Repository impl / datasource | 250 |
| Function / method | 40 |
| Test file | 300 |

- Exceeding a limit means more than one responsibility. Split by responsibility.
- Max 4 positional parameters (use named parameters or a params class beyond that). Max 3 levels of nesting (early returns).
- Generated files (`*.g.dart`, `*.freezed.dart`, `l10n` output) are exempt and never edited by hand.

---

## 5. Data Flow

```
Widget -> dispatch Event -> BLoC -> UseCase -> Repository (abstract)
                                                   |
                                    RepositoryImpl -> RemoteDataSource (Dio) / LocalDataSource
                                                   |
                          Result<Entity> <- maps Model -> Entity, exceptions -> Failure
BLoC emits State -> BlocBuilder/BlocListener rebuilds Widget
```

- **Reads and writes** always go widget -> BLoC -> use case. Widgets never call repositories, Dio or storage directly.
- **Never** call `Navigator` or `GoRouter` from a BLoC. Emit a state; navigate in a `BlocListener` or via `go_router` redirects.
- **Never** use `BuildContext` across async gaps without a `mounted` check.
- **Never** hold `BuildContext`, widgets or Flutter types in BLoCs or domain classes.

---

## 6. Boilerplate Eliminators (use these, do not re-implement)

### 6.1 `Result<T>` and `Failure`: `core/result/result.dart`

```dart
sealed class Result<T> {
  const Result();
}
final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}
final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

sealed class Failure {
  const Failure(this.message);
  final String message;
}
final class NetworkFailure extends Failure { const NetworkFailure([super.message = 'No connection']); }
final class UnauthorizedFailure extends Failure { const UnauthorizedFailure([super.message = 'Session expired']); }
final class NotFoundFailure extends Failure { const NotFoundFailure(super.message); }
final class ValidationFailure extends Failure { const ValidationFailure(super.message, {this.fields = const {}}); final Map<String, String> fields; }
final class ServerFailure extends Failure { const ServerFailure([super.message = 'Something went wrong']); }
```

Consume with exhaustive `switch` expressions (pattern matching). Never throw from use cases for expected errors.

### 6.2 `UseCase`: `core/usecase/usecase.dart`

```dart
abstract interface class UseCase<T, P> {
  Future<Result<T>> call(P params);
}
class NoParams { const NoParams(); }
```

### 6.3 Dio client and error mapping: `core/network/`

One `DioClient` factory with base URL from `Env`, timeouts, an auth interceptor (attach token, refresh once on 401, then emit logout), a logging interceptor (debug only, redact secrets) and `error_mapper.dart` that converts `DioException` to `Failure`. Datasources use this client; **no other file constructs `Dio`**. Retry only idempotent requests.

### 6.4 Repository implementation pattern

```dart
Future<Result<List<Product>>> getProducts(ProductsQuery q) async {
  try {
    final models = await _remote.getProducts(q);
    return Success(models.map((m) => m.toEntity()).toList());
  } on Object catch (e, s) {
    return Err(mapError(e, s)); // central mapper logs and converts to Failure
  }
}
```

The try/catch exists **only** in repository implementations, delegating to the central mapper. No copy-pasted error handling elsewhere.

### 6.5 Generic screen state: `shared/widgets/state_builder.dart`

`StateBuilder` renders loading, empty, error (with retry) and content from one status model so every list or detail screen is mostly configuration. Use it instead of hand-writing `if (loading) ... else if (error) ...`.

### 6.6 Dependency injection: `core/di/injection.dart`

Each feature has `<feature>_injection.dart` registering its datasources, repository (as the abstract type), use cases (factory) and BLoCs (factory). `injection.dart` only calls those functions. Singletons are limited to `Dio`, secure storage, logger and the router.

### 6.7 Environment config: `core/config/env.dart`

```dart
abstract final class Env {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
}
```

Values come from `--dart-define-from-file=env/<flavor>.json` (git-ignored; `env/example.json` is committed). Only `env.dart` reads `String.fromEnvironment`. Never hardcode URLs or keys. Validate required values at startup and fail fast.

---

## 7. State Management Rules (BLoC)

- One BLoC/Cubit per screen or cohesive flow. Do not create a global "god" BLoC.
- Events and states are immutable (`freezed` or `equatable`); `props` must include every field.
- Handlers use `emit` only while the handler is active; use `emit.forEach`/`restartable()` transformers for streams and search-as-you-type (`bloc_concurrency`).
- BLoCs call **use cases only**. No repositories, no Dio.
- Provide BLoCs with `BlocProvider` at the lowest possible scope; dispose is automatic, do not leak subscriptions (cancel in `close()`).
- Use `BlocSelector` or `buildWhen` to limit rebuilds. Never rebuild a whole page for one field.
- Side effects (snackbar, navigation, dialogs) go through `BlocListener`, never inside `build`.
- Register a `BlocObserver` in `bootstrap.dart` for logging in debug builds.

---

## 8. Data and Storage Rules

- Models (`data/models`) mirror the API JSON with `freezed` + `json_serializable`; entities (`domain/entities`) mirror business needs. Always map model -> entity; never expose models to presentation.
- Parse defensively: unknown enum values and missing optional fields must not crash the app.
- Secrets and tokens only in `flutter_secure_storage`. Never in `shared_preferences`, logs or source.
- Money as integer minor units (or a decimal type), never `double`. Dates stored and transferred in UTC (ISO 8601), formatted in the UI.
- Local database access only inside `*_local_datasource.dart`. Schema changes via versioned migrations.
- Paginate every list endpoint (cursor or page). Never fetch unbounded lists.
- Cache with a clear policy (source of truth, TTL, invalidation) documented in the repository.

---

## 9. External Services and Platform Rules

1. Every plugin or SDK (Firebase, maps, payments, push) is wrapped behind an interface in `core/services/` or the feature's `data/`. Domain and presentation never import the SDK.
2. Secrets via `Env` only. API keys that must ship in the app are treated as public; real secrets stay on the backend.
3. Request only the permissions the feature needs, at the moment of use, with a rationale screen. Handle denied and permanently denied states.
4. Handle offline and flaky network explicitly (connectivity checks do not replace error handling).
5. Platform-specific code uses conditional imports or `Platform` checks inside `core/services/` only.
6. Document each integration's reference link at the top of its wrapper file.

---

## 10. Security Checklist (every feature touching data)

- [ ] Tokens in secure storage; refresh and logout flows implemented
- [ ] No secrets, keys or PII in logs, crash reports or analytics events
- [ ] TLS only; certificate pinning decision recorded in `docs/DECISIONS.md` for sensitive apps
- [ ] Input validated client-side for UX **and** treated as untrusted by the backend
- [ ] Deep links and route parameters validated before use
- [ ] Release builds obfuscated (`--obfuscate --split-debug-info`) and debug symbols stored
- [ ] Biometric/PIN gates where the plan requires them
- [ ] WebViews restricted to trusted origins; JavaScript disabled unless required
- [ ] Android: `allowBackup`/cleartext traffic reviewed; iOS: ATS enabled
- [ ] Dependency audit (`flutter pub outdated`, advisories) reviewed

---

## 11. Performance and Quality

- `const` widgets and constructors wherever possible; avoid rebuilding large subtrees.
- Use `ListView.builder`/slivers for long lists; never build unbounded `Column` children in a scroll view.
- Move heavy work (JSON parsing of large payloads, image processing) to an isolate (`compute`/`Isolate.run`).
- Cache and size images (`cached_network_image` with width/height); dispose controllers, focus nodes and subscriptions.
- No work in `build`. No `setState` for state that belongs in a BLoC.
- Profile in **profile mode** on a real device before release; watch for jank (frames over 16 ms) and startup time.
- Support text scaling, dark mode and screen readers (see `docs/UI_RULES.md`).

---

## 12. Testing

- **Domain**: unit tests for use cases and pure logic with mocked repositories (highest priority).
- **Data**: unit tests for models (JSON round trip), mappers and repository impls with mocked datasources (`mocktail`), including every failure mapping.
- **BLoC**: `bloc_test` for each event: initial state, success path, failure path, edge case.
- **Widgets**: widget tests for key screens and shared widgets (loading, empty, error, content) with a mocked BLoC. Use golden tests for stable design-system widgets.
- **Integration**: a few `integration_test` flows for critical journeys (sign in, core action).
- `test/` mirrors `lib/` (`test/features/products/domain/usecases/get_products_test.dart`).

### Mandatory: write AND run tests

- Every new or changed use case, repository, BLoC, model, mapper and shared helper **must** ship with tests in the same change. No test, not done.
- Cover per unit: happy path, failure path, and one edge case. Bug fixes start with a failing regression test.
- After writing code, **run the checks yourself**:
  ```bash
  dart format --set-exit-if-changed . && flutter analyze && flutter test --coverage && flutter build apk --debug
  ```
  Re-run code generation when annotations change: `dart run build_runner build --delete-conflicting-outputs`.
- If anything fails, fix it and re-run until green. Report the final result (passed / failed counts).
- If tests cannot be run in the current environment, say so explicitly and list the exact commands for the user. Never claim tests passed without running them.
- Do not delete, skip, or weaken tests to make them pass. Fix the code, or explain why the test is wrong.
- Mock all network, storage and platform channels in tests. Never call real APIs.
- Coverage target: 80% on `domain/` and `data/`; BLoCs at 90%.

## 13. Workflow for the AI Code Writer

0. **Align with style**: read `docs/ai/STYLE_AND_SKILLS.md` to adapt to developer preferences and avoid disliked patterns.
1. **Locate**: identify the owning feature. If none exists, create `features/<name>/` with `data/`, `domain/`, `presentation/` and an injection file.
2. **Search for reuse**: check `core/` and `shared/` for existing widgets, helpers, failures, use case bases.
3. **Domain first**: entity -> repository interface -> use case (pure Dart).
4. **Data next**: model (freezed/json) -> datasource -> repository impl with error mapping -> DI registration.
5. **Presentation last**: events/states -> BLoC -> page -> widgets -> route in `core/router/`.
6. **Extract** anything now used twice into `core/` or `shared/` (and update the earlier usage).
7. **Test**: write tests for every new or changed unit (section 12).
8. **Verify**: run the quality gate until green. Check size limits, import boundaries, security checklist, and UI rules on a small phone and a tablet.
9. **Document**: tick the matching item in `docs/TASK_LIST.md`; log any architectural decision in `docs/DECISIONS.md`.
10. **Log request & learn**: record the request under its matching category in `docs/ai/REQUEST_LOG.md`. If the user provided style feedback or corrected a mistake, append the preference to `docs/ai/STYLE_AND_SKILLS.md`.

### Output rules for the AI

- When fixing an error or modifying existing code, output **only the changed code** with enough context to place it.
- When creating new files, state the full path above each code block.
- Briefly justify any deviation from these guidelines.
- If requirements are ambiguous in a way that affects architecture (offline-first, auth model, data ownership), ask **one** concise question before coding.
- Follow `docs/PROJECT_GUIDELINES.md` for branches and commits. Never commit directly to `main` or `dev`.

---

## 14. Anti-Patterns (never do)

- Business logic, networking or storage inside widgets, pages or `build` methods.
- `domain/` importing Flutter, Dio, JSON or storage packages.
- Presentation importing `data/`; features importing each other's internals.
- BLoCs calling repositories, Dio or `Navigator`; holding `BuildContext`.
- Constructing `Dio`, `SharedPreferences` or SDK clients outside their DI/wrapper.
- Throwing for expected errors instead of returning `Failure`; empty `catch` blocks.
- Hand-written JSON parsing or duplicated models where `freezed`/`json_serializable` applies; editing generated files.
- `setState` for shared or business state; global mutable singletons for state.
- Hardcoded colors, text styles, spacing, strings or route paths (see `docs/UI_RULES.md`).
- Helper methods returning widgets (`Widget _buildX()`) instead of widget classes for non-trivial UI.
- `print` or `debugPrint` left in code; use the logger service.
- Skipping or weakening tests; claiming tests pass without running them.
- Floats for money; unbounded lists; storing tokens in plain storage.
- Emojis in UI text, comments or commit messages.

---

## 15. Definition of Done

- Follows feature, layer and import-boundary rules
- No duplicated logic that an existing shared piece covers
- Errors returned as `Failure` and rendered by shared error/empty/loading widgets
- Typed and immutable end-to-end (model -> entity -> state -> widget)
- Loading, empty, error and offline states handled
- Verified on a small phone (360 dp wide), a tablet and with large text scale, light and dark theme
- Tests written for all new or changed logic and **actually run green** (format, analyze, test, build)
- No file or method exceeds the size limits; no generated file edited by hand
- `docs/TASK_LIST.md` updated; `env/example.json` updated if config changed

---

## 16. Related Documents

- Visual and widget work: [docs/UI_RULES.md](./docs/UI_RULES.md)
- Branching, PRs, commits, releases and maintenance: [docs/PROJECT_GUIDELINES.md](./docs/PROJECT_GUIDELINES.md)
- Product scope and architecture overview: [docs/PROJECT_PLAN.md](./docs/PROJECT_PLAN.md)

<!-- END:flutter-agent-rules -->
