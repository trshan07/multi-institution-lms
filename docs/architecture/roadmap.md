# Implementation roadmap

1. **Project and design starter (this milestone):** runnable web/API/worker packages, responsive institute workspace, shared types, local container configuration, and reserved domain folders.
2. **Tenant foundation:** migrations, verified domain resolver, OIDC login, memberships, contextual roles, PostgreSQL RLS, audit records. Acceptance: two institutions cannot read or mutate each other's data through any exposed path; missing tenant context fails closed.
3. **Course and enrollment slice:** definitions, offerings, course roles, students, manual enrollment, idempotency, pagination, private uploads and authorized downloads. Replace demo data with typed API calls and persistent integration tests.
4. **Teaching:** sections, reusable learning activities, assignments, question banks with versions, attempts with durable answers, grading, completion rules.
5. **Operations:** outbox and jobs, branding/domain verification, billing, observability, accessibility review, backup restoration, security and load testing, pilot release.
6. **Expansion:** enterprise database routing, integrations, SCORM/LTI, mobile Flutter app and offline workflows.

Each milestone needs its own acceptance checks. Folder creation and mock UI do not complete the production platform.
