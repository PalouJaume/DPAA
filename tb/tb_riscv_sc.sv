//
// Microcredencial en Diseño de Procesadores con Arquitectura Abierta
// Cátedra UPM-INDRA en Microelectrónica
//
// Author: Alfonso Rodríguez <alfonso.rodriguezm@upm.es>
// Date: March 2025
//

module tb_riscv_sc;

    // Configure simulation
    timeunit 10ns;
    timeprecision 10ps;

    // Local parameters for the simulation
    localparam int XLen = 32;
    localparam int ILen = 32;
    localparam int MemPos = 1024;
    localparam int AddrWidth = $clog2(MemPos);

    // DPI-C imports
    import "DPI-C" function rvm_load_bin(input string filename);
    import "DPI-C" function rvm_reset();
    import "DPI-C" function rvm_step(output logic [XLen-1:0] pc_o, output logic [XLen-1:0] rf_o[32]);

    // Signals for the simulation
    logic clk;
    logic rst_n;
    logic [AddrWidth-1:0] pmem_addr;
    logic [ILen-1:0] pmem_rdata;
    logic [AddrWidth-1:0] dmem_addr;
    logic [XLen-1:0] dmem_rdata;
    logic dmem_we;
    logic [XLen-1:0] dmem_wdata;

    // Single cycle RISC-V processor
    riscv_sc #(
        .XLen(XLen),
        .ILen(ILen)
    ) riscv_sc_i (
        .clk_i(clk),
        .rst_ni(rst_n),
        .pmem_addr_o(pmem_addr),
        .pmem_rdata_i(pmem_rdata),
        .dmem_addr_o(dmem_addr),
        .dmem_rdata_i(dmem_rdata),
        .dmem_we_o(dmem_we),
        .dmem_wdata_o(dmem_wdata)
    );

    // Data memory
    ram #(
        .DataWidth(XLen),
        .NPos(MemPos)
    ) dmem_ram_i (
        .clk_i(clk),
        .a_i(dmem_addr[AddrWidth-1:2]),  // Remove byte-addressing
        .we_i(dmem_we),
        .wd_i(dmem_wdata),
        .rd_o(dmem_rdata)
    );

    // Program memory
    ram #(
        .DataWidth(XLen),
        .NPos(MemPos)
    ) pmem_ram_i (
        .clk_i(clk),
        .a_i(pmem_addr[AddrWidth-1:2]),  // Remove byte-addressing
        .we_i(1'b0),
        .wd_i('0),
        .rd_o(pmem_rdata)
    );

    // Memory initialization
    initial begin
        string binary;

        // Set all program and data memory positions to 0s
        pmem_ram_i.mem = '{default: '0};
        dmem_ram_i.mem = '{default: '0};

        // Simulation needs to be run with the "+binary=<binary>" switch
        if ($value$plusargs("binary=%s", binary)) begin

            $display("[TESTBENCH] RISC-V binary: %s", binary);
            // Load program in the testbench memory
            $readmemh(binary, pmem_ram_i.mem);
            // Load program in the reference model memory
            rvm_load_bin(binary);

        end else begin
            $display("[TESTBENCH] Running simulation without RISC-V binary...");
        end
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

        // Start simulation
        #10 $display("[TESTBENCH] Simulation START");

        // Deassert reset
        rst_n = 1'b1;

        // End simulation after some clock cycles
        #50 $display("[TESTBENCH] Simulation FINISH");
        $finish;
    end

    // Signal monitoring
    initial begin
        $monitor("[TESTBENCH] time=%0t, pc=%08x, instr=%08x, addr=%08x, rdata=%08x, wdata=%08x, wen=%1b", $time, pmem_addr, pmem_rdata, dmem_addr, dmem_rdata, dmem_wdata, dmem_we);
    end

    // Waveform generation (VCD)
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_riscv_sc);
    end

    // DPI-C variables
    logic [XLen-1:0] pc_d, pc_q;
    logic [XLen-1:0] rf_d[32], rf_q[32];

    // Sample DPI-C functions in rising edge
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rvm_reset();
            pc_q <= '0;
            rf_q <= '{default: '0};
        end else begin
            // Evaluate DPI-C function (blocking)...
            rvm_step(pc_d, rf_d);
            // ...and register outputs (non-blocking)...
            pc_q <= pc_d;
            rf_q <= rf_d;
            // ...to eventually evaluate SVAs
            assert (riscv_sc_i.pc_q == pc_q) else $error("[TESTBENCH] (SVA) Program counter differs from reference model (rtl=%08x != ref=%08x)", riscv_sc_i.pc_q, pc_q);
            for (int i = 1; i < 32; i++) assert (riscv_sc_i.regfile_i.rf[i] == rf_q[i]) else $error("[TESTBENCH] (SVA) Register x%1d differs from reference model (rtl=%08x != ref=%08x)", i, riscv_sc_i.regfile_i.rf[i], rf_q[i]);
        end
    end

endmodule
