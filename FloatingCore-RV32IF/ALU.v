module ALU(
    input  [31:0] A, B,           // ALU operands
    input  [3:0]  ALUControl,      // Operation selector
    output        Carry,           // Carry-out (for add/sub)
    output        OverFlow,         // Signed overflow flag
    output        Zero,             // Result == 0 flag
    output        Negative,         // Result sign bit
    output [31:0] Result            // ALU result
);

    
    wire [32:0] Sum;  // Bit 32 = carry, bits 31:0 = result
    wire Cout;

    // Shift operation result
    wire signed [31:0] ShiftResult;
    wire [4:0] ShiftAmount;
    wire [31:0] srl_res;
    wire [31:0] sra_res;
    wire sign;

    // Extract sign bit of A
    assign sign = A[31];

    // Logical right shift (fills with zeros)
    assign srl_res = A >> ShiftAmount;

    // Arithmetic right shift
    assign sra_res =
        sign ? (srl_res | (~32'h0 << (32 - ShiftAmount))) :
               srl_res;

    // Shift amount comes from B[4:0]
    assign ShiftAmount = B[4:0];

   
    assign Sum = (ALUControl[0] == 1'b0) ? 
                  {1'b0, A} + {1'b0, B} :                    // ADD
                  {1'b0, A} + {1'b0, (~B)} + 33'd1;          // SUB

    // Shift operations result
    assign ShiftResult =
        (ALUControl == 4'b0111) ? (A << ShiftAmount) :
        (ALUControl == 4'b1000) ? (A >> ShiftAmount) :
        (ALUControl == 4'b1001) ? sra_res :
        32'b0;

    // ============================================
    // Main ALU result multiplexer
    // Uses Sum[32:0] for ADD/SUB to get carry
    // ============================================
    assign {Cout, Result} =
        (ALUControl == 4'b0000) ? Sum[32:0] :                    // ADD 
        (ALUControl == 4'b0001) ? Sum[32:0] :                    // SUB 
        (ALUControl == 4'b0010) ? {1'b0, A & B} :                // AND
        (ALUControl == 4'b0011) ? {1'b0, A | B} :                // OR
        (ALUControl == 4'b0100) ? {1'b0, A ^ B} :                // XOR
        (ALUControl == 4'b0101) ? {1'b0, {31'b0, Sum[31]}} :     // SLT (signed)
        (ALUControl == 4'b0110) ? {1'b0, {31'b0, ~Sum[32]}} :    // SLTU (unsigned) 
        (ALUControl == 4'b0111) ? {1'b0, ShiftResult} :          // SLL
        (ALUControl == 4'b1000) ? {1'b0, ShiftResult} :          // SRL
        (ALUControl == 4'b1001) ? {1'b0, ShiftResult} :          // SRA
        {1'b0, 32'b0};                                           // Default

    // ============================================
    // Signed overflow detection (only for add/sub)
    // ============================================
    assign OverFlow =
        ((Sum[31] ^ A[31]) &
         (~(ALUControl[0] ^ B[31] ^ A[31])) &
         (ALUControl[3:1] == 3'b000));

    // ============================================
    // Carry flag (valid only for add/sub operations)
    // ============================================
    assign Carry = ((ALUControl[3:1] == 3'b000) & Cout);

    // ============================================
    // Status flags
    // ============================================
    assign Zero = &(~Result);       // All bits zero
    assign Negative = Result[31];   // Sign bit

endmodule
