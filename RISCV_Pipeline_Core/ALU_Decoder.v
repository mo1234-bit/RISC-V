// ALU Decoder
// Decodes instruction fields and ALUOp into a 4-bit ALUControl signal
// Compatible with RISC-V integer instructions
module ALU_Decoder(
    input  [1:0] ALUOp,        // Main control ALU operation type
    input  [2:0] funct3,       // RISC-V funct3 field
    input  [6:0] funct7,       // RISC-V funct7 field
    input  [6:0] op,           // RISC-V opcode field
    output [3:0] ALUControl    // Control signal sent to ALU
);

    /*
     ALUOp encoding (typical):
     00 → Load / Store        → ADD
     01 → Branch              → SUB
     10 → R-type instructions
     11 → I-type ALU instructions

     ALUControl encoding (from your ALU):
     0000 → ADD
     0001 → SUB
     0010 → AND
     0011 → OR
     0100 → XOR
     0101 → SLT   (signed)
     0110 → SLTU  (unsigned)
     0111 → SLL
     1000 → SRL
     1001 → SRA
    */

    assign ALUControl = 
        
        // Load / Store instructions → ADD
        (ALUOp == 2'b00) ? 4'b0000 :

        // Branch instructions → SUB (for comparison)
        (ALUOp == 2'b01) ? 4'b0001 :

        // ---------------- R-type instructions ----------------
        // ADD / SUB (funct3 = 000)
        // SUB when funct7[5]=1 and op[5]=1
        (ALUOp == 2'b10 && funct3 == 3'b000 &&
         ({op[5], funct7[5]} == 2'b11)) ? 4'b0001 :

        // SLL
        (ALUOp == 2'b10 && funct3 == 3'b001) ? 4'b0111 :

        // SLT (signed)
        (ALUOp == 2'b10 && funct3 == 3'b010) ? 4'b0101 :

        // SLTU (unsigned)
        (ALUOp == 2'b10 && funct3 == 3'b011) ? 4'b0110 :

        // XOR
        (ALUOp == 2'b10 && funct3 == 3'b100) ? 4'b0100 :

        // SRA (funct7[5] = 1)
        (ALUOp == 2'b10 && funct3 == 3'b101 && funct7[5]) ? 4'b1001 :

        // SRL (funct7[5] = 0)
        (ALUOp == 2'b10 && funct3 == 3'b101 && !funct7[5]) ? 4'b1000 :

        // OR
        (ALUOp == 2'b10 && funct3 == 3'b110) ? 4'b0011 :

        // AND
        (ALUOp == 2'b10 && funct3 == 3'b111) ? 4'b0010 :

        // ---------------- I-type ALU instructions ----------------

        // ADDI
        (ALUOp == 2'b11 && funct3 == 3'b000) ? 4'b0000 :

        // SLLI
        (ALUOp == 2'b11 && funct3 == 3'b001) ? 4'b0111 :

        // SLTI
        (ALUOp == 2'b11 && funct3 == 3'b010) ? 4'b0101 :

        // SLTIU
        (ALUOp == 2'b11 && funct3 == 3'b011) ? 4'b0110 :

        // XORI
        (ALUOp == 2'b11 && funct3 == 3'b100) ? 4'b0100 :

        // SRAI
        (ALUOp == 2'b11 && funct3 == 3'b101 && funct7[5]) ? 4'b1001 :

        // SRLI
        (ALUOp == 2'b11 && funct3 == 3'b101 && !funct7[5]) ? 4'b1000 :

        // ORI
        (ALUOp == 2'b11 && funct3 == 3'b110) ? 4'b0011 :

        // ANDI
        (ALUOp == 2'b11 && funct3 == 3'b111) ? 4'b0010 :

        // Default: ADD
        4'b0000;

endmodule
