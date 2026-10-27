-- Reference definitions only: no fake students, institutions, or credentials.
INSERT INTO platform.activity_types(code, contract_version) VALUES
  ('page',1), ('file',1), ('url',1), ('video',1), ('quiz',1), ('assignment',1), ('forum',1);
INSERT INTO platform.capabilities(code, description) VALUES
  ('tenant.manage', 'Manage institution configuration'),
  ('users.manage', 'Manage institution memberships'),
  ('roles.manage', 'Manage scoped role assignments'),
  ('academic.manage', 'Manage departments, terms and programs'),
  ('courses.create', 'Create course definitions'),
  ('courses.manage', 'Manage assigned course offerings'),
  ('content.manage', 'Author learning activities'),
  ('enrollments.manage', 'Manage enrollment separately from roles'),
  ('files.upload', 'Upload authorized learning files'),
  ('files.read', 'Read authorized files'),
  ('quizzes.manage', 'Manage quizzes and question versions'),
  ('quizzes.attempt', 'Attempt available quizzes'),
  ('assignments.manage', 'Manage assignments and rubrics'),
  ('assignments.submit', 'Submit eligible assignments'),
  ('grades.manage', 'Grade assigned students'),
  ('grades.read_own', 'Read own published grades'),
  ('reports.read', 'Read authorized reports'),
  ('communication.manage', 'Manage announcements and discussions'),
  ('integrations.manage', 'Manage institution integrations'),
  ('billing.manage', 'Manage institution billing');
