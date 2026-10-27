-- Initial control plane. Fail on conflicting tables rather than silently adopting them.
CREATE SCHEMA platform;
CREATE SCHEMA lms;
REVOKE ALL ON SCHEMA platform, lms FROM PUBLIC;

CREATE TABLE platform.tenants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL CHECK (length(btrim(slug)) > 0),
  name text NOT NULL CHECK (length(btrim(name)) > 0),
  status text NOT NULL DEFAULT 'provisioning' CHECK (status IN ('provisioning','active','suspended','archived')),
  isolation_tier text NOT NULL DEFAULT 'standard' CHECK (isolation_tier IN ('standard','enterprise','dedicated')),
  timezone text NOT NULL DEFAULT 'Asia/Colombo',
  archived_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (slug),
  CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$')
);


CREATE TABLE platform.users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL CHECK (length(btrim(email)) > 0),
  display_name text NOT NULL CHECK (length(btrim(display_name)) > 0),
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','disabled')),
  last_login_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);


CREATE INDEX ON platform.users (lower(email));
CREATE TABLE platform.user_identities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  issuer text NOT NULL CHECK (length(btrim(issuer)) > 0),
  subject text NOT NULL CHECK (length(btrim(subject)) > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (user_id) REFERENCES platform.users(id) ON DELETE RESTRICT,
  UNIQUE (issuer, subject)
);

CREATE INDEX ON platform.user_identities (user_id);

CREATE TABLE platform.plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL CHECK (length(btrim(code)) > 0),
  name text NOT NULL CHECK (length(btrim(name)) > 0),
  price_minor bigint NOT NULL DEFAULT 0 CHECK (price_minor >= 0),
  currency text NOT NULL DEFAULT 'USD' CHECK (currency ~ '^[A-Z]{3}$'),
  limits jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(limits) = 'object'),
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (code)
);


CREATE TABLE platform.tenant_domains (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  hostname text NOT NULL CHECK (length(btrim(hostname)) > 0),
  verified_at timestamptz,
  verification_token_hash text,
  is_primary boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (tenant_id) REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  UNIQUE (hostname),
  CHECK (hostname = lower(hostname))
);

CREATE INDEX ON platform.tenant_domains (tenant_id);

CREATE UNIQUE INDEX ON platform.tenant_domains (tenant_id) WHERE is_primary;
CREATE TABLE platform.subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  plan_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'trial' CHECK (status IN ('trial','active','past_due','cancelled','expired')),
  provider text,
  external_id text,
  starts_at timestamptz NOT NULL DEFAULT now(),
  ends_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (tenant_id) REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  FOREIGN KEY (plan_id) REFERENCES platform.plans(id) ON DELETE RESTRICT,
  CHECK (ends_at IS NULL OR ends_at > starts_at),
  UNIQUE (provider, external_id)
);

CREATE INDEX ON platform.subscriptions (tenant_id);
CREATE INDEX ON platform.subscriptions (plan_id);

CREATE UNIQUE INDEX ON platform.subscriptions (tenant_id) WHERE status IN ('trial','active','past_due');
CREATE TABLE platform.tenant_features (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  feature_key text NOT NULL CHECK (length(btrim(feature_key)) > 0),
  enabled boolean NOT NULL DEFAULT false,
  configuration jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(configuration) = 'object'),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (tenant_id) REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, feature_key)
);

CREATE INDEX ON platform.tenant_features (tenant_id);

CREATE TABLE platform.provisioning_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  idempotency_key text NOT NULL CHECK (length(btrim(idempotency_key)) > 0),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','running','completed','failed')),
  checkpoint jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(checkpoint) = 'object'),
  attempts integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
  last_error text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (tenant_id) REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, idempotency_key)
);

CREATE INDEX ON platform.provisioning_jobs (tenant_id);

CREATE TABLE platform.billing_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  provider text NOT NULL CHECK (length(btrim(provider)) > 0),
  external_event_id text NOT NULL CHECK (length(btrim(external_event_id)) > 0),
  event_type text NOT NULL CHECK (length(btrim(event_type)) > 0),
  payload jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(payload) = 'object'),
  processed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (tenant_id) REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  UNIQUE (provider, external_event_id)
);

CREATE INDEX ON platform.billing_events (tenant_id);

CREATE TABLE platform.capabilities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL CHECK (length(btrim(code)) > 0),
  description text NOT NULL CHECK (length(btrim(description)) > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (code)
);


CREATE TABLE platform.activity_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL CHECK (length(btrim(code)) > 0),
  contract_version integer NOT NULL CHECK (contract_version > 0),
  configuration_schema jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(configuration_schema) = 'object'),
  enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (code, contract_version)
);


CREATE TABLE platform.audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id uuid,
  tenant_id uuid,
  action text NOT NULL CHECK (length(btrim(action)) > 0),
  resource_type text,
  resource_id uuid,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(metadata) = 'object'),
  request_id text,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (actor_user_id) REFERENCES platform.users(id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id) REFERENCES platform.tenants(id) ON DELETE RESTRICT
);

CREATE INDEX ON platform.audit_logs (actor_user_id);
CREATE INDEX ON platform.audit_logs (tenant_id);

