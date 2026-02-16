//
// Microcredencial en Diseño de Procesadores con Arquitectura Abierta
// Cátedra UPM-INDRA en Microelectrónica
//
// Author: Alfonso Rodríguez <alfonso.rodriguezm@upm.es>
// Date: March 2025
//

module tb_alu;

    // Configure simulation
    timeunit 10ns;
    timeprecision 10ps;

    // Local parameters for the simulation
    localparam int XLen = 32;
    localparam int NOps = 5;
    localparam int NOpsWidth = $clog2(NOps);
    localparam int Iterations = 16;

    // Data types for the simulation
    typedef enum logic [NOpsWidth-1:0] {
        OP_ADD = 'b000,
        OP_SUB = 'b001,
        OP_AND = 'b010,
        OP_OR  = 'b011,
        OP_SLT = 'b101,
        OP_ERR = 'b111
    } ops_e;

    // Signals for the simulation
    logic [XLen-1:0] a;
    logic [XLen-1:0] b;
    logic [NOpsWidth-1:0] alu_control;
    logic [XLen-1:0] result;
    logic zero;
    ops_e ops;

    // Instantiate UUT
    alu #(
        .XLen(XLen),
        .NOps(NOps)
    ) alu_i (
        .a_i(a),
        .b_i(b),
        .alu_control_i(alu_control),
        .result_o(result),
        .zero_o(zero)
    );

    // Bind SVA module to UUT
    bind alu prop_alu #(
        .XLen(XLen),
        .NOps(NOps)
    ) prop_alu_i (.*);

    // Stimuli generation
    initial begin
        // Reset state
        a = '0;
        b = '0;
        alu_control = OP_ADD;

        #10 $display("[TESTBENCH] Simulation START");

        // Core evaluation
        ops = ops.first;
        do begin
            $display("[TESTBENCH] Current OP: %s", ops.name);
            for (int i = 0; i < Iterations; i++) begin
                for (int j = 0; j < Iterations; j++) begin
                    alu_control = ops;
                    a = $urandom;
                    b = $urandom;
                    #1 ; //$display("[TESTBENCH] a=%08x, b=%08x, alu_control=%03b, result=%08x, zero=%b", a, b, alu_control, result, zero);
                end
            end
            ops = ops.next;
        end while (ops != ops.first);

        // End simulation
        #10 $display("[TESTBENCH] Simulation FINISH");
        $finish;
    end

    // Signal monitoring
    initial begin
        $monitor("[TESTBENCH] time=%0t, a=%08x, b=%08x, alu_control=%03b, result=%08x, zero=%b", $time, a, b, alu_control, result, zero);
    end

    // Waveform generation (VCD)
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_alu);
    end

endmodule
