module Main_Decoder(input [6:0]Op,
    input [6:0]funct7,output FRegWrite,
    output fadd,fsub,fmul,fdiv,fload,fstore,fsqrt,
    output RegWrite,ALUSrc,MemWrite,ResultSrc,Branch,Jump,
    output FResultSrc, 
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
    assign FResultSrc = (fload) ? 1 : 0;
    
    assign RegWrite = (Op == 7'b0000011 ||
                      Op == 7'b0110011 || 
                      Op == 7'b0010011 ||   
                      Op == 7'b0110111 ||   
                      Op == 7'b0010111 ||  
                      Op == 7'b1101111) ?  
                      1'b1 : 1'b0;
    
    assign ImmSrc = (Op == 7'b0100011) ? 3'b001 :  
                    (Op == 7'b1100011) ? 3'b010 :  
                    (Op == 7'b0110111) ? 3'b011 :  
                    (Op == 7'b0010111) ? 3'b011 :  
                    (Op == 7'b1101111) ? 3'b100 :
                    3'b000;                        
    
    assign ALUSrc = (Op == 7'b0000011 ||  
                    Op == 7'b0100011 ||   
                    Op == 7'b0010011 || 
                    Op == 7'b0110111 || 
                    Op == 7'b0010111 ) ?   
                    1'b1 : 1'b0;
    
    assign MemWrite = (Op == 7'b0100011 || fstore) ? 1'b1 : 1'b0;  
    
    assign ResultSrc = (Op == 7'b0000011 || fload) ? 1'b1 : 1'b0; 
    
    assign Branch = (Op == 7'b1100011) ? 1'b1 : 1'b0; 
    
    assign Jump = (Op == 7'b1101111 ||   
                  Op == 7'b1100111) ?  
                  1'b1 : 1'b0;
    
    assign ALUOp = (Op == 7'b0110011) ? 2'b10 : 
                   (Op == 7'b0010011) ? 2'b11 :  
                   (Op == 7'b1100011) ? 2'b01 :  
                   2'b00;                   

endmodule
