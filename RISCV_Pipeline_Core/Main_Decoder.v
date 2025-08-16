module Main_Decoder(input [6:0]Op,
    input [6:0]funct7,output FRegWrite,
    output fadd,fsub,fmul,fdiv,fload,fstore,fsqrt,
    output RegWrite,ALUSrc,MemWrite,ResultSrc,Branch,
    output [1:0]ImmSrc,ALUOp);
    

    assign fadd=(Op==7'b1010011&&funct7 == 7'b0000000)?1:0;

    assign fsub=(Op==7'b1010011&&funct7 == 7'b0000100)?1:0;

    assign fmul=(Op==7'b1010011&&funct7 == 7'b0001000)?1:0;

    assign fdiv=(Op==7'b1010011&&funct7 == 7'b0001100)?1:0;

    assign fsqrt=(Op==7'b1010011&&funct7 == 7'b0101100)?1:0;

    assign fload=(Op==7'b0000111)?1:0;

    assign fstore=(Op==7'b0100111)?1:0;

    assign FRegWrite=(fadd||fsub||fdiv||fmul||fsqrt)?1:0;
     
    assign RegWrite = (Op == 7'b0000011 | Op == 7'b0110011 | Op == 7'b0010011 ) ? 1'b1 :
                                                              1'b0 ;
    assign ImmSrc = (Op == 7'b0100011) ? 2'b01 : 
                    (Op == 7'b1100011) ? 2'b10 :    
                                         2'b00 ;
    assign ALUSrc = (Op == 7'b0000011 | Op == 7'b0100011 | Op == 7'b0010011) ? 1'b1 :
                                                            1'b0 ;
    assign MemWrite = (Op == 7'b0100011) ? 1'b1 :
                                           1'b0 ;
    assign ResultSrc = (Op == 7'b0000011) ? 1'b1 :
                                            1'b0 ;
    assign Branch = (Op == 7'b1100011) ? 1'b1 :
                                         1'b0 ;
    assign ALUOp = (Op == 7'b0110011) ? 2'b10 :
                   (Op == 7'b1100011) ? 2'b01 :
                                        2'b00 ;

endmodule