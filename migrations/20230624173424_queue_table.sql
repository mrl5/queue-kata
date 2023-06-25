-- queue table

CREATE TABLE queue (
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
        REFERENCES task (id, created_at)
-- for HOT updates
) WITH (fillfactor=70);
CREATE INDEX ON queue USING BRIN (not_before);
