FROM rust:1.70 AS build-env
ENV SQLX_OFFLINE=true
WORKDIR /app
COPY ./Cargo.lock ./Cargo.toml /app/
COPY ./migrations /app/migrations
COPY ./sqlx-data.json /app/
COPY ./crates /app/crates
RUN cargo build --release

FROM gcr.io/distroless/cc
COPY --from=build-env /app/target/release/scheduler-api /app
EXPOSE 8000
CMD ["./app"]
