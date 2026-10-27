# Development workflow

Use Node.js 22.14+ and pnpm 10.34.8 (pinned in the root package manifest). The pnpm CLI is also installed as a development dependency so Turbo can find its child-task executable without global shims. Keep the `packageManager` and pnpm dependency versions aligned when upgrading. From the repository root:

```sh
corepack pnpm install --frozen-lockfile
corepack pnpm dev
```

On Windows PowerShell use `corepack.cmd pnpm` if script execution policy blocks the PowerShell shim. After installation, `node node_modules/pnpm/bin/pnpm.cjs dev` also works without Corepack or global pnpm. If Corepack is unavailable for the initial install, use a pnpm 10.34.8 installation from your normal Node toolchain.

`pnpm dev` starts the web app. `pnpm dev:api` starts NestJS. `pnpm dev:worker` requires Redis. `pnpm dev:all` starts all implemented dev processes and requires Redis. Turborepo orchestrates tasks; empty reserved folders have no package manifest and are not runnable workspaces.

Internal dependencies use `workspace:*` so contracts always resolve to local source. Add a unique private package manifest when implementing a reserved app or shared library. Do not add package manifests for empty folders solely to make tasks appear complete.

Use `pnpm typecheck` and `pnpm build` before submitting changes. CI runs these commands with frozen dependency resolution. Only the pnpm lockfile is maintained; do not regenerate an npm lockfile.

The root Docker Compose entry point includes `infrastructure/containers/compose.yml`. The default starts Redis and object storage. PostgreSQL is opt-in (`docker compose --profile database up -d`) because this developer workspace already has PostgreSQL at localhost:5432. Do not enable the container database on that port while the local service is running. Compose include requires Docker Compose 2.20+.

Read [local development](../runbooks/local-development.md) for ports, environment loading, and demo data reset. Local `.env` credentials are ignored by Git and are not required for CI.

References: [pnpm workspaces](https://pnpm.io/workspaces), [Turborepo configuration](https://turborepo.com/docs/reference/configuration).
