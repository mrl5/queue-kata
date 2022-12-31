-- task queue
-- references:
-- * https://www.cybertec-postgresql.com/en/what-is-fillfactor-and-how-does-it-affect-postgresql-performance/

ALTER TABLE task_active
ADD PRIMARY KEY (id);

CREATE TABLE task_queue (
    is_running boolean
        NOT NULL
        DEFAULT false,

    retries smallint
        NOT NULL
        DEFAULT 0
        CONSTRAINT retries_check CHECK (retries >= 0),

    queued_at timestamptz
        NOT NULL
        DEFAULT now(),

    not_before timestamptz
        NOT NULL
        DEFAULT now(),

    task_id uuid
        PRIMARY KEY
        REFERENCES task_active(id)
-- for HOT updates
) WITH (fillfactor=70);
CREATE INDEX ON task_queue USING BRIN (not_before);

CREATE TABLE task_job (
    started_at timestamptz
        NOT NULL
        DEFAULT now(),

    finished_at timestamptz
        DEFAULT NULL,

    task_id uuid
        NOT NULL,

    id uuid
        NOT NULL
        DEFAULT gen_random_uuid(),

    state text
        DEFAULT NULL
        CONSTRAINT state_check CHECK (
            state in (NULL, 'failed', 'done')
        ),

    UNIQUE (id, finished_at, task_id)
)
PARTITION BY RANGE (finished_at);
CREATE INDEX ON task_job (task_id);
CREATE INDEX ON task_job (state);
CREATE INDEX ON task_job USING BRIN (finished_at);

CREATE TABLE task_job_active PARTITION OF task_job (
    CHECK (finished_at IS NULL)
) DEFAULT;
CREATE TABLE task_job_202212 PARTITION OF task_job
FOR VALUES FROM ('2022-12-26 00:00:000') TO ('2023-04-01 00:00:000');
CREATE TABLE task_job_202304 PARTITION OF task_job
FOR VALUES FROM ('2023-04-01 00:00:000') TO ('2023-07-01 00:00:000');
-- todo: cron job for creating partitions + detaching old partitions
