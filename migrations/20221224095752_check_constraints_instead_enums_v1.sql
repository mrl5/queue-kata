-- [1 of 2] use CHECK constraints instead of ENUM TYPEs
-- rationale: https://www.crunchydata.com/blog/enums-vs-check-constraints-in-postgres
-- avoid table lock trick from: https://youtu.be/9_pbEVeMEB4?t=388

ALTER TABLE task
ALTER COLUMN typ TYPE text;

ALTER TABLE task
ADD CONSTRAINT typ_check
CHECK (
    typ in (
        'type_a', 'type_b', 'type_c'
    )
-- avoid table lock by postponing validation
) NOT VALID;

ALTER TABLE task
ALTER COLUMN state TYPE text;

ALTER TABLE task
ADD CONSTRAINT state_check
CHECK (
    state in (
        'pending', 'running', 'finished', 'deleted'
    )
) NOT VALID;
