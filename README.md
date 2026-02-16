# Diseño de Procesadores con Arquitectura Abierta

Laboratorios de Diseño de Procesadores con Arquitectura Abierta - UPM 2025/26

## Requisitos

- [OrbStack](https://orbstack.dev/) o Docker

## Setup

Construir la imagen (solo una vez):

```bash
docker build -t dpaa -f docker/Dockerfile .
```

## Uso

```bash
docker run -it --rm -v $PWD:/workspace -w /workspace dpaa /bin/bash
```

Ejecutar tests:

```bash
make TARGET=alu run
make TARGET=regfile run
make TARGET=ram run
make TARGET=riscv_sc run
```
