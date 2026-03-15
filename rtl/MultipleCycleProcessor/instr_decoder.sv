module instr_decoder
    (input logic[6:0] op,
     output logic[2:0] ImmSrc);

     always_comb
          case (op[6:4])
               3'b000 : ImmSrc = 3'b000;    // lw
               3'b001 : ImmSrc = 3'b000;    // addi/andi/ori/slti/xori
               3'b010 : ImmSrc = 3'b001;    // sw
               3'b011 : ImmSrc = op[2] ? 3'b011 : 3'bxxx;    // lui / R-Type 
               3'b110 : ImmSrc = op[2] ? 3'b100 : 3'b010;  // jal: J-type, beq: B-type
               default : ImmSrc = 3'b000;
          endcase
endmodule : instr_decoder

