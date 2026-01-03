module Pipeline_top1(
    input clk, 
    input rst_n,
    output [15:0] Result
);

    // ----------------------------
    // Control signals between stages
    // ----------------------------
    wire PCSrcE;           // Branch or Jump control from execute stage
    wire RegWriteW, RegWriteE;
    wire ALUSrcE, MemWriteE, ResultSrcE;
    wire BranchE, JumpE;
    wire ResultSrcR, pass_2;
    wire RegWriteM, MemWriteM, ResultSrcM, ResultSrcW;
    wire finish, pass, write_ready, read_ready, stall_WB, finish1;
    wire [3:0] ALUControlE;
    wire [2:0] funct3E;
    wire [6:0] OpE;
    
    // ----------------------------
    // Register IDs and counters
    // ----------------------------
    wire [4:0] RD_E, RD_M, RDW, Rs1_D, Rs2_D;
    wire [4:0] counter, counter_1, counter1;

    // ----------------------------
    // Data signals between stages
    // ----------------------------
    wire [31:0] PCTargetE, InstrD, PCD, PCPlus4D, ResultW, RD1_E, RD2_E, Imm_Ext_E;
    wire [31:0] InstrDM, InstrDE, instr;
    wire [31:0] PCE, PCPlus4E, PCPlus4M, WriteDataM, ALU_ResultM;
    wire [31:0] PCPlus4W, ALU_ResultW, ReadDataW, FPU_ResultEW, InstrME;
    wire [4:0] RS1_E, RS2_E, DRDW, tag_data, mem_tag, DRDW_1, DRDW_2, DRDW_3;
    wire [1:0] ForwardBE, ForwardAE;

    // ----------------------------
    // Floating point signals
    // ----------------------------
    wire faddE, fsubE, fmulE, fdivE, floadE, fstoreE, fsqrtE, FRegWrite_E;
    wire [31:0] FPU_ResultEM, FRD1_E, FRD2_E, FResultW;
    wire FRegWrite_M, FRegWriteMW, floadM, fstoreM;
    wire FResultSrcE, FResultSrcM, FResultSrcW;
    
    // Flags for store instructions
    wire is_store  = (InstrDM[6:0]==7'b0100011 || InstrDM[6:0]==7'b0100111)?1:0;
    wire is_store_1= (InstrDE[6:0]==7'b0100011 || InstrDE[6:0]==7'b0100111)?1:0;

    // Pipeline control signals
    wire o_p_waitrequest, stall, is_FOP;
    wire StallF, StallD, FlushE, FlushD, o_p_readdata_valid;
    wire [31:0] fReadDataW;

    // Assign the top-level output
    assign Result = ResultW[15:0];

    // Stall in execute stage if decode stage is stalled
    wire stallE = (StallD) ? 1 : 0;

    // ----------------------------
    // Fetch stage instance
    // ----------------------------
    fetch_cycle Fetch (
        .clk(clk), 
        .rst_n(rst_n), 
        .PCSrcE(PCSrcE), 
        .JumpE(JumpE),
        .PCTargetE(PCTargetE), 
        .InstrD(InstrD), 
        .PCD(PCD), 
        .PCPlus4D(PCPlus4D),
        .stall(StallF),
        .stall_f(stall),
        .pass(pass),
        .is_FOP(is_FOP)
    );

    // ----------------------------
    // Decode stage instance
    // ----------------------------
    decode_cycle Decode (
        .clk(clk), 
        .rst_n(rst_n), 
        .InstrDe(InstrD),
        .FResultSrcW(FResultSrcW),
        .PCD(PCD), 
        .PCPlus4D(PCPlus4D), 
        .RegWriteW(RegWriteW), 
        .RDW(RDW), 
        .ResultW(ResultW), 
        .RegWriteE(RegWriteE), 
        .ALUSrcE(ALUSrcE), 
        .MemWriteE(MemWriteE), 
        .ResultSrcE(ResultSrcE),
        .BranchE(BranchE),
        .JumpE(JumpE),
        .ALUControlE(ALUControlE), 
        .funct3E(funct3E),
        .OpE(OpE), 
        .RD1_E(RD1_E), 
        .RD2_E(RD2_E), 
        .Imm_Ext_E(Imm_Ext_E), 
        .RD_E(RD_E), 
        .PCE(PCE), 
        .PCPlus4E(PCPlus4E),
        .RS1_E(RS1_E),
        .RS2_E(RS2_E),
        .stall(StallD),
        .faddE(faddE),
        .fsubE(fsubE),
        .fmulE(fmulE),
        .fdivE(fdivE),
        .floadE(floadE),
        .fstoreE(fstoreE),
        .fsqrtE(fsqrtE),
        .FRD1_E(FRD1_E),
        .FRD2_E(FRD2_E),
        .FRegWrite_E(FRegWrite_E),
        .FRegWriteW(FRegWriteMW),
        .is_FOP(is_FOP),
        .FResultSrcE(FResultSrcE),
        .FlushD(FlushD),
        .InstrDE(InstrDE),
        .Rs1_D(Rs1_D),
        .Rs2_D(Rs2_D),
        .fResultW(FResultW),
        .stall_f(stall),
        .finish(finish),
        .ResultSrcD(ResultSrcD),
        .pass(pass),
        .counter1(counter1)
    );

    // ----------------------------
    // Execute stage instance
    // ----------------------------
    execute_cycle Execute (
        .clk(clk), 
        .rst_n(rst_n), 
        .RegWriteE(RegWriteE), 
        .ALUSrcE(ALUSrcE), 
        .MemWriteE(MemWriteE), 
        .ResultSrcE(ResultSrcE), 
        .BranchE(BranchE),
        .JumpE(JumpE),
        .ALUControlE(ALUControlE), 
        .funct3E(funct3E),
        .OpE(OpE),  
        .RD1_E(RD1_E), 
        .RD2_E(RD2_E), 
        .Imm_Ext_E(Imm_Ext_E), 
        .RD_E(RD_E), 
        .PCE(PCE), 
        .PCPlus4E(PCPlus4E), 
        .PCSrcE(PCSrcE), 
        .PCTargetE(PCTargetE), 
        .RegWriteM(RegWriteM), 
        .MemWriteM(MemWriteM), 
        .ResultSrcM(ResultSrcM), 
        .RD_M(RD_M), 
        .PCPlus4M(PCPlus4M), 
        .WriteDataM(WriteDataM), 
        .ALU_ResultM(ALU_ResultM),
        .ResultW(ResultW),
        .ForwardA_E(ForwardAE),
        .ForwardB_E(ForwardBE),
        .faddE(faddE),
        .fsubE(fsubE),
        .fmulE(fmulE),
        .fdivE(fdivE),
        .FResultSrcE(FResultSrcE),
        .floadE(floadE),
        .fstoreE(fstoreE),
        .fsqrtE(fsqrtE),
        .FRegWrite_E(FRegWrite_E),
        .FRegWrite_M(FRegWrite_M),
        .FPU_ResultEM(FPU_ResultEM),
        .floadM(floadM),
        .fstoreM(fstoreM),
        .stall_f(stall),
        .FPU_ResultW(FResultW),
        .is_FOP(is_FOP),
        .FRD1_E(FRD1_E),
        .FRD2_E(FRD2_E),
        .FResultSrcM(FResultSrcM),
        .InstrDE(InstrDE),
        .InstrDM(InstrDM),
        .finish(finish),
        .stallE(stallE),
        .pass(pass),
        .finish1(finish1)
    );

    // ----------------------------
    // Memory stage instance
    // ----------------------------
    memory_cycle Memory (
        .clk(clk), 
        .rst_n(rst_n), 
        .RegWriteM(RegWriteM),
        .MemWriteM(MemWriteM), 
        .ResultSrcM(ResultSrcM), 
        .RD_M(RD_M), 
        .PCPlus4M(PCPlus4M), 
        .stall(StallD),
        .WriteDataM(WriteDataM), 
        .ALU_ResultM(ALU_ResultM), 
        .RegWriteW(RegWriteW), 
        .ResultSrcW(ResultSrcW), 
        .FResultSrcM(FResultSrcM),
        .FResultSrcW(FResultSrcW),
        .RD_W(RDW), 
        .PCPlus4W(PCPlus4W), 
        .ALU_ResultW(ALU_ResultW), 
        .ReadDataW(ReadDataW),
        .FRegWriteMW(FRegWriteMW),
        .FPU_ResultEM(FPU_ResultEM),
        .FPU_ResultEW(FPU_ResultEW),
        .FRegWriteM(FRegWrite_M),
        .InstrDM(InstrDM),
        .fReadDataW(fReadDataW),
        .DRDW(DRDW),
        .instr(instr),
        .counter(counter),
        .counter_1(counter_1),
        .pass(pass)
    );

    // ----------------------------
    // Writeback stage instance
    // ----------------------------
    writeback_cycle WriteBack (
        .ResultSrcW(ResultSrcW), 
        .FResultSrcW(FResultSrcW),
        .PCPlus4W(PCPlus4W), 
        .ALU_ResultW(ALU_ResultW), 
        .ReadDataW(ReadDataW), 
        .ResultW(ResultW),
        .fResultW(FResultW),
        .FPU_ResultW(FPU_ResultEW),
        .fReadDataW(fReadDataW),
        .ResultSrcR(ResultSrcR)
    );

    // ----------------------------
    // Hazard detection and forwarding unit
    // ----------------------------
    hazard_unit Forwarding_block (
        .clk(clk),
        .rst_n(rst_n), 
        .RegWriteM(RegWriteM),
        .FRegWriteM(FRegWrite_M), 
        .RegWriteW(RegWriteW),
        .FRegWriteW(FRegWriteMW),
        .RD_M(RD_M), 
        .RD_W(RDW),
        .DRD_W(DRDW),
        .RD_E(RD_E),
        .Rs1_E(RS1_E), 
        .Rs2_E(RS2_E), 
        .ResultSrcE(ResultSrcE),
        .ForwardAE(ForwardAE), 
        .ForwardBE(ForwardBE),
        .StallF(StallF),
        .StallD(StallD),
        .FlushE(FlushE),
        .PCSrcE(PCSrcE),
        .FlushD(FlushD),
        .Rs2_D(Rs2_D),
        .Rs1_D(Rs1_D),
        .ResultSrcM(ResultSrcM),
        .ResultSrcD(ResultSrcD),
        .InstrDE(InstrDE),
        .pass(pass),
        .InstrD(InstrD),
        .counter(counter),
        .counter_1(counter_1),
        .is_store(is_store),
        .counter1(counter1),
        .is_FOP(is_FOP),
        .finish1(finish1),
        .is_store_1(is_store_1)
    );

endmodule
