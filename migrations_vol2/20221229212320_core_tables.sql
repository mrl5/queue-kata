-- core tables

CREATE TABLE core.task (
    -- trick: reduce table size by rearranging columns: https://youtu.be/9_pbEVeMEB4?t=1082
    created_at timestamptz
        NOT NULL
        DEFAULT now(),

    not_before timestamptz
        DEFAULT NULL,

    inactive_since timestamptz
        DEFAULT NULL,

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

    UNIQUE (id, created_at)
) PARTITION BY RANGE (created_at);
CREATE INDEX ON core.task (id);
CREATE INDEX ON core.task USING BRIN (created_at);

CREATE TABLE core.job (
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
CREATE INDEX ON core.job (task);
CREATE INDEX ON core.job (state);
CREATE INDEX ON core.job USING BRIN (started_at);
