DOCKER_COMPOSE := "docker-compose"

set dotenv-load
set export

build:
    ${DOCKER_COMPOSE} build

run:
    ${DOCKER_COMPOSE} up

db-only:
    ${DOCKER_COMPOSE} up db

dev-tools:
    cargo install hurl sqlx-cli

db-migrate:
    sqlx migrate run
    cargo sqlx prepare --merged

local-api:
    cargo run

test: test-unit test-api

test-unit:
    cargo test

test-api:
    hurl --test ./tests/*.hurl

lint: fmt
    cargo clippy --fix --allow-staged

fmt:
    rustfmt crates/**/src/*.rs
