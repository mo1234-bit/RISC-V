

module Control_Unit_Top(  input [6:0]Op,funct7,
    input [2:0]funct3,
    output RegWrite,ALUSrc,MemWrite,ResultSrc,Branch,
    output [1:0]ImmSrc,
    output [2:0]ALUControl,
    output fadd,fsub,fmul,fdiv,fload,fstore,fsqrt,FRegWrite);

  
    wire [1:0]ALUOp;

    Main_Decoder Main_Decoder(
                .Op(Op),
                .funct7(funct7),
                .RegWrite(RegWrite),
                .ImmSrc(ImmSrc),
                .MemWrite(MemWrite),
                .ResultSrc(ResultSrc),
                .Branch(Branch),
                .ALUSrc(ALUSrc),
                .ALUOp(ALUOp),
                .fadd(fadd),
                .fsub(fsub),
                .fmul(fmul),
                .fdiv(fdiv),
                .fload(fload),
                .fstore(fstore),
                .fsqrt(fsqrt),
                .FRegWrite(FRegWrite)

    );

    ALU_Decoder ALU_Decoder(
                            .ALUOp(ALUOp),
                            .funct3(funct3),
                            .funct7(funct7),
                            .op(Op),
                            .ALUControl(ALUControl)
    );


endmodule