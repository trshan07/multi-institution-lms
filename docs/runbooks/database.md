# Database operations

## Applied locally on 25 October 2026

Inspected `LMS` on PostgreSQL 18.3 before changes: no application tables existed. Created 77 application tables and the migration ledger using eight numbered migrations. Seven activity contracts and twenty capability definitions were seeded. No business/demo data was retained.

Migration validation ran in a rollback transaction before initial installation. Re-running migrations skips checksum-matching versions. Integration checks ran as `lms_runtime` via `SET LOCAL ROLE`, not as unrestricted postgres queries, and cover:

- Every tenant table has forced RLS; runtime role does not bypass it.
- Missing context blocks reads and writes; global users and TRUNCATE are inaccessible.
- Cross-tenant SELECT, INSERT, UPDATE, DELETE and tenant reassignment are blocked.
- Cross-tenant foreign keys and foreign-tenant storage keys are rejected.
- Enrollment duplicates and mismatched offering/method or section links are rejected.
- Published question references cannot gain new choices; question versions cannot be updated.
- Submitted answers cannot change, closed attempts cannot reopen, and excessive scores are rejected.
- Grade changes automatically generate immutable history; incorrect context hierarchy is rejected.
- Switching tenant context does not reveal earlier tenant data; suspension blocks access.
- Transaction-local tenant context does not survive rollback.

Test fixtures roll back; the suite can run again against this development database. The test assumes no other process is writing to its random fixture tenants. It does not replace concurrent exam load tests, full authorization testing or backup restoration exercises.

## Applying future migrations

1. Back up a populated database with your approved backup process.
2. Add a new numbered SQL migration. Do not modify a checksum-recorded migration.
3. Set `MIGRATION_DATABASE_URL` for the intended database or use the local ignored `.env` connection.
4. Run `node database/manage.mjs validate` to test outstanding SQL in a rollback transaction.
5. Run `node database/manage.mjs migrate`, then `node database/manage.mjs verify`.
6. Use `node database/manage.mjs inventory` to inspect installed tables and migration versions.

The runner stops on the first SQL error. All pending migrations in one run commit together or roll back together. No automatic destructive down/reset command is provided. `lms_runtime` is a cluster-wide NOLOGIN group, so another database on the cluster must not redefine it with elevated attributes.

## Finding tables in pgAdmin

Refresh **Databases → LMS → Schemas**. Expand **platform → Tables** or **lms → Tables**. Migration records are under **lms_meta → Tables → schema_migrations**. The public schema is intentionally unused.
