# Multi-Institution LMS

A Moodle-inspired LMS starter using Next.js, NestJS, TypeScript, PostgreSQL, S3-compatible storage, and Redis/BullMQ.

## Start locally

Requires Node.js 22.14+ and Corepack or pnpm 10.34.8. The pinned pnpm CLI is also a project development dependency, so Turbo can find it after installation without global shims or PATH changes. The commands below use the Corepack supplied with this machine's Node installation.

```powershell
corepack.cmd pnpm install --frozen-lockfile
corepack.cmd pnpm dev
```

Open http://localhost:3000.

Authentication page designs are available at `/login`, `/register`, `/forgot-password`, and `/reset-password`. They include responsive forms and validation; real authentication and email delivery are not connected. See [authentication pages](docs/development/auth-pages.md).

In another terminal, start the API:

```powershell
corepack.cmd pnpm dev:api
```

API liveness: http://localhost:4000/v1/health. The API currently exposes only liveness; it does not yet serve course or identity data. Health is not a database readiness check.

## First milestone

The **Aster Institute** demo includes a responsive institution dashboard, course catalog, category filters, search, course details, browser-persisted draft creation, CSV export, sample people directory, October 2026 calendar, help, and browser-persisted institution naming.

The interface is a frontend prototype. All institutional statistics, users, and events are sample data. Course drafts and the institution name are stored in this browser only; they are not accounts or tenant records. Do not enter real student information. The calendar is a fixed October 2026 demo, not a live scheduler.

## Repository map

```text
apps/
  web/                  Next.js institution workspace (implemented demo)
  api/                  NestJS modular API (health endpoint)
  worker/               BullMQ infrastructure worker (ping jobs only)
  tenant-admin/         Reserved for a separate administration app
  platform-admin/       Reserved for the SaaS operator app
  media-worker/         Reserved for scanning/transcoding
  mobile/               Reserved for phased Flutter rollout
packages/
  contracts/            Shared TypeScript API and course types
  ui/                   Reserved shared design components
  api-client/           Reserved generated OpenAPI client
  auth/                 Reserved authentication helpers
  tenant-context/       Reserved verified tenant resolution
  observability/        Reserved tracing/logging
  testing/              Reserved integration test utilities
database/
  migrations/ seeds/ policies/ schema/
infrastructure/
  containers/           Included local service definitions
  terraform/ monitoring/ environments/
docs/
  architecture/ adr/ api/ security/ development/ runbooks/ reference/
.github/
  workflows/ci.yml       Install, type checks, builds, Compose validation
docker-compose.yml      Root entry point for local services
pnpm-workspace.yaml     Application and shared-package workspace discovery
pnpm-lock.yaml          Reproducible dependency resolution
turbo.json              Development, build, and type-check tasks
package.json            Root scripts and pinned package manager
tsconfig.base.json      Shared TypeScript settings
.env.example            Non-secret local configuration template
```

Folders marked reserved are intentional placeholders, not working services. The web app currently houses the institution admin experience; separate portals will be added as their workflows are implemented.

The target responsibilities are `web` for students/teachers, `tenant-admin` for institution administration, and `platform-admin` for SaaS operations. Existing `apps/mobile` and additional documentation folders are retained for the earlier roadmap. See [development workflow](docs/development/README.md) for adding packages and running the monorepo.

## Local backing services

Install Docker Desktop, then run:

```powershell
corepack.cmd pnpm infra:up
corepack.cmd pnpm dev:worker
```

Existing local PostgreSQL: `localhost:5432` (configured through your ignored `.env`); Redis: `localhost:6379`; MinIO API: `localhost:9000`; MinIO console: http://localhost:9001. The default Compose command starts Redis and MinIO only. To use a container database instead of an existing PostgreSQL service, run `docker compose --profile database up -d` with port 5432 free. Container development credentials are in `.env.example` and the included service file. Services bind to loopback and retain data in named volumes. The storage bucket must be created before a future upload integration can use it.

The API development and start scripts load the root `.env` file if present. Copy `.env.example` to `.env` for a new checkout and configure your local credentials; `.env` is ignored by Git. Existing shell variables take precedence. The worker currently reads shell variables or uses its local Redis default. PostgreSQL now has the 77-table schema and tenant policies; API persistence and object-storage integration are not wired up yet.

```powershell
corepack.cmd pnpm infra:down
```

This stops containers without deleting their volumes.

## Checks

```powershell
corepack.cmd pnpm typecheck
corepack.cmd pnpm build
```

`pnpm build` builds the web app, API, and worker. The pnpm lockfile pins the resolved dependency graph. NestJS uses the Fastify HTTP adapter; file uploads will use signed object-storage upload sessions.

## Next milestone

The database migrations, RLS, and initial two-institution database checks are implemented. Next implement verified hostname resolution, OIDC identity, runtime database credentials, tenant membership and contextual authorization services, then connect course creation and enrollment to persistent APIs. See [database documentation](database/README.md), [architecture notes](docs/architecture/foundation.md) and [development roadmap](docs/architecture/roadmap.md).

The web design uses warm ivory, forest green, lime accents, serif editorial headlines, and original CSS sculptures/course illustrations. A keyboard-accessible workspace search and interactive sample learning chart complement the institute screens. Google Fonts is optional at runtime; system fonts are fallbacks. See [frontend design](docs/development/frontend-design.md).
