-- Immutable question versions intentionally have no runtime UPDATE privilege.
-- Serialize definition/reference operations with an advisory lock instead of FOR UPDATE.
CREATE OR REPLACE FUNCTION lms.validate_question_choice() RETURNS trigger LANGUAGE plpgsql
SET search_path = pg_catalog AS $$
BEGIN
  PERFORM pg_advisory_xact_lock(hashtextextended(NEW.tenant_id::text || NEW.question_version_id::text, 0));
  IF EXISTS (SELECT 1 FROM lms.quiz_questions WHERE tenant_id = NEW.tenant_id AND question_version_id = NEW.question_version_id)
    OR EXISTS (SELECT 1 FROM lms.attempt_questions WHERE tenant_id = NEW.tenant_id AND question_version_id = NEW.question_version_id) THEN
    RAISE EXCEPTION 'Referenced question version cannot gain choices; create a new version' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END $$;

CREATE FUNCTION lms.lock_question_version_reference() RETURNS trigger LANGUAGE plpgsql
SET search_path = pg_catalog AS $$
BEGIN
  PERFORM pg_advisory_xact_lock(hashtextextended(NEW.tenant_id::text || NEW.question_version_id::text, 0));
  RETURN NEW;
END $$;
CREATE TRIGGER lock_question_version_reference BEFORE INSERT OR UPDATE ON lms.quiz_questions
FOR EACH ROW EXECUTE FUNCTION lms.lock_question_version_reference();
CREATE TRIGGER lock_question_version_reference BEFORE INSERT ON lms.attempt_questions
FOR EACH ROW EXECUTE FUNCTION lms.lock_question_version_reference();
