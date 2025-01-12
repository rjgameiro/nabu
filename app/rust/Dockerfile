
FROM docker.io/library/rust:slim-bookworm as build

RUN USER=root cargo new --lib package_name
COPY ./package_name/Cargo.toml /package_name/Cargo.toml

RUN USER=root cargo new --bin package_name_api
COPY ./package_name_api/Cargo.toml /package_name_api/Cargo.toml

COPY ./Cargo.toml /Cargo.toml
COPY ./Cargo.lock /Cargo.lock

RUN cargo build
RUN rm -rf /package_name/src/* /package_name_api/src/*

COPY ./package_name/src /package_name/src
COPY ./package_name_api/src /package_name_api/src

RUN rm -f ./target/*/deps/package_name*
RUN cargo build

FROM docker.io/library/debian:bookworm-slim

COPY ./package_name_api/data/scales.json /
COPY --from=build /target/debug/package_name_api /

CMD ["/package_name_api"]
