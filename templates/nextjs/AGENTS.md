<!-- BEGIN:nextjs-agent-rules -->

# AGENTS.md - Architecture and Coding Guidelines (Next.js)

> Read this file fully before writing or changing any code.
> These rules are mandatory. If a request conflicts with them, say so and propose the compliant alternative.
> Project name: **{{PROJECT_NAME}}**

---

## 0. Document Map

| Document | Answers |
|---|---|
| `AGENTS.md` (this file) | How code is structured and written |
| `docs/UI_RULES.md` | How things look (tokens, components, mobile rules) |
| `docs/PROJECT_GUIDELINES.md` | How work flows (branches, PRs, commits, releases, maintenance) |
| `docs/PROJECT_PLAN.md` | What is being built and why |
| `docs/TASK_LIST.md` | What is done and what is next |
| `docs/DECISIONS.md` | Why a technical choice was made (ADR log) |
| `docs/ISSUES.md` | Blockers parked under the 10-minute rule |
| `docs/ai/STYLE_AND_SKILLS.md` | Developer habits, skills, preferences & learned style |
| `docs/ai/REQUEST_LOG.md` | Categorized request history (Feature, Bugfix, Refactor, etc.) |

Reading order for a new contributor or AI agent: `docs/ai/STYLE_AND_SKILLS.md` -> `PROJECT_PLAN` -> `AGENTS` -> `UI_RULES` -> `PROJECT_GUIDELINES` -> `TASK_LIST`.

---

## 1. Stack Defaults

| Concern | Choice |
|---|---|
| Framework | Next.js (App Router), TypeScript `strict` |
| Package manager | pnpm |
| Validation | Zod (single source of truth for types) |
| Database | PostgreSQL via Drizzle ORM (swap only the `server/db/` layer if a project uses another ORM) |
| Server state (client) | TanStack Query |
| Forms | React Hook Form + Zod resolver |
| UI | Tailwind CSS with owned components (see `docs/UI_RULES.md`); no runtime UI kits (MUI, Chakra, Ant) |
| Env | Validated with Zod in `src/config/env.ts` |
| Tests | Vitest (unit/integration), Playwright (E2E) |

Deviations from this table must be recorded in `docs/DECISIONS.md` before implementation.

---

## 2. Core Principles

1. **Feature-first**: code lives with the feature that owns it. Only truly shared code goes in `shared/`.
2. **Layered, one-way dependencies**: `UI -> hooks -> API route -> service -> repository -> DB / external client`. Never skip or reverse a layer.
3. **DRY with judgment**: before writing anything, search `shared/` and the feature folder for an existing util, component, hook or template. Extract on the **second** use, not the first.
4. **Zod schema first**: define the schema once; derive types with `z.infer`. Never hand-write a duplicate type.
5. **Thin routes, thick services**: route handlers only parse, authorize, call a service, and format the response.
6. **No boilerplate**: use the factories and wrappers in section 6 instead of copy-pasting try/catch, auth checks, fetch calls, or CRUD code.
7. **Server by default**: use Server Components. Add `"use client"` only for interactivity, and push it to the smallest leaf component.
8. **Single CSS file**: never create separate or per-page CSS files. All tokens, theme definitions and application styles live in `src/app/globals.css`.
9. **Pure core logic**: domain algorithms (scheduling, pricing, scoring, etc.) are pure functions with no DB, HTTP or framework imports, so they are trivially testable.
10. **Portable by design**: avoid hard dependencies on one hosting vendor. Business logic must not import platform-specific SDKs.

---

## 3. Folder Structure

```
src/
├── app/                          # Routing ONLY (no business logic)
│   ├── (auth)/login/page.tsx
│   ├── (dashboard)/
│   │   ├── layout.tsx
│   │   └── products/page.tsx     # imports from features/products
│   ├── api/
│   │   └── products/
│   │       ├── route.ts          # GET list, POST create
│   │       └── [id]/route.ts     # GET, PATCH, DELETE
│   ├── globals.css               # the ONLY stylesheet
│   ├── layout.tsx
│   └── providers.tsx
│
├── features/                     # One folder per business domain
│   └── products/
│       ├── components/           # Feature-specific UI (ProductForm, ProductTable)
│       ├── hooks/                # useProducts, useCreateProduct (TanStack Query)
│       ├── api/                  # Client-side API calls: products.api.ts
│       ├── server/
│       │   ├── products.service.ts     # Business logic
│       │   └── products.repository.ts  # DB access only
│       ├── schemas/products.schema.ts  # Zod schemas + inferred types
│       ├── constants.ts
│       └── index.ts              # Public API of the feature (barrel)
│
├── shared/                       # Cross-feature, domain-agnostic
│   ├── components/
│   │   ├── ui/                   # Primitives (Button, Input, Select, Checkbox, Textarea)
│   │   ├── common/               # Card, StatCard, Badge, DataTable, Modal, EmptyState, StateBoundary
│   │   ├── forms/                # FormField, FormSelect, FormWrapper
│   │   └── templates/            # DashboardLayout, PageTemplate, ListPageTemplate, DetailPageTemplate
│   ├── hooks/                    # useDebounce, useDisclosure, usePagination
│   ├── lib/                      # Pure helpers: format, date, string, cn, api-client
│   ├── types/                    # ApiResponse, Pagination, etc.
│   └── constants/
│
├── server/                       # Server-only infrastructure
│   ├── db/
│   │   ├── client.ts             # Single DB connection
│   │   ├── schema/               # Drizzle tables (one file per table)
│   │   └── migrations/
│   ├── http/                     # Route helpers (see section 6)
│   │   ├── handler.ts            # createHandler wrapper
│   │   ├── action.ts             # createAction wrapper (Server Actions)
│   │   ├── errors.ts             # AppError + handleError
│   │   └── response.ts           # ok(), created(), fail()
│   ├── integrations/             # External APIs
│   │   ├── _base/http-client.ts  # Shared fetch wrapper
│   │   └── <vendor>/             # <vendor>.client.ts, <vendor>.types.ts, <vendor>.webhook.ts
│   ├── auth/                     # Session, permissions
│   ├── lib/logger.ts             # Structured logger
│   └── crud/createCrudService.ts # Generic CRUD factory
│
├── config/
│   ├── env.ts                    # Zod-validated env (server + public)
│   └── routes.ts                 # Route and API path constants
│
└── proxy.ts                      # Edge/request interception (named middleware.ts before Next.js 16)
```

### Placement rules

| Code is... | Goes in |
|---|---|
| Used by one feature | `features/<name>/` |
| Used by 2+ features and has no domain knowledge | `shared/` |
| Server-only (DB, secrets, external APIs) | `server/` or `features/<name>/server/` |
| A pure domain algorithm | `features/<name>/server/engine/` (or `server/<domain>/`), no framework imports |
| A page/route file | `app/` (import and compose only) |

### Import boundaries

- A feature may import from `shared/` and `server/`. It must **not** import another feature's internals. Use that feature's `index.ts` only.
- `shared/` never imports from `features/`.
- Client components never import from `server/`. Mark server-only files with `import "server-only"`.
- Use path aliases: `@/features/...`, `@/shared/...`, `@/server/...`, `@/config/...`.

---

## 4. Naming Conventions

- Folders and files: `kebab-case`. Components: `PascalCase.tsx`.
- Suffix by role: `*.service.ts`, `*.repository.ts`, `*.schema.ts`, `*.api.ts`, `*.client.ts`.
- Hooks: `useXxx`. Query keys: from a per-feature factory, never inline strings.
- One exported component per file. Named exports (default only for `page`, `layout`, `route`).

### Size limits (hard limits, split before exceeding)

| Item | Max lines |
|---|---|
| Any source file | 250 |
| React component file | 150 |
| `route.ts` handler file | 80 |
| Service / repository file | 250 (split by use case: `products.queries.ts`, `products.commands.ts`) |
| Function / hook | 40 |
| Zod schema file | 150 |
| Test file | 300 |

- Exceeding a limit means the file has more than one responsibility. Split by responsibility, not arbitrarily.
- Max 4 parameters per function (use an options object beyond that). Max 3 levels of nesting (use early returns).
- Generated files (migrations, lockfiles) are exempt.

---

## 5. Data Flow

```
Component -> hook (TanStack Query) -> feature api.ts -> /api route
          -> createHandler -> service -> repository -> DB
                                   \-> integrations/* -> external API
```

- **Reads in Server Components**: call the service directly (no HTTP round trip to your own API).
- **Mutations and client reads**: hook -> `api.ts` -> API route.
- **Server Actions** are allowed for form mutations only when wrapped in `createAction` (section 6.8) and calling the same service layer. A Server Action never contains business logic or DB calls.
- **Never** call `fetch` directly in components. Use `api.ts` through hooks.
- **Never** access the DB from a route handler, action, or component. Only repositories touch the DB.

---

## 6. Boilerplate Eliminators (use these, do not re-implement)

### 6.1 Route handler wrapper: `server/http/handler.ts`

Handles auth, validation, error mapping and response shape in one place.

```ts
// server/http/handler.ts
import { NextRequest, NextResponse } from "next/server";
import type { ZodType } from "zod";
import { AppError, handleError } from "./errors";
import { getSession } from "@/server/auth/session";

type Ctx<B, Q> = {
  req: NextRequest;
  body: B;
  query: Q;
  params: Record<string, string>;
  user: { id: string; role: string } | null;
};

export function createHandler<B = unknown, Q = unknown>(opts: {
  auth?: boolean | string[]; // true = any signed-in user, array = allowed roles
  body?: ZodType<B>;
  query?: ZodType<Q>;
  handle: (ctx: Ctx<B, Q>) => Promise<unknown>;
  status?: number;
}) {
  return async (
    req: NextRequest,
    { params }: { params: Promise<Record<string, string>> },
  ) => {
    try {
      const user = await getSession();
      if (opts.auth && !user) throw AppError.unauthorized();
      if (Array.isArray(opts.auth) && !(user && opts.auth.includes(user.role))) {
        throw AppError.forbidden();
      }

      const body = opts.body ? opts.body.parse(await req.json()) : (undefined as B);
      const query = opts.query
        ? opts.query.parse(Object.fromEntries(req.nextUrl.searchParams))
        : (undefined as Q);

      const data = await opts.handle({ req, body, query, params: await params, user });
      return NextResponse.json({ success: true, data }, { status: opts.status ?? 200 });
    } catch (e) {
      return handleError(e);
    }
  };
}
```

**Usage: a route is about 5 lines.**

```ts
// app/api/products/route.ts
export const GET = createHandler({
  auth: true,
  query: listProductsQuerySchema,
  handle: ({ query, user }) => productsService.list(query, user),
});

export const POST = createHandler({
  auth: ["admin"],
  body: createProductSchema,
  status: 201,
  handle: ({ body, user }) => productsService.create(body, user),
});
```

### 6.2 Standard error type: `server/http/errors.ts`

Throw `AppError.notFound("Product")`, `AppError.conflict(...)`, `AppError.badRequest(...)` anywhere in services. **Never** return error responses manually.

```ts
// server/http/errors.ts
import { NextResponse } from "next/server";
import { ZodError } from "zod";
import { logger } from "@/server/lib/logger";

export type ErrorCode =
  | "BAD_REQUEST" | "UNAUTHORIZED" | "FORBIDDEN" | "NOT_FOUND"
  | "CONFLICT" | "RATE_LIMITED" | "UPSTREAM_ERROR" | "INTERNAL";

export class AppError extends Error {
  constructor(
    readonly code: ErrorCode,
    readonly status: number,
    message: string,
    readonly details: unknown = null,
  ) {
    super(message);
    this.name = "AppError";
  }
  static badRequest(message: string, details?: unknown) { return new AppError("BAD_REQUEST", 400, message, details); }
  static unauthorized(message = "Authentication required") { return new AppError("UNAUTHORIZED", 401, message); }
  static forbidden(message = "You do not have access to this resource") { return new AppError("FORBIDDEN", 403, message); }
  static notFound(label: string) { return new AppError("NOT_FOUND", 404, `${label} not found`); }
  static conflict(message: string) { return new AppError("CONFLICT", 409, message); }
  static rateLimited() { return new AppError("RATE_LIMITED", 429, "Too many requests. Try again later."); }
  static upstream(message: string, details?: unknown) { return new AppError("UPSTREAM_ERROR", 502, message, details); }
}

export function handleError(e: unknown): NextResponse {
  if (e instanceof AppError) return body(e.code, e.message, e.details, e.status);
  if (e instanceof ZodError) return body("BAD_REQUEST", "Validation failed", e.issues, 400);
  logger.error({ err: e }, "Unhandled error");
  return body("INTERNAL", "Something went wrong. Try again later.", null, 500);
}

function body(code: ErrorCode, message: string, details: unknown, status: number) {
  return NextResponse.json({ success: false, error: { code, message, details } }, { status });
}
```

Response shape (always):

```json
{ "success": false, "error": { "code": "NOT_FOUND", "message": "...", "details": null } }
```

### 6.3 Generic CRUD factory: `server/crud/createCrudService.ts`

For standard tables, generate repository + service instead of writing them by hand. Override only what is custom.

```ts
export const productsRepository = createRepository(products);
export const productsService = {
  ...createCrudService(productsRepository, { notFoundLabel: "Product" }),
  async publish(id: string) { /* custom logic only */ },
};
```

### 6.4 External API client: `server/integrations/_base/http-client.ts`

One typed fetch wrapper with base URL, auth header injection, timeout, retry with backoff (idempotent calls only), error normalization to `AppError`, and optional Zod response validation.

```ts
export const vendorClient = createHttpClient({
  baseUrl: env.VENDOR_API_URL,
  headers: () => ({ Authorization: `Bearer ${env.VENDOR_API_KEY}` }),
  timeoutMs: 8000,
});

// usage
const customer = await vendorClient.post("/customers", payload, { schema: customerSchema });
```

Each integration exposes a small, domain-named interface (`vendor.createCustomer()`), never raw HTTP calls scattered in services. Services depend on that interface so it can be mocked.

### 6.5 Client API layer: `shared/lib/api-client.ts`

```ts
export const api = {
  get:    <T>(url: string, params?: object) => request<T>("GET", url, { params }),
  post:   <T>(url: string, body?: unknown)  => request<T>("POST", url, { body }),
  patch:  <T>(url: string, body?: unknown)  => request<T>("PATCH", url, { body }),
  delete: <T>(url: string)                  => request<T>("DELETE", url),
};
```

`request` unwraps `{ success, data }`, throws a typed `ApiError` on failure, and is the **only** place that calls `fetch` on the client.

### 6.6 Generic query hooks: `shared/hooks/`

`createResourceHooks<T>("products", productsApi)` returns `useList`, `useOne`, `useCreate`, `useUpdate`, `useDelete` with automatic cache invalidation and toasts. Feature hooks wrap or extend it only when needed.

### 6.7 Common UI building blocks (reuse before creating)

| Need | Use |
|---|---|
| Table with sort, pagination, empty/loading state | `<DataTable columns data />` |
| Any form | `<FormWrapper schema onSubmit>` + `<FormField name />` |
| Delete/confirm actions | `<ConfirmDialog />` |
| Page layout | `<ListPageTemplate>` / `<DetailPageTemplate>` |
| Loading / empty / error | `<StateBoundary isLoading isError isEmpty>` |

**A new feature list page should be mostly configuration** (columns, schema, hooks), not new layout code.

### 6.8 Server Action wrapper: `server/http/action.ts`

Same guarantees as `createHandler` for Server Actions: session check, Zod validation, error mapping to a typed result. Never throw raw errors to the client.

```ts
export const createTaskAction = createAction({
  auth: true,
  input: createTaskSchema,
  handle: ({ input, user }) => tasksService.create(input, user),
});
// returns { success: true, data } | { success: false, error: { code, message, details } }
```

### 6.9 Environment config: `config/env.ts`

```ts
import { z } from "zod";

const server = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]),
  DATABASE_URL: z.string().url(),
  AUTH_SECRET: z.string().min(32),
});
const client = z.object({
  NEXT_PUBLIC_APP_URL: z.string().url(),
});

export const env = { ...server.parse(process.env), ...client.parse({
  NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
}) };
```

Only `env.ts` reads `process.env`. Keep `.env.example` in sync with every variable added.

---

## 7. Database Rules

- Only `*.repository.ts` imports from `server/db`.
- Repositories return plain typed objects. No business rules in them.
- Multi-step writes go in a **transaction** inside the service via `db.transaction`.
- Always paginate list queries (default limit 20, max 100). Never return unbounded lists.
- Select only needed columns for list endpoints.
- Index foreign keys and frequently filtered columns.
- Schema changes via migrations only. Never edit the database manually. Use `drizzle-kit generate` + `migrate` for shared environments; `push` is for local prototyping only.
- Money as integer minor units (or `numeric`), never floats. Timestamps in UTC.
- Every user-owned table has an owner column (`user_id` or `tenant_id`) and every query filters by it.
- Use standard PostgreSQL features where practical to keep hosting portable.

---

## 8. External Services Rules

1. Every integration lives in `server/integrations/<name>/` with `client`, `types`, and (if needed) `webhook` files.
2. Secrets only via `env.ts`. Never read `process.env` elsewhere.
3. Validate **inbound** webhooks (signature + Zod) and make handlers **idempotent**.
4. Validate **outbound** responses with Zod when the data is used for logic.
5. Set timeouts on every call. Retry only idempotent requests.
6. Wrap provider errors into `AppError` so callers never see vendor-specific shapes.
7. Long or unreliable work (emails, sync, large exports) is queued or run in the background, not awaited inside the user request.
8. Document each integration's API reference link at the top of its `client` file.

---

## 9. Validation, Types, Errors

- One Zod schema per input: `createXSchema`, `updateXSchema = createXSchema.partial()`, `listXQuerySchema`.
- Reuse the **same** schema on client forms and server routes.
- No `any`. Use `unknown` and narrow. No non-null `!` except where proven.
- Never swallow errors with an empty `catch`. Throw `AppError` or log and rethrow.
- Never leak stack traces or internal messages to the client in production.

---

## 10. Security Checklist (every endpoint)

- [ ] Auth and role check via `createHandler({ auth })` or `createAction({ auth })`
- [ ] Input validated with Zod
- [ ] Resource ownership/tenant check in the service (never trust IDs from the client)
- [ ] No secrets in client bundles (`NEXT_PUBLIC_` only for public values)
- [ ] Rate limiting on auth, public and expensive endpoints
- [ ] Output shaped through DTO/select (no password hashes, internal fields)
- [ ] Security headers configured (CSP, `X-Content-Type-Options`, `Referrer-Policy`, frame protection)
- [ ] Cookies: `HttpOnly`, `Secure`, `SameSite` set for session cookies
- [ ] Passwords hashed with a modern algorithm (argon2id or bcrypt); never logged

---

## 11. Performance and Caching

- Prefer Server Components and streaming (`Suspense`) for data-heavy pages.
- Use cache tags and `revalidateTag` after mutations; keep tags in a constants file.
- Use `next/image`, `next/font`, and dynamic imports for heavy client-only components.
- Avoid N+1 queries: batch or join in the repository.
- Budget: no page ships avoidable client JS; check bundle output on every release.

---

## 12. Testing

- Services: unit tests with mocked repositories and integration clients.
- Repositories: integration tests against a test DB.
- Schemas, pure helpers and domain engines: unit tests (highest priority for pure algorithms).
- Critical flows: a few E2E tests (Playwright).
- Co-locate tests: `products.service.test.ts` next to the file.

### Mandatory: write AND run tests

- Every new or changed service, repository, schema, route and shared helper **must** ship with tests in the same change. No test, not done.
- Cover per unit: happy path, validation failure, not found / forbidden, and one edge case. Bug fixes start with a failing regression test.
- After writing code, **run the checks yourself**. Do not hand back untested code:
  ```bash
  pnpm typecheck && pnpm lint && pnpm test && pnpm build
  ```
- If anything fails, fix it and re-run until green. Report the final result (passed / failed counts) in your reply.
- If tests cannot be run in the current environment, say so explicitly and list the exact commands for the user to run. Never claim tests passed without running them.
- Do not delete, skip (`.skip`), or weaken tests to make them pass. Fix the code, or explain why the test is wrong.
- Mock external services in tests. Never call real third-party APIs or production databases.
- Coverage target: 80% on `server/` and `features/*/server/`.

---

## 13. Workflow for the AI Code Writer

When asked to build or change something, follow this order:

0. **Align with style**: read `docs/ai/STYLE_AND_SKILLS.md` to adapt to developer preferences and avoid disliked patterns.
1. **Locate**: identify the owning feature. If none exists, create `features/<name>/` with the standard layout.
2. **Search for reuse**: check `shared/` and the feature for existing components, hooks, helpers, schemas. Reuse or extend; do not duplicate.
3. **Schema first**: Zod schema (and DB table + migration if needed).
4. **Bottom-up**: repository -> service -> route (`createHandler`) -> `api.ts` -> hook -> component -> page.
5. **Extract** anything now used twice into `shared/` (and update the earlier usage).
6. **Test**: write tests for every new or changed unit (section 12).
7. **Verify**: run `pnpm typecheck && pnpm lint && pnpm test && pnpm build` until green. Check size limits (section 4), import boundaries and the security checklist.
8. **Document**: tick the matching item in `docs/TASK_LIST.md`; log any architectural decision in `docs/DECISIONS.md`.
9. **Log request & learn**: record the request under its matching category in `docs/ai/REQUEST_LOG.md`. If the user provided style feedback or corrected a mistake, append the preference to `docs/ai/STYLE_AND_SKILLS.md`.

### Output rules for the AI

- When fixing an error or modifying existing code, output **only the changed code** (with enough surrounding context to place it), not whole files.
- When creating new files, state the full path above each code block.
- Briefly justify any deviation from these guidelines.
- If requirements are ambiguous in a way that affects architecture (multi-tenancy, auth model, data ownership), ask **one** concise question before coding.
- Follow `docs/PROJECT_GUIDELINES.md` for branches and commits. Never commit directly to `main` or `dev`.

---

## 14. Anti-Patterns (never do)

- Business logic or DB calls inside `app/` pages, components, route handlers or Server Actions.
- Direct `fetch` in components, or `process.env` outside `env.ts`.
- Copy-pasted try/catch, auth checks or response formatting in routes.
- Cross-feature imports of internal files; `shared/` importing from `features/`.
- Duplicated types that could be `z.infer`'d.
- Files or functions over the size limits in section 4, or doing more than one job.
- Skipping, deleting or weakening tests to get a green run; claiming tests pass without running them.
- `useEffect` for data fetching. Use Server Components or TanStack Query.
- Premature abstraction on first use. Wait for the second.
- Unbounded queries, floats for money, magic strings for routes or query keys.
- Separate, multiple or per-page CSS files (maintain a single `src/app/globals.css`).
- Hardcoded colors, radii, shadows or font sizes (see `docs/UI_RULES.md`).
- Emojis in UI text, comments or commit messages.

---

## 15. Definition of Done

- Follows folder and layer rules; no import-boundary violations
- No duplicated logic that an existing shared piece covers
- Validated, authorized, error-handled through the shared wrappers
- Typed end-to-end (schema -> API -> hook -> UI)
- Loading, empty and error states handled
- Mobile verified (320px and up) per `docs/UI_RULES.md`
- Tests written for all new or changed logic and **actually run green** (typecheck, lint, test, build)
- No file or function exceeds the size limits
- `docs/TASK_LIST.md` updated; `.env.example` updated if env changed

---

## 16. Related Documents

- Visual and component work: [docs/UI_RULES.md](./docs/UI_RULES.md)
- Branching, PRs, commits, releases and maintenance: [docs/PROJECT_GUIDELINES.md](./docs/PROJECT_GUIDELINES.md)
- Product scope and architecture overview: [docs/PROJECT_PLAN.md](./docs/PROJECT_PLAN.md)

<!-- END:nextjs-agent-rules -->
