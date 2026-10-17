# db: schema, seed, reset, and tool image

| File | Role |
|---|---|
| `schema.sql` | DDL for `schema_version=001` (repeatable; DROP then CREATE) |
| `seed.sql` | Synthetic customer/account/probe data (no real data or credentials) |
| `reset.sql` | Clear business tables while preserving schema; reset a running course database |
| `Dockerfile` | ESQL tool image (reuses P1's pinned GixSQL commit and two local patches) |

## Build and run

```bash
lab=$(cd curriculum/modules/08-database && pwd)
bash "$lab/scripts/docker-image.sh"       # create/reuse cobol-course-gixsql:m08
```

`Dockerfile` references `gixsql-cursor-null.patch` and `gixsql-closed-cursor.patch`. These patches come from P1 `curriculum/validation/database/`; `scripts/docker-image.sh` copies them into a temporary build context (**without modifying P1 files**). Module 08 COBOL and database experiments run inside this image.

## Manually reset the running course database

```bash
PGHOST=… PGPORT=5432 PGUSER=postgres psql_dsn bash "$lab/scripts/reset.sh" --db
# or explicitly:
psql -v ON_ERROR_STOP=1 -f "$lab/db/schema.sql"
psql -v ON_ERROR_STOP=1 -f "$lab/db/seed.sql"
```

Automated experiments use disposable containers that are destroyed on exit. The reset script in this directory affects only the explicitly specified course database.
