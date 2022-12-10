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

local-api:
    cargo run

test-api:
    hurl --test ./tests/*.hurl

lint: fmt
    cargo clippy --fix --allow-staged

fmt:
    rustfmt crates/**/src/*.rs
