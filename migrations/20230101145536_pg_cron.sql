-- pgcron
-- MAKE SURE TO RUN `just db-bootstrap` first
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- at every minute - https://crontab.guru/#*_*_*_*_*
SELECT cron.schedule('refresh scheduler.task_state_cached', '* * * * *', $$
    REFRESH MATERIALIZED VIEW scheduler.task_state_cached;
$$);

-- at 00:00 on Sunday - https://crontab.guru/#0_0_*_*_0
SELECT cron.schedule('create new subpartitions', '0 0 * * 0', $$
    CALL subpartitions.create_all_partitions_for_next_month();
$$);
