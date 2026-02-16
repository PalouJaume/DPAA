//
// Microcredencial en Diseño de Procesadores con Arquitectura Abierta
// Cátedra UPM-INDRA en Microelectrónica
//
// Author: Alfonso Rodríguez <alfonso.rodriguezm@upm.es>
// Date: March 2025
//

module prop_alu #(
    parameter int XLen = 32,
    parameter int NOps = 5,
    localparam int NOpsWidth = $clog2(NOps)
) (
    input logic [XLen-1:0] a_i,
    input logic [XLen-1:0] b_i,
    input logic [NOpsWidth-1:0] alu_control_i,
    input logic [XLen-1:0] result_o,
    input logic zero_o
);

    // Clock generation (block is combinational, but SVAs require clocking condition)
    logic clk;
    initial begin
        clk = 1'b0;
        forever #0.5 clk = ~clk;
    end

    // Basic operation modes
    a_op_add : assert property (@(posedge clk) (alu_control_i == 'b000) |-> (result_o == (a_i + b_i)));
    a_op_sub : assert property (@(posedge clk) (alu_control_i == 'b001) |-> (result_o == (a_i - b_i)));
    a_op_and : assert property (@(posedge clk) (alu_control_i == 'b010) |-> (result_o == (a_i & b_i)));
    a_op_or  : assert property (@(posedge clk) (alu_control_i == 'b011) |-> (result_o == (a_i | b_i)));
    a_op_xor : assert property (@(posedge clk) (alu_control_i == 'b100) |-> (result_o == (a_i ^ b_i)));
    a_op_slt : assert property (@(posedge clk) (alu_control_i == 'b101) |-> (result_o == ((signed'(a_i) < signed'(b_i)) ? 1'b1 : 1'b0)));

    // Flags
    a_flag_z : assert property (@(posedge clk) (result_o == '0) |-> zero_o);

    // Undefined scenarios
    a_op_err : assert property (@(posedge clk) !(alu_control_i inside {'b000, 'b001, 'b010, 'b011, 'b100, 'b101}) |-> (result_o == '0));

endmodule
