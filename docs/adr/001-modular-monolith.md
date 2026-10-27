# ADR 001: Modular monolith with asynchronous workers

Status: Accepted target from the user's architecture selection.

Use one NestJS API application with domain modules and separately runnable workers. Keep interfaces explicit and share contracts instead of importing another module's persistence internals. Add domain/application/infrastructure/presentation subfolders as use cases need them, not as empty ceremony.

Use pnpm workspaces and Turborepo for the TypeScript repository, aligned with the requested folder structure. This supersedes the initial npm-workspaces setup. Run the Next.js institution portal independently from the API. Reserve separate admin portals and Flutter source without creating unused apps or a second framework.

The first milestone is a local starter. PostgreSQL RLS, identity, membership validation, and signed file access are mandatory before tenant data can be exposed. Cloud deployment follows operational validation.
