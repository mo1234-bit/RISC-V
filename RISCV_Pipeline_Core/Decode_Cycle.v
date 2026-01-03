// Decode stage of pipeline (ID stage)
// Handles instruction decode, register file reads (integer and floating-point),
// control signals generation, and pipeline register latching
module decode_cycle(
    input clk, rst_n,                     // Clock and reset
    input RegWriteW, FRegWriteW,          // Write enable from WB stage (integer and FP)
    input stall_f, finish, pass, FResultSrcW,
    input [4:0] RDW, counter1,            // Write-back register and counter
    input [31:0] InstrDe, PCD, PCPlus4D, ResultW,  // Input instruction, PC, PC+4, write-back result

    output RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE, JumpE,
    output ResultSrcD,
    output [3:0] ALUControlE,
    output [2:0] funct3E,
    output [6:0] OpE,  
    output [31:0] RD1_E, RD2_E, FRD1_E, FRD2_E, Imm_Ext_E,
    output [4:0] RS1_E, RS2_E, RD_E, Rs1_D, Rs2_D,
    output [31:0] PCE, PCPlus4E, InstrDE, fResultW,
    input stall, FlushD,
    output faddE, fsubE, fmulE, fdivE, floadE, fstoreE, fsqrtE, FRegWrite_E, is_FOP, FResultSrcE
);

    // -----------------------------
    // Wires for decoded control signals
    // -----------------------------
    wire RegWriteD, ALUSrcD, MemWriteD, BranchD, JumpD;
    wire [2:0] ImmSrcD;
    wire [3:0] ALUControlD, FPUControl;
    wire [31:0] RD1_D, RD2_D, FRD1_D, FRD2_D, Imm_Ext_D, InstrD;
    wire fadd, fsub, fmul, fdiv, fload, fstore, fsqrt, FRegWriteD;
    wire FResultSrc;

    // -----------------------------
    // Pipeline registers (D stage -> E stage)
    // -----------------------------
    reg RegWriteD_r, ALUSrcD_r, MemWriteD_r, ResultSrcD_r, BranchD_r, JumpD_r, FResultSrcD_r;
    reg [3:0] ALUControlD_r;
    reg [2:0] funct3D_r;
    reg [6:0] OpD_r;  
    reg [31:0] RD1_D_r, RD2_D_r, FRD1_D_r, FRD2_D_r, Imm_Ext_D_r;
    reg [4:0] RD_D_r, RS1_D_r, RS2_D_r;
    reg [31:0] PCD_r, PCPlus4D_r, InstrD_r;
    reg faddr, fsubr, fmulr, fdivr, floadr, fstorer, fsqrtr, FRegWrite_r;

    // -----------------------------
    // Floating-point control selection
    // -----------------------------
    assign FPUControl = (faddE) ? 3'b001 :    // FP addition
                        (fsubE) ? 3'b001 :    // FP subtraction (handled by negating B)
                        (fmulE) ? 3'b010 :    // FP multiply
                        (fdivE) ? 3'b011 :    // FP divide
                        (fsqrtE)? 3'b100 :    // FP square root
                        3'b000;               // Default NOP

    // -----------------------------
    // Instruction flush
    // -----------------------------
    assign InstrD = (FlushD) ? 32'd0 : InstrDe;

    // -----------------------------
    // Detect if current instruction is floating-point operation
    // -----------------------------
    assign is_FOP = (faddr || fsubr || fmulr || fdivr || fsqrtr) ? 1'b1 : 1'b0;

    // Source registers
    assign Rs1_D = InstrD[19:15];
    assign Rs2_D = InstrD[24:20];

    // -----------------------------
    // Control Unit
    // -----------------------------
    Control_Unit_Top control (
        .Op(InstrD[6:0]),
        .RegWrite(RegWriteD),
        .ImmSrc(ImmSrcD),
        .ALUSrc(ALUSrcD),
        .MemWrite(MemWriteD),
        .ResultSrc(ResultSrcD),
        .Branch(BranchD),
        .Jump(JumpD),
        .funct3(InstrD[14:12]),
        .funct7(InstrD[31:25]),
        .ALUControl(ALUControlD),
        .fadd(fadd),
        .fsub(fsub),
        .fmul(fmul),
        .fdiv(fdiv),
        .fload(fload),
        .fstore(fstore),
        .fsqrt(fsqrt),
        .FRegWrite(FRegWriteD),
        .FResultSrc(FResultSrc)
    );

    // -----------------------------
    // Enable signal for floating-point register write
    // -----------------------------
    wire en_f = (!FResultSrcW && finish) ? 1'b1 :
                (FResultSrcW) ? FRegWriteW : 1'b0;

    // -----------------------------
    // Floating-Point Register File read/write
    // -----------------------------
    freg_file frf(
        .clk(clk),
        .rst_n(rst_n), 
        .F_WD(fResultW),
        .rs1(InstrD[19:15]),
        .rs2(InstrD[24:20]),
        .rd(RDW),
        .WE(en_f),
        .F_RD1(FRD1_D),
        .F_RD2(FRD2_D)
    );

    // -----------------------------
    // Enable signal for integer register file write
    // -----------------------------
    wire en = (counter1 > 5'd9) ? 0 : RegWriteW;

    // Integer register file read/write
    Register_File rf (
        .clk(clk),
        .rst_n(rst_n),
        .WE3(en),
        .WD3(ResultW),
        .A1(InstrD[19:15]),
        .A2(InstrD[24:20]),
        .A3(RDW),
        .RD1(RD1_D),
        .RD2(RD2_D)
    );

    // -----------------------------
    // Sign extension for immediate values
    // -----------------------------
    Sign_Extend extension (
        .In(InstrD[31:0]),
        .Imm_Ext(Imm_Ext_D),
        .ImmSrc(ImmSrcD)
    );

    // -----------------------------
    // D-stage pipeline register latching
    // -----------------------------
    always @(posedge clk) begin
        if (rst_n == 1'b0) begin
            // Reset all pipeline registers
            RegWriteD_r <= 1'b0;
            ALUSrcD_r <= 1'b0;
            MemWriteD_r <= 1'b0;
            ResultSrcD_r <= 1'b0;
            BranchD_r <= 1'b0;
            JumpD_r <= 1'b0;
            ALUControlD_r <= 4'b0000;
            funct3D_r <= 3'b000;
            OpD_r <= 7'b0000000;
            RD1_D_r <= 32'h0; RD2_D_r <= 32'h0; 
            Imm_Ext_D_r <= 32'h0;
            RD_D_r <= 5'h0;
            PCD_r <= 32'h0; PCPlus4D_r <= 32'h0;
            RS1_D_r <= 5'h0; RS2_D_r <= 5'h0;
            faddr <= 1'b0; fsubr <= 1'b0; fmulr <= 1'b0; fdivr <= 1'b0;
            floadr <= 1'b0; fstorer <= 1'b0; fsqrtr <= 1'b0;
            FRD1_D_r <= 32'b0; FRD2_D_r <= 32'b0;
            FRegWrite_r <= 1'b0;
            FResultSrcD_r <= 0;
            InstrD_r <= 0;
        end
        else if ((!stall && !stall_f) || (is_FOP && pass)) begin
            // Latch all D-stage signals to E-stage
            RegWriteD_r <= RegWriteD;
            ALUSrcD_r <= ALUSrcD;
            MemWriteD_r <= MemWriteD;
            ResultSrcD_r <= ResultSrcD;
            BranchD_r <= BranchD;
            JumpD_r <= JumpD;
            ALUControlD_r <= ALUControlD;
            funct3D_r <= InstrD[14:12];
            OpD_r <= InstrD[6:0];  
            RD1_D_r <= RD1_D; 
            RD2_D_r <= RD2_D; 
            Imm_Ext_D_r <= Imm_Ext_D;
            RD_D_r <= InstrD[11:7];
            PCD_r <= PCD; PCPlus4D_r <= PCPlus4D;
            RS1_D_r <= InstrD[19:15];
            RS2_D_r <= InstrD[24:20];
            faddr <= fadd; fsubr <= fsub; fmulr <= fmul; fdivr <= fdiv;
            floadr <= fload; fstorer <= fstore; fsqrtr <= fsqrt;
            FRD1_D_r <= FRD1_D; FRD2_D_r <= FRD2_D;
            FRegWrite_r <= FRegWriteD;
            FResultSrcD_r <= FResultSrc;
            InstrD_r <= InstrDe;
        end
    end

    // -----------------------------
    // Output assignments (E-stage signals)
    // -----------------------------
    assign FResultSrcE = FResultSrcD_r;
    assign RegWriteE   = RegWriteD_r;
    assign ALUSrcE     = ALUSrcD_r;
    assign MemWriteE   = MemWriteD_r;
    assign ResultSrcE  = ResultSrcD_r;
    assign BranchE     = BranchD_r;
    assign JumpE       = JumpD_r;
    assign ALUControlE = ALUControlD_r;
    assign funct3E     = funct3D_r;
    assign OpE         = OpD_r;
    assign RD1_E       = RD1_D_r;
    assign RD2_E       = RD2_D_r;
    assign Imm_Ext_E   = Imm_Ext_D_r;
    assign RD_E        = RD_D_r;
    assign PCE         = PCD_r;
    assign PCPlus4E    = PCPlus4D_r;
    assign RS1_E       = RS1_D_r;
    assign RS2_E       = RS2_D_r;
    assign faddE       = faddr;
    assign fsubE       = fsubr;
    assign fmulE       = fmulr;
    assign fdivE       = fdivr;
    assign floadE      = floadr;
    assign fstoreE     = fstorer;
    assign fsqrtE      = fsqrtr;
    assign FRD1_E      = FRD1_D_r;
    assign FRD2_E      = FRD2_D_r;
    assign FRegWrite_E = FRegWrite_r;
    assign InstrDE     = InstrD_r;

endmodule
