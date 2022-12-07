build:
    docker build -t scheduler-api .

run:
    docker run --rm -p 8000:8000 mrl5-scheduler-api:latest

dev-tools:
    cargo install hurl

test-api:
    hurl --test ./tests/*.hurl

lint: fmt
    cargo clippy --fix --allow-staged

fmt:
    rustfmt crates/**/src/*.rs
