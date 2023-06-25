-- queue
-- * https://www.cybertec-postgresql.com/en/what-is-fillfactor-and-how-does-it-affect-postgresql-performance/

CREATE SCHEMA queue;

CREATE TABLE queue.task_queue (
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

    task_created_at timestamptz
        NOT NULL,

    task_id uuid
        NOT NULL,

    PRIMARY KEY (task_id, task_created_at),
    FOREIGN KEY (task_id, task_created_at)
        REFERENCES core.task (id, created_at)
-- for HOT updates
) WITH (fillfactor=70);
CREATE INDEX ON queue.task_queue USING BRIN (not_before);
