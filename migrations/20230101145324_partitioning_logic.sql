-- (vol.2) partitioning logic

CREATE PROCEDURE subpartitions.create_partition_for_next_month(partitioned_table text)
LANGUAGE plpgsql
AS $$
DECLARE next_month timestamptz;
DECLARE range_interval interval := '1month'::interval;
DECLARE ddl_to_execute text;
BEGIN
    SELECT format(
        '%s-%s-01',
        extract(year FROM now),
        lpad((extract(month FROM now + '1month'::interval))::text, 2, '0')
    )::timestamptz INTO next_month FROM now();
    SELECT subpartitions.get_ddl_new_partition(
        partitioned_table,
        next_month,
        range_interval
    ) INTO ddl_to_execute;
    EXECUTE ddl_to_execute;
END
$$;

CREATE PROCEDURE subpartitions.create_all_partitions_for_next_month()
LANGUAGE plpgsql
AS $$
DECLARE tables text[] := array ['task', 'job'];
DECLARE t text;
BEGIN

    FOREACH t IN array tables LOOP
        CALL subpartitions.create_partition_for_next_month(t);
    END LOOP;

END
$$;
