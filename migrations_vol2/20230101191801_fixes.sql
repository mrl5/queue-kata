-- fixes
-- https://www.crunchydata.com/blog/tentative-smarter-query-optimization-in-postgres-starts-with-pg_stat_statements

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

DROP MATERIALIZED VIEW scheduler.task_state_cached;
DROP VIEW scheduler.task_state;

ALTER TABLE core.task
ADD CONSTRAINT not_before_check CHECK (
    created_at + '1month'::interval >= not_before
);

CREATE INDEX ON core.task (state);
-- remove limit + optimize
CREATE VIEW scheduler.task_state AS
    SELECT id, typ, state, created_at, not_before, inactive_since
    FROM core.task WHERE state IS NOT NULL

    UNION ALL

    SELECT
        t.id,
        t.typ,

        -- state
        CASE
            WHEN t.id = q.task_id AND q.is_running IS true
                THEN 'running'
            WHEN t.id = q.task_id AND t.not_before > now()
                THEN 'deferred'
            WHEN t.id = q.task_id
                THEN 'pending'
            ELSE 'created'
        END as state,

        t.created_at,
        t.not_before,
        t.inactive_since
    FROM core.task t
    LEFT JOIN queue.task_queue q on t.id = q.task_id
    WHERE t.state is NULL;

-- add limit here
CREATE MATERIALIZED VIEW scheduler.task_state_cached AS
WITH aggregated AS (
    (SELECT * FROM scheduler.task_state
    WHERE state != 'created' LIMIT 1000)

    UNION ALL

    (SELECT * FROM scheduler.task_state
    WHERE state = 'created')
) SELECT
    id,
    typ,
    state,
    created_at,
    not_before,
    inactive_since
FROM aggregated
ORDER BY id desc;
-- recreate same indexes
CREATE UNIQUE INDEX on scheduler.task_state_cached (id);
CREATE INDEX on scheduler.task_state_cached (typ);
CREATE INDEX on scheduler.task_state_cached (state);

REFRESH MATERIALIZED VIEW CONCURRENTLY scheduler.task_state_cached;
