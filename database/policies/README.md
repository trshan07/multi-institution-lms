# Tenant boundary and database roles

The executable policies are migration `005_tenant_security.sql`; integrity triggers are migrations 006 and 008. All 65 `lms` tables have ENABLE and FORCE ROW LEVEL SECURITY. Their runtime policy requires matching `app.tenant_id` and an active tenant. Missing or empty tenant context returns no rows and rejects writes; malformed UUID context errors rather than falling back to unrestricted access.

`lms_runtime` is a NOLOGIN, non-owner, non-superuser, non-BYPASSRLS privilege group. It can operate within tenant tables but cannot truncate them, change schemas, read global identities, or modify the platform registry. Only capabilities and activity-type definitions are globally readable. Tenant-scoped foreign keys prevent cross-institution links even where IDs are known. Appendix/event records and question snapshots are protected from mutation; academic records default to restricted deletion.

The existing local `postgres` connection is an **administrative migration connection**. It bypasses RLS and must not be used to serve tenant requests. A separate runtime login with membership in `lms_runtime` must be provisioned before persistence is wired to the API. No login/password was generated or added to the application in this milestone.

Trusted backend code must derive tenant identity from verified domain mappings, validate user membership and resource permissions, then use a transaction-local setting:

```sql
BEGIN;
-- With a restricted runtime connection and a validated tenant UUID:
SELECT set_config('app.tenant_id', '<validated-tenant-uuid>', true);
-- Parameterized, authorized tenant queries go here.
COMMIT;
```

Never set context session-wide on a pooled connection. Rollbacks also clear transaction-local settings. Do not expose database credentials or an API that accepts arbitrary tenant context to end users. A database client with runtime credentials can choose its context; this is defense against accidental unscoped queries, not a substitute for trusted server authorization. Teacher/student permissions within one tenant remain an application responsibility, especially answer keys, draft grades, role administration and private files.

Platform tables are intentionally administrative-only, with no runtime access except the two reference catalogs. The security-definer active-tenant helper uses a fixed search path and returns only a boolean. Do not grant arbitrary runtime access to the platform schema's tables or global identity records.

Reference: [PostgreSQL row security](https://www.postgresql.org/docs/18/ddl-rowsecurity.html).
