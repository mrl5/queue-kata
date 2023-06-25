-- indexes improving task filtering

CREATE INDEX type_idx ON task (typ);
CREATE INDEX state_idx ON task (state);
