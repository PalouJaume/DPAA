//
// Microcredencial en Diseño de Procesadores con Arquitectura Abierta
// Cátedra UPM-INDRA en Microelectrónica
//
// Author: Alfonso Rodríguez <alfonso.rodriguezm@upm.es>
// Date: March 2025
//

module prop_ram #(
    parameter int DataWidth = 32,
    parameter int NPos = 1024,
    localparam int NPosWidth = $clog2(NPos)
) (
    input logic clk_i,
    input logic [NPosWidth-1:0] a_i,
    input logic we_i,
    input logic [DataWidth-1:0] wd_i,
    input logic [DataWidth-1:0] rd_o,
    input logic [DataWidth-1:0] mem[NPos]
);

    // Iterate for all positions in the RAM memory
    for (genvar i = 0; i < NPos; i++) begin : gen_a_npos

        // TODO: assert initial value (unknown)

        // Write enable deasserted
        a_ram_nop : assert property (@(posedge clk_i)!we_i |=> (mem[i] == $past(mem[i])));

    end

    // Write enable asserted
    a_ram_we : assert property (@(posedge clk_i) we_i |=> (mem[$past(a_i)] == $past(wd_i)));

    // Asynchronous read
    a_ram_rd : assert property (@(posedge clk_i) (rd_o == mem[a_i]));

endmodule
