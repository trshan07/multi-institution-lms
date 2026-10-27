-- This role is a privilege group, not a login. Never use postgres for request traffic.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'lms_runtime') THEN
    CREATE ROLE lms_runtime NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
  ELSIF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'lms_runtime'
    AND (rolsuper OR rolbypassrls OR rolcreatedb OR rolcreaterole OR rolreplication OR rolcanlogin)) THEN
    RAISE EXCEPTION 'Existing lms_runtime role has unsafe attributes; migration stopped';
  END IF;
END $$;

CREATE FUNCTION lms.current_tenant_id() RETURNS uuid
LANGUAGE sql STABLE PARALLEL SAFE
SET search_path = pg_catalog
AS $$ SELECT nullif(current_setting('app.tenant_id', true), '')::uuid $$;

-- Only reveals whether the selected tenant is active; no global registry access is granted.
CREATE FUNCTION lms.tenant_is_active() RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = pg_catalog
AS $$ SELECT EXISTS (SELECT 1 FROM platform.tenants
                     WHERE id = lms.current_tenant_id() AND status = 'active') $$;

REVOKE ALL ON FUNCTION lms.current_tenant_id(), lms.tenant_is_active() FROM PUBLIC;
GRANT USAGE ON SCHEMA lms, platform TO lms_runtime;
GRANT EXECUTE ON FUNCTION lms.current_tenant_id(), lms.tenant_is_active() TO lms_runtime;
GRANT SELECT ON platform.capabilities, platform.activity_types TO lms_runtime;

DO $$ DECLARE t record;
BEGIN
  FOR t IN SELECT tablename FROM pg_tables WHERE schemaname = 'lms' LOOP
    EXECUTE format('ALTER TABLE lms.%I ENABLE ROW LEVEL SECURITY', t.tablename);
    EXECUTE format('ALTER TABLE lms.%I FORCE ROW LEVEL SECURITY', t.tablename);
    EXECUTE format('CREATE POLICY tenant_isolation ON lms.%I TO lms_runtime
      USING (tenant_id = lms.current_tenant_id() AND lms.tenant_is_active())
      WITH CHECK (tenant_id = lms.current_tenant_id() AND lms.tenant_is_active())', t.tablename);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON lms.%I TO lms_runtime', t.tablename);
  END LOOP;
END $$;

-- No TRUNCATE, DDL, registry changes, identity changes, or table ownership granted.
REVOKE UPDATE, DELETE ON lms.audit_logs, lms.grade_history, lms.quiz_attempt_events,
  lms.learning_events, lms.processed_events FROM lms_runtime;
REVOKE UPDATE, DELETE ON lms.question_versions, lms.question_choices, lms.attempt_questions FROM lms_runtime;
ALTER DEFAULT PRIVILEGES IN SCHEMA lms, platform REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA lms, platform REVOKE ALL ON TABLES FROM PUBLIC;

CREATE INDEX ON lms.memberships (tenant_id, status);
CREATE INDEX ON lms.course_offerings (tenant_id, status);
CREATE INDEX ON lms.enrollments (tenant_id, membership_id, status);
CREATE INDEX ON lms.notifications (tenant_id, recipient_id, created_at DESC) WHERE read_at IS NULL;
CREATE INDEX ON lms.audit_logs (tenant_id, occurred_at DESC);
CREATE INDEX ON lms.learning_events (tenant_id, offering_id, occurred_at DESC);
CREATE INDEX ON lms.idempotency_keys (tenant_id, expires_at);
CREATE INDEX ON platform.audit_logs (tenant_id, occurred_at DESC);
