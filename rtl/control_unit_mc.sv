module control_unit_mc
     (input logic clk_i,
      input logic rst_ni,
      input logic zero,
      input logic[6:0] op,
      input logic[2:0] funct3,
      input logic[6:0] funct7,
      output logic PCWrite,
      output logic AdrSrc,
      output logic MemWrite,
      output logic IRWrite,
      output logic[1:0] ResultSrc,
      output logic[2:0] ALUControl,
      output logic[1:0] ALUSrcB,
      output logic[1:0] ALUSrcA,
      output logic[2:0] ImmSrc,
      output logic RegWrite);

    logic[1:0] ALUOp;
    logic Branch;
    logic PCUpdate;
    logic[3:0] state_q;

    always_comb
        PCWrite = PCUpdate | (Branch & zero);

    main_fsm_mc MAIN_FSM(
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .op(op),
        .Branch(Branch),
        .PCUpdate(PCUpdate),
        .RegWrite(RegWrite),
        .MemWrite(MemWrite),
        .IRWrite(IRWrite),
        .ResultSrc(ResultSrc),
        .ALUSrcB(ALUSrcB),
        .ALUSrcA(ALUSrcA),
        .AdrSrc(AdrSrc),
        .ALUOp(ALUOp),
        .state_q(state_q)
        );

    alu_decoder_mc ALU_DECODER(
        .ALUOp(ALUOp),
        .op(op),
        .funct3(funct3),
        .funct7(funct7),
        .ALUControl(ALUControl)
        );

    instr_decoder INSTR_DECODER(
        .op(op),
        .ImmSrc(ImmSrc)
        );  


endmodule : control_unit_mc