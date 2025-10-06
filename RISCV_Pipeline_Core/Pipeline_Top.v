module Pipeline_top1(input clk, rst,
    output [15:0] Result);

    
    wire PCSrcE, RegWriteW, RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE, JumpE;
    wire RegWriteM, MemWriteM, ResultSrcM, ResultSrcW;
    wire [3:0] ALUControlE;
    wire [2:0] funct3E;
    wire [6:0] OpE;  
    wire [4:0] RD_E, RD_M, RDW;
    
    // Data signals
    wire [31:0] PCTargetE, InstrD, PCD, PCPlus4D, ResultW, RD1_E, RD2_E, Imm_Ext_E;
    wire [31:0] PCE, PCPlus4E, PCPlus4M, WriteDataM, ALU_ResultM;
    wire [31:0] PCPlus4W, ALU_ResultW, ReadDataW, FPU_ResultEW;
    wire [4:0] RS1_E, RS2_E;
    wire [1:0] ForwardBE, ForwardAE;
    
    // Floating point signals
    wire faddE, fsubE, fmulE, fdivE, floadE, fstoreE, fsqrtE, FRegWrite_E;
    wire [31:0] FPU_ResultEM, FRD1_E, FRD2_E, FResultW;
    wire FRegWrite_M, FRegWriteMW, floadM, fstoreM,FResultSrcE,FResultSrcM,FResultSrcW;
    
    // Pipeline control
    wire o_p_waitrequest, stall, is_FOP;
    wire StallF, StallD, FlushE,FlushD;
    
    assign Result = ResultW[15:0];

    fetch_cycle Fetch (
        .clk(clk), 
        .rst(rst), 
        .PCSrcE(PCSrcE), 
        .JumpE(JumpE),
        .PCTargetE(PCTargetE), 
        .InstrD(InstrD), 
        .PCD(PCD), 
        .PCPlus4D(PCPlus4D),
        .o_p_waitrequest(o_p_waitrequest),
        .stall(StallF)
    );

    decode_cycle Decode (
        .clk(clk), 
        .rst(rst), 
        .InstrDe(InstrD), 
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
        .o_p_waitrequest(o_p_waitrequest),
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
        .FlushD(FlushD)
    );

    execute_cycle Execute (
        .clk(clk), 
        .rst(rst), 
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
        .o_p_waitrequest(o_p_waitrequest),
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
        .stall(stall),
        .FPU_ResultW(FResultW),
        .is_FOP(is_FOP),
        .FRD1_E(FRD1_E),
        .FRD2_E(FRD2_E),
        .FResultSrcM(FResultSrcM)
    );

    memory_cycle Memory (
        .clk(clk), 
        .rst(rst), 
        .RegWriteM(RegWriteM), 
        .MemWriteM(MemWriteM), 
        .ResultSrcM(ResultSrcM), 
        .RD_M(RD_M), 
        .PCPlus4M(PCPlus4M), 
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
        .o_p_waitrequest(o_p_waitrequest),
        .FRegWriteMW(FRegWriteMW),
        .FPU_ResultEM(FPU_ResultEM),
        .FPU_ResultEW(FPU_ResultEW),
        .FRegWriteM(FRegWrite_M),
        .floadM(floadM),
        .fstoreM(fstoreM)
    );

    writeback_cycle WriteBack (
        .clk(clk), 
        .rst(rst), 
        .ResultSrcW(ResultSrcW), 
        .FResultSrcW(FResultSrcW),
        .PCPlus4W(PCPlus4W), 
        .ALU_ResultW(ALU_ResultW), 
        .ReadDataW(ReadDataW), 
        .ResultW(ResultW),
        .o_p_waitrequest(o_p_waitrequest),
        .fResultW(FResultW),
        .FPU_ResultW(FPU_ResultEW),
        .fReadDataW(32'b0)
    );

    hazard_unit Forwarding_block (
        .rst(rst), 
        .RegWriteM(RegWriteM),
        .FRegWriteM(FRegWrite_M), 
        .RegWriteW(RegWriteW),
        .FRegWriteW(FRegWriteMW),
        .RD_M(RD_M), 
        .RD_W(RDW),
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
        .FlushD(FlushD)
    );

endmodule
