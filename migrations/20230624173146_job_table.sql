-- job table

CREATE TABLE job (
    started_at timestamptz
        NOT NULL
        DEFAULT now(),

    finished_at timestamptz
        DEFAULT NULL,

    task uuid
        NOT NULL,

    id bigserial
        NOT NULL,

    state text
        DEFAULT NULL
        CONSTRAINT state_check CHECK (
            state in (NULL, 'failed', 'done')
        ),

    UNIQUE (id, started_at)
)
PARTITION BY RANGE (started_at);
CREATE INDEX ON job (task);
CREATE INDEX ON job (state);
CREATE INDEX ON job USING BRIN (started_at);
