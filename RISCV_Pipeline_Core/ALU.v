module ALU( input [31:0]A,B,
    input [2:0]ALUControl,
    output Carry,OverFlow,Zero,Negative,
    output [31:0]Result);

   

    wire Cout;
    wire [31:0]Sum;

    assign Sum = (ALUControl[0] == 1'b0) ? A + B :
                                          (A + ((~B)+1)) ;
    assign {Cout,Result} = (ALUControl == 3'b000) ? Sum :
                           (ALUControl == 3'b001) ? Sum :
                           (ALUControl == 3'b010) ? A & B :
                           (ALUControl == 3'b011) ? A | B :
                           (ALUControl == 3'b101) ? {{32{1'b0}},(Sum[31])} :
                           {33{1'b0}};
    assign OverFlow = ((Sum[31] ^ A[31]) & 
                      (~(ALUControl[0] ^ B[31] ^ A[31])) &
                      (~ALUControl[1]));
    assign Carry = ((~ALUControl[1]) & Cout);
    assign Zero = &(~Result);
    assign Negative = Result[31];
endmodule
module ALU( input [31:0]A,B,
    input [3:0]ALUControl,
    output Carry,OverFlow,Zero,Negative,
    output [31:0]Result);

    wire Cout;
    wire [31:0]Sum;
    wire [31:0]ShiftResult;
    wire [4:0]ShiftAmount;
    
    assign ShiftAmount = B[4:0]; 
    
    // Addition/Subtraction
    assign Sum = (ALUControl[0] == 1'b0) ? A + B : (A + ((~B) + 1));
    
    // Shift operations
   assign ShiftResult = (ALUControl == 4'b0111) ? (A << ShiftAmount) :               // SLL
                     (ALUControl == 4'b1000) ? (A >> ShiftAmount) :               // SRL
                     (ALUControl == 4'b1001) ? {{ShiftAmount{A[31]}}, A[31:ShiftAmount]} : // SRA
                     32'b0;

    
    // Result multiplexer
    assign {Cout, Result} = 
        (ALUControl == 4'b0000) ? {1'b0, Sum} :                    // ADD
        (ALUControl == 4'b0001) ? {1'b0, Sum} :                    // SUB
        (ALUControl == 4'b0010) ? {1'b0, A & B} :                  // AND
        (ALUControl == 4'b0011) ? {1'b0, A | B} :                  // OR
        (ALUControl == 4'b0100) ? {1'b0, A ^ B} :                  // XOR
        (ALUControl == 4'b0101) ? {1'b0, {31'b0, Sum[31]}} :      // SLT 
        (ALUControl == 4'b0110) ? {1'b0, {31'b0, ~Cout}} :        // SLTU 
        (ALUControl == 4'b0111) ? {1'b0, ShiftResult} :           // SLL
        (ALUControl == 4'b1000) ? {1'b0, ShiftResult} :           // SRL
        (ALUControl == 4'b1001) ? {1'b0, ShiftResult} :           // SRA
        {1'b0, 32'b0};  // Default
    
    // Flag generation
    assign OverFlow = ((Sum[31] ^ A[31]) & 
                      (~(ALUControl[0] ^ B[31] ^ A[31])) &
                      (ALUControl[3:1] == 3'b000));  
                      
    assign Carry = ((ALUControl[3:1] == 3'b000) & Cout);  
    assign Zero = &(~Result);
    assign Negative = Result[31];

endmodule
