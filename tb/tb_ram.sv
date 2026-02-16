//
// Microcredencial en Diseño de Procesadores con Arquitectura Abierta
// Cátedra UPM-INDRA en Microelectrónica
//
// Author: Alfonso Rodríguez <alfonso.rodriguezm@upm.es>
// Date: March 2025
//

module tb_ram;

    // Configure simulation
    timeunit 10ns;
    timeprecision 10ps;

    // Local parameters for the simulation
    localparam int DataWidth = 32;
    localparam int NPos = 128;
    localparam int NPosWidth = $clog2(NPos);
    localparam int Iterations = 2*NPos;

    // Signals for the simulation
    logic clk;
    logic [NPosWidth-1:0] a;
    logic we;
    logic [DataWidth-1:0] wd;
    logic [DataWidth-1:0] rd;

    // Instantiate UUT
    ram #(
        .DataWidth(DataWidth),
        .NPos(NPos)
    ) ram_i (
        .clk_i(clk),
        .a_i(a),
        .we_i(we),
        .wd_i(wd),
        .rd_o(rd)
    );

    // Bind SVA module to UUT
    bind ram prop_ram #(
        .DataWidth(DataWidth),
        .NPos(NPos)
    ) prop_ram_i (.*);

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #0.5 clk = ~clk;
    end

    // Stimuli generation
    initial begin
        // Reset state for inputs
        a = '0;
        we = 1'b0;
        wd = '0;

        #10 $display("[TESTBENCH] Simulation START");

        // Generate R/W operations
        for (int i = 0; i < Iterations; i++) begin
            a = i;
            we = 1'b1;
            wd = $urandom;
            #1 we = 1'b0;
            #1 ; //$display("[TESTBENCH] a=%03x, we=%b, wd=%08x, rd=%08x", a, we, wd, rd);
        end

        // End simulation
        #10 $display("[TESTBENCH] Simulation FINISH");
        $finish;
    end

    // Signal monitoring
    initial begin
        $monitor("[TESTBENCH] time=%0t, a=%02x, rd=%08x, we=%b, wd=%08x", $time, a, rd, we, wd);
    end

    // Waveform generation (VCD)
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_ram);
    end

endmodule
