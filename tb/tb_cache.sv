//
// Microcredencial en Diseño de Procesadores con Arquitectura Abierta
// Cátedra UPM-INDRA en Microelectrónica
//
// Author: Alfonso Rodríguez <alfonso.rodriguezm@upm.es>
// Date: April 2025
//

module tb_cache;

    // Configure simulation
    timeunit 10ns;
    timeprecision 10ps;

    // Local parameters for the simulation
    localparam int AddrWidth = 32;
    localparam int DataWidth = 32;     // 32-bit words
    localparam int CacheSize = 1024;   // 1 KiB
    localparam int BlockSize = 64;     // Cache block (64 bytes)
    localparam int CacheWays = 2;      // 2-way set associative cache
    localparam int MemSize = 8192;     // 8 KiB
    localparam int Latency = 100;      // Slow memory latency
    localparam int Iterations = 512;   // Number of write/read transactions to make

    // Signals for the simulation
    logic clk;
    logic rst_n;
    logic cpu_req;
    logic cpu_gnt;
    logic cpu_rw;
    logic [AddrWidth-1:0] cpu_addr;
    logic [DataWidth-1:0] cpu_wdata;
    logic [DataWidth-1:0] cpu_rdata;
    logic mem_req;
    logic mem_gnt;
    logic mem_rw;
    logic [AddrWidth-1:0] mem_addr;
    logic [DataWidth-1:0] mem_wdata;
    logic [DataWidth-1:0] mem_rdata;

    // Signals to measure time
    time t0, tf;

    // Instantiate cache
    cache #(
        .AddrWidth(AddrWidth),
        .DataWidth(DataWidth),
        .CacheSize(CacheSize),
        .BlockSize(BlockSize),
        .CacheWays(CacheWays)
    ) cache_i (
        .clk_i(clk),
        .rst_ni(rst_n),
        .cpu_req_i(cpu_req),
        .cpu_gnt_o(cpu_gnt),
        .cpu_rw_i(cpu_rw),
        .cpu_addr_i(cpu_addr),
        .cpu_wdata_i(cpu_wdata),
        .cpu_rdata_o(cpu_rdata),
        .mem_req_o(mem_req),
        .mem_gnt_i(mem_gnt),
        .mem_rw_o(mem_rw),
        .mem_addr_o(mem_addr),
        .mem_wdata_o(mem_wdata),
        .mem_rdata_i(mem_rdata)
    );

    // Instantiate main memory
    slow_mem #(
        .AddrWidth(AddrWidth),
        .DataWidth(DataWidth),
        .MemSize(MemSize),
        .Latency(Latency)
    ) mem_i (
        .clk_i(clk),
        .rst_ni(rst_n),
        .mem_req_i(mem_req),
        .mem_gnt_o(mem_gnt),
        .mem_rw_i(mem_rw),
        .mem_addr_i(mem_addr),
        .mem_wdata_i(mem_wdata),
        .mem_rdata_o(mem_rdata)
    );

    // Memory initialization
    initial begin
        // Set all memory positions to 0s
        mem_i.ram_i.mem = '{default: '0};
    end

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #0.5 clk = ~clk;
    end

    // Stimuli generation
    initial begin
        // Assert reset
        rst_n = 1'b0;

        // Initial state for inputs
        cpu_req = 1'b0;
        cpu_rw = 1'b0;
        cpu_addr = '0;
        cpu_wdata = '0;

        // Start simulation
        #10 $display("[TESTBENCH] Simulation START");

        // Deassert reset
        rst_n = 1'b1;

        // Emulate some accesses from CPU
        for (int i = 0; i < Iterations; i++) begin

            // Write request
            #5 cpu_req = 1'b1;
            cpu_rw = 1'b1;
            cpu_addr = $urandom_range(0, MemSize >> 2);
            cpu_wdata = $urandom;

            // Measure #cycles
            t0 = $time;
            @(negedge cpu_gnt) tf = $time;
            $display("[TESTBENCH] W (cycles=%04d, addr=%08x, data=%08x)", tf-t0, cpu_addr, cpu_wdata);
            @(negedge clk) cpu_req = 1'b0;

            // Read request
            #5 cpu_req = 1'b1;
            cpu_rw = 1'b0;
            cpu_wdata = '0;

            // Measure #cycles
            t0 = $time;
            @(negedge cpu_gnt) tf = $time;
            $display("[TESTBENCH] R (cycles=%04d, addr=%08x, data=%08x)", tf-t0, cpu_addr, cpu_rdata);
            @(negedge clk) cpu_req = 1'b0;
        end

        // End simulation after some clock cycles
        #10 $display("[TESTBENCH] Simulation FINISH");
        $finish;
    end

    // Signal monitoring
    initial begin
        $monitor("[TESTBENCH] time=%0t", $time);
    end

    // Waveform generation (VCD)
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_cache);
    end

endmodule