-- fix type
-- https://stackoverflow.com/a/3275885

ALTER TYPE task_state RENAME TO _task_state;
CREATE TYPE task_state AS ENUM (
    'pending', 'running',
    'finished', 'deleted'
);

ALTER TABLE task rename COLUMN state TO _state;
ALTER TABLE task add
    state task_state
        NOT NULL
        DEFAULT 'pending';
UPDATE task SET state = _state::text::task_state;

ALTER TABLE task DROP COLUMN _state;
DROP TYPE _task_state;
