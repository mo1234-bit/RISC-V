module ALU( input [31:0]A,B,
    input [3:0]ALUControl,
    output Carry,OverFlow,Zero,Negative,
    output [31:0]Result);

    wire Cout;
    wire [31:0]Sum;
    wire [31:0]ShiftResult;
    wire [4:0]ShiftAmount;
    
    assign ShiftAmount = B[4:0]; 
    assign Sum = (ALUControl[0] == 1'b0) ? A + B : (A + ((~B) + 1));
   assign ShiftResult = (ALUControl == 4'b0111) ? (A << ShiftAmount) :             
                     (ALUControl == 4'b1000) ? (A >> ShiftAmount) :              
                     32'b0;

    assign {Cout, Result} = 
        (ALUControl == 4'b0000) ? {1'b0, Sum} :                   
        (ALUControl == 4'b0001) ? {1'b0, Sum} :                    
        (ALUControl == 4'b0010) ? {1'b0, A & B} :                  
        (ALUControl == 4'b0011) ? {1'b0, A | B} :                  
        (ALUControl == 4'b0100) ? {1'b0, A ^ B} :                 
        (ALUControl == 4'b0101) ? {1'b0, {31'b0, Sum[31]}} :     
        (ALUControl == 4'b0110) ? {1'b0, {31'b0, ~Cout}} :        
        (ALUControl == 4'b0111) ? {1'b0, ShiftResult} :           
        (ALUControl == 4'b1000) ? {1'b0, ShiftResult} :           
        {1'b0, 32'b0}; 
    

    assign OverFlow = ((Sum[31] ^ A[31]) & 
                      (~(ALUControl[0] ^ B[31] ^ A[31])) &
                      (ALUControl[3:1] == 3'b000));  
                      
    assign Carry = ((ALUControl[3:1] == 3'b000) & Cout);  
    assign Zero = &(~Result);
    assign Negative = Result[31];

endmodule
