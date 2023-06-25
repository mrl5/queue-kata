-- task table

CREATE TABLE task (
    -- trick: reduce table size by rearranging columns: https://youtu.be/9_pbEVeMEB4?t=1082
    created_at timestamptz
        NOT NULL
        DEFAULT now(),

    not_before timestamptz
        DEFAULT NULL
        CONSTRAINT not_before_check CHECK (
            created_at + '1month'::interval >= not_before
        ),

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
CREATE INDEX ON task (id);
CREATE INDEX ON task USING BRIN (created_at);
CREATE INDEX ON task (state);

