module FPU (
    input rst_n,
    input [31:0]A,B,
    output [31:0]FResult,
    input [2:0]FPUControl,
    output stall 
);

    wire A_ack_adder, B_ack_adder, A_ack_div, B_ack_div, A_ack_mul, B_ack_mul;
    wire finish_adder, finish_div, finish_mul, active_div, active_mul, active_adder;
    wire [31:0]FResult_adder, FResult_div, FResult_mul;
    
    assign stall = (active_div || active_mul || active_adder);
    
    // Fixed control signal assignments
    assign A_ack_adder = (FPUControl == 3'd1);  // Addition/Subtraction
    assign B_ack_adder = (FPUControl == 3'd1);
    assign A_ack_mul = (FPUControl == 3'd2);    // Multiplication
    assign B_ack_mul = (FPUControl == 3'd2);
    assign A_ack_div = (FPUControl == 3'd3);    // Division
    assign B_ack_div = (FPUControl == 3'd3);
    
    // Fixed result selection
    assign FResult = (FPUControl == 3'd1) ? FResult_adder :
                     (FPUControl == 3'd2) ? FResult_mul :
                     (FPUControl == 3'd3) ? FResult_div :
                     (FPUControl == 3'd4) ? FResult_adder :  // Square root uses adder
                     32'd0;

    adder fadder(
        .rst(rst_n),
        .input_a(A),
        .input_a_stb(A_ack_adder),
        .input_b(B),
        .input_b_stb(B_ack_adder),
        .output_z(FResult_adder),
        .output_z_stb(finish_adder),
        .active(active_adder)
    );

    divider fdiv(
        .rst(rst_n),
        .input_a(A),
        .input_a_stb(A_ack_div),
        .input_b(B),
        .input_b_stb(B_ack_div),
        .output_z(FResult_div),
        .output_z_stb(finish_div),
        .active(active_div)
    );

    multiplier fmul(
        .rst(rst_n),
        .input_a(A),
        .input_a_stb(A_ack_mul),
        .input_b(B),
        .input_b_stb(B_ack_mul),
        .output_z(FResult_mul),
        .output_z_stb(finish_mul),
        .active(active_mul)
    );

endmodule
