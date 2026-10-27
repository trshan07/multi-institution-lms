# PostgreSQL database

The `LMS` database now contains **77 application tables**: 12 control-plane tables in `platform`, 65 tenant-owned tables in `lms`, plus `lms_meta.schema_migrations` for migration checksums/history.

See [table inventory](schema/tables.md), [tenant security](policies/README.md), and [database operations](../docs/runbooks/database.md).

## Commands

Run from the repository root; these commands need Node and PostgreSQL's `psql` client, not a running API:

```sh
node database/manage.mjs inspect
node database/manage.mjs validate
node database/manage.mjs migrate
node database/manage.mjs verify
node database/manage.mjs inventory
```

Equivalent pnpm scripts are `db:inspect`, `db:validate`, `db:migrate`, `db:verify`, and `db:inventory`.

The runner loads the ignored root `.env`. `MIGRATION_DATABASE_URL` takes precedence over `DATABASE_URL`. `PSQL_PATH` overrides client discovery; PostgreSQL 18's standard Windows installation is detected automatically. Credentials are passed through the child environment, never printed or passed on the command line. These administrative operations require a privileged migration account.

Migrations are ordered, transactionally applied under an advisory lock, and SHA-256 checked. Re-running skips applied migrations. Never edit an applied migration; add a new numbered migration. `validate` runs outstanding migrations and rolls back; on an up-to-date database it only validates checksums. An initial conflicting schema causes failure rather than adoption or destructive recreation. Tests generate temporary fixtures and roll back all changes.

## Coverage

- Tenant lifecycle, domains, identity providers, plans, subscriptions, entitlements, provisioning, billing events.
- Memberships, profiles, invitations, settings, organizational units, terms, programs, cohorts.
- Course definitions, offerings, sections, versioned activity types, enrollment methods/enrollments.
- Contexts, roles, capabilities, and assignments separate from enrollment.
- Private file metadata, upload sessions, course/submission attachments.
- Question banks and immutable versions, choices, quizzes, question snapshots, attempts, answers, events, accommodations.
- Assignments, submissions, rubrics, criteria, grade items, grades, append-only grade history.
- Completion rules, activity/course completion, certificates, learning events, report jobs.
- Announcements, discussions, posts, notifications, calendar events.
- Integration references, mappings, webhooks, delivery retries, transactional outbox, consumer deduplication, idempotency and audits.

This is a schema foundation, not a completed backend. The API still exposes health only, and the browser still uses demo data. Runtime authorization, verified tenant resolution, login provisioning, real uploads, enrollment eligibility, deadlines, quiz scoring, task dispatch, billing and academic workflows still need application services. Generic external resource mappings intentionally use type/id references validated by the integration service. Aggregate totals/weights, maximum-attempt limits, active-enrollment eligibility, retention workflows and concurrent business transitions require service-level transactions and further tests.
