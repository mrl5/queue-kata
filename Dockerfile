FROM rust:latest AS build-env
ENV SQLX_OFFLINE=true
WORKDIR /app
COPY ./Cargo.lock ./Cargo.toml /app/
COPY ./migrations /app/migrations
COPY ./sqlx-data.json /app/
COPY ./crates /app/crates
RUN cargo build --release

FROM gcr.io/distroless/cc
COPY --from=build-env /app/target/release/app /
EXPOSE 8000
CMD ["./app"]
