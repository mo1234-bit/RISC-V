// 32-bit ALU
// Supports arithmetic, logic, comparison, and shift operations
module ALU(
    input  [31:0] A, B,           // ALU operands
    input  [3:0]  ALUControl,      // Operation selector
    output        Carry,           // Carry-out (for add/sub)
    output        OverFlow,         // Signed overflow flag
    output        Zero,             // Result == 0 flag
    output        Negative,         // Result sign bit
    output [31:0] Result            // ALU result
);

    // Internal carry-out from adder
    wire Cout;

    // Sum result used for add/sub operations
    wire [31:0] Sum;

    // Shift operation result
    wire signed [31:0] ShiftResult;

    // Shift amount is taken from lower 5 bits of B
    wire [4:0] ShiftAmount;

    // Logical right shift result
    wire [31:0] srl_res;

    // Arithmetic right shift result
    wire [31:0] sra_res;

    // Sign bit of operand A (used for arithmetic shift right)
    wire sign;

    // Extract sign bit of A
    assign sign = A[31];

    // Logical right shift (fills with zeros)
    assign srl_res = A >> ShiftAmount;

    // Arithmetic right shift
    // If A is negative, fill vacated bits with 1s
    // Otherwise, same as logical right shift
    assign sra_res =
        sign ? (srl_res | (~32'h0 << (32 - ShiftAmount))) :
               srl_res;

    // Shift amount comes from B[4:0]
    assign ShiftAmount = B[4:0];

    // Adder/subtractor
    // ALUControl[0] = 0 → addition
    // ALUControl[0] = 1 → subtraction (A + two's complement of B)
    assign Sum = (ALUControl[0] == 1'b0) ? 
                  A + B : 
                  (A + ((~B) + 1));

    // Shift operations result
    // 0111 → logical left shift
    // 1000 → logical right shift
    // 1001 → arithmetic right shift
    assign ShiftResult =
        (ALUControl == 4'b0111) ? (A << ShiftAmount) :
        (ALUControl == 4'b1000) ? (A >> ShiftAmount) :
        (ALUControl == 4'b1001) ? sra_res :
        32'b0;

    // Main ALU result multiplexer
    // Selects output based on ALUControl
    assign {Cout, Result} =
        (ALUControl == 4'b0000) ? {1'b0, Sum} :                    // ADD
        (ALUControl == 4'b0001) ? {1'b0, Sum} :                    // SUB
        (ALUControl == 4'b0010) ? {1'b0, A & B} :                  // AND
        (ALUControl == 4'b0011) ? {1'b0, A | B} :                  // OR
        (ALUControl == 4'b0100) ? {1'b0, A ^ B} :                  // XOR
        (ALUControl == 4'b0101) ? {1'b0, {31'b0, Sum[31]}} :       // SLT (signed)
        (ALUControl == 4'b0110) ? {1'b0, {31'b0, ~Cout}} :         // SLTU (unsigned)
        (ALUControl == 4'b0111) ? {1'b0, ShiftResult} :            // SLL
        (ALUControl == 4'b1000) ? {1'b0, ShiftResult} :            // SRL
        (ALUControl == 4'b1001) ? {1'b0, ShiftResult} :            // SRA
        {1'b0, 32'b0};                                             // Default

    // Signed overflow detection (only for add/sub)
    // Overflow occurs when:
    // - Operands have same sign
    // - Result has different sign
    assign OverFlow =
        ((Sum[31] ^ A[31]) &
         (~(ALUControl[0] ^ B[31] ^ A[31])) &
         (ALUControl[3:1] == 3'b000));

    // Carry flag (valid only for add/sub operations)
    assign Carry = ((ALUControl[3:1] == 3'b000) & Cout);

    // Zero flag: asserted if Result == 0
    assign Zero = &(~Result);

    // Negative flag: MSB of result
    assign Negative = Result[31];

endmodule
