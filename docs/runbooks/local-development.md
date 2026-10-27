# Local development

Run commands from the repository root. See the root README for startup scripts and local service ports.

On Windows, `corepack.cmd pnpm` runs the pinned package manager without changing PowerShell execution policy. See `docs/development/README.md` for the workspace workflow.

If port 3000 is in use, run `corepack.cmd pnpm --filter @lms/web dev --port 3001`. If connecting the web app to the API later, also set `WEB_ORIGIN` to the chosen origin. Set `API_PORT` in the API shell to override port 4000.

The worker requires Redis. Only explicitly named `ping` jobs in the `platform-health` queue are supported. SIGINT/SIGTERM close the worker and Redis connection gracefully.

To reset the demo, clear `aster-demo-courses-v1` and `aster-demo-name` from the browser's local storage. This affects only the demo workspace in that browser.

Do not use local Compose credentials in a shared environment. The Compose database role is a development bootstrap role, not a safe tenant-facing application role.
