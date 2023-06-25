-- [2 of 2] use CHECK constraints instead of ENUM TYPEs
-- rationale: https://www.crunchydata.com/blog/enums-vs-check-constraints-in-postgres
-- avoid table lock trick from: https://youtu.be/9_pbEVeMEB4?t=388


-- enable validation w/o table lock
ALTER TABLE task
VALIDATE CONSTRAINT typ_check;

ALTER TABLE task
VALIDATE CONSTRAINT state_check;


-- clean-up
ALTER TABLE task
ALTER COLUMN state
SET DEFAULT 'pending';

DROP TYPE task_type;
DROP TYPE task_state;
