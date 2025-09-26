module Main_Decoder(input [6:0]Op,
    input [6:0]funct7,output FRegWrite,
    output fadd,fsub,fmul,fdiv,fload,fstore,fsqrt,
    output RegWrite,ALUSrc,MemWrite,ResultSrc,Branch,Jump,
    output [2:0]ImmSrc,  
    output [1:0]ALUOp);
    

    assign fadd = (Op == 7'b1010011 && funct7 == 7'b0000000) ? 1 : 0;
    assign fsub = (Op == 7'b1010011 && funct7 == 7'b0000100) ? 1 : 0;
    assign fmul = (Op == 7'b1010011 && funct7 == 7'b0001000) ? 1 : 0;
    assign fdiv = (Op == 7'b1010011 && funct7 == 7'b0001100) ? 1 : 0;
    assign fsqrt = (Op == 7'b1010011 && funct7 == 7'b0101100) ? 1 : 0;
    assign fload = (Op == 7'b0000111) ? 1 : 0;
    assign fstore = (Op == 7'b0100111) ? 1 : 0;
    assign FRegWrite = (fadd || fsub || fdiv || fmul || fsqrt || fload) ? 1 : 0;
     
    
    assign RegWrite = (Op == 7'b0000011 ||  // Load
                      Op == 7'b0110011 ||   // R-type
                      Op == 7'b0010011 ||   // I-type arithmetic
                      Op == 7'b0110111 ||   // LUI
                      Op == 7'b0010111 ||   // AUIPC
                      Op == 7'b1101111) ?   // JAL
                      1'b1 : 1'b0;
    
    assign ImmSrc = (Op == 7'b0100011) ? 3'b001 :  // S-type (Store)
                    (Op == 7'b1100011) ? 3'b010 :  // B-type (Branch)
                    (Op == 7'b0110111) ? 3'b011 :  // U-type (LUI)
                    (Op == 7'b0010111) ? 3'b011 :  // U-type (AUIPC)
                    (Op == 7'b1101111) ? 3'b100 :  // J-type (JAL)
                    3'b000;                         // I-type default
    
    assign ALUSrc = (Op == 7'b0000011 ||  // Load
                    Op == 7'b0100011 ||   // Store
                    Op == 7'b0010011 ||   // I-type
                    Op == 7'b0110111 ||   // LUI
                    Op == 7'b0010111) ?   // AUIPC
                    1'b1 : 1'b0;
    
    assign MemWrite = (Op == 7'b0100011 || fstore) ? 1'b1 : 1'b0;  // Store or FP store
    
    assign ResultSrc = (Op == 7'b0000011 || fload) ? 1'b1 : 1'b0;  // Load or FP load
    
    assign Branch = (Op == 7'b1100011) ? 1'b1 : 1'b0;  // Branch instructions
    
    assign Jump = (Op == 7'b1101111 ||   // JAL
                  Op == 7'b1100111) ?    // JALR
                  1'b1 : 1'b0;
    
    assign ALUOp = (Op == 7'b0110011) ? 2'b10 :  // R-type
                   (Op == 7'b0010011) ? 2'b11 :  // I-type arithmetic (new)
                   (Op == 7'b1100011) ? 2'b01 :  // Branch
                   2'b00;                        // Default (add for loads/stores)

endmodule
