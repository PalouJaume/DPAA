//
// Microcredencial en Diseño de Procesadores con Arquitectura Abierta
// Cátedra UPM-INDRA en Microelectrónica
//
// Author: Alfonso Rodríguez <alfonso.rodriguezm@upm.es>
// Date: March 2025
//

module prop_regfile #(
    parameter int XLen = 32,
    parameter int NReg = 32,
    localparam int NRegWidth = $clog2(NReg)
) (
    input logic clk_i,
    input logic rst_ni,
    input logic [NRegWidth-1:0] a1_i,
    input logic [NRegWidth-1:0] a2_i,
    input logic [NRegWidth-1:0] a3_i,
    input logic we3_i,
    input logic [XLen-1:0] wd3_i,
    input logic [XLen-1:0] rd1_o,
    input logic [XLen-1:0] rd2_o,
    input logic [XLen-1:0] rf[NReg]
);

    // Iterate for all registers in the register file
    for (genvar i = 0; i < NReg; i++) begin : gen_a_nreg

        // Reset condition
        a_rst : assert property (@(posedge clk_i) !rst_ni |-> (rf[i] == '0));

        // Write enable deasserted
        a_rf_nop : assert property (@(posedge clk_i) disable iff (!rst_ni) !we3_i |=> (rf[i] == $past(rf[i])));

    end

    // Write enable asserted
    a_rf_we : assert property (@(posedge clk_i) disable iff (!rst_ni) we3_i |=> (rf[$past(a3_i)] == $past(wd3_i)));

    // Asynchronous reads
    a_rd1 : assert property (@(posedge clk_i) (rd1_o == ((a1_i == '0) ? '0 : rf[a1_i])));
    a_rd2 : assert property (@(posedge clk_i) (rd2_o == ((a2_i == '0) ? '0 : rf[a2_i])));

endmodule
