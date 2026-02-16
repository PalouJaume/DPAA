#
# Microcredencial en Diseño de Procesadores con Arquitectura Abierta
# Cátedra UPM-INDRA en Microelectrónica
#
# Author: Alfonso Rodríguez <alfonso.rodriguezm@upm.es>
# Date: March 2025
#

# Default targets
TARGET ?= riscv_sc
BINARY ?= app

# SystemVerilog source files
SOURCES = $(wildcard rtl/*.sv verif/*.sv tb/*.sv)

# DPI C++ source files
SOURCES += verif/riscv.cpp

# Simulation objects (SystemVerilog source files after running Verible)
OBJECTS = $(SOURCES:%=verible/%)

# Verilator flags
VFLAGS = ""
#VFLAGS += --cc --exe --build -j 0 --main
#VFLAGS += --timing
# NOTE: "--binary" is an alias for "--main --exe --build --timing"
# NOTE: "--cc" seems to be the default option, so it's not needed...
VFLAGS += --cc --binary -j 0        # Enable C++ compilation, build executable, use multiple threads during build
VFLAGS += -Wall -Wno-fatal          # Enable all warnings, prevent them from stopping the build process
VFLAGS += --trace                   # Enable VCD tracing
VFLAGS += --assert                  # Enable SVA support
VFLAGS += --coverage                # Enable code coverage
VFLAGS += --threads $(shell nproc)  # Run simulation with multiple threads
VFLAGS += --threads-dpi none        # Assume DPI calls are not thread-safe

# Configure default goal
.DEFAULT_GOAL := run

# Help/documentation
.PHONY: help
help:
	@echo  ''
	@echo  '#'
	@echo  '# Microcredencial en Diseño de Procesadores con Arquitectura Abierta'
	@echo  '# Cátedra UPM-INDRA en Microelectrónica'
	@echo  '#'
	@echo  '# Author: Alfonso Rodríguez <alfonso.rodriguezm@upm.es>'
	@echo  '# Date: March 2025'
	@echo  '#'
	@echo  ''
	@echo  'Configuration variables:'
	@echo  '  TARGET     - target design for simulation (default: $(TARGET))'
	@echo  '    supported values: alu, regfile, ram, riscv_sc'
	@echo  '  BINARY     - target binary for execution in the processor (default: $(BINARY))'
	@echo  '    supported values: app, test'
	@echo  ''
	@echo  'Available targets:'
	@echo  '  conda      - setup/update conda-based environment for the labs'
	@echo  '  apps       - build software applications (*.S) under sw/'
	@echo  '  verilator  - build simulation executable'
	@echo  '  run        - run simulation executable'
	@echo  '  waves      - run simulation executable and show VCD dump'
	@echo  '  clean      - clean simulation files'
	@echo  '  distclean  - clean all generated files'
	@echo  ''
	@echo  'Example invocations:'
	@echo  ''
	@echo  '  Run simulation of the ALU'
	@echo  '    make TARGET=alu run'
	@echo  ''
	@echo  '  Run simulation of the register file and show waveforms'
	@echo  '    make TARGET=regfile waves'
	@echo  ''
	@echo  '  Build simulation of the single-port RAM'
	@echo  '    make TARGET=ram verilator'
	@echo  ''
	@echo  '  Run simulation of the single cycle processor with the test.hex binary'
	@echo  '    make TARGET=riscv_sc BINARY=test run'
	@echo  ''
	@echo  '  Run simulation of the single cycle processor with the app.hex binary and show waveforms'
	@echo  '    make TARGET=riscv_sc BINARY=app waves'
	@echo  ''

# Environment setup (1: download and install miniconda)
~/miniconda3:
	# Install Miniconda3
	#    https://docs.anaconda.com/miniconda/
	mkdir -p ~/miniconda3
	wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
	bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
	rm ~/miniconda3/miniconda.sh

	# Add Miniconda3 to the PATH but disable default base environment init in shells
	~/miniconda3/bin/conda init --all
	~/miniconda3/bin/conda config --set auto_activate_base false

# Environment setup (2: create environment)
~/miniconda3/envs/labs-dpaa: ~/miniconda3
	# Create environment for DPAA
	~/miniconda3/bin/conda create -y --name labs-dpaa

# Environment setup (3: ensure all requirements are available in the environment)
conda: ~/miniconda3/envs/labs-dpaa
	# Install all requirements in the DPAA environment
	~/miniconda3/bin/conda install -y --name labs-dpaa --channel conda-forge --channel litex-hub verilator=5.034 verible=0.0_3667_g88d12889 gtkwave gcc-riscv64-elf-newlib

# Build software
apps:
	make -C sw apps

# Build simulation
verilator: $(OBJECTS)
	verilator $(VFLAGS) $^ --top-module tb_$(TARGET)

# Run simulation
run: verilator apps
	# ./obj_dir/Vtb_$(TARGET) +binary="sw/build/$(BINARY).hex" +verilator+seed+$(shell date +%s)
	./obj_dir/Vtb_$(TARGET) +binary="sw/build/$(BINARY).hex"
	rm -rf coverage_annotated
	verilator_coverage --annotate coverage_annotated coverage.dat

# Show waveforms
waves: run
	gtkwave dump.vcd

# Clean simulation outputs
clean:
	rm -rf verible obj_dir dump.vcd coverage.dat coverage_annotated

# Clean simulation and software
distclean: clean
	make -C sw clean

# Run verible for each SystemVerilog source file
verible/%.sv: %.sv
	# Copy files to build directory
	mkdir -p verible/rtl verible/tb verible/verif
	cp $< $@

	# Format SystemVerilog code
	verible-verilog-format $@ --inplace \
		--formal_parameters_indentation indent --named_parameter_indentation indent \
		--named_port_indentation indent --port_declarations_indentation indent 2> /dev/null

	# Lint SystemVerilog code
	verible-verilog-lint $@ --lint_fatal=false --parse_fatal=false

# DPI C++ source file
verible/%.cpp: %.cpp
	# Copy files to build directory
	mkdir -p verible/verif
	cp $< $@
