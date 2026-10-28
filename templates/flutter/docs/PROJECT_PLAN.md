# {{PROJECT_NAME}} - Project Plan (Flutter App)

**Version:** 0.1 (draft)
**Date:** YYYY-MM-DD
**Owner:** {{OWNER_NAME}}
**Status:** Draft | Approved | In progress | Released

> How to use this document: replace every text in `[square brackets]`, delete the guidance lines starting with `>` once a section is filled in, and keep the change log (section 17) current. This plan is the source of truth for scope. `docs/TASK_LIST.md` tracks execution.

---

## 1. Project Overview

[Two to four sentences: what the app is, who it is for, and the main value it delivers.]

**One-line pitch:** {{ONE_LINE_DESCRIPTION}}

**Target users:** [primary persona], [secondary persona]
**Platforms:** [Android, iOS, web, desktop]
**First release audience:** [who gets v1]

## 2. Problem Statement

[Describe the problem users face, why current solutions fall short, and what happens if it stays unsolved.]

## 3. Objectives and Success Metrics

| # | Objective | Measure of success |
|---|---|---|
| 1 | [Objective] | [Metric and target, for example "crash-free sessions above 99.5%"] |
| 2 | [Objective] | [Metric and target] |

## 4. Proposed Solution

[Main user flow, key screens and the core mechanism.]

## 5. Users, Roles and Permissions

| Role | Description | Can do | Cannot do |
|---|---|---|---|
| [Guest] | [Not signed in] | [Browse public content] | [Everything else] |
| [User] | [Signed-in user] | [Manage own data] | [Access other users' data] |
| [Admin] | [Operator] | [Manage content/users] | [-] |

## 6. Core Features

### 6.1 [Feature name]

- **User value:** [why it matters]
- **Screens and flow:** [list]
- **Backend endpoints used:** [list or "local only"]
- **Acceptance criteria:**
  - [ ] [Given / when / then statement]
  - [ ] [Given / when / then statement]
- **Offline behavior:** [none / cached read / full offline]
- **Priority:** Must | Should | Could

### 6.2 [Feature name]

[Repeat the structure above for each feature.]

## 7. Domain Model

| Entity | Purpose | Key fields | Source (API / local) |
|---|---|---|---|
| `User` | Account | id, email, role | API |
| `[Entity]` | [purpose] | [fields] | [source] |

> Guidance: business entities only (`domain/entities`). API JSON shapes are `data/models` and are documented by the backend OpenAPI spec.

## 8. System Architecture

### 8.1 Technology stack

| Component | Technology | Responsibility |
|---|---|---|
| Framework | Flutter (stable), Dart 3 | UI and app logic |
| Architecture | Clean Architecture, feature-first | Separation of concerns |
| State | BLoC (`flutter_bloc`) | Screen state and events |
| Navigation | `go_router` | Routing, deep links, auth redirects |
| Networking | `dio` | API access, interceptors |
| DI | `get_it` | Dependency wiring |
| Models | `freezed`, `json_serializable` | Immutable models and JSON |
| Storage | `flutter_secure_storage`, [drift / isar / shared_preferences] | Tokens and local data |
| Push / analytics / crash | [Firebase / other / none in v1] | Engagement and monitoring |
| Distribution | [TestFlight, Play tracks, Firebase App Distribution] | Releases |

### 8.2 Layered architecture

```text
Widget (Page)
  |  dispatch Event / read State
  v
BLoC / Cubit
  |
  v
UseCase  (domain, pure Dart)
  |
  v
Repository interface  <-- Entities
  ^
  |  implements
RepositoryImpl (data) --> RemoteDataSource (Dio) / LocalDataSource
```

Full rules: `AGENTS.md`. Visual rules: `docs/UI_RULES.md`.

### 8.3 Integrations and plugins

| Integration | Purpose | Platform notes | Docs link | In v1? |
|---|---|---|---|---|
| [Name] | [Purpose] | [permissions, native setup] | [URL] | [Yes / No] |

## 9. Non-Functional Requirements

| Area | Requirement |
|---|---|
| Performance | [For example: cold start under 2 s on a mid-range device; 60 fps scrolling] |
| Stability | [Crash-free sessions target] |
| Accessibility | Text scaling to 200%; contrast 4.5:1; screen-reader labels |
| Supported OS | [Android API level, iOS version] |
| Device support | Phones from 360 dp width; tablets [yes / no] |
| Offline | [Policy from ADR-007] |
| App size | [Target download size] |
| Observability | Crash reporting, analytics events list, structured logger |

## 10. Localization

- **Localized:** Yes | No
- **Default locale:** [for example en]
- **Other locales:** [list; RTL support yes/no]
- **Currency and date formats:** [via `intl`]

## 11. Scope

### Included in Version 1

- [Feature]
- [Feature]

### Excluded from Version 1

- [Feature deferred]

## 12. Security and Privacy

- Tokens only in secure storage; refresh and logout flows.
- No secrets, keys or personal data in logs or analytics.
- TLS only; certificate pinning decision recorded (ADR).
- Release builds obfuscated; debug symbols archived.
- Permissions requested just in time with rationale.
- Store privacy declarations (App Store privacy labels, Play data safety): [describe]. Personal data collected: [list]. Account deletion flow: [describe; required by the stores].

## 13. Development Roadmap

| Phase | Main activities | Estimated duration |
|---|---|---|
| 0. Discovery | Requirements, user flows, wireframes | [x weeks] |
| 1. Foundation | Project setup, flavors, CI, theme, DI, networking | [x weeks] |
| 2. Authentication | Sign-in, session, router guard | [x weeks] |
| 3. Design system and shell | Shared widgets, navigation shell | [x weeks] |
| 4 to N. Feature phases | One phase per feature group | [x weeks each] |
| N+1. Quality and release | Device testing, store assets, submission | [x weeks] |

## 14. Testing and Quality Assurance

- Unit tests: use cases, mappers, repository impls, models.
- `bloc_test`: every BLoC event path.
- Widget and golden tests for shared and key screens.
- `integration_test` for critical flows: [sign in, core action].
- Manual: small phone, tablet, light/dark, 200% text scale, offline, slow network, background/foreground.
- Quality gate for every PR: `dart format --set-exit-if-changed . && flutter analyze && flutter test --coverage && flutter build apk --debug`.

## 15. Deployment and Release

- Flavors: dev, staging, prod with separate app ids and backends.
- Signing keys stored in CI secret store; upload keys documented.
- Distribution: [TestFlight / Play internal -> closed -> production].
- Versioning: `version: x.y.z+build` in `pubspec.yaml`; build number auto-incremented in CI.
- Rollback plan: staged rollout with halt, previous build retained, backend kept backward compatible with the last two app versions.
- Force-update / minimum version strategy: [describe].

## 16. Risks and Future Enhancements

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| [Risk] | Low / Med / High | Low / Med / High | [Mitigation] |

### Future enhancements (post v1)

- [Idea]

## 17. Open Questions and Change Log

| # | Question | Owner | Due | Resolution |
|---|---|---|---|---|
| 1 | [Question] | [Name] | [Date] | [Pending] |

| Version | Date | Change | Approved by |
|---|---|---|---|
| 0.1 | YYYY-MM-DD | Initial draft | {{OWNER_NAME}} |
