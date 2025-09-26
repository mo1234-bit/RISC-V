module decode_cycle( input clk, rst, RegWriteW,FRegWriteW,
    input [4:0] RDW,
    input [31:0] InstrD, PCD, PCPlus4D, ResultW,
    output RegWriteE,ALUSrcE,MemWriteE,ResultSrcE,BranchE,JumpE,
    output [3:0] ALUControlE,
    output [2:0] funct3E,
    output [6:0] OpE,  
    output [31:0] RD1_E, RD2_E,FRD1_E,FRD2_E, Imm_Ext_E,
    output [4:0] RS1_E, RS2_E, RD_E,
    output [31:0] PCE, PCPlus4E,
    input o_p_waitrequest, stall,
    output faddE,fsubE,fmulE,fdivE,floadE,fstoreE,fsqrtE,FRegWrite_E,is_FOP);

    wire RegWriteD,ALUSrcD,MemWriteD,ResultSrcD,BranchD,JumpD;
    wire [2:0] ImmSrcD;
    wire [3:0] ALUControlD;
    wire [31:0] RD1_D, RD2_D,FRD1_D,FRD2_D, Imm_Ext_D;
    wire fadd,fsub,fmul,fdiv,fload,fstore,fsqrt,FRegWriteD;
    
    // Pipeline registers
    reg RegWriteD_r,ALUSrcD_r,MemWriteD_r,ResultSrcD_r,BranchD_r,JumpD_r;
    reg [3:0] ALUControlD_r;
    reg [2:0] funct3D_r;
    reg [6:0] OpD_r;  
    reg [31:0] RD1_D_r, RD2_D_r,FRD1_D_r,FRD2_D_r, Imm_Ext_D_r;
    reg [4:0] RD_D_r, RS1_D_r, RS2_D_r;
    reg [31:0] PCD_r, PCPlus4D_r;
    reg faddr,fsubr,fmulr,fdivr,floadr,fstorer,fsqrtr,FRegWrite_r;
    
    assign is_FOP = (faddr||fsubr||fmulr||fdivr||floadr||fstorer || fsqrtr || FRegWrite_r) ? 1 : 0;

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
        .fadd(fadd),
        .fsub(fsub),
        .fmul(fmul),
        .fdiv(fdiv),
        .fload(fload),
        .fstore(fstore),
        .fsqrt(fsqrt),
        .FRegWrite(FRegWriteD)
    );

    // Floating Point Register File
    freg_file frf(
        .clk(clk),
        .rst_n(~rst), 
        .F_WD(ResultW),
        .rs1(InstrD[19:15]),
        .rs2(InstrD[24:20]),
        .rd(RDW),
        .WE(FRegWriteW),
        .F_RD1(FRD1_D),
        .F_RD2(FRD2_D)
    );


    Register_File rf (
        .clk(clk),
        .rst(rst),
        .WE3(RegWriteW),
        .WD3(ResultW),
        .A1(InstrD[19:15]),
        .A2(InstrD[24:20]),
        .A3(RDW),
        .RD1(RD1_D),
        .RD2(RD2_D)
    );

    // Sign Extension
    Sign_Extend extension (
        .In(InstrD[31:0]),
        .Imm_Ext(Imm_Ext_D),
        .ImmSrc(ImmSrcD)
    );


    always @(posedge clk or negedge rst) begin
        if(rst == 1'b0) begin
            RegWriteD_r <= 1'b0;
            ALUSrcD_r <= 1'b0;
            MemWriteD_r <= 1'b0;
            ResultSrcD_r <= 1'b0;
            BranchD_r <= 1'b0;
            JumpD_r <= 1'b0;
            ALUControlD_r <= 4'b0000;
            funct3D_r <= 3'b000;
            OpD_r <= 7'b0000000;
            RD1_D_r <= 32'h00000000; 
            RD2_D_r <= 32'h00000000; 
            Imm_Ext_D_r <= 32'h00000000;
            RD_D_r <= 5'h00;
            PCD_r <= 32'h00000000; 
            PCPlus4D_r <= 32'h00000000;
            RS1_D_r <= 5'h00;
            RS2_D_r <= 5'h00;
            faddr <= 1'b0;
            fsubr <= 1'b0;
            fmulr <= 1'b0;
            fdivr <= 1'b0;
            floadr <= 1'b0;
            fstorer <= 1'b0;
            fsqrtr <= 1'b0;
            FRD1_D_r <= 32'b0;
            FRD2_D_r <= 32'b0;
            FRegWrite_r <= 1'b0;
        end
        else if(!o_p_waitrequest && !stall) begin
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
            PCD_r <= PCD; 
            PCPlus4D_r <= PCPlus4D;
            RS1_D_r <= InstrD[19:15];
            RS2_D_r <= InstrD[24:20];
            faddr <= fadd;
            fsubr <= fsub;
            fmulr <= fmul;
            fdivr <= fdiv;
            floadr <= fload;
            fstorer <= fstore;
            fsqrtr <= fsqrt;
            FRD1_D_r <= FRD1_D;
            FRD2_D_r <= FRD2_D;
            FRegWrite_r <= FRegWriteD;
        end
    end

    // Output assignments
    assign RegWriteE = RegWriteD_r;
    assign ALUSrcE = ALUSrcD_r;
    assign MemWriteE = MemWriteD_r;
    assign ResultSrcE = ResultSrcD_r;
    assign BranchE = BranchD_r;
    assign JumpE = JumpD_r;
    assign ALUControlE = ALUControlD_r;
    assign funct3E = funct3D_r;
    assign OpE = OpD_r;
    assign RD1_E = RD1_D_r;
    assign RD2_E = RD2_D_r;
    assign Imm_Ext_E = Imm_Ext_D_r;
    assign RD_E = RD_D_r;
    assign PCE = PCD_r;
    assign PCPlus4E = PCPlus4D_r;
    assign RS1_E = RS1_D_r;
    assign RS2_E = RS2_D_r;
    assign faddE = faddr;
    assign fsubE = fsubr;
    assign fmulE = fmulr;
    assign fdivE = fdivr;
    assign floadE = floadr;
    assign fstoreE = fstorer;
    assign fsqrtE = fsqrtr;
    assign FRD1_E = FRD1_D_r;
    assign FRD2_E = FRD2_D_r;
    assign FRegWrite_E = FRegWrite_r;

endmodule
