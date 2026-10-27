# Starter validation — 24 October 2026

## Frontend redesign and fixes — 27 October 2026

- Redesigned the institute workspace with ivory/forest/lime styling, local CSS illustrations, a workspace-search dialog and a sample week/month activity chart.
- Browser workflows pass for draft creation and duplicate-code errors, persistence, search, CSV download, course details, people, calendar, settings and chart periods.
- All five screens fit 320, 390, 768, 1024 and 1440px viewports without horizontal page overflow.
- Mobile menu checks confirm focus containment, Escape dismissal, focus restoration and inert background/closed-menu content.
- Production compilation and TypeScript validation pass. No browser page errors were observed in exercised flows.
- The frontend is still a demo and does not yet read or write the PostgreSQL tables.

## Workspace migration — 25 October 2026

- Verified all 50 requested directory/file paths.
- Imported the dependency graph into `pnpm-lock.yaml` and removed the obsolete npm lockfile.
- Installed with pnpm 10.34.8 and frozen lockfile verification before adding the pinned project-local CLI.
- Verified Turbo type checks and production builds for web, API, and worker without temporary PATH changes after adding the local CLI.
- API liveness returned 200; the unimplemented course endpoint returned 404 after migration. The smoke-check startup allowance was increased to 30 seconds after an initial cold-start timeout.
- `.env` remains Git-ignored; local database credentials were not changed.
- Root Compose and GitHub Actions CI are configured. Docker is unavailable locally, and the GitHub workflow has not been executed remotely.

## Initial starter checks

Verified on Windows with Node 22.14 and npm 11.10:

- TypeScript checks for the web app, API, and worker.
- Production compilation for the three runnable applications.
- API liveness response from `/v1/health`.
- Chrome desktop rendering at 1440px and mobile rendering at 390px.
- Course draft creation and persistence after reload; category/search UI; empty search state; course detail dialog and Escape dismissal; CSV download.
- People search, 31-day October calendar, institution name persistence, and mobile navigation.
- No horizontal page overflow at the checked desktop/mobile sizes; no browser page errors in the exercised workflows.
- Dependency installation audit reports zero known vulnerabilities with the locked Next.js 16 and NestJS 12 dependency graph.

Browser verification script and screenshots were generated in ignored `.local/` for this development session. They are not a maintained end-to-end test suite.

Not verified: Docker services (Docker is unavailable on this machine), Redis job execution, cloud deployment, real authentication, database migrations/isolation, screen-reader review, or production load. These are not implemented capabilities of this starter.
