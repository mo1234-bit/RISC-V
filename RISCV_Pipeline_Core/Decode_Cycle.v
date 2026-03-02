module decode_cycle(
    input clk, rst_n,
    input RegWriteW, FRegWriteW,
    input stall_f, finish, pass, FResultSrcW,
    input [4:0] RDW, counter1,
    input [31:0] InstrDe, PCD, PCPlus4D, ResultW,instr,

    output RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE, JumpE,
    output ResultSrcD,
    output [3:0] ALUControlE,
    output [2:0] funct3E,
    output [6:0] OpE,  
    output [31:0] RD1_E, RD2_E, FRD1_E, FRD2_E, Imm_Ext_E,
    output [4:0] RS1_E, RS2_E, RD_E, Rs1_D, Rs2_D,
    output [31:0] PCE, PCPlus4E, InstrDE, fResultW,
    input stall, FlushD,
    output faddE, fsubE, fmulE, fdivE, floadE, fstoreE, fsqrtE, FRegWrite_E, is_FOP, FResultSrcE,
    
    input mispredict  // From Fetch stage
);

    // Control signals
    wire RegWriteD, ALUSrcD, MemWriteD, BranchD, JumpD;
    wire [2:0] ImmSrcD;
    wire [3:0] ALUControlD, FPUControl;
    wire [31:0] RD1_D, RD2_D, FRD1_D, FRD2_D, Imm_Ext_D, InstrD;
    wire fadd, fsub, fmul, fdiv, fload, fstore, fsqrt, FRegWriteD;
    wire FResultSrc;
    
    // Pipeline registers
    reg RegWriteD_r, ALUSrcD_r, MemWriteD_r, ResultSrcD_r, BranchD_r, JumpD_r, FResultSrcD_r;
    reg [3:0] ALUControlD_r;
    reg [2:0] funct3D_r;
    reg [6:0] OpD_r;  
    reg [31:0] RD1_D_r, RD2_D_r, FRD1_D_r, FRD2_D_r, Imm_Ext_D_r;
    reg [4:0] RD_D_r, RS1_D_r, RS2_D_r;
    reg [31:0] PCD_r, PCPlus4D_r, InstrD_r;
    reg faddr, fsubr, fmulr, fdivr, floadr, fstorer, fsqrtr, FRegWrite_r;
    
    assign FPUControl = (faddE) ? 3'b001 :
                        (fsubE) ? 3'b001 :
                        (fmulE) ? 3'b010 :
                        (fdivE) ? 3'b011 :
                        (fsqrtE)? 3'b100 :
                        3'b000;
    
 
    assign InstrD = (FlushD || mispredict) ? 32'h00000013 : InstrDe;  // NOP if flushed
    
    assign is_FOP = (faddr || fsubr || fmulr || fdivr || fsqrtr) ? 1'b1 : 1'b0;
    assign Rs1_D = InstrD[19:15];
    assign Rs2_D = InstrD[24:20];
    
    // Control Unit
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
        .fadd(fadd), .fsub(fsub), .fmul(fmul), .fdiv(fdiv),
        .fload(fload), .fstore(fstore), .fsqrt(fsqrt),
        .FRegWrite(FRegWriteD),
        .FResultSrc(FResultSrc)
    );
    
    wire en_f = (!FResultSrcW && finish) ? 1'b1 :
                (FResultSrcW) ? FRegWriteW : 1'b0;
    
    freg_file frf(
        .clk(clk), .rst_n(rst_n), 
        .F_WD(fResultW),
        .rs1(InstrD[19:15]),
        .rs2(InstrD[24:20]),
        .rd(RDW),
        .WE(en_f),
        .F_RD1(FRD1_D),
        .F_RD2(FRD2_D)
    );
    
    wire en = (counter1 > 5'd9) ? 0 : RegWriteW;
    
    Register_File rf (
        .clk(clk), .rst_n(rst_n),
        .WE3(en),
        .WD3(ResultW),
        .A1(InstrD[19:15]),
        .A2(InstrD[24:20]),
        .A3(RDW),
        .RD1(RD1_D),
        .RD2(RD2_D)
    );
    
    Sign_Extend extension (
        .In(InstrD[31:0]),
        .Imm_Ext(Imm_Ext_D),
        .ImmSrc(ImmSrcD)
    );
    
    always @(posedge clk) begin
        if (rst_n == 1'b0) begin
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
        
            if (FlushD || mispredict) begin
                // Flush: Insert NOP into Execute stage
                RegWriteD_r <= 1'b0;
                ALUSrcD_r <= 1'b0;
                MemWriteD_r <= 1'b0;
                ResultSrcD_r <= 1'b0;
                BranchD_r <= 1'b0;
                JumpD_r <= 1'b0;
                ALUControlD_r <= 4'b0000;
                RD_D_r <= 5'h0;
                faddr <= 1'b0; fsubr <= 1'b0; fmulr <= 1'b0; fdivr <= 1'b0;
                floadr <= 1'b0; fstorer <= 1'b0; fsqrtr <= 1'b0;
                FRegWrite_r <= 1'b0;
                InstrD_r <= 32'h00000013;  // NOP
            end
            else begin
                // Normal operation: latch decoded values
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
    end
    
    // Outputs
   // Control signals - set to zero on mispredict to create a bubble (NOP)
assign FResultSrcE = mispredict ? 1'b0 : FResultSrcD_r;
assign RegWriteE = mispredict ? 1'b0 : RegWriteD_r;
assign ALUSrcE = mispredict ? 1'b0 : ALUSrcD_r;
assign MemWriteE = mispredict ? 1'b0 : MemWriteD_r;
assign ResultSrcE = mispredict ? 2'b0 : ResultSrcD_r;
assign BranchE = mispredict ? 1'b0 : BranchD_r;
assign JumpE = mispredict ? 1'b0 : JumpD_r;
assign ALUControlE = mispredict ? 3'b0 : ALUControlD_r;
assign funct3E = mispredict ? 3'b0 : funct3D_r;
assign OpE = mispredict ? 7'b0 : OpD_r;

// Floating point control signals
assign faddE = mispredict ? 1'b0 : faddr;
assign fsubE = mispredict ? 1'b0 : fsubr;
assign fmulE = mispredict ? 1'b0 : fmulr;
assign fdivE = mispredict ? 1'b0 : fdivr;
assign floadE = mispredict ? 1'b0 : floadr;
assign fstoreE = mispredict ? 1'b0 : fstorer;
assign fsqrtE = mispredict ? 1'b0 : fsqrtr;
assign FRegWrite_E = mispredict ? 1'b0 : FRegWrite_r;

// Data signals - can be zero or kept as-is (won't matter if control signals are 0)
assign RD1_E = mispredict ? 32'b0 : RD1_D_r;
assign RD2_E = mispredict ? 32'b0 : RD2_D_r;
assign Imm_Ext_E = mispredict ? 32'b0 : Imm_Ext_D_r;
assign RD_E = mispredict ? 5'b0 : RD_D_r;
assign PCE = mispredict ? 32'b0 : PCD_r;
assign PCPlus4E = mispredict ? 32'b0 : PCPlus4D_r;
assign RS1_E = mispredict ? 5'b0 : RS1_D_r;
assign RS2_E = mispredict ? 5'b0 : RS2_D_r;
assign FRD1_E = mispredict ? 32'b0 : FRD1_D_r;
assign FRD2_E = mispredict ? 32'b0 : FRD2_D_r;
assign InstrDE = mispredict ? 32'b0 : InstrD_r;

endmodule
