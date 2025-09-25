module ALU_Decoder( input [1:0]ALUOp,
    input [2:0]funct3,
    input [6:0]funct7,op,
    output [3:0]ALUControl 
);

    
    
    assign ALUControl = 
        // ALUOp = 00: Add (for loads/stores/AUIPC)
        (ALUOp == 2'b00) ? 4'b0000 :
        
        // ALUOp = 01: Subtract (for branches/comparison)
        (ALUOp == 2'b01) ? 4'b0001 :
        
        // ALUOp = 10: R-type instructions
        (ALUOp == 2'b10) ? (
            (funct3 == 3'b000) ? 
                ({op[5], funct7[5]} == 2'b11) ? 4'b0001 : 4'b0000 
            ) :
            (funct3 == 3'b001) ? 4'b0111 :  // SLL
            (funct3 == 3'b010) ? 4'b0101 :  // SLT
            (funct3 == 3'b011) ? 4'b0110 :  // SLTU
            (funct3 == 3'b100) ? 4'b0100 :  // XOR
            (funct3 == 3'b101) ? (  // SRL/SRA
                (funct7[5] == 1'b1) ? 4'b1001 : 4'b1000  // SRA : SRL
            ) :
            (funct3 == 3'b110) ? 4'b0011 :  // OR
            (funct3 == 3'b111) ? 4'b0010 :  // AND
            4'b0000  // Default ADD
        ) :
        
        (ALUOp == 2'b11) ? (
            (funct3 == 3'b000) ? 4'b0000 :  // ADDI
            (funct3 == 3'b001) ? 4'b0111 :  // SLLI
            (funct3 == 3'b010) ? 4'b0101 :  // SLTI
            (funct3 == 3'b011) ? 4'b0110 :  // SLTIU
            (funct3 == 3'b100) ? 4'b0100 :  // XORI
            (funct3 == 3'b101) ? (  // SRLI/SRAI
                (funct7[5] == 1'b1) ? 4'b1001 : 4'b1000  // SRAI : SRLI
            ) :
            (funct3 == 3'b110) ? 4'b0011 :  // ORI
            (funct3 == 3'b111) ? 4'b0010 :  // ANDI
            4'b0000  // Default ADD
        ) :
        
        4'b0000;  // Default ADD

endmodule
