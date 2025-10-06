module execute_cycle( input clk, rst, RegWriteE,FRegWrite_E,ALUSrcE,MemWriteE,ResultSrcE,BranchE,JumpE,FResultSrcE,
    input [3:0] ALUControlE,
    input [2:0] funct3E,
    input [6:0] OpE, 
    input [31:0] RD1_E, RD2_E,FRD1_E,FRD2_E, Imm_Ext_E,
    input [4:0] RD_E,
    input [31:0] PCE, PCPlus4E,
    input [31:0] ResultW,FPU_ResultW,
    input [1:0] ForwardA_E, ForwardB_E,
    input faddE,fsubE,fmulE,fdivE,floadE,fstoreE,fsqrtE,is_FOP,
    input o_p_waitrequest,
    output PCSrcE, RegWriteM, MemWriteM, ResultSrcM,
    output [4:0] RD_M,
    output [31:0] PCPlus4M, WriteDataM, ALU_ResultM,
    output [31:0] PCTargetE,
    output FRegWrite_M,
    output [31:0]FPU_ResultEM,
    output stall,fstoreM,floadM,FResultSrcM);

    wire [31:0] Src_A_ALU,Src_B_ALU,Src_A_FPU,Src_B_FPU, Src_B_FPU_interim,Src_B_ALU_interim;
    wire [31:0] ResultE,FResultE;
    wire ZeroE, NegativeE, OverFlowE, CarryE;
    wire BranchCondition;
    wire [31:0] BranchTarget, JumpTarget;
    reg RegWriteE_r, MemWriteE_r, FRegWrite_E_r,ResultSrcE_r, FResultSrcE_r;  
    reg [4:0] RD_E_r;
    reg [31:0] PCPlus4E_r, RD2_E_r, ResultE_r,FResultE_r;
    reg floadE_r, fstoreE_r;
    
    
    wire [2:0] FPUControl;
    assign FPUControl = (faddE) ? 3'b001 :    // Addition
                       (fsubE) ? 3'b001 :    // Subtraction (handled by negating B)
                       (fmulE) ? 3'b010 :    // Multiplication  
                       (fdivE) ? 3'b011 :    // Division
                       (fsqrtE) ? 3'b100 :   // Square root
                       3'b000;               // Default

    // Integer ALU forwarding
    Mux_3_by_1 alu_srca_mux (
        .a(RD1_E),
        .b(ResultW),
        .c(ALU_ResultM),
        .s(ForwardA_E),
        .d(Src_A_ALU)
    );

    Mux_3_by_1 alu_srcb_mux (
        .a(RD2_E),
        .b(ResultW),
        .c(ALU_ResultM),
        .s(ForwardB_E),
        .d(Src_B_ALU_interim)
    );

    // ALU Src Mux
    Mux alu_src_mux (
        .a(Src_B_ALU_interim),
        .b(Imm_Ext_E),
        .s(ALUSrcE||FResultSrcE),
        .c(Src_B_ALU)
    );

    // FPU forwarding
    Mux_3_by_1 fpu_srca_mux (
        .a(FRD1_E),
        .b(FPU_ResultW),
        .c(FPU_ResultEM),
        .s(ForwardA_E),
        .d(Src_A_FPU)
    );

    Mux_3_by_1 fpu_srcb_mux (
        .a(FRD2_E),
        .b(FPU_ResultW),
        .c(FPU_ResultEM),
        .s(ForwardB_E),
        .d(Src_B_FPU_interim)
    );

    // FPU Src Mux
    Mux fpu_src_mux (
        .a(Src_B_FPU_interim),
        .b(Imm_Ext_E),
        .s(ALUSrcE),
        .c(Src_B_FPU)
    );

    
    FPU fpu_unit(
        .clk(clk),              
        .rst_n(rst),
        .A(Src_A_FPU),
        .B(fsubE ? {~Src_B_FPU[31], Src_B_FPU[30:0]} : Src_B_FPU),
        .FResult(FResultE),
        .FPUControl(FPUControl),
        .stall(stall)
    );

    // Integer ALU Unit
    ALU alu (
        .A(Src_A_ALU),
        .B(Src_B_ALU),
        .Result(ResultE),
        .ALUControl(ALUControlE),
        .OverFlow(OverFlowE),
        .Carry(CarryE),
        .Zero(ZeroE),
        .Negative(NegativeE)
    );

   
    PC_Adder branch_adder (
        .a(PCE),
        .b(Imm_Ext_E),
        .c(BranchTarget)
    );

    
    assign JumpTarget = (OpE == 7'b1100111) ? (Src_A_ALU + Imm_Ext_E) :  
                       (PCE + Imm_Ext_E);                                  

  
    wire signed_less, unsigned_less;
    assign signed_less = (NegativeE ^ OverFlowE);  
    assign unsigned_less = ~CarryE;                
    
    assign BranchCondition = (funct3E == 3'b000) ? ZeroE :        // BEQ
                            (funct3E == 3'b001) ? ~ZeroE :       // BNE  
                            (funct3E == 3'b100) ? signed_less :  // BLT (signed)
                            (funct3E == 3'b101) ? ~signed_less : // BGE (signed)
                            (funct3E == 3'b110) ? unsigned_less : // BLTU (unsigned)
                            (funct3E == 3'b111) ? ~unsigned_less : // BGEU (unsigned)
                            1'b0;                                // Default

   
    assign PCTargetE = JumpE ? JumpTarget : BranchTarget;

  
    always @(posedge clk or negedge rst) begin
        if(rst == 1'b0) begin
            RegWriteE_r <= 1'b0; 
            MemWriteE_r <= 1'b0; 
            ResultSrcE_r <= 1'b0;
            FResultSrcE_r <= 1'b0; 
            RD_E_r <= 5'h00;
            PCPlus4E_r <= 32'h00000000; 
            RD2_E_r <= 32'h00000000; 
            ResultE_r <= 32'h00000000;
            FRegWrite_E_r <= 1'b0;
            FResultE_r <= 32'd0;
            floadE_r <= 0;
            fstoreE_r <= 0;
        end
        else if(!o_p_waitrequest && !stall) begin
            RegWriteE_r <= RegWriteE; 
            MemWriteE_r <= MemWriteE; 
            ResultSrcE_r <= ResultSrcE;
            FResultSrcE_r <= FResultSrcE;  
            RD_E_r <= RD_E;
            PCPlus4E_r <= PCPlus4E; 
            RD2_E_r <= (is_FOP) ? Src_B_FPU_interim : Src_B_ALU_interim; 
         
            ResultE_r <= (JumpE) ? PCPlus4E :                   
                        (OpE == 7'b0110111) ? Imm_Ext_E :       
                        (OpE == 7'b0010111) ? (PCE + Imm_Ext_E) : 
                        ResultE;                               
            FRegWrite_E_r <= FRegWrite_E;
            FResultE_r <= FResultE;
            floadE_r <= floadE;
            fstoreE_r <= fstoreE;
        end
    end

    // Output Assignments
    assign PCSrcE = (BranchE & BranchCondition) | JumpE;
    assign RegWriteM = RegWriteE_r;
    assign MemWriteM = MemWriteE_r;
    assign ResultSrcM = ResultSrcE_r;
    assign FResultSrcM = FResultSrcE_r; 
    assign RD_M = RD_E_r;
    assign PCPlus4M = PCPlus4E_r;
    assign WriteDataM = RD2_E_r;
    assign ALU_ResultM = ResultE_r;
    assign FRegWrite_M = FRegWrite_E_r;
    assign FPU_ResultEM = FResultE_r;
    assign floadM = floadE_r;
    assign fstoreM = fstoreE_r;

endmodule
