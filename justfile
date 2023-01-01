set dotenv-load
set export

DOCKER_COMPOSE := "docker-compose"
TMRW := `date -u -Iseconds -d"+1days"`

build:
    ${DOCKER_COMPOSE} build

run:
    ${DOCKER_COMPOSE} up

dev-tools:
    cargo install hurl sqlx-cli

db-only:
    ${DOCKER_COMPOSE} up db

db-bootstrap: && db-only
    # allow using pg_cron in our db
    PGPASSWORD=${DB_PASSWORD} psql -h ${DB_HOST} -p ${DB_PORT} -U postgres -d ${DB_NAME} \
        -c "ALTER SYSTEM SET cron.database_name TO '${DB_NAME}';"

    # restart db so that changes are effective
    ${DOCKER_COMPOSE} restart db

db-migrate:
    sqlx migrate run
    cargo sqlx prepare --merged

local-api:
    cargo run

test: test-unit test-api

test-unit:
    cargo test

test-api:
    hurl --variable tomorrow={{TMRW}} --test ./tests/*.hurl

lint: fmt
    cargo clippy --fix --allow-staged

fmt:
    rustfmt crates/**/src/*.rs
