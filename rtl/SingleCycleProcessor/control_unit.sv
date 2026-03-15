module control_unit
     (input logic zero,
      input logic[6:0] op,
      input logic[2:0] funct3,
      input logic[6:0] func7,
      output logic PCSrc,
      output logic[1:0] ResultSrc,
      output logic MemWrite,
      output logic ALUSrc,
      output logic[2:0] ImmSrc,
      output logic RegWrite,
      output logic[2:0] ALUControl);

     // Señales
     logic[1:0] ALUOp;
     logic Branch;
     logic Jmp;

     always_comb
          PCSrc = Branch & zero | Jmp;

     // MAIN DECODER : START
     always_comb
          case (op[6:4])
               3'b000 : ResultSrc = 2'b01;  // lw
               3'b001 : ResultSrc = 2'b00;  // addi/andi/ori/slti/xori
               3'b010 : ResultSrc = 2'b00;  // sw
               3'b011 : ResultSrc = op[2] ? 2'b11 : 2'b00;  // R-Type
               3'b110 : ResultSrc = op[2] ? 2'b10 : 2'b00;  // jal: PC+4, beq: x
               default : ResultSrc = 2'b00;
          endcase

     always_comb
          case (op[6:4])
               3'b000 : MemWrite = 1'b0;   // lw
               3'b001 : MemWrite = 1'b0;   // addi/andi/ori/slti/xori
               3'b010 : MemWrite = 1'b1;   // sw
               3'b011 : MemWrite = 1'b0;   // R-Type / lui
               3'b110 : MemWrite = 1'b0;   // beq / jal
               default : MemWrite = 1'b0;
          endcase

     always_comb
          case (op[6:4])
               3'b000 : ALUSrc = 1'b1;     // lw
               3'b001 : ALUSrc = 1'b1;     // addi/andi/ori/slti/xori
               3'b010 : ALUSrc = 1'b1;     // sw
               3'b011 : ALUSrc = 1'b0;     // R-Type / lui
               3'b110 : ALUSrc = 1'b0;     // beq / jal
               default : ALUSrc = 1'b0;
          endcase

     always_comb
          case (op[6:4])
               3'b000 : ImmSrc = 3'b000;    // lw
               3'b001 : ImmSrc = 3'b000;    // addi/andi/ori/slti/xori
               3'b010 : ImmSrc = 3'b001;    // sw
               3'b011 : ImmSrc = op[2] ? 3'b011 : 3'bxxx;    // lui / R-Type 
               3'b110 : ImmSrc = op[2] ? 3'b100 : 3'b010;  // jal: J-type, beq: B-type
               default : ImmSrc = 3'b000;
          endcase

     always_comb
          case (op[6:4])
               3'b000 : RegWrite = 1'b1;   // lw
               3'b001 : RegWrite = 1'b1;   // addi/andi/ori/slti/xori
               3'b010 : RegWrite = 1'b0;   // sw
               3'b011 : RegWrite = 1'b1;   // R-Type / lui
               3'b110 : RegWrite = op[2];  // jal: 1, beq: 0
               default : RegWrite = 1'b0;
          endcase

     always_comb
          case (op[6:4])
               3'b000 : Branch = 1'b0;     // lw
               3'b001 : Branch = 1'b0;     // addi/andi/ori/slti/xori
               3'b010 : Branch = 1'b0;     // sw
               3'b011 : Branch = 1'b0;     // R-type / lui
               3'b110 : Branch = 1'b1;     // beq / jal
               default : Branch = 1'b0;
          endcase
     
     always_comb
          case (op[6:4])
               3'b000 : ALUOp = 2'b00;     // lw
               3'b001 : ALUOp = 2'b10;     // addi/andi/ori/slti/xori
               3'b010 : ALUOp = 2'b00;     // sw
               3'b011 : ALUOp = 2'b10;     // R-type / lui 
               3'b110 : ALUOp = 2'b01;     // beq / jal
               default : ALUOp = 2'b00;
          endcase

     always_comb
          case (op[6:4])
               3'b110 : Jmp = op[2];  // jal: 1, beq: 0
          default: Jmp = 1'b0;
    endcase
     // MAIN DECODER : END

     // ALU Decoder : START
     always_comb
          case (ALUOp)
               2'b00 : ALUControl = 3'b000; // lw / sw
               2'b10 : // I/R-type
                    case (funct3)
                         3'b000 : ALUControl = (op[5] & func7[5]) ? 3'b001 : 3'b000; // add / sub
                         3'b111 : ALUControl = 3'b010;      // and
                         3'b110 : ALUControl = 3'b011;      // or
                         3'b100 : ALUControl = 3'b100;      // xor
                         3'b010 : ALUControl = 3'b101;      // slt
                         default : ALUControl = 3'b000;      
                    endcase
               2'b01 : ALUControl = 3'b001;       // beq / jal
               default : ALUControl = 3'b000;
          endcase
     // ALU Decoder : END

endmodule : control_unit