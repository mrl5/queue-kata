-- cron

CREATE EXTENSION IF NOT EXISTS pg_cron;

CREATE PROCEDURE internal.create_partitions_for_next_interval_for_all_tenants()
LANGUAGE plpgsql
AS $$
DECLARE tenant record;
BEGIN
    FOR tenant IN SELECT name from internal.tenant
    LOOP
        CALL internal.create_partitions_for_next_interval(tenant.name);
    END LOOP;
END
$$;

CREATE PROCEDURE internal.refresh_cache_for_all_tenants()
LANGUAGE plpgsql
AS $x$
DECLARE tenant record;
BEGIN
    FOR tenant IN SELECT name from internal.tenant
    LOOP
        -- `CONCURRENTLY` - non blocking but slower
        EXECUTE format($$
            REFRESH MATERIALIZED VIEW CONCURRENTLY tenant_%s.task_state_cached
        $$, tenant.name);

    END LOOP;
END
$x$;

-- at 00:00 on Sunday - https://crontab.guru/#0_0_*_*_0
SELECT cron.schedule('create new table partitions for all tenants', '0 0 * * 0', $$
    CALL internal.create_partitions_for_next_interval_for_all_tenants();
$$);

-- at every minute - https://crontab.guru/#*_*_*_*_*
SELECT cron.schedule('refresh task_state_cached for all tenants', '* * * * *', $c$
    CALL internal.refresh_cache_for_all_tenants();
$c$);
