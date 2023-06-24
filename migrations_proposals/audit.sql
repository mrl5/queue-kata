-- https://www.cybertec-postgresql.com/en/row-change-auditing-options-for-postgresql/

CREATE TABLE task_audit (
    id uuid
        NOT NULL,
    operation char(1)
        NOT NULL,
    executed_at timestamptz
        NOT NULL
        DEFAULT now(),
    userid text
        NOT NULL,
    app text,
    data jsonb
        NOT NULL
) PARTITION BY RANGE (executed_at);
CREATE INDEX ON task_audit (id);
CREATE INDEX ON task_audit USING BRIN (executed_at);

CREATE TABLE task_audit_20221225 PARTITION OF task_audit
FOR VALUES FROM ('2022-12-25 00:00:000') TO ('2023-03-31 00:00:000');

CREATE OR REPLACE FUNCTION process_task_audit() RETURNS TRIGGER AS $task_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
            INSERT INTO task_audit SELECT OLD.id, 'D', now(), user, current_setting('application_name'), to_jsonb(OLD.*);

        ELSIF (TG_OP = 'UPDATE') THEN
            INSERT INTO task_audit SELECT NEW.id, 'U', now(), user, current_setting('application_name'), to_jsonb(NEW.*);

        ELSIF (TG_OP = 'INSERT') THEN
            INSERT INTO task_audit SELECT NEW.id, 'I', now(), user, current_setting('application_name'), to_jsonb(NEW.*);
        END IF;
        RETURN NULL; -- result is ignored since this is an AFTER trigger
    END;
$task_audit$ LANGUAGE plpgsql;

CREATE TRIGGER task_audit
AFTER INSERT OR UPDATE OR DELETE ON task
    FOR EACH ROW EXECUTE FUNCTION process_task_audit();
