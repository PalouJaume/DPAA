module alu
     #(parameter int XLen = 32,
       parameter int NOps = 5,
       localparam int NOpsWidth = $clog2(NOps))

      (input logic[XLen-1:0] a_i,
       input logic[XLen-1:0] b_i,
       input logic[NOpsWidth-1:0] alu_control_i,
       output logic[XLen-1:0] result_o,
       output logic zero_o);

       always_comb
           begin
                zero_o = 1'b0;
                result_o = '0;
           end

endmodule : alu