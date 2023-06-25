-- [2 of 2] new task states

-- enable validation w/o table lock
ALTER TABLE task
VALIDATE CONSTRAINT state_check;
