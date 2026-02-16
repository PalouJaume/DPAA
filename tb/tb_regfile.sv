//
// Microcredencial en Diseño de Procesadores con Arquitectura Abierta
// Cátedra UPM-INDRA en Microelectrónica
//
// Author: Alfonso Rodríguez <alfonso.rodriguezm@upm.es>
// Date: March 2025
//

module tb_regfile;

    // Configure simulation
    timeunit 10ns;
    timeprecision 10ps;

    // Local parameters for the simulation
    localparam int XLen = 32;
    localparam int NReg = 32;
    localparam int NRegWidth = $clog2(NReg);
    localparam int Iterations = 2*NReg;

    // Signals for the simulation
    logic clk;
    logic rst_n;
    logic [NRegWidth-1:0] a1;
    logic [NRegWidth-1:0] a2;
    logic [NRegWidth-1:0] a3;
    logic we3;
    logic [XLen-1:0] wd3;
    logic [XLen-1:0] rd1;
    logic [XLen-1:0] rd2;

    // Instantiate UUT
    regfile #(
        .XLen(XLen),
        .NReg(NReg)
    ) regfile_i (
        .clk_i(clk),
        .rst_ni(rst_n),
        .a1_i(a1),
        .a2_i(a2),
        .a3_i(a3),
        .we3_i(we3),
        .wd3_i(wd3),
        .rd1_o(rd1),
        .rd2_o(rd2)
    );

    // Bind SVA module to UUT
    bind regfile prop_regfile #(
        .XLen(XLen),
        .NReg(NReg)
    ) prop_regfile_i (.*);

    // Clock generation
    initial begin
        clk = 0;
        forever #0.5 clk = ~clk;
    end

    // Stimuli generation
    initial begin
        // Assert reset signal
        rst_n = 1'b0;

        // Reset state for inputs
        a1 = '0;
        a3 = '0;
        a3 = '0;
        we3 = 1'b0;
        wd3 = '0;

        $display("[TESTBENCH] Simulation START");

        // Deassert reset
        #10 rst_n = 1'b1;

        // Generate R/W operations
        for (int i = 0; i < Iterations; i++) begin
            a1 = i;
            a2 = $urandom;
            a3 = i;
            we3 = 1'b1;
            wd3 = $urandom;
            #1 we3 = 1'b0;
            #1 ; //$display("[TESTBENCH] a1=%02x, rd1=%08x, a2=%02x, rd2=%08x, a3=%02x, we3=%b, wd3=%08x", a1, rd1, a2, rd2, a3, we3, wd3);
        end

        // End simulation
        #10 $display("[TESTBENCH] Simulation FINISH");
        $finish;
    end

    // Signal monitoring
    initial begin
        $monitor("[TESTBENCH] time=%0t, a1=%02x, rd1=%08x, a2=%02x, rd2=%08x, a3=%02x, we3=%b, wd3=%08x", $time, a1, rd1, a2, rd2, a3, we3, wd3);
    end

    // Waveform generation (VCD)
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_regfile);
    end

endmodule
