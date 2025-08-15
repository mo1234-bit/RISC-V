

module execute_cycle( input clk, rst, RegWriteE,FRegWrite_E,ALUSrcE,MemWriteE,ResultSrcE,BranchE,
    input [2:0] ALUControlE,
    input [31:0] RD1_E, RD2_E, Imm_Ext_E,
    input [4:0] RD_E,
    input [31:0] PCE, PCPlus4E,
    input [31:0] ResultW,FPU_ResultW,
    input [1:0] ForwardA_E, ForwardB_E,
    output PCSrcE, RegWriteM, MemWriteM, ResultSrcM,
    output [4:0] RD_M,
    output [31:0] PCPlus4M, WriteDataM, ALU_ResultM,
    output [31:0] PCTargetE,
    input o_p_waitrequest,
    output FRegWrite_M,
    output [31:0]FPU_ResultEM,
     input faddE,fsubE,fmulE,fdivE,floadE,fstoreE,fsqrtE,output stall,fstoreM,floadM);

    wire [31:0] Src_A, Src_B_interim, Src_B;
    wire [31:0] ResultE,FResultE;
    wire ZeroE;
    reg RegWriteE_r, MemWriteE_r, FRegWrite_E_r,ResultSrcE_r;
    reg [4:0] RD_E_r;
    reg [31:0] PCPlus4E_r, RD2_E_r, ResultE_r,FResultE_r;
    reg  floadE_r, fstoreE_r;
    wire [2:0]FPUControl;
    assign FPUControl=(faddE)?3'b001:(fsubE)?3'b111:(fmulE)?3'b010:(fdivE)?3'b011:(fsqrtE)?3'b100:3'b000;


    Mux_3_by_1 srca_mux (
                        .a(RD1_E),
                        .b(ResultW),
                        .c(ALU_ResultM),
                        .s(ForwardA_E),
                        .d(Src_A)
                        );

    // 3 by 1 Mux for Source B
    Mux_3_by_1 srcb_mux (
                        .a(RD2_E),
                        .b(ResultW),
                        .c(ALU_ResultM),
                        .s(ForwardB_E),
                        .d(Src_B_interim)
                        );
    // ALU Src Mux
    Mux alu_src_mux (
            .a(Src_B_interim),
            .b(Imm_Ext_E),
            .s(ALUSrcE),
            .c(Src_B)
            );

    FPU fbu(
        .rst_n(rst),
        .A(Src_A),
            .B(Src_B),
            .FResult(FResultE),
            .FPUControl(FPUControl),
            .stall(stall)
            );

    // ALU Unit
    ALU alu (
            .A(Src_A),
            .B(Src_B),
            .Result(ResultE),
            .ALUControl(ALUControlE),
            .OverFlow(),
            .Carry(),
            .Zero(ZeroE),
            .Negative()
            );

    // Adder
    PC_Adder branch_adder (
            .a(PCE),
            .b(Imm_Ext_E),
            .c(PCTargetE)
            );

    // Register Logic
    always @(posedge clk or negedge rst) begin
        if(rst == 1'b0) begin
            RegWriteE_r <= 1'b0; 
            MemWriteE_r <= 1'b0; 
            ResultSrcE_r <= 1'b0;
            RD_E_r <= 5'h00;
            PCPlus4E_r <= 32'h00000000; 
            RD2_E_r <= 32'h00000000; 
            ResultE_r <= 32'h00000000;
            FRegWrite_E_r<=1'b0;
            FResultE_r<=32'd0;
            floadE_r<=0;
            fstoreE_r<=0;
        end
        else if(!o_p_waitrequest) begin
            RegWriteE_r <= RegWriteE; 
            MemWriteE_r <= MemWriteE; 
            ResultSrcE_r <= ResultSrcE;
            RD_E_r <= RD_E;
            PCPlus4E_r <= PCPlus4E; 
            RD2_E_r <= Src_B_interim; 
            ResultE_r <= ResultE;
            FRegWrite_E_r<=FRegWrite_E;
            FResultE_r<=FResultE;
            floadE_r<= floadE;
            fstoreE_r<=fstoreE;
        end
    end

    // Output Assignments
    assign PCSrcE = ZeroE &  BranchE;
    assign RegWriteM = RegWriteE_r;
    assign MemWriteM = MemWriteE_r;
    assign ResultSrcM = ResultSrcE_r;
    assign RD_M = RD_E_r;
    assign PCPlus4M = PCPlus4E_r;
    assign WriteDataM = RD2_E_r;
    assign ALU_ResultM = ResultE_r;
    assign FRegWrite_M=FRegWrite_E_r;
    assign FPU_ResultEM=FResultE_r;
    assign floadM= floadE_r;
    assign fstoreM= fstoreE_r;


endmodule