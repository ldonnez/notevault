FROM debian:trixie-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    bash bats bats-support bats-assert git gpg coreutils moreutils tar \
    && apt-get clean

WORKDIR /opt
