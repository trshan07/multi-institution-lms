# Foundation boundaries

## Agreed stack

Next.js + React frontend; NestJS + TypeScript modular monolith; asynchronous BullMQ workers; PostgreSQL; private S3-compatible storage; Redis; Docker and managed cloud/CDN. Flutter follows a stable API. The user's original specification is preserved under `docs/reference` (including its pasted diagram formatting).

## Current implementation

- Web is a client-side demo inside a real Next.js app. No authentication or tenant isolation is claimed.
- API exposes only `/v1/health`. Module README files reserve the requested bounded domains without pretending that empty services are implemented.
- The PostgreSQL schema is implemented with 77 application tables, forced tenant RLS on all 65 `lms` tables, composite tenant foreign keys, assessment protections, and grade history. The database integration suite passes; the API is not yet connected to these tables. See `database/README.md`.
- Worker accepts only platform infrastructure `ping` jobs. Unsupported jobs fail. It does not process tenant data.
- Contracts hold shared types. Other shared-package directories are reserved until there is actual cross-app code to extract.
- Docker Compose provisions local backing services only, with named data volumes. It is not a production deployment.
- pnpm workspaces discover implemented packages under `apps/*` and `packages/*`; Turborepo runs development, build, and type-check tasks. Root Compose includes the service definitions under infrastructure. CI validates the workspace without local credentials.

## Required persistence design

Use `platform` and `lms` schemas. Global identity must key on issuer plus subject, with institution-specific membership and profiles. Resolve tenant context from verified hostnames with an explicit trusted-proxy policy. Do not accept arbitrary tenant headers as authorization.

Tenant-owned tables need `tenant_id`, composite foreign keys that prohibit cross-tenant relationships, and RLS enforced for a non-owner, non-BYPASSRLS application role. Set tenant context transaction-locally so pooled connections cannot leak context. Missing context must fail closed. Provisioning/migration privileges must be separate from application privileges.

Enrollment is separate from course-level role assignments. Course definitions are separate from scheduled offerings. Permission checks combine tenant state, active membership, contextual capability, and resource eligibility.

Before adding tenant jobs, implement a transactional outbox, idempotent consumers, and validated tenant context. File keys, signed downloads, cache keys, reporting, and audit events must preserve the same isolation boundary. Authentication and database policies are prerequisites for exposing data APIs.

## Design direction

Working brand: Aster Institute. The name is editable in the demo; it is not a final product name. Navigation emphasizes Overview, Courses, People, and Calendar. The current frontend uses a warm ivory navigation rail, forest-green hero, lime accents, and original CSS sculptures; restrained gold/lilac differentiate departments. Dedicated workspace-search and learning-pulse components support discovery and sample analytics. Responsive layouts and native forms/dialogs are included; formal accessibility validation remains a release task. See `docs/development/frontend-design.md`.

## Setup references

- [Next.js App Router installation](https://nextjs.org/docs/app/getting-started/installation)
- [NestJS documentation](https://docs.nestjs.com/)

Deployment target and external identity provider remain unconfigured. No cloud resources have been created.
