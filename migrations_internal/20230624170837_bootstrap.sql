-- bootstrap
-- * https://www.crunchydata.com/blog/tentative-smarter-query-optimization-in-postgres-starts-with-pg_stat_statements

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

CREATE TABLE internal.tenant (
    name text
        PRIMARY KEY,

    created_at timestamptz
        NOT NULL
        DEFAULT now()
);

CREATE PROCEDURE internal.create_new_tenant(schema_owner text, new_tenant text)
LANGUAGE plpgsql
AS $x$
BEGIN
    EXECUTE format($$
        INSERT INTO internal.tenant (name) VALUES ('%s')
    $$, new_tenant);

    EXECUTE format($$
        CREATE SCHEMA tenant_%s
    $$, new_tenant);

    EXECUTE format($$
        CREATE SCHEMA partitions_%s
    $$, new_tenant);

    EXECUTE format($$
        GRANT USAGE ON SCHEMA tenant_%s TO tenant_%s;
    $$, new_tenant, new_tenant);

    EXECUTE format($$
        ALTER DEFAULT PRIVILEGES FOR USER %s IN SCHEMA tenant_%s
            GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO tenant_%s;
    $$, schema_owner, new_tenant, new_tenant, new_tenant);
END
$x$;
