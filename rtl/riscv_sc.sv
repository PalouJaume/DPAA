module riscv_sc
    #(parameter int XLen = 32,
      parameter int ILen = 32
    )
    (// Clock and reset
     input logic clk_i,
     input logic rst_ni,
     // Program memory interface
     output logic[XLen-1:0] pmem_addr_o,
     input logic[XLen-1:0] pmem_rdata_i,
     // Data memory interface
     output logic[XLen-1:0] dmem_addr_o,
     input logic[XLen-1:0] dmem_rdata_i,
     output logic dmem_we_o,
     output logic[XLen-1:0] dmem_wdata_o);

        // Nodos del circuito
        logic[XLen-1:0] pc_d, pc_q;
        logic[ILen-1:0] Instr;
        logic[XLen-1:0] SrcA;
        logic[XLen-1:0] SrcB;
        logic[XLen-1:0] ALUResult;
        logic[XLen-1:0] ReadData;
        logic[XLen-1:0] WriteData;
        logic[XLen-1:0] ImmExt;
        logic[XLen-1:0] Result;
        logic[XLen-1:0] PCTarget;
        logic[XLen-1:0] PCPlus4;
       
        // Nodos Control Unit
        logic zero; 
        logic PCSrc;
        logic[1:0] ResultSrc;
        logic MemWrite;
        logic ALUSrc;
        logic[2:0] ImmSrc;
        logic RegWrite;
        logic[2:0] ALUControl;

        always_ff @(posedge clk_i)
            if (!rst_ni)
                pc_q <= '0;
            else 
                pc_q <= pc_d;

        // PROGRAM MEMORY : START
        always_comb
            pmem_addr_o = pc_q;

        always_comb
            Instr = pmem_rdata_i;

        // PROGRAM MEMORY : END

        always_comb
            PCPlus4 = pc_q + 4;

        control_unit Control_Unit(.op(Instr[6:0]),
                                  .funct3(Instr[14:12]),
                                  .func7(Instr[31:25]),
                                  .*);

        regfile #() regfile_i(.clk_i(clk_i),
                                  .rst_ni(rst_ni),
                                  .a1_i(Instr[19:15]),
                                  .a2_i(Instr[24:20]),
                                  .a3_i(Instr[11:7]),
                                  .we3_i(RegWrite),
                                  .wd3_i(Result),
                                  .rd1_o(SrcA),
                                  .rd2_o(WriteData));

        always_comb
            case (ImmSrc)
                3'b000 : ImmExt = {{20{Instr[31]}}, Instr[31:20]};   // I-type
                3'b001 : ImmExt = {{20{Instr[31]}}, Instr[31:25], Instr[11:7]};  // S-Type
                3'b010 : ImmExt = {{19{Instr[31]}}, Instr[31], Instr[7], Instr[30:25], Instr[11:8], 1'b0}; // B-Type
                3'b011 : ImmExt = {Instr[31:12], 12'b0}; // U-Type
                3'b100 : ImmExt = {{12{Instr[31]}}, Instr[19:12], Instr[20], Instr[30:21], 1'b0}; // J-Type
                default : ImmExt = 'x;
            endcase

        always_comb
            case (ALUSrc)
                1'b0 : SrcB = WriteData;
                1'b1 : SrcB = ImmExt;
            endcase

        alu #() alu(.a_i(SrcA),
                    .b_i(SrcB),
                    .alu_control_i(ALUControl[2:0]),
                    .result_o(ALUResult),
                    .zero_o(zero));

        always_comb
            PCTarget = pc_q + ImmExt;

        // DATA MEMORY : START
        always_comb
            ReadData = dmem_rdata_i;

        always_comb
            dmem_addr_o = ALUResult;

        always_comb
            dmem_we_o = MemWrite;

        always_comb
            dmem_wdata_o = WriteData;
        // DATA MEMORY : END 

        always_comb
            case (ResultSrc)
                2'b00 : Result = ALUResult; // R-type
                2'b01 : Result = ReadData; // lw
                2'b10 : Result = PCPlus4; // jal
                2'b11 : Result = ImmExt; // lui
                default : Result = '0;
            endcase

        always_comb
            case (PCSrc) 
                1'b0 : pc_d = PCPlus4; // jal
                1'b1 : pc_d = PCTarget; // Normal flow
            endcase 

endmodule : riscv_sc
