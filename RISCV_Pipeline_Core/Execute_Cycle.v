module execute_cycle(
    input clk, rst_n,
    // Control signals from decode stage
    input RegWriteE, FRegWrite_E, ALUSrcE, MemWriteE, ResultSrcE, BranchE, JumpE, FResultSrcE,pass_load,
    input stallE,

    // ALU control and instruction info
    input [3:0] ALUControlE,
    input [2:0] funct3E,
    input [6:0] OpE,
    
    // Data and registers from decode
    input [31:0] RD1_E, RD2_E, FRD1_E, FRD2_E, Imm_Ext_E,
    input [4:0] RD_E,
    input [31:0] PCE, PCPlus4E, InstrDE,
    
    // Forwarding data from later stages
    input [31:0] ResultW, FPU_ResultW,
    input [1:0] ForwardA_E, ForwardB_E,ForwardA_E_FPU,ForwardB_E_FPU,
    
    // FPU control signals
    input faddE, fsubE, fmulE, fdivE, floadE, fstoreE, fsqrtE,
    input is_FOP, pass,
    
    // Outputs to next pipeline stage
    output PCSrcE, RegWriteM, MemWriteM, ResultSrcM, finish, finish1,JumpM,
    output [4:0] RD_M,Rs1_M,Rs2_M,
    output [31:0] PCPlus4M, WriteDataM, ALU_ResultM,
    output [31:0] PCTargetE,
    output FRegWrite_M,
    output [31:0] FPU_ResultEM, InstrDM,
    output stall_f, fstoreM, floadM, FResultSrcM,

  //  Branch prediction feedback signals
    output exec_is_branch,        // Is this instruction a branch?
    output exec_actual_taken,     // Was branch taken?
    output [31:0] exec_pc         // PC of this branch
);

    // ----------------------------
    // Wires for ALU/FPU inputs
    // ----------------------------
    wire [31:0] Src_A_ALU, Src_B_ALU;             // Integer ALU operands
    wire [31:0] Src_A_FPU, Src_B_FPU, Src_B_FPU_interim, Src_B_ALU_interim; // FPU operands
    wire [31:0] ResultE, FResultE;               // ALU and FPU results
  
    // Status signals from ALU
    wire ZeroE, NegativeE, OverFlowE, CarryE;
    wire finish2, finish_div2, finish_adder, finish_div, finish_mul, finish_sqr;
    
    wire BranchCondition;
    wire [31:0] BranchTarget, JumpTarget;

    // Registers to hold outputs to memory stage
    reg RegWriteE_r, MemWriteE_r, FRegWrite_E_r, ResultSrcE_r, FResultSrcE_r;
    reg [4:0] RD_E_r,Rs1_E_r, Rs2_E_r;
    reg [31:0] PCPlus4E_r, RD2_E_r, ResultE_r, FResultE_r, InstrDE_r;
    reg floadE_r, fstoreE_r,JumpM_r;

    wire stall_f_buf;
    wire [2:0] FPUControl;

      // A branch instruction is being executed
    assign exec_is_branch = BranchE;
    // ----------------------------
    // Determine FPU operation type
    // ----------------------------
    assign FPUControl = (faddE) ? 3'b001 :    // FPU addition
                        (fsubE) ? 3'b001 :    // FPU subtraction (negate B handled later)
                        (fmulE) ? 3'b010 :    // FPU multiplication
                        (fdivE) ? 3'b011 :    // FPU division
                        (fsqrtE) ? 3'b100 :   // FPU square root
                        3'b000;               // Default (no FPU op)

    // ----------------------------
    // Integer ALU Forwarding Muxes
    // ----------------------------
    Mux_3_by_1 alu_srca_mux (
        .a(RD1_E),
        .b(ResultW),
        .c(ALU_ResultM),
        .s(ForwardA_E ),
        .d(Src_A_ALU)
    );

    Mux_3_by_1 alu_srcb_mux (
        .a(RD2_E),
        .b(ResultW),
        .c(ALU_ResultM),
        .s(ForwardB_E),
        .d(Src_B_ALU_interim)
    );

    // ALU source selection (immediate vs register)
    Mux alu_src_mux (
        .a(Src_B_ALU_interim),
        .b(Imm_Ext_E),
        .s(ALUSrcE || FResultSrcE),
        .c(Src_B_ALU)
    );

    // ----------------------------
    // FPU Forwarding Muxes
    // ----------------------------
    Mux_3_by_1 fpu_srca_mux (
        .a(FRD1_E),
        .b(FPU_ResultW),
        .c(FPU_ResultEM),
        .s(ForwardA_E_FPU),
        .d(Src_A_FPU)
    );

    Mux_3_by_1 fpu_srcb_mux (
        .a(FRD2_E),
        .b(FPU_ResultW),
        .c(FPU_ResultEM),
        .s(ForwardB_E_FPU),
        .d(Src_B_FPU_interim)
    );

    // FPU source selection (immediate)
    Mux fpu_src_mux (
        .a(Src_B_FPU_interim),
        .b(Imm_Ext_E),
        .s(ALUSrcE),
        .c(Src_B_FPU)
    );

    wire [31:0] alu_mux = Src_A_ALU;

    // ----------------------------
    // FPU Unit
    // ----------------------------
    FPU fpu_unit(
        .clk(clk),
        .rst_n(rst_n),
        .A(Src_A_FPU),
        .B(fsubE ? {~Src_B_FPU[31], Src_B_FPU[30:0]} : Src_B_FPU), // Subtraction via negation
        .FResult(FResultE),
        .FPUControl(FPUControl),
        .stall(stall_f_buf),
        .finish_adder(finish_adder),
        .finish_div(finish_div),
        .finish_mul(finish_mul),
        .finish_sqr(finish_sqr)
    );

    // ----------------------------
    // Integer ALU
    // ----------------------------
    ALU alu (
        .A(alu_mux),
        .B(Src_B_ALU),
        .Result(ResultE),
        .ALUControl(ALUControlE),
        .OverFlow(OverFlowE),
        .Carry(CarryE),
        .Zero(ZeroE),
        .Negative(NegativeE)
    );

    // ----------------------------
    // Branch Target Adder
    // ----------------------------
    PC_Adder branch_adder (
        .a(PCE),
        .b(Imm_Ext_E),
        .c(BranchTarget)
    );

    // Stall signal for FPU instructions
    assign stall_f = ((fsubE && !finish_adder) || (faddE && !finish_adder) || 
                      (fmulE && !finish_mul) || (fsqrtE && !finish_sqr) || (fdivE && !finish_div)) ? 1'b1 : stall_f_buf;

    // Finish signal for floating-point ops
    assign finish1 = (finish_mul || finish_adder || finish_div || finish_sqr) ? 1'b1 : 1'b0;

    // Flip-flops to synchronize finish signals
    D #(1) flip(.in(finish1), .out(finish2), .clk(clk), .rst_n(rst_n));
    D #(1) flip1(.in(finish2), .out(finish), .clk(clk), .rst_n(rst_n));

    // Compute jump target (JAL/JALR)
  assign JumpTarget = (OpE == 7'b1100111) ? ((Src_A_ALU + Imm_Ext_E) & ~32'h1) : (PCE + Imm_Ext_E);
    // ----------------------------
    // Branch condition logic
    // ----------------------------
    wire signed_less, unsigned_less;
    assign signed_less = (NegativeE ^ OverFlowE); // signed comparison
    assign unsigned_less = ~CarryE;              // unsigned comparison

    assign BranchCondition = (funct3E == 3'b000) ? ZeroE :        // BEQ
                             (funct3E == 3'b001) ? ~ZeroE :       // BNE
                             (funct3E == 3'b100) ? signed_less :  // BLT
                             (funct3E == 3'b101) ? ~signed_less : // BGE
                             (funct3E == 3'b110) ? unsigned_less :// BLTU
                             (funct3E == 3'b111) ? ~unsigned_less:// BGEU
                             1'b0;                                // Default

    assign PCTargetE = JumpE ? JumpTarget : BranchTarget;

    // Was the branch actually taken?
       assign exec_actual_taken = BranchE & BranchCondition;
    
    // PC of the branch instruction
    assign exec_pc = PCE;
    // ----------------------------
    // Pipeline registers to Memory stage
    // ----------------------------
    always @(posedge clk) begin
        if(rst_n == 1'b0) begin
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
            InstrDE_r <= 0;
            JumpM_r<=0;
            Rs1_E_r<=5'd0;
            Rs2_E_r<=5'd0;
        end
        else if(((!stallE || pass) && (!stall_f || pass))||pass_load) begin
            RegWriteE_r <= RegWriteE; 
            MemWriteE_r <= MemWriteE; 
            ResultSrcE_r <= ResultSrcE;
            FResultSrcE_r <= FResultSrcE;  
            RD_E_r <= RD_E;
            PCPlus4E_r <= PCPlus4E; 
            RD2_E_r <= (OpE==7'b0100111) ? Src_B_FPU_interim : Src_B_ALU_interim; 
            ResultE_r <= (JumpE) ? PCPlus4E :                    // JAL
                         (OpE == 7'b0110111) ? Imm_Ext_E :      // LUI
                         (OpE == 7'b0010111) ? (PCE + Imm_Ext_E) : // AUIPC
                         ResultE;                               // Default ALU result
            FRegWrite_E_r <= FRegWrite_E;
            FResultE_r <= FResultE;
            floadE_r <= floadE;
            fstoreE_r <= fstoreE;
            InstrDE_r <= InstrDE;
            JumpM_r<=JumpE;
            Rs1_E_r<=InstrDE[19:15];
            Rs2_E_r<=InstrDE[24:20];
        end
    end

    // ----------------------------
    // Output assignments to Memory stage
    // ----------------------------
    assign PCSrcE = exec_actual_taken| JumpE;
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
    assign InstrDM = InstrDE_r;
    assign JumpM=JumpM_r;
    assign Rs1_M=Rs1_E_r;
    assign Rs2_M=Rs2_E_r;

endmodule
