# Architecture Decision Records (ADR)

Log of technical decisions for **{{PROJECT_NAME}}** (Flutter). Add a new entry whenever you choose, change or reject a stack component, architectural pattern, vendor or convention. Never rewrite history: if a decision changes, add a new ADR that supersedes the old one and update the old status.

## How to add an entry

Copy the template at the bottom, use the next number, and set the status. Link the ADR from the PR that implements it.

**Statuses:** Proposed, Accepted, Superseded by ADR-XXX, Rejected.

---

## ADR-001: Baseline stack

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Context:** The mobile app needs a testable, scalable foundation that a small team can own across Android and iOS (and optionally web/desktop).
- **Decision:** Flutter stable with Dart 3, Clean Architecture (feature-first), BLoC, `go_router`, `dio`, `get_it`, `freezed` + `json_serializable`, `flutter_secure_storage`, `bloc_test` and `mocktail`.
- **Consequences:** Strong separation of concerns and high testability; more files per feature and code generation in the build loop.
- **Alternatives considered:** Riverpod (less ceremony, different testing style); Provider (too little structure for growth); GetX (implicit coupling, harder to test).

## ADR-002: Clean Architecture layering and the dependency rule

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Context:** Business logic mixed into widgets becomes untestable and tied to the UI and network.
- **Decision:** `presentation -> domain <- data`; domain is pure Dart; repositories are interfaces in domain; use cases are the only entry point for BLoCs; errors flow as `Result<T>`/`Failure`.
- **Consequences:** Domain and BLoCs tested without Flutter or network. Mapping boilerplate between models and entities is accepted.

## ADR-003: Errors as values (`Result<T>`)

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Context:** Exceptions leaking into UI cause inconsistent error handling and crashes.
- **Decision:** Repositories catch and map exceptions to `Failure`; use cases return `Result<T>`; BLoCs map failures to states using exhaustive pattern matching.
- **Consequences:** No dependency on a functional-programming package; callers must handle both cases.

## ADR-004: Authentication and session handling

- **Status:** Proposed
- **Date:** YYYY-MM-DD
- **Context:** [Describe needs: email/password, social sign-in, biometrics, token lifetime, backend contract.]
- **Decision:** [Access + refresh tokens in secure storage, refresh interceptor, router redirect on logout / managed provider.]
- **Consequences:** [Trade-offs, offline behavior, security responsibilities.]

## ADR-005: Environments, flavors and release pipeline

- **Status:** Proposed
- **Date:** YYYY-MM-DD
- **Context:** [Dev, staging, production backends; store distribution; signing.]
- **Decision:** [Flavors via `--dart-define-from-file`, app ids per flavor, distribution via Fastlane / Codemagic / GitHub Actions + Firebase App Distribution / TestFlight / Play tracks.]
- **Consequences:** [Signing key handling, build times, vendor lock-in.]

## ADR-006: Brand tokens, font and icon set

- **Status:** Proposed
- **Date:** YYYY-MM-DD
- **Context:** `docs/UI_RULES.md` ships neutral starter values.
- **Decision:** Seed/primary color [hex], font [name], icon set [name], supported locales [list].
- **Consequences:** Changing these later means editing `lib/core/theme/` and ARB files only.

## ADR-007: Offline and local storage strategy

- **Status:** Proposed
- **Date:** YYYY-MM-DD
- **Context:** [Online-only, cache-first, or full offline-first with sync.]
- **Decision:** [Storage engine (drift/isar/shared_preferences), source of truth, conflict policy.]
- **Consequences:** [Complexity, migration approach, test strategy.]

---

## Template

```markdown
## ADR-XXX: Title

- **Status:** Proposed | Accepted | Superseded by ADR-XXX | Rejected
- **Date:** YYYY-MM-DD
- **Context:** What problem or constraint forces a decision?
- **Decision:** What was chosen, stated plainly.
- **Consequences:** Benefits, costs, risks, follow-up work.
- **Alternatives considered:** Options rejected and why.
```
