-- queue logic views + populating logic

CREATE VIEW task_state AS
    SELECT id, typ, state, created_at, not_before, inactive_since
    FROM task WHERE state IS NOT NULL

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
    FROM task t
    LEFT JOIN queue q on t.id = q.task_id
    WHERE t.state is NULL;

-- notice limit here
CREATE MATERIALIZED VIEW task_state_cached AS
WITH aggregated AS (
    (SELECT * FROM task_state
    WHERE state != 'created' LIMIT 1000)

    UNION ALL

    (SELECT * FROM task_state
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
-- something (e.g. cron) should `REFRESH MATERIALIZED VIEW CONCURRENTLY`

CREATE UNIQUE INDEX on task_state_cached (id);
-- GIVEN: Show a list of tasks, filterable by their state and/or task type
CREATE INDEX on task_state_cached (typ);
CREATE INDEX on task_state_cached (state);

CREATE PROCEDURE populate_queue(tenant text)
LANGUAGE plpgsql AS $fn$
BEGIN
EXECUTE format($$

    INSERT INTO tenant_%s.queue (task_id, task_created_at, not_before)
    SELECT id, created_at,
        CASE
            WHEN not_before IS NULL
                THEN created_at
            ELSE not_before
        END
    FROM tenant_%s.task_state_cached WHERE state = 'created'
    ORDER BY id asc LIMIT 100
    ON CONFLICT DO NOTHING;

$$, tenant, tenant);
END
$fn$;
