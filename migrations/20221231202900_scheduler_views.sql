-- scheduler views

CREATE SCHEMA scheduler;

CREATE VIEW scheduler.task AS
    SELECT
        id,
        typ,
        state,
        not_before,
        inactive_since
    FROM core.task;

CREATE VIEW scheduler.task_state AS
    SELECT
        t.id,
        t.typ,

        -- state
        CASE
            WHEN t.state IS NOT NULL
                THEN t.state
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
    LIMIT 1000;

CREATE MATERIALIZED VIEW scheduler.task_state_cached AS
    SELECT
        id,
        typ,
        state,
        created_at,
        not_before,
        inactive_since
    FROM scheduler.task_state;
-- something (e.g. cron) should `REFRESH MATERIALIZED VIEW`

CREATE UNIQUE INDEX on scheduler.task_state_cached (id);
-- GIVEN: Show a list of tasks, filterable by their state and/or task type
CREATE INDEX on scheduler.task_state_cached (typ);
CREATE INDEX on scheduler.task_state_cached (state);
