module main_fsm_mc
     (input logic clk_i,
      input logic rst_ni,
      input logic[6:0] op,
      output logic Branch,
      output logic PCUpdate,
      output logic RegWrite,
      output logic MemWrite,
      output logic IRWrite,
      output logic[1:0] ResultSrc,
      output logic[1:0] ALUSrcB,
      output logic[1:0] ALUSrcA,
      output logic AdrSrc,
      output logic[1:0] ALUOp,
      output logic[3:0] state_q);

     typedef enum logic[3:0] {Fecth, Decode, MemAdr, MemRead, MemWB, MemWriteS, ExecuteR, ALUWB, Executel, JAL, BEQ, ExecuteLUI} t_estado;

     always_ff @(posedge clk_i or negedge rst_ni )
          if (!rst_ni)
               state_q <= Fecth;
          else 
               unique case (state_q)
                    Fecth : state_q <= Decode;
                    Decode : 
                         case (op)
                              7'b0000011, 7'b0100011 : state_q <= MemAdr;
                              7'b0110011 : state_q <= ExecuteR;
                              7'b0010011 : state_q <= Executel;
                              7'b1101111 : state_q <= JAL;
                              7'b1100011 : state_q <= BEQ;
                         endcase
                    MemAdr :
                         case (op)
                              7'b0000011: state_q <= MemRead;
                              7'b0100011: state_q <= MemWriteS;
                         endcase 
                    MemRead : state_q <= MemWB;
                    MemWB : state_q <= Fecth;
                    MemWriteS : state_q <= Fecth;
                    ExecuteR : state_q <= ALUWB;
                    ALUWB : state_q <= Fecth;
                    Executel : state_q <= ALUWB;
                    JAL : state_q <= ALUWB;
                    BEQ : state_q <= Fecth;
               endcase

     always_comb
          case (state_q)
               BEQ : Branch = 1'b1;
               default : Branch = 1'b0; 
          endcase

     always_comb
          case (state_q)
               Fecth : PCUpdate = 1'b1;
               JAL : PCUpdate = 1'b1;
               default : PCUpdate = 1'b0; 
          endcase

     always_comb
          case (state_q)
               MemWB : RegWrite = 1'b1;
               ALUWB : RegWrite = 1'b1;
               ExecuteLUI : RegWrite = 1'b1;
               default : RegWrite = 1'b0; 
          endcase

     always_comb
          case (state_q)
               MemWriteS : MemWrite = 1'b1;
               default : MemWrite = 1'b0; 
          endcase

     always_comb
          case (state_q)
               Fecth : IRWrite = 1'b1;
               default : IRWrite = 1'b0; 
          endcase
        
     always_comb
          case (state_q)
               Fecth : ResultSrc = 2'b10;
               MemRead : ResultSrc = 2'b00;
               MemWB : ResultSrc = 2'b01;
               MemWriteS : ResultSrc = 2'b00;
               ALUWB : ResultSrc = 2'b00;
               JAL : ResultSrc = 2'b00;
               BEQ : ResultSrc = 2'b00;
               ExecuteLUI : ResultSrc = 2'b11;
               default : ResultSrc = 2'b00; 
          endcase

     always_comb
          case (state_q)
               Fecth : ALUSrcB = 2'b10;
               Decode : ALUSrcB = 2'b01;
               MemAdr : ALUSrcB = 2'b01;
               ExecuteR : ALUSrcB = 2'b00;
               Executel : ALUSrcB = 2'b01;
               JAL : ALUSrcB = 2'b10;
               BEQ : ALUSrcB = 2'b00;
               default : ALUSrcB = 2'b00; 
          endcase

     always_comb
          case (state_q)
               Fecth : ALUSrcA = 2'b00;
               Decode : ALUSrcA = 2'b01;
               MemAdr : ALUSrcA = 2'b10;
               ExecuteR : ALUSrcA = 2'b10;
               Executel : ALUSrcA = 2'b10;
               JAL : ALUSrcA = 2'b01;
               BEQ : ALUSrcA = 2'b10;
               default : ALUSrcA = 2'b00; 
          endcase

     always_comb
          case (state_q)
               Fecth : AdrSrc = 1'b0;
               MemRead : AdrSrc = 1'b1;
               MemWriteS : AdrSrc = 1'b1;
               default : AdrSrc = 1'b0; 
          endcase

     always_comb
          case (state_q)
               Decode : ALUOp = 2'b00;
               MemAdr : ALUOp = 2'b00;
               ExecuteR : ALUOp = 2'b10;
               Executel : ALUOp = 2'b10;
               JAL : ALUOp = 2'b00;
               BEQ : ALUOp = 2'b01;
               default : ALUOp = 2'b00; 
          endcase
          
                

endmodule : main_fsm_mc
