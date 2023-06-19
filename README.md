# scheduler kata

## requirements

Expose an API that can:
* Create a task of a specific type and execution time, returning the task's ID
* Show a list of tasks, filterable by their state (whatever states you define) and/or their task type
* Show a task based on its ID
* Delete a task based on its ID
* The tasks must be persisted into some external data store (your choice).
* Process each task only once and only at/after their specified execution time.
* Support running multiple instances of your code in parallel.

## howto dev

install dev tools

```console
cargo install just
just dev-tools
```

### setup db on first run
```console
just db-only
just db-bootstrap
just db-migrate
```

### locally

```console
find . -type l -iname ".env" | xargs rm -v && ln -s -v .env.local .env
just db-only
just test-unit
just local-api
just test-api
```

### via docker

```console
just build run
just test-api
```

### database migrations

run migrations on db
```console
just db-migrate
```

for new migration definition
```console
sqlx migrate add <migration name w/o timestamp>
```
