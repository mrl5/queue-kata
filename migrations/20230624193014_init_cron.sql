-- init cron

CREATE EXTENSION IF NOT EXISTS pg_cron;

-- at 00:00 on Sunday - https://crontab.guru/#0_0_*_*_0
SELECT cron.schedule('create new table partitions for tenant "default"', '0 0 * * 0', $$
    CALL internal.create_all_partitions_for_next_month('default');
$$);

-- at every minute - https://crontab.guru/#*_*_*_*_*
SELECT cron.schedule('refresh task_state_cached for tenant "default"', '* * * * *', $c$
    -- `CONCURRENTLY` - non blocking but slower
    REFRESH MATERIALIZED VIEW CONCURRENTLY tenant_default.task_state_cached;
$c$);

SELECT cron.schedule('call queue.add_orphaned_tasks for tenant "default"', '* * * * *', $$
    CALL internal.populate_queue('default');
$$);
