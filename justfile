set dotenv-load
set export

DOCKER_COMPOSE := "docker compose"
TMRW := `date -u -Iseconds -d"+1days"`

build:
    ${DOCKER_COMPOSE} build

run:
    ${DOCKER_COMPOSE} up

dev-tools:
    cargo install hurl sqlx-cli

db-only:
    ${DOCKER_COMPOSE} up db

db-bootstrap-cron:
    # allow using pg_cron in our db
    PGPASSWORD=${ADMIN_DB_PASSWORD} psql -h ${DB_HOST} -p ${DB_PORT} \
    -U ${ADMIN_DB_USER} -d ${DB_NAME} \
        -c "ALTER SYSTEM SET cron.database_name TO '${DB_NAME}';"

    # restart db so that changes are effective
    ${DOCKER_COMPOSE} restart db

db-bootstrap-internal:
    PGPASSWORD=${ADMIN_DB_PASSWORD} psql -h ${DB_HOST} -p ${DB_PORT} \
        -U ${ADMIN_DB_USER} -d ${DB_NAME} \
        -c "CREATE SCHEMA internal AUTHORIZATION ${ADMIN_DB_USER};"

    cat ./migrations_internal/*.sql \
    | PGPASSWORD=${ADMIN_DB_PASSWORD} psql -h ${DB_HOST} -p ${DB_PORT} \
        -U ${ADMIN_DB_USER} -d ${DB_NAME}

db-add-new-tenant:
    # workaround sqlx limitation
    # https://github.com/launchbadge/sqlx/issues/1835#issuecomment-1493727747
    PGPASSWORD=${ADMIN_DB_PASSWORD} psql -h ${DB_HOST} -p ${DB_PORT} \
        -U ${ADMIN_DB_USER} -d ${DB_NAME} \
        -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';"

    PGPASSWORD=${ADMIN_DB_PASSWORD} psql -h ${DB_HOST} -p ${DB_PORT} \
        -U ${ADMIN_DB_USER} -d ${DB_NAME} \
        -c "CALL internal.create_new_tenant('${TENANT}');"

db-migrate:
    sqlx migrate run
    cargo sqlx prepare --merged

    PGPASSWORD=${ADMIN_DB_PASSWORD} psql -h ${DB_HOST} -p ${DB_PORT} \
        -U ${ADMIN_DB_USER} -d ${DB_NAME} \
        -c "CALL internal.create_all_partitions_for_now('${TENANT}');"

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
