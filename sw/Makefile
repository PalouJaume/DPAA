#
# Microcredencial en Diseño de Procesadores con Arquitectura Abierta
# Cátedra UPM-INDRA en Microelectrónica
#
# Author: Alfonso Rodríguez <alfonso.rodriguezm@upm.es>
# Date: March 2025
#

# Source files (RISC-V assembly)
SOURCES = $(wildcard *.S)

# GNU assembler outputs
OBJECTS = $(SOURCES:%.S=build/%.o)

# .text section dumps
DUMPS = $(OBJECTS:build/%.o=build/%.dump)

# Simulation files (text-based, one binary instruction per line)
SIMFILES = $(DUMPS:build/%.dump=build/%.hex)

# Generate all apps
apps: $(SIMFILES)

# Generate simulation files
build/%.hex: build/%.dump
	hexdump -e '32/4 "%08x\n"' $< > $@

# Extract .text sections from object files
build/%.dump: build/%.o
	riscv64-unknown-elf-objcopy --dump-section .text=$@ $<

# Build object files from source code
build/%.o: %.S
	mkdir -p build
	riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o $@ $<

# Clean simulation files
clean:
	rm -rf build