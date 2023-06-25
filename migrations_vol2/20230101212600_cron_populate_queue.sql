-- cron populate queue
-- * https://www.postgresql.org/docs/current/sql-refreshmaterializedview.html

CREATE PROCEDURE queue.add_orphaned_tasks()
LANGUAGE sql AS $$
    INSERT INTO queue.task_queue (task_id, task_created_at, not_before)
    SELECT id, created_at,
        CASE
            WHEN not_before IS NULL
                THEN created_at
            ELSE not_before
        END
    FROM scheduler.task_state_cached WHERE state = 'created'
    ORDER BY id asc LIMIT 100
    ON CONFLICT DO NOTHING;
$$;

-- remove old cron job
DO $$
DECLARE id bigint;
DECLARE res record;
BEGIN
    SELECT jobid INTO id FROM cron.job
    WHERE jobname = 'refresh scheduler.task_state_cached';

    SELECT cron.unschedule(id) INTO res;
END $$;

-- add again
-- at every minute - https://crontab.guru/#*_*_*_*_*
SELECT cron.schedule('refresh scheduler.task_state_cached', '* * * * *', $$
    -- `CONCURRENTLY` - non blocking but slower
    REFRESH MATERIALIZED VIEW CONCURRENTLY scheduler.task_state_cached;
$$);

SELECT cron.schedule('call queue.add_orphaned_tasks', '* * * * *', $$
    CALL queue.add_orphaned_tasks();
$$);
