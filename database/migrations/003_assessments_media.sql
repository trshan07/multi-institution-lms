CREATE TABLE lms.files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  uploaded_by uuid,
  bucket text NOT NULL CHECK (length(btrim(bucket)) > 0),
  object_key text NOT NULL CHECK (length(btrim(object_key)) > 0),
  filename text NOT NULL CHECK (length(btrim(filename)) > 0),
  content_type text NOT NULL CHECK (length(btrim(content_type)) > 0),
  size_bytes bigint NOT NULL CHECK (size_bytes >= 0),
  sha256 text CHECK (sha256 ~ '^[a-f0-9]{64}$'),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','scanning','available','rejected','deleted')),
  object_version text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, uploaded_by) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, bucket, object_key),
  CHECK (object_key LIKE tenant_id::text || '/%')
);

CREATE INDEX ON lms.files (tenant_id, uploaded_by);

CREATE TABLE lms.upload_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  file_id uuid NOT NULL,
  membership_id uuid NOT NULL,
  multipart_upload_id text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','uploaded','completed','aborted')),
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, file_id) REFERENCES lms.files(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, membership_id) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, file_id)
);

CREATE INDEX ON lms.upload_sessions (tenant_id, file_id);
CREATE INDEX ON lms.upload_sessions (tenant_id, membership_id);

CREATE TABLE lms.activity_files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  activity_id uuid NOT NULL,
  file_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, activity_id) REFERENCES lms.activities(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, file_id) REFERENCES lms.files(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, activity_id, file_id)
);

CREATE INDEX ON lms.activity_files (tenant_id, activity_id);
CREATE INDEX ON lms.activity_files (tenant_id, file_id);

CREATE TABLE lms.question_banks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  name text NOT NULL CHECK (length(btrim(name)) > 0),
  unit_id uuid,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, unit_id) REFERENCES lms.institution_units(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, created_by) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT
);

CREATE INDEX ON lms.question_banks (tenant_id, unit_id);
CREATE INDEX ON lms.question_banks (tenant_id, created_by);

CREATE TABLE lms.questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  bank_id uuid NOT NULL,
  name text NOT NULL CHECK (length(btrim(name)) > 0),
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','archived')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, bank_id) REFERENCES lms.question_banks(tenant_id, id) ON DELETE RESTRICT
);

CREATE INDEX ON lms.questions (tenant_id, bank_id);

CREATE TABLE lms.question_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  question_id uuid NOT NULL,
  version integer NOT NULL CHECK (version > 0),
  question_type text NOT NULL CHECK (question_type IN ('single_choice','multiple_choice','true_false','short_answer','essay','numeric')),
  prompt text NOT NULL CHECK (length(btrim(prompt)) > 0),
  answer_key jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(answer_key) = 'object'),
  max_mark numeric(10,3) NOT NULL CHECK (max_mark > 0),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(metadata) = 'object'),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, question_id) REFERENCES lms.questions(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, question_id, version)
);

CREATE INDEX ON lms.question_versions (tenant_id, question_id);

CREATE TABLE lms.question_choices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  question_version_id uuid NOT NULL,
  choice_key text NOT NULL CHECK (length(btrim(choice_key)) > 0),
  body text NOT NULL CHECK (length(btrim(body)) > 0),
  sort_order integer NOT NULL CHECK (sort_order >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, question_version_id) REFERENCES lms.question_versions(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, question_version_id, choice_key),
  UNIQUE (tenant_id, question_version_id, sort_order)
);

CREATE INDEX ON lms.question_choices (tenant_id, question_version_id);

CREATE TABLE lms.quizzes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  activity_id uuid NOT NULL,
  offering_id uuid NOT NULL,
  time_limit_seconds integer CHECK (time_limit_seconds > 0),
  max_attempts integer NOT NULL DEFAULT 1 CHECK (max_attempts > 0),
  pass_percentage numeric(5,2) NOT NULL DEFAULT 50 CHECK (pass_percentage BETWEEN 0 AND 100),
  shuffle_questions boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, activity_id) REFERENCES lms.activities(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, offering_id) REFERENCES lms.course_offerings(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, activity_id),
  UNIQUE (tenant_id, offering_id, id),
  FOREIGN KEY (tenant_id, offering_id, activity_id) REFERENCES lms.activities(tenant_id, offering_id, id)
);

CREATE INDEX ON lms.quizzes (tenant_id, activity_id);
CREATE INDEX ON lms.quizzes (tenant_id, offering_id);

CREATE TABLE lms.quiz_questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  quiz_id uuid NOT NULL,
  question_version_id uuid NOT NULL,
  position integer NOT NULL CHECK (position > 0),
  max_mark numeric(10,3) NOT NULL CHECK (max_mark > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, quiz_id) REFERENCES lms.quizzes(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, question_version_id) REFERENCES lms.question_versions(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, quiz_id, position)
);

CREATE INDEX ON lms.quiz_questions (tenant_id, quiz_id);
CREATE INDEX ON lms.quiz_questions (tenant_id, question_version_id);

CREATE TABLE lms.quiz_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  quiz_id uuid NOT NULL,
  offering_id uuid NOT NULL,
  membership_id uuid NOT NULL,
  attempt_number integer NOT NULL CHECK (attempt_number > 0),
  status text NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress','submitted','graded','abandoned')),
  started_at timestamptz NOT NULL DEFAULT now(),
  deadline_at timestamptz,
  submitted_at timestamptz,
  graded_at timestamptz,
  total_score numeric(12,3) CHECK (total_score >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, quiz_id) REFERENCES lms.quizzes(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, offering_id) REFERENCES lms.course_offerings(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, membership_id) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, quiz_id, membership_id, attempt_number),
  FOREIGN KEY (tenant_id, offering_id, quiz_id) REFERENCES lms.quizzes(tenant_id, offering_id, id),
  FOREIGN KEY (tenant_id, offering_id, membership_id) REFERENCES lms.enrollments(tenant_id, offering_id, membership_id),
  CHECK (status NOT IN ('submitted','graded') OR submitted_at IS NOT NULL),
  CHECK (submitted_at IS NULL OR submitted_at >= started_at)
);

CREATE INDEX ON lms.quiz_attempts (tenant_id, quiz_id);
CREATE INDEX ON lms.quiz_attempts (tenant_id, offering_id);
CREATE INDEX ON lms.quiz_attempts (tenant_id, membership_id);

CREATE UNIQUE INDEX ON lms.quiz_attempts (tenant_id, quiz_id, membership_id) WHERE status = 'in_progress';
CREATE TABLE lms.attempt_questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  attempt_id uuid NOT NULL,
  question_version_id uuid NOT NULL,
  position integer NOT NULL CHECK (position > 0),
  max_mark numeric(10,3) NOT NULL CHECK (max_mark > 0),
  question_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(question_snapshot) = 'object'),
  grading_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(grading_snapshot) = 'object'),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, attempt_id) REFERENCES lms.quiz_attempts(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, question_version_id) REFERENCES lms.question_versions(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, attempt_id, position),
  UNIQUE (tenant_id, attempt_id, id)
);

CREATE INDEX ON lms.attempt_questions (tenant_id, attempt_id);
CREATE INDEX ON lms.attempt_questions (tenant_id, question_version_id);

CREATE TABLE lms.quiz_answers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  attempt_id uuid NOT NULL,
  attempt_question_id uuid NOT NULL,
  answer jsonb,
  score numeric(10,3) CHECK (score >= 0),
  feedback text,
  revision integer NOT NULL DEFAULT 1 CHECK (revision > 0),
  saved_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, attempt_id) REFERENCES lms.quiz_attempts(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, attempt_question_id) REFERENCES lms.attempt_questions(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, attempt_question_id),
  FOREIGN KEY (tenant_id, attempt_id, attempt_question_id) REFERENCES lms.attempt_questions(tenant_id, attempt_id, id)
);

CREATE INDEX ON lms.quiz_answers (tenant_id, attempt_id);
CREATE INDEX ON lms.quiz_answers (tenant_id, attempt_question_id);

CREATE TABLE lms.quiz_attempt_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  attempt_id uuid NOT NULL,
  event_type text NOT NULL CHECK (length(btrim(event_type)) > 0),
  payload jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(payload) = 'object'),
  occurred_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, attempt_id) REFERENCES lms.quiz_attempts(tenant_id, id) ON DELETE RESTRICT
);

CREATE INDEX ON lms.quiz_attempt_events (tenant_id, attempt_id);

CREATE TABLE lms.assessment_accommodations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  activity_id uuid NOT NULL,
  membership_id uuid NOT NULL,
  extra_time_seconds integer NOT NULL DEFAULT 0 CHECK (extra_time_seconds >= 0),
  extra_attempts integer NOT NULL DEFAULT 0 CHECK (extra_attempts >= 0),
  deadline_override timestamptz,
  reason text NOT NULL CHECK (length(btrim(reason)) > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, activity_id) REFERENCES lms.activities(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, membership_id) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, activity_id, membership_id)
);

CREATE INDEX ON lms.assessment_accommodations (tenant_id, activity_id);
CREATE INDEX ON lms.assessment_accommodations (tenant_id, membership_id);

CREATE TABLE lms.rubrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  name text NOT NULL CHECK (length(btrim(name)) > 0),
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, created_by) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT
);

CREATE INDEX ON lms.rubrics (tenant_id, created_by);

CREATE TABLE lms.rubric_criteria (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  rubric_id uuid NOT NULL,
  title text NOT NULL CHECK (length(btrim(title)) > 0),
  description text,
  max_score numeric(10,3) NOT NULL CHECK (max_score > 0),
  sort_order integer NOT NULL CHECK (sort_order >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, rubric_id) REFERENCES lms.rubrics(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, rubric_id, sort_order)
);

CREATE INDEX ON lms.rubric_criteria (tenant_id, rubric_id);

CREATE TABLE lms.assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  activity_id uuid NOT NULL,
  offering_id uuid NOT NULL,
  rubric_id uuid,
  instructions text,
  due_at timestamptz,
  cutoff_at timestamptz,
  max_score numeric(10,3) NOT NULL DEFAULT 100 CHECK (max_score > 0),
  max_submissions integer NOT NULL DEFAULT 1 CHECK (max_submissions > 0),
  max_file_bytes bigint NOT NULL DEFAULT 52428800 CHECK (max_file_bytes > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, activity_id) REFERENCES lms.activities(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, offering_id) REFERENCES lms.course_offerings(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, rubric_id) REFERENCES lms.rubrics(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, activity_id),
  UNIQUE (tenant_id, offering_id, id),
  FOREIGN KEY (tenant_id, offering_id, activity_id) REFERENCES lms.activities(tenant_id, offering_id, id),
  CHECK (cutoff_at IS NULL OR due_at IS NULL OR cutoff_at >= due_at)
);

CREATE INDEX ON lms.assignments (tenant_id, activity_id);
CREATE INDEX ON lms.assignments (tenant_id, offering_id);
CREATE INDEX ON lms.assignments (tenant_id, rubric_id);

CREATE TABLE lms.submissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  assignment_id uuid NOT NULL,
  offering_id uuid NOT NULL,
  membership_id uuid NOT NULL,
  submission_number integer NOT NULL CHECK (submission_number > 0),
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','submitted','returned','graded')),
  body text,
  submitted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, assignment_id) REFERENCES lms.assignments(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, offering_id) REFERENCES lms.course_offerings(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, membership_id) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, assignment_id, membership_id, submission_number),
  FOREIGN KEY (tenant_id, offering_id, assignment_id) REFERENCES lms.assignments(tenant_id, offering_id, id),
  FOREIGN KEY (tenant_id, offering_id, membership_id) REFERENCES lms.enrollments(tenant_id, offering_id, membership_id),
  CHECK (status = 'draft' OR submitted_at IS NOT NULL)
);

CREATE INDEX ON lms.submissions (tenant_id, assignment_id);
CREATE INDEX ON lms.submissions (tenant_id, offering_id);
CREATE INDEX ON lms.submissions (tenant_id, membership_id);

CREATE TABLE lms.submission_files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  submission_id uuid NOT NULL,
  file_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, submission_id) REFERENCES lms.submissions(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, file_id) REFERENCES lms.files(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, submission_id, file_id)
);

CREATE INDEX ON lms.submission_files (tenant_id, submission_id);
CREATE INDEX ON lms.submission_files (tenant_id, file_id);

CREATE TABLE lms.grade_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  offering_id uuid NOT NULL,
  activity_id uuid,
  title text NOT NULL CHECK (length(btrim(title)) > 0),
  max_score numeric(10,3) NOT NULL CHECK (max_score > 0),
  weight numeric(10,4) NOT NULL DEFAULT 1 CHECK (weight >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, offering_id) REFERENCES lms.course_offerings(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, activity_id) REFERENCES lms.activities(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, activity_id),
  UNIQUE (tenant_id, offering_id, id),
  FOREIGN KEY (tenant_id, offering_id, activity_id) REFERENCES lms.activities(tenant_id, offering_id, id)
);

CREATE INDEX ON lms.grade_items (tenant_id, offering_id);
CREATE INDEX ON lms.grade_items (tenant_id, activity_id);

CREATE TABLE lms.grades (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  grade_item_id uuid NOT NULL,
  offering_id uuid NOT NULL,
  membership_id uuid NOT NULL,
  score numeric(10,3) CHECK (score >= 0),
  feedback text,
  graded_by uuid,
  published_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, grade_item_id) REFERENCES lms.grade_items(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, offering_id) REFERENCES lms.course_offerings(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, membership_id) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, graded_by) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, grade_item_id, membership_id),
  FOREIGN KEY (tenant_id, offering_id, grade_item_id) REFERENCES lms.grade_items(tenant_id, offering_id, id),
  FOREIGN KEY (tenant_id, offering_id, membership_id) REFERENCES lms.enrollments(tenant_id, offering_id, membership_id)
);

CREATE INDEX ON lms.grades (tenant_id, grade_item_id);
CREATE INDEX ON lms.grades (tenant_id, offering_id);
CREATE INDEX ON lms.grades (tenant_id, membership_id);
CREATE INDEX ON lms.grades (tenant_id, graded_by);

CREATE TABLE lms.grade_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  grade_id uuid NOT NULL,
  previous_score numeric(10,3),
  new_score numeric(10,3),
  changed_by uuid,
  reason text NOT NULL CHECK (length(btrim(reason)) > 0),
  changed_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, grade_id) REFERENCES lms.grades(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, changed_by) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT
);

CREATE INDEX ON lms.grade_history (tenant_id, grade_id);
CREATE INDEX ON lms.grade_history (tenant_id, changed_by);

CREATE TABLE lms.rubric_scores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES platform.tenants(id) ON DELETE RESTRICT,
  submission_id uuid NOT NULL,
  criterion_id uuid NOT NULL,
  score numeric(10,3) NOT NULL CHECK (score >= 0),
  graded_by uuid NOT NULL,
  feedback text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, id),
  FOREIGN KEY (tenant_id, submission_id) REFERENCES lms.submissions(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, criterion_id) REFERENCES lms.rubric_criteria(tenant_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (tenant_id, graded_by) REFERENCES lms.memberships(tenant_id, id) ON DELETE RESTRICT,
  UNIQUE (tenant_id, submission_id, criterion_id)
);

CREATE INDEX ON lms.rubric_scores (tenant_id, submission_id);
CREATE INDEX ON lms.rubric_scores (tenant_id, criterion_id);
CREATE INDEX ON lms.rubric_scores (tenant_id, graded_by);

