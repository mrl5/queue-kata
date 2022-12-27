-- given: listing task(s) via API MUST include state that MUST be updated
-- given: tasks MUST be filtered by state

-- assumption 1: implementing task queue in postgres that changes task state
-- will cause table bloat and state index bloat
-- assumption 2: if #1 is true then queue performance will degenerate over time
-- assumption 3: "In Postgres, trying to remove old rows from a large, hot
-- table is flitting with disaster"

-- goals:
-- * reduce task table bloat
-- * reduce task state index bloat
-- * still allow filtering tasks by state
-- * neglible costs of deleting old tasks

-- references:
-- * https://brandur.org/fragments/postgres-partitioning-2022
-- * https://www.crunchydata.com/blog/native-partitioning-with-postgres
-- * https://www.cybertec-postgresql.com/en/hot-updates-in-postgresql-for-better-performance/
-- * https://onesignal.com/blog/lessons-learned-from-5-years-of-scaling-postgresql/#bloat
-- * https://www.enterprisedb.com/blog/containing-bloat-partitions
-- * https://blog.anayrat.info/en/2021/09/01/partitioning-use-cases-with-postgresql/#partitioning-to-control-index-bloat
-- * https://www.youtube.com/watch?v=7VCSmuHMpfk

-- trick: reduce table size by rearranging columns: https://youtu.be/9_pbEVeMEB4?t=1082

ALTER TABLE task
RENAME TO old_task;

CREATE TABLE task (
    created_at timestamptz
        NOT NULL
        DEFAULT now(),

    not_before timestamptz
        DEFAULT NULL,

    inactive_since timestamptz
        DEFAULT NULL,

    int_id uuid
        -- workaround for lack of global index for partitioned tables
        NOT NULL
        DEFAULT gen_random_uuid(),

    id uuid
        NOT NULL,

    typ text
        NOT NULL
        CONSTRAINT typ_check CHECK (
            typ in ('type_a', 'type_b', 'type_c')
        ),

    state text
        DEFAULT NULL
        CONSTRAINT state_check CHECK (
            state in (NULL, 'deleted', 'failed', 'done')
        ),

    UNIQUE (id, inactive_since, int_id)
) PARTITION BY RANGE (inactive_since);
CREATE INDEX ON task (id);
CREATE INDEX ON task (typ);
CREATE INDEX ON task (state);
CREATE INDEX ON task USING BRIN (inactive_since);

CREATE TABLE task_active PARTITION OF task (
    CHECK (inactive_since IS NULL)
) DEFAULT;
CREATE TABLE task_202212 PARTITION OF task
FOR VALUES FROM ('2022-12-26 00:00:000') TO ('2023-04-01 00:00:000');
CREATE TABLE task_202304 PARTITION OF task
FOR VALUES FROM ('2023-04-01 00:00:000') TO ('2023-07-01 00:00:000');
-- todo: cron job for creating partitions + detaching old partitions
-- todo example: ALTER TABLE task DETACH PARTITION task_archive_202212 + create
-- new archive for Q3

-- data migration
INSERT INTO task
SELECT
    created_at,
    not_before,
    -- inactive_since
    CASE
        WHEN deleted_at IS NOT NULL
        THEN deleted_at

        WHEN state IN ('failed', 'done')
        THEN now()
    END AS inactive_since,
    gen_random_uuid(),
    id,
    typ,
    -- state
    CASE
        WHEN state IN ('deleted', 'failed', 'done')
        THEN state
        ELSE NULL
    END AS inactive_since
FROM old_task;
DROP TABLE old_task;
