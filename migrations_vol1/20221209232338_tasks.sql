-- tasks
CREATE TYPE task_type AS ENUM (
    'type_a', 'type_b', 'type_c'
);

CREATE TYPE task_state AS ENUM (
    'pending', 'running'
    'finished', 'deleted'
);

CREATE TYPE task_result AS ENUM (
    'success', 'failure'
);

CREATE TABLE task (
    id uuid
        PRIMARY KEY
        DEFAULT gen_random_uuid(),

    typ task_type
        NOT NULL,

    state task_state
        NOT NULL
        DEFAULT 'pending',

    created_at timestamptz
        NOT NULL
        DEFAULT now(),

    deleted_at timestamptz
        DEFAULT NULL,

    not_before timestamptz
        DEFAULT NULL
);
