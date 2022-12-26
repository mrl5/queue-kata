-- [1 of 2] new task states

ALTER TABLE task
DROP CONSTRAINT state_check;

ALTER TABLE task
ADD CONSTRAINT state_check
CHECK (
    state in (
        'pending', 'deleted', 'running', 'failed', 'done'
    )
-- avoid table lock by postponing validation
) NOT VALID;
