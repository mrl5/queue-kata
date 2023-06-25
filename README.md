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

## setup db on BEFORE run

### One time bootstrap

You will need two terminals:
0. 

1. Let's create our container with vanilla postgres first
```console
just db-only
```

2. We have vanilla postgres with empty database for the project. Now let's
   bootstrap `pg_cron`. Run it in 2nd terminal:
```console
just db-bootstrap-cron
```

3. Container was restarted. You can attach to it in 1st terminal again:
```console
just db-only
```

4. Let's continue the bootstrap process in 2nd terminal:
```console
just db-bootstrap-internal
```

### Per tenant migration

Each time you provide new `TENANT` value you will need to run:
```console
just db-add-new-tenant db-migrate
```
For more info inspect the content of `.env` (it's symlink to `.env.docker`).
Then compare it with `.env.local`. Notice the `TENANT` variable


## howto dev

install dev tools

```console
cargo install just
just dev-tools
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
