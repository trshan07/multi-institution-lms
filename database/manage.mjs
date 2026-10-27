import { loadEnvFile } from 'node:process';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { resolve, dirname } from 'node:path';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
if (existsSync(resolve(root, '.env'))) loadEnvFile(resolve(root, '.env'));
const connection = process.env.MIGRATION_DATABASE_URL || process.env.DATABASE_URL;
if (!connection) throw new Error('Set MIGRATION_DATABASE_URL or DATABASE_URL.');
const url = new URL(connection);
const psql = process.env.PSQL_PATH || (process.platform === 'win32' && existsSync('C:/Program Files/PostgreSQL/18/bin/psql.exe') ? 'C:/Program Files/PostgreSQL/18/bin/psql.exe' : 'psql');
const command = process.argv[2] || 'inspect';
let sql;
if (command === 'inspect') {
  sql = `SELECT current_database(), current_user, current_setting('server_version') AS version;
SELECT schemaname, count(*) AS tables FROM pg_tables WHERE schemaname NOT IN ('pg_catalog','information_schema') GROUP BY schemaname;
SELECT rolname, rolsuper, rolbypassrls, rolcanlogin FROM pg_roles WHERE rolname = 'lms_runtime';`;
} else if (command === 'migrate' || command === 'validate') {
  sql = `BEGIN; SET LOCAL lock_timeout = '15s'; SELECT pg_advisory_xact_lock(637294801);
CREATE SCHEMA IF NOT EXISTS lms_meta;
REVOKE ALL ON SCHEMA lms_meta FROM PUBLIC;
CREATE TABLE IF NOT EXISTS lms_meta.schema_migrations (name text PRIMARY KEY, checksum text NOT NULL, applied_at timestamptz NOT NULL DEFAULT now());\n`;
  for (const name of readdirSync(resolve(root, 'database/migrations')).filter(n => /^\d{3}_[a-z0-9_]+\.sql$/.test(n)).sort()) {
    const source = readFileSync(resolve(root, 'database/migrations', name), 'utf8');
    const checksum = createHash('sha256').update(source).digest('hex');
    sql += String.raw`DO $check$ BEGIN IF EXISTS (SELECT 1 FROM lms_meta.schema_migrations WHERE name = '${name}' AND checksum <> '${checksum}') THEN RAISE EXCEPTION 'Applied migration checksum mismatch: ${name}'; END IF; END $check$;
SELECT EXISTS (SELECT 1 FROM lms_meta.schema_migrations WHERE name = '${name}') AS already_applied \gset
\if :already_applied
\echo Already applied: ${name}
\else
\echo Applying: ${name}
${source}
INSERT INTO lms_meta.schema_migrations(name, checksum) VALUES ('${name}', '${checksum}');
\endif
`;
  }
  sql += command === 'validate' ? 'ROLLBACK;' : 'COMMIT;';
} else if (command === 'verify') {
  sql = readFileSync(resolve(root, 'database/tests/integrity.sql'), 'utf8');
} else if (command === 'inventory') {
  sql = `SELECT schemaname, tablename, rowsecurity FROM pg_tables WHERE schemaname IN ('platform','lms') ORDER BY 1,2;
SELECT name, applied_at FROM lms_meta.schema_migrations ORDER BY name;`;
} else { throw new Error('Usage: node database/manage.mjs inspect|validate|migrate|verify|inventory'); }
const result = spawnSync(psql, ['-X', '-w', '-v', 'ON_ERROR_STOP=1', '-h', url.hostname, '-p', url.port || '5432', '-U', decodeURIComponent(url.username), '-d', decodeURIComponent(url.pathname.slice(1))], {
  input: sql, encoding: 'utf8', windowsHide: true, maxBuffer: 10 * 1024 * 1024,
  env: { ...process.env, PGPASSWORD: decodeURIComponent(url.password), PGCONNECT_TIMEOUT: '5', PGCLIENTENCODING: 'UTF8' }
});
if (result.error) throw new Error(`Could not run psql: ${result.error.code}. Set PSQL_PATH if needed.`);
process.stdout.write(result.stdout || '');
process.stderr.write(result.stderr || '');
process.exitCode = result.status ?? 1;
