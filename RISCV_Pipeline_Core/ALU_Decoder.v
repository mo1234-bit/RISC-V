module ALU_Decoder( input [1:0]ALUOp,
    input [2:0]funct3,
    input [6:0]funct7,op,
    output [3:0]ALUControl 
);

    
    
    assign ALUControl = 
        
        (ALUOp == 2'b00) ? 4'b0000 :
        (ALUOp == 2'b01) ? 4'b0001 :
        (ALUOp == 2'b10&&funct3 == 3'b000&&({op[5], funct7[5]} == 2'b11)) ? 4'b0001:
            (ALUOp == 2'b10&&funct3 == 3'b001) ? 4'b0111 :  
            (ALUOp == 2'b10&&funct3 == 3'b010) ? 4'b0101 : 
            (ALUOp == 2'b10&&funct3 == 3'b011) ? 4'b0110 :
            (ALUOp == 2'b10&&funct3 == 3'b100) ? 4'b0100 :  
            (ALUOp == 2'b10&&funct3 == 3'b101&&funct7[5] == 1'b1) ?4'b1001:
            (ALUOp == 2'b10&&funct3 == 3'b101&&funct7[5] == 1'b0)? 4'b1000:  
            (ALUOp == 2'b10&&funct3 == 3'b110) ? 4'b0011 :  
            (ALUOp == 2'b10&&funct3 == 3'b111) ? 4'b0010 :  
            ((ALUOp == 2'b11)&&funct3 == 3'b000) ? 4'b0000 : 
            ((ALUOp == 2'b11)&&funct3 == 3'b001) ? 4'b0111 :
            ((ALUOp == 2'b11)&&funct3 == 3'b010) ? 4'b0101 :  
            ((ALUOp == 2'b11)&&funct3 == 3'b011) ? 4'b0110 :  
            ((ALUOp == 2'b11)&&funct3 == 3'b100) ? 4'b0100 :  
            ((ALUOp == 2'b11)&&funct3 == 3'b101&&(funct7[5] == 1'b1)) ? 4'b1001: 
            ((ALUOp == 2'b11)&&funct3 == 3'b101&&(funct7[5] == 1'b0)) ?  4'b1000 :
            ((ALUOp == 2'b11)&&funct3 == 3'b110) ? 4'b0011 :  
            ((ALUOp == 2'b11)&&funct3 == 3'b111) ? 4'b0010   
            :4'b0000; 
        
        

endmodule
