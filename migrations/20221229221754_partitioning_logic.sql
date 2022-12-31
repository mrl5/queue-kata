-- partitioning logic
-- * https://www.cybertec-postgresql.com/en/partition-management-do-you-really-need-a-tool-for-that/
-- * https://youtu.be/7VCSmuHMpfk?t=3168 - Webinar: PostgreSQL Partitioning by Simon Riggs
-- * https://www.postgresql.org/docs/current/sql-altertable.html#SQL-ALTERTABLE-DETACH-PARTITION

-- disclaimer: `DEFAULT` partition not defined on purpose in order to:
-- * avoid locking when `ATTACH PARTITION`
-- * be able to use `DETACH PARTITION CONCURRENTLY`

-- DRY for creation
CREATE FUNCTION subpartitions.get_ddl_new_partition(
    partitioned_table text,
    range_start_tz timestamptz,
    range_interval interval
)
RETURNS text
LANGUAGE sql as $fn$
    SELECT format(
        $$CREATE TABLE IF NOT EXISTS subpartitions.%s_y%sm%s PARTITION OF core.%s
            FOR VALUES FROM ('%s') TO ('%s')$$,
        partitioned_table,
        extract(year from range_start_tz),
        lpad((extract(month from range_start_tz))::text, 2, '0'),
        partitioned_table,
        range_start_tz,
        range_start_tz + range_interval::interval
    ) AS ddl_to_exec;
$fn$;

-- DRY for info
CREATE FUNCTION subpartitions.get_dml_partitions(partitioned_table text)
RETURNS text
LANGUAGE sql as $fn$
    SELECT $x$WITH table_partitions AS (
        SELECT
            format('%I.%I', n.nspname, c.relname) as part_name,
            pg_catalog.pg_get_expr(c.relpartbound, c.oid) as part_expr
        FROM pg_class p
        JOIN pg_inherits i ON i.inhparent = p.oid
        JOIN pg_class c ON c.oid = i.inhrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE p.relname = partitioned_table::text AND p.relkind = 'p'
    )

    SELECT part_name text, part_expr, (
        (regexp_match(part_expr, $$ TO \('(.*)'\)$$))[1]
    )::timestamptz as last_part_end
    FROM table_partitions
    $x$ AS sql_fragment;
$fn$;

-- DDLs
CREATE PROCEDURE subpartitions.create_partition_for_now(partitioned_table text)
LANGUAGE plpgsql
AS $$
DECLARE this_month timestamptz;
DECLARE range_interval interval := '1month'::interval;
DECLARE ddl_to_execute text;
BEGIN
    SELECT format(
        '%s-%s-01',
        extract(year FROM now),
        lpad((extract(month FROM now))::text, 2, '0')
    )::timestamptz INTO this_month FROM now();
    SELECT subpartitions.get_ddl_new_partition(
        partitioned_table,
        this_month,
        range_interval
    ) INTO ddl_to_execute;
    EXECUTE ddl_to_execute;
END
$$;

CREATE PROCEDURE subpartitions.create_all_partitions_for_now()
LANGUAGE plpgsql
AS $$
DECLARE tables text[] := array ['task', 'job'];
DECLARE t text;
BEGIN

    FOREACH t IN array tables LOOP
        CALL subpartitions.create_partition_for_now(t);
    END LOOP;

END
$$;
