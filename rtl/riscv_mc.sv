module riscv_mc
     #(
        parameter int XLen = 32,
        parameter int ILen = 32,
        localparam int Len = (XLen > ILen) ? XLen : ILen
     )
     (
        // Clock and reset
        input logic clk_i,
        input logic rst_ni,
        // Program/data memory interface
        output logic[Len-1:0] mem_addr_o,
        input logic[XLen-1:0] mem_rdata_i,
        output logic mem_we_o,
        output logic[Len-1:0] mem_wdata_o
    );
    
        // Nodos del circuito
        logic[Len-1:0] pc_q;
        logic[ILen-1:0] ir_q;
        logic[XLen-1:0] SrcA;
        logic[XLen-1:0] SrcB;
        logic[XLen-1:0] ReadData;
        logic[XLen-1:0] ImmExt;
        logic[XLen-1:0] Result;

        // Nodos Control Unit
        logic zero; 
        logic PCWrite;
        logic AdrSrc;
        logic MemWrite;
        logic IRWrite;
        logic[1:0] ResultSrc;
        logic[2:0] ALUControl;
        logic[1:0] ALUSrcB;
        logic[1:0] ALUSrcA;
        logic[2:0] ImmSrc;
        logic RegWrite;

        // Reegistro Pre registros
        logic[XLen-1:0] OldPC;

        // Registro PreALU
        logic[XLen-1:0] A_d;
        logic[XLen-1:0] A_q;

        logic[XLen-1:0] WriteData_d;
        logic[XLen-1:0] WriteData_q;

        // Registro PostALU
        logic[XLen-1:0] ALUResult;
        logic[XLen-1:0] ALUResult_q;

        // Registro Data
        logic[XLen-1:0] Data;

        // Registro PC
        always_ff @(posedge clk_i or negedge rst_ni)
            if (!rst_ni)
                pc_q <= '0;
            else
                if (PCWrite) 
                    pc_q <= Result; 

        // Multiplexor postRegistro PC
        always_comb
            case (AdrSrc)
                1'b0 : mem_addr_o = pc_q;
                1'b1 : mem_addr_o = Result;
                default : mem_addr_o = 'x; 
            endcase

        // Interfaz memoria de datos/instrucciones
        always_comb
            mem_we_o = MemWrite; // MemWrite;

        always_comb
            mem_wdata_o = WriteData_q; // WriteData_q;

        always_comb
            ReadData = mem_rdata_i; // mem_addr_i;

        // Resgistro postMemoria de Instrucciones/PC
        always_ff @(posedge clk_i or negedge rst_ni)
            if (!rst_ni)
                OldPC <= '0;
            else if (IRWrite)
                OldPC <= pc_q;

        always_ff @(posedge clk_i or negedge rst_ni)
            if (!rst_ni)
                ir_q <= '0;
            else if (IRWrite)
                ir_q <= ReadData;

        // Registro postMemoria de datos
        always_ff @(posedge clk_i or negedge rst_ni)
            if (!rst_ni)
                Data <= '0;
            else
                Data <= ReadData;

        regfile #(.XLen(XLen)) regfile_i(
                            .clk_i(clk_i),
                            .rst_ni(rst_ni),
                            .a1_i(ir_q[19:15]),
                            .a2_i(ir_q[24:20]),
                            .a3_i(ir_q[11:7]),
                            .we3_i(RegWrite),
                            .wd3_i(Result),
                            .rd1_o(A_d),
                            .rd2_o(WriteData_d));

        control_unit_mc cu_i(    
                                  .clk_i(clk_i),
                                  .rst_ni(rst_ni),
                                  .op(ir_q[6:0]),
                                  .funct3(ir_q[14:12]),
                                  .funct7(ir_q[31:25]),
                                  .zero(zero),
                                  .PCWrite(PCWrite),
                                  .AdrSrc(AdrSrc),
                                  .MemWrite(MemWrite),
                                  .IRWrite(IRWrite),
                                  .ResultSrc(ResultSrc),
                                  .ALUControl(ALUControl),
                                  .ALUSrcB(ALUSrcB),
                                  .ALUSrcA(ALUSrcA),
                                  .ImmSrc(ImmSrc),
                                  .RegWrite(RegWrite));

        always_comb
            case (ImmSrc)
                3'b000 : ImmExt = {{20{ir_q[31]}}, ir_q[31:20]};   // I-type
                3'b001 : ImmExt = {{20{ir_q[31]}}, ir_q[31:25], ir_q[11:7]};  // S-Type
                3'b010 : ImmExt = {{19{ir_q[31]}}, ir_q[31], ir_q[7], ir_q[30:25], ir_q[11:8], 1'b0}; // B-Type
                3'b011 : ImmExt = {ir_q[31:12], 12'b0}; // U-Type
                3'b100 : ImmExt = {{12{ir_q[31]}}, ir_q[19:12], ir_q[20], ir_q[30:21], 1'b0}; // J-Type
                default : ImmExt = 'x;
            endcase

        // Registros preALU
        always_ff @(posedge clk_i or negedge rst_ni)
            if (!rst_ni)
                A_q <= '0;
            else 
                A_q <= A_d;
        
        always_ff @(posedge clk_i or negedge rst_ni)
            if (!rst_ni)
                WriteData_q <= '0;
            else
                WriteData_q <= WriteData_d;

        // Multiplexores PreALU
        always_comb
            case (ALUSrcA)
                2'b00 : SrcA = pc_q;
                2'b01 : SrcA = OldPC;
                2'b10 : SrcA = A_q;
                default : SrcA = 'x;
            endcase

        always_comb
            case (ALUSrcB)
                2'b00 : SrcB = WriteData_q;
                2'b01 : SrcB = ImmExt;
                2'b10 : SrcB = 4;
                default : SrcB = 'x;
            endcase

        // ALU
        alu ALU_i(.a_i(SrcA),
                  .b_i(SrcB),
                  .alu_control_i(ALUControl),
                  .result_o(ALUResult),
                  .zero_o(zero));   

        // Registro PostALU
        always_ff @(posedge clk_i or negedge rst_ni)
            if (!rst_ni)
                ALUResult_q <= '0;
            else
                ALUResult_q <= ALUResult;

        // Multiplexores PostALU
        always_comb
            case (ResultSrc)
                2'b00 : Result = ALUResult_q;
                2'b01 : Result = Data;
                2'b10 : Result = ALUResult;
                2'b11 : Result = ImmExt;
                default : Result = 'x;
            endcase

endmodule : riscv_mc