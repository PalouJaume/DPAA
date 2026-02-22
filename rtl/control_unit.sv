module control_unit
     (input logic zero,
      input logic[6:0] op,
      input logic[2:0] funct3,
      input logic[6:0] func7,
      output logic PCSrc,
      output logic[1:0] ResultSrc,
      output logic MemWrite,
      output logic ALUSrc,
      output logic[1:0] ImmSrc,
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
               3'b000 : ResultSrc = 2'b01;  // add
               3'b001 : ResultSrc = 2'b00;  // addi/andi/ori/slti/xori
               3'b010 : ResultSrc = 2'b00;  // add
               3'b011 : ResultSrc = 2'b00;  // R-Type
               3'b110 : ResultSrc = op[2] ? 2'b10 : 2'b00;  // jal: PC+4, beq: x
               default : ResultSrc = 2'b00;
          endcase

     always_comb
          case (op[6:4])
               3'b000 : MemWrite = 1'b0;   // add
               3'b001 : MemWrite = 1'b0;   // addi/andi/ori/slti/xori
               3'b010 : MemWrite = 1'b1;   // add
               3'b011 : MemWrite = 1'b0;   // R-Type
               3'b110 : MemWrite = 1'b0;   // sub
               default : MemWrite = 1'b0;
          endcase

     always_comb
          case (op[6:4])
               3'b000 : ALUSrc = 1'b1;     // add
               3'b001 : ALUSrc = 1'b1;     // addi/andi/ori/slti/xori
               3'b010 : ALUSrc = 1'b1;     // add
               3'b011 : ALUSrc = 1'b0;     // R-Type
               3'b110 : ALUSrc = 1'b0;     // sub
               default : ALUSrc = 1'b0;
          endcase

     always_comb
          case (op[6:4])
               3'b000 : ImmSrc = 2'b00;    // add
               3'b001 : ImmSrc = 2'b00;    // addi/andi/ori/slti/xori
               3'b010 : ImmSrc = 2'b01;    // add
               3'b011 : ImmSrc = 2'bxx;    // R-Type
               3'b110 : ImmSrc = op[2] ? 2'b11 : 2'b10;  // jal: J-type, beq: B-type
               default : ImmSrc = 2'b00;
          endcase

     always_comb
          case (op[6:4])
               3'b000 : RegWrite = 1'b1;   // add
               3'b001 : RegWrite = 1'b1;   // addi/andi/ori/slti/xori
               3'b010 : RegWrite = 1'b0;   // add
               3'b011 : RegWrite = 1'b1;   // R-Type
               3'b110 : RegWrite = op[2];  // jal: 1, beq: 0
               default : RegWrite = 1'b0;
          endcase

     always_comb
          case (op[6:4])
               3'b000 : Branch = 1'b0;     // add
               3'b001 : Branch = 1'b0;     // addi/andi/ori/slti/xori
               3'b010 : Branch = 1'b0;     // add
               3'b011 : Branch = 1'b0;     // R-type
               3'b110 : Branch = 1'b1;     // sub
               default : Branch = 1'b0;
          endcase
     
     always_comb
          case (op[6:4])
               3'b000 : ALUOp = 2'b00;     // add
               3'b001 : ALUOp = 2'b10;     // addi/andi/ori/slti/xori
               3'b010 : ALUOp = 2'b00;     // add
               3'b011 : ALUOp = 2'b10;     // R-type
               3'b110 : ALUOp = 2'b01;     // sub
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
               2'b00 : ALUControl = 3'b000; // add (lw, sw)
               2'b10 : 
                    case (funct3)
                         3'b000 : ALUControl = (op[5] & func7[5]) ? 3'b001 : 3'b000; // add / sub
                         3'b111 : ALUControl = 3'b010;      // and
                         3'b110 : ALUControl = 3'b011;      // or
                         3'b100 : ALUControl = 3'b100;      // xor
                         3'b010 : ALUControl = 3'b101;      // slt
                         default : ALUControl = 3'b000;      
                    endcase
               2'b01 : ALUControl = 3'b001;       // sub (beq)
               default : ALUControl = 3'b000;
          endcase
     // ALU Decoder : END

endmodule : control_unit