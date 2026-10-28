<!-- BEGIN:nestjs-agent-rules -->

# AGENTS.md - Architecture and Coding Guidelines (NestJS)

> Read this file fully before writing or changing any code.
> These rules are mandatory. If a request conflicts with them, say so and propose the compliant alternative.
> Project name: **{{PROJECT_NAME}}**

---

## 0. Document Map

| Document | Answers |
|---|---|
| `AGENTS.md` (this file) | How code is structured and written |
| `docs/API_RULES.md` | How the HTTP API looks (URLs, envelopes, pagination, versioning, errors) |
| `docs/PROJECT_GUIDELINES.md` | How work flows (branches, PRs, commits, releases, maintenance) |
| `docs/PROJECT_PLAN.md` | What is being built and why |
| `docs/TASK_LIST.md` | What is done and what is next |
| `docs/DECISIONS.md` | Why a technical choice was made (ADR log) |
| `docs/ISSUES.md` | Blockers parked under the 10-minute rule |
| `docs/ai/STYLE_AND_SKILLS.md` | Developer habits, skills, preferences & learned style |
| `docs/ai/REQUEST_LOG.md` | Categorized request history (Feature, Bugfix, Refactor, etc.) |

Reading order: `docs/ai/STYLE_AND_SKILLS.md` -> `PROJECT_PLAN` -> `AGENTS` -> `API_RULES` -> `PROJECT_GUIDELINES` -> `TASK_LIST`.

---

## 1. Stack Defaults

| Concern | Choice |
|---|---|
| Framework | NestJS (latest LTS-compatible), TypeScript `strict`, Node LTS |
| Package manager | pnpm |
| Validation | Zod via `nestjs-zod` (single source of truth for DTOs and types) |
| Database | PostgreSQL via Drizzle ORM (swap only the `database/` layer and repositories for another ORM) |
| Config | `@nestjs/config` with a Zod-validated schema in `src/config/env.ts` |
| Auth | Passport or custom guards behind an `AuthModule` (decision in `docs/DECISIONS.md`) |
| API docs | `@nestjs/swagger` (OpenAPI), generated from Zod DTOs |
| Logging | `nestjs-pino` (structured JSON logs) |
| Tests | Jest + `@nestjs/testing` (unit/integration), Supertest (e2e) |

Deviations from this table must be recorded in `docs/DECISIONS.md` before implementation.

---

## 2. Core Principles

1. **Module-per-feature**: each business domain is one Nest module that owns its controller, service, repository, DTOs and tests.
2. **Layered, one-way dependencies**: `Controller -> Service -> Repository -> DB` and `Service -> Integration client -> external API`. Never skip or reverse a layer.
3. **Thin controllers, thick services**: controllers only bind routes, declare guards and DTOs, and call one service method.
4. **Zod schema first**: define the schema once, derive the DTO class with `createZodDto` and the type with `z.infer`. Never hand-write a duplicate type.
5. **DRY with judgment**: search `common/` and the feature before writing anything. Extract on the **second** use.
6. **Dependency injection only**: no `new Service()`, no module-level singletons holding state. Everything injectable and mockable.
7. **No boilerplate**: global pipes, filters and interceptors (section 6) handle validation, errors and response shape. Never repeat try/catch in controllers.
8. **Pure core logic**: domain algorithms live in `domain/` as pure functions with no Nest, DB or HTTP imports.
9. **Stateless service**: no in-memory session or cache that breaks horizontal scaling. Use the database or an external cache.
10. **Portable by design**: business logic must not import platform-specific SDKs. Wrap vendors in `integrations/`.

---

## 3. Folder Structure

```
src/
├── main.ts                        # Bootstrap: global pipe, filter, interceptor, swagger, versioning, shutdown hooks
├── app.module.ts
│
├── config/
│   ├── env.ts                     # Zod-validated env schema + typed getter
│   └── config.module.ts
│
├── common/                        # Cross-module, domain-agnostic
│   ├── errors/app-error.ts        # AppError factory (section 6.2)
│   ├── filters/all-exceptions.filter.ts
│   ├── interceptors/response.interceptor.ts
│   ├── guards/                    # roles.guard.ts, throttler config
│   ├── decorators/                # @CurrentUser(), @Roles(), @Public()
│   ├── pipes/                     # ZodValidationPipe registration
│   ├── pagination/                # pagination.schema.ts, paginate.ts
│   └── types/
│
├── database/
│   ├── database.module.ts         # Provides the single Drizzle client
│   ├── schema/                    # Drizzle tables (one file per table)
│   └── migrations/
│
├── auth/                          # Sessions/JWT, strategies, guards (global guard + @Public())
│
├── modules/                       # One folder per business domain
│   └── products/
│       ├── products.module.ts
│       ├── products.controller.ts
│       ├── products.service.ts           # Business logic
│       ├── products.repository.ts        # DB access only
│       ├── dto/products.dto.ts           # Zod schemas + createZodDto classes
│       ├── domain/                       # Pure algorithms (optional)
│       ├── products.constants.ts
│       └── products.service.spec.ts      # Co-located tests
│
├── integrations/                  # External APIs
│   └── <vendor>/                  # <vendor>.module.ts, <vendor>.client.ts, <vendor>.types.ts, <vendor>.webhook.controller.ts
│
└── jobs/                          # Queue processors / scheduled tasks (BullMQ or @nestjs/schedule)

test/                              # e2e specs (*.e2e-spec.ts) and shared test utilities
```

### Placement rules

| Code is... | Goes in |
|---|---|
| Used by one feature | `modules/<name>/` |
| Used by 2+ modules and has no domain knowledge | `common/` |
| A pure domain algorithm | `modules/<name>/domain/` (no framework imports) |
| An external API client | `integrations/<vendor>/` |
| A scheduled or queued task | `jobs/` (calls a service, holds no business logic) |

### Import boundaries

- A module may import `common/`, `database/`, `config/` and **other modules only through their exported providers** (declared in `exports` of that module). Never import another module's repository or internals.
- Only `*.repository.ts` imports from `database/`.
- `common/` never imports from `modules/`.
- Avoid circular module dependencies. If two modules need each other, extract a third module or use events.
- Use path aliases: `@/modules/...`, `@/common/...`, `@/database/...`, `@/config/...`.

---

## 4. Naming Conventions

- Folders and files: `kebab-case` with Nest suffixes: `*.module.ts`, `*.controller.ts`, `*.service.ts`, `*.repository.ts`, `*.dto.ts`, `*.guard.ts`, `*.filter.ts`, `*.interceptor.ts`, `*.client.ts`.
- Classes: `PascalCase` with the role suffix (`ProductsService`). DI tokens: `UPPER_SNAKE_CASE` constants.
- One exported class per file.
- Events: `domain.action` (`order.created`). Queues and jobs: `kebab-case`.

### Size limits (hard limits, split before exceeding)

| Item | Max lines |
|---|---|
| Any source file | 250 |
| Controller file | 120 |
| Service / repository file | 250 (split by use case: `products.queries.ts`, `products.commands.ts`) |
| Method / function | 40 |
| DTO / Zod schema file | 150 |
| Test file | 300 |

- Exceeding a limit means more than one responsibility. Split by responsibility.
- Max 4 parameters per function (use an options object beyond that). Max 3 levels of nesting (early returns).
- Generated files (migrations, lockfiles, OpenAPI output) are exempt.

---

## 5. Request Flow

```
HTTP -> global middleware (helmet, cors, request id, pino)
     -> global guards (auth, roles, throttler)
     -> ZodValidationPipe (body, query, params)
     -> Controller -> Service -> Repository -> DB
                         \-> Integration client -> external API
     -> ResponseInterceptor (envelope)   |   AllExceptionsFilter (error envelope)
```

- **Never** access the DB from a controller, guard, interceptor or job. Only repositories touch the DB.
- **Never** put business rules in a repository or controller.
- Cross-module reactions use events (`@nestjs/event-emitter`) or an exported service, never direct repository access.

---

## 6. Boilerplate Eliminators (use these, do not re-implement)

### 6.1 Global validation, response and error pipeline (`main.ts`)

```ts
app.useGlobalPipes(new ZodValidationPipe());
app.useGlobalInterceptors(new ResponseInterceptor());
app.useGlobalFilters(new AllExceptionsFilter(app.get(Logger)));
app.useGlobalGuards(app.get(JwtAuthGuard), app.get(RolesGuard)); // routes are private unless @Public()
app.enableVersioning({ type: VersioningType.URI });
app.enableShutdownHooks();
```

Routes are **private by default**. Opt out with `@Public()`, restrict with `@Roles("admin")`.

### 6.2 Standard error type: `common/errors/app-error.ts`

Throw `AppError.notFound("Product")`, `AppError.conflict(...)`, `AppError.badRequest(...)` anywhere in services. **Never** build error responses manually or throw bare `HttpException` in feature code.

```ts
export class AppError extends HttpException {
  constructor(readonly code: ErrorCode, status: number, message: string, readonly details: unknown = null) {
    super({ code, message, details }, status);
  }
  static badRequest(message: string, details?: unknown) { return new AppError("BAD_REQUEST", 400, message, details); }
  static unauthorized(message = "Authentication required") { return new AppError("UNAUTHORIZED", 401, message); }
  static forbidden(message = "You do not have access to this resource") { return new AppError("FORBIDDEN", 403, message); }
  static notFound(label: string) { return new AppError("NOT_FOUND", 404, `${label} not found`); }
  static conflict(message: string) { return new AppError("CONFLICT", 409, message); }
  static rateLimited() { return new AppError("RATE_LIMITED", 429, "Too many requests. Try again later."); }
  static upstream(message: string, details?: unknown) { return new AppError("UPSTREAM_ERROR", 502, message, details); }
}
```

`AllExceptionsFilter` maps `AppError`, Zod validation errors and unknown errors to one shape (unknown errors are logged and returned as a generic `INTERNAL` message, never a stack trace):

```json
{ "success": false, "error": { "code": "NOT_FOUND", "message": "Product not found", "details": null } }
```

Success shape (added by `ResponseInterceptor`): `{ "success": true, "data": ..., "meta": { ...pagination } }`.

### 6.3 Controllers: about 5 lines per route

```ts
@Controller({ path: "products", version: "1" })
export class ProductsController {
  constructor(private readonly products: ProductsService) {}

  @Get()
  list(@Query() query: ListProductsQueryDto, @CurrentUser() user: SessionUser) {
    return this.products.list(query, user);
  }

  @Post()
  @Roles("admin")
  create(@Body() body: CreateProductDto, @CurrentUser() user: SessionUser) {
    return this.products.create(body, user);
  }
}
```

### 6.4 DTOs from Zod: `dto/products.dto.ts`

```ts
export const createProductSchema = z.object({ name: z.string().min(1).max(120), priceMinor: z.number().int().nonnegative() });
export const updateProductSchema = createProductSchema.partial();
export const listProductsQuerySchema = paginationSchema.extend({ search: z.string().optional() });

export class CreateProductDto extends createZodDto(createProductSchema) {}
export type CreateProduct = z.infer<typeof createProductSchema>;
```

### 6.5 Generic CRUD base

For standard tables use `createRepository(table)` and `CrudService` from `common/` instead of hand-writing them; override only what is custom.

### 6.6 External API client: `integrations/_base/http-client.ts`

One typed fetch wrapper with base URL, auth header injection, timeout, retry with backoff (idempotent calls only), error normalization to `AppError`, and optional Zod response validation. Each integration exposes a small domain-named interface (`vendor.createCustomer()`), provided through DI so services can mock it.

### 6.7 Environment config: `config/env.ts`

```ts
const schema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]),
  PORT: z.coerce.number().default(3000),
  DATABASE_URL: z.string().url(),
  AUTH_SECRET: z.string().min(32),
});
export const validateEnv = (raw: Record<string, unknown>) => schema.parse(raw);
```

Wire it as `ConfigModule.forRoot({ validate: validateEnv, isGlobal: true })`. Read config only through the typed `ConfigService`; `process.env` is not read anywhere else. Keep `.env.example` in sync with every variable added.

---

## 7. Database Rules

- Only `*.repository.ts` imports from `database/`.
- Repositories return plain typed objects. No business rules in them.
- Multi-step writes go in a **transaction** opened in the service (`db.transaction`), passing the transaction handle to repositories.
- Always paginate list queries (default limit 20, max 100). Never return unbounded lists.
- Select only needed columns for list endpoints. Avoid N+1: batch or join in the repository.
- Index foreign keys and frequently filtered columns.
- Schema changes via migrations only (`drizzle-kit generate` + `migrate`). `push` is for local prototyping only. Migrations run as an explicit deploy step, not on app boot in production.
- Money as integer minor units (or `numeric`), never floats. Timestamps in UTC.
- Every user-owned table has an owner column (`user_id` or `tenant_id`) and every query filters by it.

---

## 8. External Services Rules

1. Every integration lives in `integrations/<name>/` with `module`, `client`, `types` and (if needed) `webhook` files.
2. Secrets only via `ConfigService`. Never read `process.env` elsewhere.
3. Validate **inbound** webhooks (signature + Zod, raw body) and make handlers **idempotent**.
4. Validate **outbound** responses with Zod when the data is used for logic.
5. Set timeouts on every call. Retry only idempotent requests.
6. Wrap provider errors into `AppError` so callers never see vendor-specific shapes.
7. Long or unreliable work (emails, sync, large exports) goes to a queue (`jobs/`), not awaited inside the request.
8. Document each integration's API reference link at the top of its `client` file.

---

## 9. Validation, Types, Errors

- One Zod schema per input: `createXSchema`, `updateXSchema = createXSchema.partial()`, `listXQuerySchema`.
- Validate body, query **and** params. Reject unknown keys on write schemas (`.strict()`).
- No `any`. Use `unknown` and narrow. No non-null `!` except where proven.
- Never swallow errors with an empty `catch`. Throw `AppError` or log and rethrow.
- Never leak stack traces or internal messages to the client in production.

---

## 10. Security Checklist (every endpoint)

- [ ] Auth applies (default private) and role check via `@Roles()` where needed
- [ ] Input validated with Zod (body, query, params)
- [ ] Resource ownership/tenant check in the service (never trust IDs from the client)
- [ ] No secrets in code, logs or error responses
- [ ] Rate limiting (`@nestjs/throttler`) on auth, public and expensive endpoints
- [ ] Output shaped through response DTO or explicit select (no password hashes, internal fields)
- [ ] `helmet` enabled; CORS restricted to known origins; body size limits set
- [ ] Cookies (if used): `HttpOnly`, `Secure`, `SameSite`
- [ ] Passwords hashed with argon2id or bcrypt; never logged
- [ ] Uploads: type, size and storage location validated

---

## 11. Performance and Operations

- Health endpoints (`/health/live`, `/health/ready`) via `@nestjs/terminus`.
- Graceful shutdown enabled; no work lost on SIGTERM.
- Structured logs with a request id on every line; never log secrets or personal data.
- Cache with an external store (Redis) only after measuring; define TTL and invalidation in the service that owns the data.
- Use compression and connection pooling; set DB pool limits per environment.
- Budget: list endpoints respond p95 under the target in `docs/PROJECT_PLAN.md` section 9.

---

## 12. Testing

- Services: unit tests with mocked repositories and integration clients (`Test.createTestingModule`).
- Repositories: integration tests against a test database (container or dedicated schema).
- DTO schemas, pure helpers and domain engines: unit tests (highest priority for pure algorithms).
- Controllers and the full pipeline (auth, validation, error shape): e2e tests with Supertest for critical flows.
- Co-locate unit tests: `products.service.spec.ts` next to the file. e2e specs live in `test/`.

### Mandatory: write AND run tests

- Every new or changed service, repository, schema, controller and shared helper **must** ship with tests in the same change. No test, not done.
- Cover per unit: happy path, validation failure, not found / forbidden, and one edge case. Bug fixes start with a failing regression test.
- After writing code, **run the checks yourself**:
  ```bash
  pnpm typecheck && pnpm lint && pnpm test && pnpm test:e2e && pnpm build
  ```
- If anything fails, fix it and re-run until green. Report the final result (passed / failed counts).
- If tests cannot be run in the current environment, say so explicitly and list the exact commands for the user. Never claim tests passed without running them.
- Do not delete, skip (`.skip`, `xit`), or weaken tests to make them pass. Fix the code, or explain why the test is wrong.
- Mock external services in tests. Never call real third-party APIs or production databases.
- Coverage target: 80% on `modules/*/*.service.ts` and `modules/*/domain/`.

---

## 13. Workflow for the AI Code Writer

0. **Align with style**: read `docs/ai/STYLE_AND_SKILLS.md` to adapt to developer preferences and avoid disliked patterns.
1. **Locate**: identify the owning module. If none exists, create `modules/<name>/` with the standard layout and register it in `app.module.ts`.
2. **Search for reuse**: check `common/` and the module for existing helpers, schemas, guards, base classes.
3. **Schema first**: Zod schema and DTO (and DB table + migration if needed).
4. **Bottom-up**: repository -> service -> controller -> module wiring -> OpenAPI decorators.
5. **Extract** anything now used twice into `common/` (and update the earlier usage).
6. **Test**: write tests for every new or changed unit (section 12).
7. **Verify**: run the quality gate until green. Check size limits, import boundaries and the security checklist.
8. **Document**: tick the matching item in `docs/TASK_LIST.md`; log any architectural decision in `docs/DECISIONS.md`; update `docs/API_RULES.md` if a convention changed.
9. **Log request & learn**: record the request under its matching category in `docs/ai/REQUEST_LOG.md`. If the user provided style feedback or corrected a mistake, append the preference to `docs/ai/STYLE_AND_SKILLS.md`.

### Output rules for the AI

- When fixing an error or modifying existing code, output **only the changed code** with enough context to place it.
- When creating new files, state the full path above each code block.
- Briefly justify any deviation from these guidelines.
- If requirements are ambiguous in a way that affects architecture (multi-tenancy, auth model, data ownership), ask **one** concise question before coding.
- Follow `docs/PROJECT_GUIDELINES.md` for branches and commits. Never commit directly to `main` or `dev`.

---

## 14. Anti-Patterns (never do)

- Business logic or DB calls inside controllers, guards, interceptors, jobs or repositories (rules).
- Importing another module's repository or internals; circular module imports.
- Copy-pasted try/catch, auth checks or response formatting in controllers.
- `process.env` outside `config/env.ts`; hardcoded secrets or URLs.
- Duplicated types that could be `z.infer`'d; hand-written DTO classes with `class-validator` next to Zod.
- Files or methods over the size limits, or doing more than one job.
- Skipping, deleting or weakening tests to get a green run; claiming tests pass without running them.
- Unbounded queries, floats for money, magic strings for roles, events or queue names.
- Returning ORM entities directly to clients without shaping.
- `synchronize`-style automatic schema changes in shared environments.
- Emojis in comments, logs or commit messages.

---

## 15. Definition of Done

- Follows module and layer rules; no import-boundary violations
- No duplicated logic that an existing shared piece covers
- Validated, authorized, error-handled through the global pipeline
- Typed end-to-end (Zod schema -> DTO -> service -> repository)
- Documented in OpenAPI; follows `docs/API_RULES.md`
- Tests written for all new or changed logic and **actually run green** (typecheck, lint, unit, e2e, build)
- No file or method exceeds the size limits
- `docs/TASK_LIST.md` updated; `.env.example` updated if env changed

---

## 16. Related Documents

- API conventions: [docs/API_RULES.md](./docs/API_RULES.md)
- Branching, PRs, commits, releases and maintenance: [docs/PROJECT_GUIDELINES.md](./docs/PROJECT_GUIDELINES.md)
- Product scope and architecture overview: [docs/PROJECT_PLAN.md](./docs/PROJECT_PLAN.md)

<!-- END:nestjs-agent-rules -->
