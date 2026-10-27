CREATE TABLE lms.completion_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  activity_id uuid NOT NULL,
  rule jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(rule) = 'object'),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, activity_id) REFERENCES lms.activities(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, activity_id)
);

CREATE INDEX ON lms.completion_rules (tenant_id, activity_id);

CREATE TABLE lms.activity_completions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  offering_id uuid NOT NULL,
  activity_id uuid NOT NULL,
  membership_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'not_started' CHECK (status IN ('not_started','in_progress','completed')),
  completed_at timestamptz,
  evidence jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(evidence) = 'object'),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, offering_id) REFERENCES lms.course_offerings(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, activity_id) REFERENCES lms.activities(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, membership_id) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, activity_id, membership_id),
  FOREIGN KEY (tenant_id, offering_id, activity_id) REFERENCES lms.activities(tenant_id, offering_id, id),
  FOREIGN KEY (tenant_id, offering_id, membership_id) REFERENCES lms.enrollments(tenant_id, offering_id, membership_id),
  CHECK (status <> 'completed' OR completed_at IS NOT NULL)
);

CREATE INDEX ON lms.activity_completions (tenant_id, offering_id);
CREATE INDEX ON lms.activity_completions (tenant_id, activity_id);
CREATE INDEX ON lms.activity_completions (tenant_id, membership_id);

CREATE TABLE lms.course_completions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  offering_id uuid NOT NULL,
  membership_id uuid NOT NULL,
  completed_at timestamptz NOT NULL DEFAULT now(),
  final_score numeric(10,3),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, offering_id) REFERENCES lms.course_offerings(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, membership_id) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, offering_id, membership_id),
  FOREIGN KEY (tenant_id, offering_id, membership_id) REFERENCES lms.enrollments(tenant_id, offering_id, membership_id)
);

CREATE INDEX ON lms.course_completions (tenant_id, offering_id);
CREATE INDEX ON lms.course_completions (tenant_id, membership_id);

CREATE TABLE lms.certificates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  completion_id uuid NOT NULL,
  file_id uuid,
  verification_code text NOT NULL CHECK (length(btrim(verification_code)) > 0),
  issued_at timestamptz NOT NULL DEFAULT now(),
  revoked_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, completion_id) REFERENCES lms.course_completions(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, file_id) REFERENCES lms.files(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, completion_id),
  UNIQUE (tenant_id, verification_code)
);

CREATE INDEX ON lms.certificates (tenant_id, completion_id);
CREATE INDEX ON lms.certificates (tenant_id, file_id);

CREATE TABLE lms.announcements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  offering_id uuid,
  author_id uuid NOT NULL,
  title text NOT NULL CHECK (length(btrim(title)) > 0),
  body text NOT NULL CHECK (length(btrim(body)) > 0),
  published_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, offering_id) REFERENCES lms.course_offerings(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, author_id) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT
);

CREATE INDEX ON lms.announcements (tenant_id, offering_id);
CREATE INDEX ON lms.announcements (tenant_id, author_id);

CREATE TABLE lms.forums (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  offering_id uuid NOT NULL,
  title text NOT NULL CHECK (length(btrim(title)) > 0),
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, offering_id) REFERENCES lms.course_offerings(tenant_id, id) ON DELETE RESTRICT
);

CREATE INDEX ON lms.forums (tenant_id, offering_id);

CREATE TABLE lms.discussions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  forum_id uuid NOT NULL,
  author_id uuid NOT NULL,
  title text NOT NULL CHECK (length(btrim(title)) > 0),
  locked boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, forum_id) REFERENCES lms.forums(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, author_id) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT
);

CREATE INDEX ON lms.discussions (tenant_id, forum_id);
CREATE INDEX ON lms.discussions (tenant_id, author_id);

CREATE TABLE lms.discussion_posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  discussion_id uuid NOT NULL,
  author_id uuid NOT NULL,
  parent_id uuid,
  body text NOT NULL CHECK (length(btrim(body)) > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, discussion_id) REFERENCES lms.discussions(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, author_id) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, parent_id) REFERENCES lms.discussion_posts(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, discussion_id, id),
  CHECK (parent_id IS DISTINCT FROM id),
  FOREIGN KEY (tenant_id, discussion_id, parent_id) REFERENCES lms.discussion_posts(tenant_id, discussion_id, id)
);

CREATE INDEX ON lms.discussion_posts (tenant_id, discussion_id);
CREATE INDEX ON lms.discussion_posts (tenant_id, author_id);
CREATE INDEX ON lms.discussion_posts (tenant_id, parent_id);

CREATE TABLE lms.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  recipient_id uuid NOT NULL,
  kind text NOT NULL CHECK (length(btrim(kind)) > 0),
  title text NOT NULL CHECK (length(btrim(title)) > 0),
  payload jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(payload) = 'object'),
  read_at timestamptz,
  delivered_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, recipient_id) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT
);

CREATE INDEX ON lms.notifications (tenant_id, recipient_id);

CREATE TABLE lms.calendar_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  offering_id uuid,
  created_by uuid,
  title text NOT NULL CHECK (length(btrim(title)) > 0),
  description text,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL,
  location text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, offering_id) REFERENCES lms.course_offerings(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, created_by) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT,
  CHECK (ends_at >= starts_at)
);

CREATE INDEX ON lms.calendar_events (tenant_id, offering_id);
CREATE INDEX ON lms.calendar_events (tenant_id, created_by);

CREATE TABLE lms.integration_connections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  provider text NOT NULL CHECK (length(btrim(provider)) > 0),
  name text NOT NULL CHECK (length(btrim(name)) > 0),
  status text NOT NULL DEFAULT 'disabled' CHECK (status IN ('disabled','active','error')),
  secret_reference text,
  configuration jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(configuration) = 'object'),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  UNIQUE (tenant_id, provider, name)
);


CREATE TABLE lms.external_mappings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  connection_id uuid NOT NULL,
  resource_type text NOT NULL CHECK (length(btrim(resource_type)) > 0),
  resource_id uuid NOT NULL,
  external_id text NOT NULL CHECK (length(btrim(external_id)) > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, connection_id) REFERENCES lms.integration_connections(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, connection_id, resource_type, external_id),
  UNIQUE (tenant_id, connection_id, resource_type, resource_id)
);

CREATE INDEX ON lms.external_mappings (tenant_id, connection_id);

CREATE TABLE lms.webhook_endpoints (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  url text NOT NULL CHECK (length(btrim(url)) > 0),
  secret_reference text NOT NULL CHECK (length(btrim(secret_reference)) > 0),
  event_types text[] NOT NULL DEFAULT '{}',
  enabled boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  CHECK (url LIKE 'https://%')
);


CREATE TABLE lms.outbox_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  event_type text NOT NULL CHECK (length(btrim(event_type)) > 0),
  aggregate_type text NOT NULL CHECK (length(btrim(aggregate_type)) > 0),
  aggregate_id uuid NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(payload) = 'object'),
  event_version integer NOT NULL DEFAULT 1 CHECK (event_version > 0),
  occurred_at timestamptz NOT NULL DEFAULT now(),
  available_at timestamptz NOT NULL DEFAULT now(),
  published_at timestamptz,
  attempts integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
  last_error text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id)
);


CREATE INDEX ON lms.outbox_events (tenant_id, available_at) WHERE published_at IS NULL;
CREATE TABLE lms.webhook_deliveries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  endpoint_id uuid NOT NULL,
  event_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','delivered','failed')),
  attempts integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
  response_status integer CHECK (response_status BETWEEN 100 AND 599),
  next_attempt_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, endpoint_id) REFERENCES lms.webhook_endpoints(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, event_id) REFERENCES lms.outbox_events(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, endpoint_id, event_id)
);

CREATE INDEX ON lms.webhook_deliveries (tenant_id, endpoint_id);
CREATE INDEX ON lms.webhook_deliveries (tenant_id, event_id);

CREATE TABLE lms.processed_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  consumer text NOT NULL CHECK (length(btrim(consumer)) > 0),
  event_id uuid NOT NULL,
  processed_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  UNIQUE (tenant_id, consumer, event_id)
);


CREATE TABLE lms.idempotency_keys (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  membership_id uuid NOT NULL,
  operation text NOT NULL CHECK (length(btrim(operation)) > 0),
  key text NOT NULL CHECK (length(btrim(key)) > 0),
  request_hash text NOT NULL,
  response_status integer CHECK (response_status BETWEEN 100 AND 599),
  response_body jsonb,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, membership_id) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, membership_id, operation, key)
);

CREATE INDEX ON lms.idempotency_keys (tenant_id, membership_id);

CREATE TABLE lms.audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  actor_id uuid,
  action text NOT NULL CHECK (length(btrim(action)) > 0),
  resource_type text,
  resource_id uuid,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(metadata) = 'object'),
  request_id text,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, actor_id) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT
);

CREATE INDEX ON lms.audit_logs (tenant_id, actor_id);

CREATE TABLE lms.learning_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  membership_id uuid NOT NULL,
  offering_id uuid,
  activity_id uuid,
  event_type text NOT NULL CHECK (length(btrim(event_type)) > 0),
  payload jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(payload) = 'object'),
  occurred_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, membership_id) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, offering_id) REFERENCES lms.course_offerings(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, activity_id) REFERENCES lms.activities(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, offering_id, activity_id) REFERENCES lms.activities(tenant_id, offering_id, id),
  CHECK (activity_id IS NULL OR offering_id IS NOT NULL)
);

CREATE INDEX ON lms.learning_events (tenant_id, membership_id);
CREATE INDEX ON lms.learning_events (tenant_id, offering_id);
CREATE INDEX ON lms.learning_events (tenant_id, activity_id);

CREATE TABLE lms.report_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  requested_by uuid NOT NULL,
  report_type text NOT NULL CHECK (length(btrim(report_type)) > 0),
  filters jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(filters) = 'object'),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','running','completed','failed')),
  result_file_id uuid,
  completed_at timestamptz,
  error_message text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, requested_by) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, result_file_id) REFERENCES lms.files(tenant_id, id) ON DELETE RESTRICT
);

CREATE INDEX ON lms.report_jobs (tenant_id, requested_by);
CREATE INDEX ON lms.report_jobs (tenant_id, result_file_id);

