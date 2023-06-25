-- schemas
-- * https://www.cybertec-postgresql.com/en/partition-management-do-you-really-need-a-tool-for-that/
-- * https://www.crunchydata.com/blog/tentative-smarter-query-optimization-in-postgres-starts-with-pg_stat_statements

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

CREATE SCHEMA internal;

CREATE TABLE internal.tenant (
    name text
        PRIMARY KEY,

    created_at timestamptz
        NOT NULL
        DEFAULT now()
);

CREATE PROCEDURE internal.create_schemas_for_new_tenant(new_tenant text)
LANGUAGE plpgsql
AS $$
BEGIN
    EXECUTE format('CREATE SCHEMA tenant_%s', new_tenant);
    EXECUTE format('CREATE SCHEMA partitions_%s', new_tenant);
END
$$;

INSERT INTO internal.tenant VALUES ('default');

CALL internal.create_schemas_for_new_tenant('default');
