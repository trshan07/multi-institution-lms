-- All fixtures and changes roll back. Execute as the migration administrator.
BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '30s';

DO $$ DECLARE a uuid := gen_random_uuid(); b uuid := gen_random_uuid(); u uuid; m uuid; ca uuid; cb uuid;
BEGIN
  INSERT INTO platform.tenants(id,slug,name,status) VALUES
    (a,'test-' || a::text,'Isolation A','active'), (b,'test-' || b::text,'Isolation B','active');
  INSERT INTO platform.users(email,display_name) VALUES ('test@example.invalid','Test learner') RETURNING id INTO u;
  INSERT INTO lms.memberships(tenant_id,user_id,status) VALUES(a,u,'active') RETURNING id INTO m;
  INSERT INTO lms.courses(tenant_id,code,title) VALUES(a,'TEST-A','Course A') RETURNING id INTO ca;
  INSERT INTO lms.courses(tenant_id,code,title) VALUES(b,'TEST-B','Course B') RETURNING id INTO cb;
  PERFORM set_config('test.a',a::text,true), set_config('test.b',b::text,true),
    set_config('test.member',m::text,true), set_config('test.ca',ca::text,true), set_config('test.cb',cb::text,true);
  IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='lms' AND c.relkind='r' AND (NOT c.relrowsecurity OR NOT c.relforcerowsecurity)) THEN
    RAISE EXCEPTION 'A tenant table is missing forced RLS';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='lms_runtime' AND (rolsuper OR rolbypassrls OR rolcanlogin)) THEN
    RAISE EXCEPTION 'Unsafe runtime role';
  END IF;
END $$;

SET LOCAL ROLE lms_runtime;
SELECT set_config('app.tenant_id','',true);
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM lms.courses) THEN RAISE EXCEPTION 'Missing context leaked records'; END IF;
  BEGIN
    INSERT INTO lms.courses(tenant_id,code,title) VALUES(current_setting('test.a')::uuid,'NO-CONTEXT','Denied');
    RAISE EXCEPTION 'Missing context allowed insert';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM count(*) FROM platform.users; RAISE EXCEPTION 'Global identity exposed';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  IF has_table_privilege(current_user,'lms.courses','TRUNCATE') THEN RAISE EXCEPTION 'Runtime has TRUNCATE'; END IF;
END $$;

SELECT set_config('app.tenant_id',current_setting('test.a'),true);
DO $$ DECLARE a uuid := current_setting('test.a')::uuid; b uuid := current_setting('test.b')::uuid; n integer;
BEGIN
  IF (SELECT count(*) FROM lms.courses) <> 1 THEN RAISE EXCEPTION 'Tenant filtering failed'; END IF;
  UPDATE lms.courses SET title='Changed' WHERE id=current_setting('test.cb')::uuid;
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 0 THEN RAISE EXCEPTION 'Cross-tenant update allowed'; END IF;
  DELETE FROM lms.courses WHERE id=current_setting('test.cb')::uuid;
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 0 THEN RAISE EXCEPTION 'Cross-tenant delete allowed'; END IF;
  BEGIN INSERT INTO lms.courses(tenant_id,code,title) VALUES(b,'LEAK','Denied');
    RAISE EXCEPTION 'Cross-tenant insert allowed'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN UPDATE lms.courses SET tenant_id=b WHERE id=current_setting('test.ca')::uuid;
    RAISE EXCEPTION 'Tenant reassignment allowed'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN INSERT INTO lms.course_offerings(tenant_id,course_id,code) VALUES(a,current_setting('test.cb')::uuid,'BAD-FK');
    RAISE EXCEPTION 'Cross-tenant reference allowed'; EXCEPTION WHEN foreign_key_violation THEN NULL; END;
  BEGIN INSERT INTO lms.files(tenant_id,bucket,object_key,filename,content_type,size_bytes)
      VALUES(a,'test',b::text || '/file','file','text/plain',1);
    RAISE EXCEPTION 'Foreign tenant object key allowed'; EXCEPTION WHEN check_violation THEN NULL; END;
END $$;

-- Build a real relational slice, then exercise integrity and grading protections.
DO $$ DECLARE a uuid := current_setting('test.a')::uuid; m uuid := current_setting('test.member')::uuid;
  offering uuid; other_offering uuid; method uuid; section uuid; activity uuid; quiz uuid;
  bank uuid; question uuid; version_id uuid; attempt uuid; aq uuid; answer_id uuid; item uuid; grade uuid; root_context uuid;
BEGIN
  INSERT INTO lms.course_offerings(tenant_id,course_id,code) VALUES(a,current_setting('test.ca')::uuid,'TEST-OFFERING') RETURNING id INTO offering;
  INSERT INTO lms.course_offerings(tenant_id,course_id,code) VALUES(a,current_setting('test.ca')::uuid,'TEST-OTHER') RETURNING id INTO other_offering;
  INSERT INTO lms.enrollment_methods(tenant_id,offering_id,strategy) VALUES(a,offering,'manual') RETURNING id INTO method;
  INSERT INTO lms.enrollments(tenant_id,offering_id,membership_id,method_id) VALUES(a,offering,m,method);
  BEGIN INSERT INTO lms.enrollments(tenant_id,offering_id,membership_id,method_id) VALUES(a,offering,m,method);
    RAISE EXCEPTION 'Duplicate enrollment accepted'; EXCEPTION WHEN unique_violation THEN NULL; END;
  BEGIN INSERT INTO lms.enrollments(tenant_id,offering_id,membership_id,method_id) VALUES(a,other_offering,m,method);
    RAISE EXCEPTION 'Method from other offering accepted'; EXCEPTION WHEN foreign_key_violation THEN NULL; END;
  INSERT INTO lms.sections(tenant_id,offering_id,title) VALUES(a,offering,'Section') RETURNING id INTO section;
  INSERT INTO lms.activities(tenant_id,offering_id,section_id,activity_type,title)
    VALUES(a,offering,section,'quiz','Quiz') RETURNING id INTO activity;
  BEGIN INSERT INTO lms.activities(tenant_id,offering_id,section_id,activity_type,title,sort_order)
      VALUES(a,other_offering,section,'quiz','Bad section',1);
    RAISE EXCEPTION 'Activity linked to another offering section'; EXCEPTION WHEN foreign_key_violation THEN NULL; END;
  INSERT INTO lms.quizzes(tenant_id,activity_id,offering_id) VALUES(a,activity,offering) RETURNING id INTO quiz;
  INSERT INTO lms.question_banks(tenant_id,name) VALUES(a,'Test bank') RETURNING id INTO bank;
  INSERT INTO lms.questions(tenant_id,bank_id,name) VALUES(a,bank,'Test question') RETURNING id INTO question;
  INSERT INTO lms.question_versions(tenant_id,question_id,version,question_type,prompt,max_mark)
    VALUES(a,question,1,'single_choice','Choose one',10) RETURNING id INTO version_id;
  INSERT INTO lms.question_choices(tenant_id,question_version_id,choice_key,body,sort_order) VALUES(a,version_id,'a','First',0);
  INSERT INTO lms.quiz_questions(tenant_id,quiz_id,question_version_id,position,max_mark) VALUES(a,quiz,version_id,1,10);
  BEGIN INSERT INTO lms.question_choices(tenant_id,question_version_id,choice_key,body,sort_order) VALUES(a,version_id,'b','Too late',1);
    RAISE EXCEPTION 'Referenced version was modified'; EXCEPTION WHEN check_violation THEN NULL; END;
  BEGIN UPDATE lms.question_versions SET prompt='Changed' WHERE id=version_id;
    RAISE EXCEPTION 'Question version update accepted'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  INSERT INTO lms.quiz_attempts(tenant_id,quiz_id,offering_id,membership_id,attempt_number)
    VALUES(a,quiz,offering,m,1) RETURNING id INTO attempt;
  INSERT INTO lms.attempt_questions(tenant_id,attempt_id,question_version_id,position,max_mark,question_snapshot)
    VALUES(a,attempt,version_id,1,10,'{"prompt":"Choose one"}') RETURNING id INTO aq;
  INSERT INTO lms.quiz_answers(tenant_id,attempt_id,attempt_question_id,answer)
    VALUES(a,attempt,aq,'{"choice":"a"}') RETURNING id INTO answer_id;
  UPDATE lms.quiz_attempts SET status='submitted',submitted_at=now() WHERE id=attempt;
  BEGIN UPDATE lms.quiz_answers SET answer='{"choice":"b"}' WHERE id=answer_id;
    RAISE EXCEPTION 'Submitted answer could change'; EXCEPTION WHEN check_violation THEN NULL; END;
  BEGIN UPDATE lms.quiz_attempts SET status='in_progress' WHERE id=attempt;
    RAISE EXCEPTION 'Submitted attempt reopened'; EXCEPTION WHEN check_violation THEN NULL; END;
  BEGIN UPDATE lms.quiz_answers SET score=11 WHERE id=answer_id;
    RAISE EXCEPTION 'Excess answer mark accepted'; EXCEPTION WHEN check_violation THEN NULL; END;
  UPDATE lms.quiz_answers SET score=8 WHERE id=answer_id;
  INSERT INTO lms.grade_items(tenant_id,offering_id,activity_id,title,max_score)
    VALUES(a,offering,activity,'Test grade',10) RETURNING id INTO item;
  INSERT INTO lms.grades(tenant_id,grade_item_id,offering_id,membership_id,score,graded_by)
    VALUES(a,item,offering,m,8,m) RETURNING id INTO grade;
  UPDATE lms.grades SET score=9 WHERE id=grade;
  IF (SELECT count(*) FROM lms.grade_history WHERE grade_id=grade) <> 2 THEN RAISE EXCEPTION 'Grade history missing'; END IF;
  BEGIN UPDATE lms.grades SET score=11 WHERE id=grade;
    RAISE EXCEPTION 'Excess grade accepted'; EXCEPTION WHEN check_violation THEN NULL; END;
  BEGIN DELETE FROM lms.grade_history WHERE grade_id=grade;
    RAISE EXCEPTION 'History could be deleted'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  INSERT INTO lms.contexts(tenant_id,kind) VALUES(a,'institution') RETURNING id INTO root_context;
  BEGIN INSERT INTO lms.contexts(tenant_id,kind,parent_id,activity_id) VALUES(a,'activity',root_context,activity);
    RAISE EXCEPTION 'Invalid permission context hierarchy accepted'; EXCEPTION WHEN check_violation THEN NULL; END;
END $$;

SELECT set_config('app.tenant_id',current_setting('test.b'),true);
DO $$ BEGIN
  IF (SELECT count(*) FROM lms.courses) <> 1 OR EXISTS (SELECT 1 FROM lms.enrollments) OR EXISTS (SELECT 1 FROM lms.grades) THEN
    RAISE EXCEPTION 'Tenant switch leaked academic records'; END IF;
END $$;
RESET ROLE;
UPDATE platform.tenants SET status='suspended' WHERE id=current_setting('test.a')::uuid;
SET LOCAL ROLE lms_runtime;
SELECT set_config('app.tenant_id',current_setting('test.a'),true);
DO $$ BEGIN IF EXISTS (SELECT 1 FROM lms.courses) THEN RAISE EXCEPTION 'Suspended tenant retained access'; END IF; END $$;
ROLLBACK;

-- Verify transaction-local context did not survive rollback on the same connection.
BEGIN;
SET LOCAL ROLE lms_runtime;
DO $$ BEGIN
  IF lms.current_tenant_id() IS NOT NULL THEN RAISE EXCEPTION 'Tenant context leaked across transactions'; END IF;
END $$;
ROLLBACK;
\echo PASS: RLS coverage, missing context, tenant isolation, scoped foreign keys, enrollment uniqueness, assessment integrity, grade history, suspension, transaction cleanup.
