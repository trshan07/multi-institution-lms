CREATE FUNCTION lms.touch_updated_at() RETURNS trigger LANGUAGE plpgsql
SET search_path = pg_catalog AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END $$;

DO $$ DECLARE t record;
BEGIN
  FOR t IN SELECT schemaname, tablename FROM pg_tables WHERE schemaname IN ('platform','lms') LOOP
    EXECUTE format('CREATE TRIGGER touch_updated_at BEFORE UPDATE ON %I.%I
                    FOR EACH ROW EXECUTE FUNCTION lms.touch_updated_at()', t.schemaname, t.tablename);
  END LOOP;
END $$;

CREATE FUNCTION lms.reject_mutation() RETURNS trigger LANGUAGE plpgsql
SET search_path = pg_catalog AS $$
BEGIN RAISE EXCEPTION '% is append-only; create a new version or event', TG_TABLE_NAME USING ERRCODE = '23514'; END $$;

DO $$ DECLARE table_name text;
BEGIN
  FOREACH table_name IN ARRAY ARRAY['audit_logs','grade_history','quiz_attempt_events','learning_events',
    'processed_events','question_versions','question_choices','attempt_questions'] LOOP
    EXECUTE format('CREATE TRIGGER immutable_record BEFORE UPDATE OR DELETE ON lms.%I
                    FOR EACH ROW EXECUTE FUNCTION lms.reject_mutation()', table_name);
  END LOOP;
END $$;
CREATE TRIGGER immutable_record BEFORE UPDATE OR DELETE ON platform.audit_logs
FOR EACH ROW EXECUTE FUNCTION lms.reject_mutation();

CREATE FUNCTION lms.validate_answer() RETURNS trigger LANGUAGE plpgsql
SET search_path = pg_catalog AS $$
DECLARE attempt_status text; question_limit numeric; tenant uuid; attempt uuid;
BEGIN
  IF TG_OP = 'DELETE' THEN tenant := OLD.tenant_id; attempt := OLD.attempt_id;
  ELSE tenant := NEW.tenant_id; attempt := NEW.attempt_id; END IF;
  SELECT status INTO attempt_status FROM lms.quiz_attempts
    WHERE tenant_id = tenant AND id = attempt FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Attempt is not accessible' USING ERRCODE = '23503'; END IF;
  IF TG_OP = 'DELETE' THEN
    IF attempt_status <> 'in_progress' THEN RAISE EXCEPTION 'Submitted answers are immutable' USING ERRCODE = '23514'; END IF;
    RETURN OLD;
  END IF;
  IF TG_OP = 'UPDATE' AND (NEW.attempt_id <> OLD.attempt_id OR NEW.attempt_question_id <> OLD.attempt_question_id OR NEW.tenant_id <> OLD.tenant_id) THEN
    RAISE EXCEPTION 'Answer identity cannot change' USING ERRCODE = '23514';
  END IF;
  IF attempt_status <> 'in_progress' AND (TG_OP = 'INSERT' OR NEW.answer IS DISTINCT FROM OLD.answer) THEN
    RAISE EXCEPTION 'Submitted answers are immutable' USING ERRCODE = '23514';
  END IF;
  SELECT max_mark INTO question_limit FROM lms.attempt_questions
    WHERE tenant_id = NEW.tenant_id AND id = NEW.attempt_question_id;
  IF NEW.score > question_limit THEN RAISE EXCEPTION 'Answer score exceeds maximum' USING ERRCODE = '23514'; END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER validate_answer BEFORE INSERT OR UPDATE OR DELETE ON lms.quiz_answers
FOR EACH ROW EXECUTE FUNCTION lms.validate_answer();

CREATE FUNCTION lms.validate_grade() RETURNS trigger LANGUAGE plpgsql
SET search_path = pg_catalog AS $$
DECLARE maximum numeric;
BEGIN
  SELECT max_score INTO maximum FROM lms.grade_items WHERE tenant_id = NEW.tenant_id AND id = NEW.grade_item_id FOR SHARE;
  IF NEW.score > maximum THEN RAISE EXCEPTION 'Grade exceeds maximum' USING ERRCODE = '23514'; END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER validate_grade BEFORE INSERT OR UPDATE ON lms.grades
FOR EACH ROW EXECUTE FUNCTION lms.validate_grade();

CREATE FUNCTION lms.record_grade_history() RETURNS trigger LANGUAGE plpgsql
SET search_path = pg_catalog AS $$
BEGIN
  IF TG_OP = 'INSERT' OR NEW.score IS DISTINCT FROM OLD.score OR NEW.feedback IS DISTINCT FROM OLD.feedback THEN
    INSERT INTO lms.grade_history(tenant_id, grade_id, previous_score, new_score, changed_by, reason)
    VALUES (NEW.tenant_id, NEW.id, CASE WHEN TG_OP = 'INSERT' THEN NULL ELSE OLD.score END,
      NEW.score, NEW.graded_by, coalesce(nullif(current_setting('app.audit_reason', true), ''), 'Grade recorded'));
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER record_grade_history AFTER INSERT OR UPDATE ON lms.grades
FOR EACH ROW EXECUTE FUNCTION lms.record_grade_history();

CREATE FUNCTION lms.validate_rubric_score() RETURNS trigger LANGUAGE plpgsql
SET search_path = pg_catalog AS $$
DECLARE maximum numeric; criterion_rubric uuid; assignment_rubric uuid;
BEGIN
  SELECT max_score, rubric_id INTO maximum, criterion_rubric FROM lms.rubric_criteria
    WHERE tenant_id = NEW.tenant_id AND id = NEW.criterion_id;
  SELECT a.rubric_id INTO assignment_rubric FROM lms.submissions s
    JOIN lms.assignments a ON a.tenant_id = s.tenant_id AND a.id = s.assignment_id
    WHERE s.tenant_id = NEW.tenant_id AND s.id = NEW.submission_id;
  IF criterion_rubric IS DISTINCT FROM assignment_rubric OR NEW.score > maximum THEN
    RAISE EXCEPTION 'Rubric criterion or score does not match assignment' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER validate_rubric_score BEFORE INSERT OR UPDATE ON lms.rubric_scores
FOR EACH ROW EXECUTE FUNCTION lms.validate_rubric_score();

REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA lms FROM PUBLIC;

CREATE FUNCTION lms.validate_attempt_transition() RETURNS trigger LANGUAGE plpgsql
SET search_path = pg_catalog AS $$
BEGIN
  IF NEW.tenant_id <> OLD.tenant_id OR NEW.quiz_id <> OLD.quiz_id OR NEW.membership_id <> OLD.membership_id
    OR NEW.offering_id <> OLD.offering_id OR NEW.attempt_number <> OLD.attempt_number THEN
    RAISE EXCEPTION 'Attempt identity cannot change' USING ERRCODE = '23514';
  END IF;
  IF NEW.status <> OLD.status AND NOT (
    (OLD.status = 'in_progress' AND NEW.status IN ('submitted','abandoned')) OR
    (OLD.status = 'submitted' AND NEW.status = 'graded')) THEN
    RAISE EXCEPTION 'Invalid attempt state transition' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER validate_attempt_transition BEFORE UPDATE ON lms.quiz_attempts
FOR EACH ROW EXECUTE FUNCTION lms.validate_attempt_transition();

CREATE FUNCTION lms.validate_context() RETURNS trigger LANGUAGE plpgsql
SET search_path = pg_catalog AS $$
DECLARE parent lms.contexts; actual_offering uuid;
BEGIN
  IF NEW.parent_id IS NULL THEN RETURN NEW; END IF;
  SELECT * INTO parent FROM lms.contexts WHERE tenant_id = NEW.tenant_id AND id = NEW.parent_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Missing context parent' USING ERRCODE = '23503'; END IF;
  IF NOT ((NEW.kind IN ('unit','offering') AND parent.kind IN ('institution','unit')) OR
          (NEW.kind = 'activity' AND parent.kind = 'offering')) THEN
    RAISE EXCEPTION 'Invalid context hierarchy' USING ERRCODE = '23514';
  END IF;
  IF NEW.kind = 'activity' THEN
    SELECT offering_id INTO actual_offering FROM lms.activities WHERE tenant_id = NEW.tenant_id AND id = NEW.activity_id;
    IF actual_offering IS DISTINCT FROM parent.offering_id THEN
      RAISE EXCEPTION 'Activity context belongs to another offering' USING ERRCODE = '23514';
    END IF;
  END IF;
  IF EXISTS (WITH RECURSIVE ancestors AS (
    SELECT id, parent_id FROM lms.contexts WHERE tenant_id = NEW.tenant_id AND id = NEW.parent_id
    UNION
    SELECT c.id, c.parent_id FROM lms.contexts c JOIN ancestors a ON c.id = a.parent_id WHERE c.tenant_id = NEW.tenant_id
  ) SELECT 1 FROM ancestors WHERE id = NEW.id) THEN
    RAISE EXCEPTION 'Context cycle is not allowed' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER validate_context BEFORE INSERT OR UPDATE ON lms.contexts
FOR EACH ROW EXECUTE FUNCTION lms.validate_context();

CREATE FUNCTION lms.validate_attempt_question() RETURNS trigger LANGUAGE plpgsql
SET search_path = pg_catalog AS $$
DECLARE state text;
BEGIN
  SELECT status INTO state FROM lms.quiz_attempts WHERE tenant_id = NEW.tenant_id AND id = NEW.attempt_id FOR UPDATE;
  IF state IS DISTINCT FROM 'in_progress' THEN
    RAISE EXCEPTION 'Cannot add questions to a closed attempt' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER validate_attempt_question BEFORE INSERT ON lms.attempt_questions
FOR EACH ROW EXECUTE FUNCTION lms.validate_attempt_question();

CREATE FUNCTION lms.validate_question_choice() RETURNS trigger LANGUAGE plpgsql
SET search_path = pg_catalog AS $$
BEGIN
  PERFORM 1 FROM lms.question_versions WHERE tenant_id = NEW.tenant_id AND id = NEW.question_version_id FOR UPDATE;
  IF EXISTS (SELECT 1 FROM lms.quiz_questions WHERE tenant_id = NEW.tenant_id AND question_version_id = NEW.question_version_id)
    OR EXISTS (SELECT 1 FROM lms.attempt_questions WHERE tenant_id = NEW.tenant_id AND question_version_id = NEW.question_version_id) THEN
    RAISE EXCEPTION 'Referenced question version cannot gain choices; create a new version' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER validate_question_choice BEFORE INSERT ON lms.question_choices
FOR EACH ROW EXECUTE FUNCTION lms.validate_question_choice();
