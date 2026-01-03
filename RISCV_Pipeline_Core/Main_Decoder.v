// Main Instruction Decoder
// Generates high-level control signals based on the opcode (Op)
// Supports RV32I integer instructions and basic floating-point operations
module Main_Decoder(
    input  [6:0] Op,            // RISC-V opcode field
    input  [6:0] funct7,        // RISC-V funct7 field (used for FP ops)

    // Floating-point control signals
    output       FRegWrite,     // Write enable for floating-point register file
    output       fadd,          // Floating-point add
    output       fsub,          // Floating-point subtract
    output       fmul,          // Floating-point multiply
    output       fdiv,          // Floating-point divide
    output       fload,         // Floating-point load
    output       fstore,        // Floating-point store
    output       fsqrt,         // Floating-point square root

    // Integer datapath control signals
    output       RegWrite,      // Integer register file write enable
    output       ALUSrc,        // ALU source select (0=reg, 1=immediate)
    output       MemWrite,      // Data memory write enable
    output       ResultSrc,     // Write-back source (0=ALU, 1=memory)
    output       Branch,        // Branch instruction
    output       Jump,          // Jump instruction

    // Floating-point result selection
    output       FResultSrc,    // FP write-back source (0=FP ALU, 1=memory)

    // Immediate generator control
    output [2:0] ImmSrc,        // Immediate type selector

    // ALU operation category
    output [1:0] ALUOp          // Encodes operation class for ALU_Decoder
);

    // ---------------------------------------------------------
    // Floating-point operation decoding (opcode = 1010011)
    // ---------------------------------------------------------

    assign fadd  = (Op == 7'b1010011 && funct7 == 7'b0000000) ? 1'b1 : 1'b0;
    assign fsub  = (Op == 7'b1010011 && funct7 == 7'b0000100) ? 1'b1 : 1'b0;
    assign fmul  = (Op == 7'b1010011 && funct7 == 7'b0001000) ? 1'b1 : 1'b0;
    assign fdiv  = (Op == 7'b1010011 && funct7 == 7'b0001100) ? 1'b1 : 1'b0;
    assign fsqrt = (Op == 7'b1010011 && funct7 == 7'b0101100) ? 1'b1 : 1'b0;

    // Floating-point load/store
    assign fload  = (Op == 7'b0000111) ? 1'b1 : 1'b0; // FLW
    assign fstore = (Op == 7'b0100111) ? 1'b1 : 1'b0; // FSW

    // Enable floating-point register write
    // FP ALU ops + FP loads write to F-registers
    assign FRegWrite = (fadd || fsub || fdiv || fmul || fsqrt || fload) ? 1'b1 : 1'b0;

    // FP result source
    // 1 → memory (FLW), 0 → FP ALU
    assign FResultSrc = (fload) ? 1'b1 : 1'b0;

    // ---------------------------------------------------------
    // Integer register file write enable
    // ---------------------------------------------------------
    assign RegWrite =
        (Op == 7'b0000011 ||   // LW
         Op == 7'b0110011 ||   // R-type
         Op == 7'b0010011 ||   // I-type ALU
         Op == 7'b0110111 ||   // LUI
         Op == 7'b0010111 ||   // AUIPC
         Op == 7'b1101111) ?   // JAL
         1'b1 : 1'b0;

    // ---------------------------------------------------------
    // Immediate type selection
    // ---------------------------------------------------------
    // 000 → I-type
    // 001 → S-type
    // 010 → B-type
    // 011 → U-type
    // 100 → J-type
    assign ImmSrc =
        (Op == 7'b0100011 || Op == 7'b0100111) ? 3'b001 :  // SW / FSW
        (Op == 7'b1100011)               ? 3'b010 :       // Branch
        (Op == 7'b0110111)               ? 3'b011 :       // LUI
        (Op == 7'b0010111)               ? 3'b011 :       // AUIPC
        (Op == 7'b1101111)               ? 3'b100 :       // JAL
                                           3'b000;        // Default: I-type

    // ---------------------------------------------------------
    // ALU source selection
    // ---------------------------------------------------------
    // 1 → use immediate as second operand
    // 0 → use register as second operand
    assign ALUSrc =
        (Op == 7'b0000011 ||   // LW
         Op == 7'b0100011 ||   // SW
         Op == 7'b0010011 ||   // I-type ALU
         Op == 7'b0110111 ||   // LUI
         Op == 7'b0010111 ||   // AUIPC
         Op == 7'b0100111) ?   // FSW
         1'b1 : 1'b0;

    // ---------------------------------------------------------
    // Data memory write enable
    // ---------------------------------------------------------
    assign MemWrite =
        (Op == 7'b0100011 ||   // SW
         fstore) ?             // FSW
         1'b1 : 1'b0;

    // ---------------------------------------------------------
    // Result source selection for write-back
    // ---------------------------------------------------------
    // 1 → memory data (LW / FLW)
    // 0 → ALU result
    assign ResultSrc =
        (Op == 7'b0000011 ||   // LW
         fload) ?              // FLW
         1'b1 : 1'b0;

    // ---------------------------------------------------------
    // Branch and jump control
    // ---------------------------------------------------------
    assign Branch = (Op == 7'b1100011) ? 1'b1 : 1'b0;   // BEQ, BNE, etc.

    assign Jump =
        (Op == 7'b1101111 ||   // JAL
         Op == 7'b1100111) ?   // JALR
         1'b1 : 1'b0;

    // ---------------------------------------------------------
    // ALU operation class encoding
    // ---------------------------------------------------------
    // 00 → load/store/add
    // 01 → branch (subtract/compare)
    // 10 → R-type ALU
    // 11 → I-type ALU
    assign ALUOp =
        (Op == 7'b0110011) ? 2'b10 :  // R-type
        (Op == 7'b0010011) ? 2'b11 :  // I-type
        (Op == 7'b1100011) ? 2'b01 :  // Branch
                             2'b00;  // Default

endmodule
