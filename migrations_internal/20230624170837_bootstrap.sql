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

CREATE PROCEDURE internal.create_new_tenant(new_tenant text)
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
        GRANT SELECT, INSERT, UPDATE, DELETE
        ON ALL TABLES IN SCHEMA tenant_%s TO tenant_%s;
    $$, new_tenant, new_tenant);
END
$x$;
