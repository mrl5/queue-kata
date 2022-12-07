FROM rust:latest AS build-env
WORKDIR /app
COPY ./crates /app/crates
COPY ./Cargo.lock ./Cargo.toml /app/
RUN cargo build --release

FROM gcr.io/distroless/cc
COPY --from=build-env /app/target/release/app /
EXPOSE 8000
CMD ["./app"]
