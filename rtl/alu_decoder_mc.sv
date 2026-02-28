module alu_decoder_mc
    (input logic[1:0] ALUOp,
     input logic[6:0] op,
     input logic[2:0] funct3,
     input logic[6:0] funct7,
     output logic[2:0] ALUControl);

     // TODO: REVISA ESTO, parece funcionar pero es un poco enrevesado. Considera simplificarlo si es posible.
     always_comb
          case (ALUOp)
               2'b00 : ALUControl = 3'b000; // lw / sw
               2'b10 : // I/R-type
                    case (funct3)
                         3'b000 : ALUControl = (op[5] & funct7[5]) ? 3'b001 : 3'b000; // add / sub
                         3'b111 : ALUControl = 3'b010;      // and
                         3'b110 : ALUControl = 3'b011;      // or
                         3'b100 : ALUControl = 3'b100;      // xor
                         3'b010 : ALUControl = 3'b101;      // slt
                         default : ALUControl = 3'b000;      
                    endcase
               2'b01 : ALUControl = 3'b001;       // beq / jal
               default : ALUControl = 3'b000;
          endcase
endmodule : alu_decoder_mc