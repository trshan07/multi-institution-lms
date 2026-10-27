CREATE TABLE lms.memberships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  user_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'invited' CHECK (status IN ('invited','active','suspended','left')),
  joined_at timestamptz,
  left_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (user_id) REFERENCES platform.users(id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, user_id)
);

CREATE INDEX ON lms.memberships (tenant_id, user_id);

CREATE TABLE lms.user_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  membership_id uuid NOT NULL,
  institution_identifier text,
  preferred_name text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(metadata) = 'object'),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, membership_id) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, membership_id),
  UNIQUE (tenant_id, institution_identifier)
);

CREATE INDEX ON lms.user_profiles (tenant_id, membership_id);

CREATE TABLE lms.invitations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  email text NOT NULL CHECK (length(btrim(email)) > 0),
  token_hash text NOT NULL CHECK (length(btrim(token_hash)) > 0),
  invited_by uuid,
  expires_at timestamptz NOT NULL,
  accepted_at timestamptz,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','revoked','expired')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, invited_by) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, token_hash)
);

CREATE INDEX ON lms.invitations (tenant_id, invited_by);

CREATE TABLE lms.tenant_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  setting_key text NOT NULL CHECK (length(btrim(setting_key)) > 0),
  value jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  UNIQUE (tenant_id, setting_key)
);


CREATE TABLE lms.institution_units (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  parent_id uuid,
  code text NOT NULL CHECK (length(btrim(code)) > 0),
  name text NOT NULL CHECK (length(btrim(name)) > 0),
  kind text NOT NULL CHECK (kind IN ('faculty','department','school','division')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, parent_id) REFERENCES lms.institution_units(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, code),
  CHECK (parent_id IS DISTINCT FROM id)
);

CREATE INDEX ON lms.institution_units (tenant_id, parent_id);

CREATE TABLE lms.academic_terms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  code text NOT NULL CHECK (length(btrim(code)) > 0),
  name text NOT NULL CHECK (length(btrim(name)) > 0),
  starts_on date NOT NULL,
  ends_on date NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  UNIQUE (tenant_id, code),
  CHECK (ends_on >= starts_on)
);


CREATE TABLE lms.programs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  unit_id uuid,
  code text NOT NULL CHECK (length(btrim(code)) > 0),
  name text NOT NULL CHECK (length(btrim(name)) > 0),
  grading_policy jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(grading_policy) = 'object'),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, unit_id) REFERENCES lms.institution_units(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, code)
);

CREATE INDEX ON lms.programs (tenant_id, unit_id);

CREATE TABLE lms.course_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  parent_id uuid,
  name text NOT NULL CHECK (length(btrim(name)) > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, parent_id) REFERENCES lms.course_categories(tenant_id, id) ON DELETE RESTRICT,
  CHECK (parent_id IS DISTINCT FROM id)
);

CREATE INDEX ON lms.course_categories (tenant_id, parent_id);

CREATE TABLE lms.courses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  category_id uuid,
  unit_id uuid,
  code text NOT NULL CHECK (length(btrim(code)) > 0),
  title text NOT NULL CHECK (length(btrim(title)) > 0),
  description text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','published','archived')),
  created_by uuid,
  credits numeric(6,2) CHECK (credits >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, category_id) REFERENCES lms.course_categories(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, unit_id) REFERENCES lms.institution_units(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, created_by) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, code)
);

CREATE INDEX ON lms.courses (tenant_id, category_id);
CREATE INDEX ON lms.courses (tenant_id, unit_id);
CREATE INDEX ON lms.courses (tenant_id, created_by);

CREATE TABLE lms.program_courses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  program_id uuid NOT NULL,
  course_id uuid NOT NULL,
  required boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, program_id) REFERENCES lms.programs(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, course_id) REFERENCES lms.courses(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, program_id, course_id)
);

CREATE INDEX ON lms.program_courses (tenant_id, program_id);
CREATE INDEX ON lms.program_courses (tenant_id, course_id);

CREATE TABLE lms.course_offerings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  course_id uuid NOT NULL,
  term_id uuid,
  code text NOT NULL CHECK (length(btrim(code)) > 0),
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','open','in_progress','completed','archived')),
  starts_at timestamptz,
  ends_at timestamptz,
  capacity integer CHECK (capacity > 0),
  grading_policy jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(grading_policy) = 'object'),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, course_id) REFERENCES lms.courses(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, term_id) REFERENCES lms.academic_terms(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, code),
  CHECK (ends_at IS NULL OR starts_at IS NULL OR ends_at > starts_at)
);

CREATE INDEX ON lms.course_offerings (tenant_id, course_id);
CREATE INDEX ON lms.course_offerings (tenant_id, term_id);

CREATE TABLE lms.sections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  offering_id uuid NOT NULL,
  title text NOT NULL CHECK (length(btrim(title)) > 0),
  sort_order integer NOT NULL DEFAULT 0 CHECK (sort_order >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, offering_id) REFERENCES lms.course_offerings(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, offering_id, sort_order),
  UNIQUE (tenant_id, offering_id, id)
);

CREATE INDEX ON lms.sections (tenant_id, offering_id);

CREATE TABLE lms.activities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  offering_id uuid NOT NULL,
  section_id uuid NOT NULL,
  activity_type text NOT NULL,
  contract_version integer NOT NULL DEFAULT 1,
  title text NOT NULL CHECK (length(btrim(title)) > 0),
  configuration jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(configuration) = 'object'),
  sort_order integer NOT NULL DEFAULT 0 CHECK (sort_order >= 0),
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','published','hidden','archived')),
  opens_at timestamptz,
  closes_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, offering_id) REFERENCES lms.course_offerings(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, section_id) REFERENCES lms.sections(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, offering_id, id),
  UNIQUE (tenant_id, section_id, sort_order),
  FOREIGN KEY (tenant_id, offering_id, section_id) REFERENCES lms.sections(tenant_id, offering_id, id),
  FOREIGN KEY (activity_type, contract_version) REFERENCES platform.activity_types(code, contract_version),
  CHECK (closes_at IS NULL OR opens_at IS NULL OR closes_at >= opens_at)
);

CREATE INDEX ON lms.activities (tenant_id, offering_id);
CREATE INDEX ON lms.activities (tenant_id, section_id);

CREATE TABLE lms.cohorts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  program_id uuid,
  code text NOT NULL CHECK (length(btrim(code)) > 0),
  name text NOT NULL CHECK (length(btrim(name)) > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, program_id) REFERENCES lms.programs(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, code)
);

CREATE INDEX ON lms.cohorts (tenant_id, program_id);

CREATE TABLE lms.cohort_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  cohort_id uuid NOT NULL,
  membership_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, cohort_id) REFERENCES lms.cohorts(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, membership_id) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, cohort_id, membership_id)
);

CREATE INDEX ON lms.cohort_members (tenant_id, cohort_id);
CREATE INDEX ON lms.cohort_members (tenant_id, membership_id);

CREATE TABLE lms.cohort_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  cohort_id uuid NOT NULL,
  offering_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, cohort_id) REFERENCES lms.cohorts(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, offering_id) REFERENCES lms.course_offerings(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, cohort_id, offering_id)
);

CREATE INDEX ON lms.cohort_assignments (tenant_id, cohort_id);
CREATE INDEX ON lms.cohort_assignments (tenant_id, offering_id);

CREATE TABLE lms.enrollment_methods (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  offering_id uuid NOT NULL,
  strategy text NOT NULL CHECK (strategy IN ('manual','self','cohort','integration')),
  enabled boolean NOT NULL DEFAULT true,
  settings jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(settings) = 'object'),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, offering_id) REFERENCES lms.course_offerings(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, offering_id, strategy),
  UNIQUE (tenant_id, offering_id, id)
);

CREATE INDEX ON lms.enrollment_methods (tenant_id, offering_id);

CREATE TABLE lms.enrollments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  offering_id uuid NOT NULL,
  membership_id uuid NOT NULL,
  method_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','suspended','completed','withdrawn')),
  enrolled_at timestamptz NOT NULL DEFAULT now(),
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, offering_id) REFERENCES lms.course_offerings(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, membership_id) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, method_id) REFERENCES lms.enrollment_methods(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, offering_id, membership_id),
  FOREIGN KEY (tenant_id, offering_id, method_id) REFERENCES lms.enrollment_methods(tenant_id, offering_id, id),
  CHECK (ends_at IS NULL OR starts_at IS NULL OR ends_at > starts_at)
);

CREATE INDEX ON lms.enrollments (tenant_id, offering_id);
CREATE INDEX ON lms.enrollments (tenant_id, membership_id);
CREATE INDEX ON lms.enrollments (tenant_id, method_id);

CREATE TABLE lms.contexts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  kind text NOT NULL CHECK (kind IN ('institution','unit','offering','activity')),
  parent_id uuid,
  unit_id uuid,
  offering_id uuid,
  activity_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, parent_id) REFERENCES lms.contexts(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, unit_id) REFERENCES lms.institution_units(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, offering_id) REFERENCES lms.course_offerings(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, activity_id) REFERENCES lms.activities(tenant_id, id) ON DELETE RESTRICT,
  CHECK ((kind = 'institution' AND num_nonnulls(unit_id, offering_id, activity_id) = 0 AND parent_id IS NULL) OR (kind = 'unit' AND unit_id IS NOT NULL AND num_nonnulls(unit_id, offering_id, activity_id) = 1 AND parent_id IS NOT NULL) OR (kind = 'offering' AND offering_id IS NOT NULL AND num_nonnulls(unit_id, offering_id, activity_id) = 1 AND parent_id IS NOT NULL) OR (kind = 'activity' AND activity_id IS NOT NULL AND num_nonnulls(unit_id, offering_id, activity_id) = 1 AND parent_id IS NOT NULL)),
  CHECK (parent_id IS DISTINCT FROM id),
  UNIQUE (tenant_id, unit_id),
  UNIQUE (tenant_id, offering_id),
  UNIQUE (tenant_id, activity_id)
);

CREATE INDEX ON lms.contexts (tenant_id, parent_id);
CREATE INDEX ON lms.contexts (tenant_id, unit_id);
CREATE INDEX ON lms.contexts (tenant_id, offering_id);
CREATE INDEX ON lms.contexts (tenant_id, activity_id);

CREATE UNIQUE INDEX ON lms.contexts (tenant_id) WHERE kind = 'institution';
CREATE TABLE lms.roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  code text NOT NULL CHECK (length(btrim(code)) > 0),
  name text NOT NULL CHECK (length(btrim(name)) > 0),
  system_managed boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  UNIQUE (tenant_id, code)
);


CREATE TABLE lms.role_capabilities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  role_id uuid NOT NULL,
  capability_id uuid NOT NULL,
  effect text NOT NULL CHECK (effect IN ('allow','deny')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, role_id) REFERENCES lms.roles(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (capability_id) REFERENCES platform.capabilities(id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, role_id, capability_id)
);

CREATE INDEX ON lms.role_capabilities (tenant_id, role_id);
CREATE INDEX ON lms.role_capabilities (tenant_id, capability_id);

CREATE TABLE lms.role_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  membership_id uuid NOT NULL,
  role_id uuid NOT NULL,
  context_id uuid NOT NULL,
  assigned_by uuid,
  expires_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, membership_id) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, role_id) REFERENCES lms.roles(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, context_id) REFERENCES lms.contexts(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, assigned_by) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, membership_id, role_id, context_id)
);

CREATE INDEX ON lms.role_assignments (tenant_id, membership_id);
CREATE INDEX ON lms.role_assignments (tenant_id, role_id);
CREATE INDEX ON lms.role_assignments (tenant_id, context_id);
CREATE INDEX ON lms.role_assignments (tenant_id, assigned_by);

