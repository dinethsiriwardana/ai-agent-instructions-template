# API Rules

HTTP API conventions for **{{PROJECT_NAME}}**. Every endpoint follows these rules so clients (web, mobile, third parties) can rely on one consistent contract.

---

## 1. URLs and Methods

- Base path: `/api/v{major}/...` (URI versioning, `v1` first). Breaking changes create a new major version; additive changes do not.
- Resource names: plural `kebab-case` nouns (`/products`, `/order-items`). No verbs in paths except for non-CRUD actions (`POST /orders/:id/cancel`).
- Nesting at most one level (`/users/:userId/addresses`). Prefer filtering over deep nesting.
- IDs are opaque strings (UUID). Never expose sequential database IDs.

| Method | Use | Success status |
|---|---|---|
| `GET` | Read one or a list. Safe and idempotent | 200 |
| `POST` | Create, or run a non-CRUD action | 201 (create), 200/202 (action) |
| `PATCH` | Partial update | 200 |
| `PUT` | Full replace (use sparingly) | 200 |
| `DELETE` | Remove (soft delete when data must be recoverable) | 204 or 200 |

---

## 2. Response Envelope

Success:

```json
{ "success": true, "data": { }, "meta": { "page": 1, "limit": 20, "total": 134 } }
```

Error:

```json
{ "success": false, "error": { "code": "VALIDATION_FAILED", "message": "Validation failed", "details": [ { "path": ["name"], "message": "Required" } ] } }
```

- `meta` appears on paginated lists only.
- Error `code` values come from `ErrorCode` in `common/errors/app-error.ts`. Clients switch on `code`, never on `message`.
- `message` is safe to show to a user. Internal details never leave the server.

| HTTP | `code` | When |
|---|---|---|
| 400 | `BAD_REQUEST` / `VALIDATION_FAILED` | Malformed or invalid input |
| 401 | `UNAUTHORIZED` | Missing or invalid credentials |
| 403 | `FORBIDDEN` | Authenticated but not allowed |
| 404 | `NOT_FOUND` | Resource does not exist (or must not be revealed) |
| 409 | `CONFLICT` | Duplicate or state conflict |
| 422 | `UNPROCESSABLE` | Valid shape but violates a business rule |
| 429 | `RATE_LIMITED` | Throttled |
| 502 | `UPSTREAM_ERROR` | Third-party failure |
| 500 | `INTERNAL` | Unexpected error |

---

## 3. Pagination, Filtering, Sorting

- Query params: `page` (default 1), `limit` (default 20, max 100), `sort` (`field` or `-field`), `search`, plus explicit filters (`status=active`).
- Cursor pagination (`cursor`, `limit`) for large or fast-changing lists; document which endpoints use it.
- Always paginate. Never return an unbounded list.
- Sort fields and filters are whitelisted in the Zod query schema.

---

## 4. Request Rules

- JSON bodies only (`Content-Type: application/json`), except documented uploads and webhooks.
- Validate body, query and path params with Zod. Unknown keys on write bodies are rejected.
- Dates: ISO 8601 in UTC (`2026-01-31T10:00:00Z`). Money: integer minor units plus a currency code. Enums: lowercase `snake_case` strings.
- Idempotency: unsafe retried operations (payments, order creation) accept an `Idempotency-Key` header.
- Field naming: `camelCase` in JSON.

---

## 5. Authentication and Authorization

- `Authorization: Bearer <token>` for API clients; cookie sessions only for browser-first apps (`HttpOnly`, `Secure`, `SameSite`).
- Routes are private by default; `@Public()` is an explicit, reviewed opt-out.
- Authorization lives in the service layer (ownership/tenant checks), not in the client.
- Access tokens are short-lived; refresh flow documented in `docs/DECISIONS.md`.

---

## 6. Documentation (OpenAPI)

- Every controller method has `@ApiTags`, `@ApiOperation`, response schemas and error responses declared.
- DTOs come from Zod (`createZodDto`) so the OpenAPI schema matches validation exactly.
- Swagger UI is enabled in development and staging; disabled or protected in production.
- A contract change updates OpenAPI in the same PR. Generated clients (web/mobile) are regenerated from it.

---

## 7. Operational Endpoints

| Path | Purpose |
|---|---|
| `GET /health/live` | Process is up (no dependencies checked) |
| `GET /health/ready` | Dependencies (DB, cache) reachable |
| `GET /version` | Build version and commit (non-sensitive) |

Health endpoints are unversioned, public and never return secrets.

---

## 8. Rate Limiting and Headers

- Global throttle plus stricter limits on auth, signup, password reset and expensive endpoints. Return `429` with `Retry-After`.
- Send `X-Request-Id` on every response and log it; accept an incoming id when present.
- Security headers via `helmet`; CORS restricted to configured origins.

---

## 9. Backward Compatibility

- Never remove or rename a field or change its type inside a major version.
- Deprecate first: mark in OpenAPI, announce in the changelog, keep for at least one release cycle.
- Webhooks you send are versioned and signed; retries use exponential backoff.
