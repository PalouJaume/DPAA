FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    verilator \
    gcc-riscv64-unknown-elf \
    binutils-riscv64-unknown-elf \
    bsdmainutils \
    vim \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Instalar Verible
RUN curl -sSL https://github.com/chipsalliance/verible/releases/download/v0.0-4051-g9fdb4057/verible-v0.0-4051-g9fdb4057-linux-static-arm64.tar.gz \
    | tar -xz -C /usr/local --strip-components=1

CMD ["bin/bash"] 
