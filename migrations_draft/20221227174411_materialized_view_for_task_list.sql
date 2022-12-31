-- materialized view for task list

-- given: tasks MUST be filtered by state

DROP INDEX task_state_idx;
DROP INDEX task_typ_idx;
DROP INDEX task_job_state_idx;

CREATE VIEW task_state_view AS
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
    FROM task t
    LEFT JOIN task_queue q on t.id = q.task_id;

CREATE MATERIALIZED VIEW task_state_materialized AS
    SELECT
        id,
        typ,
        state,
        created_at,
        not_before,
        inactive_since
    FROM task_state_view;
-- todo: cron job for REFRESH MATERIALIZED VIEW task_state_materialized;

CREATE UNIQUE INDEX on task_state_materialized (id);
CREATE INDEX on task_state_materialized (typ);
CREATE INDEX on task_state_materialized (state);
