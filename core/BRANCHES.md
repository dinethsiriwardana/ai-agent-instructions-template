# Project Branches Registry — {{PROJECT_NAME}}

This document tracks all active, in-review, and recently merged branches in the repository.
It ensures that developers and AI agents can instantly identify existing work, understand branch context, and prevent branch sprawl.

## Branching Hierarchy
- **`main`**: Production / stable releases. Merges come only from `dev` (or `hotfix/*`).
- **`dev`**: QA / Staging releases. Merges come only from `dev-test` after verification.
- **`dev-test`**: Active integration & local testing branch. **All** `feat/*`, `fix/*`, `chore/*`, `refactor/*`, and `docs/*` branches branch off and target `dev-test`.

## Branch Statuses
- `Active`: Branch is currently being developed.
- `In Review`: Changes are complete and pushed, PR is open to `dev-test`, awaiting user testing & approval.
- `Merged`: Approved by user and merged into `dev-test`.
- `Closed`: Abandoned or superseded.

---

## Branches Registry

| Branch | Status | Target | Created / Updated | Description & Scope | PR Link | History Ref |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `chore/initial-setup` | `Merged` | `dev-test` | YYYY-MM-DD | Initial project architecture and AI guardrails setup | - | Initial Setup |

