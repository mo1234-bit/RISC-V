module Control_Unit_Top(
    input [6:0] Op,       // Opcode field from instruction
    input [6:0] funct7,   // funct7 field (for ALU/FPU ops)
    input [2:0] funct3,   // funct3 field (for ALU/FPU ops)
    
    // Control signals to pipeline
    output RegWrite,      // Enable writing to integer register file
    output ALUSrc,        // Select between immediate or register for ALU
    output MemWrite,      // Enable writing to memory
    output ResultSrc,     // Select ALU result vs memory data for write-back
    output Branch,        // Branch instruction
    output Jump,          // Jump instruction
    output [2:0] ImmSrc,  // Immediate type selector for sign-extension
    output FResultSrc,    // Floating-point write-back select
    output [3:0] ALUControl, // ALU operation code
    
    // Floating-point control signals
    output fadd, fsub, fmul, fdiv, fload, fstore, fsqrt, // Floating-point ops
    output FRegWrite      // Enable writing to floating-point register file
);

    wire [1:0] ALUOp; // Intermediate ALU operation from main decoder

    // --- Main Decoder ---
    // Decodes opcode (and funct7 for FPU instructions) into high-level control signals
    Main_Decoder Main_Decoder(
        .Op(Op),
        .funct7(funct7),
        .RegWrite(RegWrite),
        .ImmSrc(ImmSrc),
        .MemWrite(MemWrite),
        .ResultSrc(ResultSrc),
        .Branch(Branch),
        .Jump(Jump),
        .ALUSrc(ALUSrc),
        .ALUOp(ALUOp),      // Output to ALU decoder
        .fadd(fadd),
        .fsub(fsub),
        .fmul(fmul),
        .fdiv(fdiv),
        .fload(fload),
        .fstore(fstore),
        .fsqrt(fsqrt),
        .FRegWrite(FRegWrite),
        .FResultSrc(FResultSrc)
    );

    // --- ALU Decoder ---
    // Combines ALUOp (from main decoder) and instruction fields to generate exact ALU control signals
    ALU_Decoder ALU_Decoder(
        .ALUOp(ALUOp),      // From main decoder (type of ALU operation)
        .funct3(funct3),    // From instruction
        .funct7(funct7),    // From instruction
        .op(Op),            // Opcode (needed for some R-type ops)
        .ALUControl(ALUControl) // 4-bit ALU control output
    );

endmodule
