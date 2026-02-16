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
            case (alu_control_i)
                 'b000 : result_o = a_i + b_i;
                 'b001 : result_o = a_i + ~b_i + 1;
                 'b010 : result_o = a_i & b_i;
                 'b011 : result_o = a_i | b_i;
                 'b101 : result_o = ($signed(a_i) < $signed(b_i)) ? 'd1 : 'd0;
                 default : result_o = 'b0;
            endcase

       always_comb
            zero_o = (result_o === '0) ? 1'b1 : 1'b0;

endmodule : alu