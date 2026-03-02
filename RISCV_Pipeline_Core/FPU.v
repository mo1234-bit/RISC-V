// Floating-Point Unit (FPU) Module
// Supports addition, multiplication, division, and square root
// Handles stalling, handshaking, and result selection
module FPU (
    input clk,                   // System clock
    input rst_n,                 // Active-low reset 

    input [31:0] A, B,           // Operands (IEEE-754 32-bit)
    input [2:0] FPUControl,      // Operation select: 
                                  // 1 = add, 2 = mul, 3 = div, 4 = sqrt

    output [31:0] FResult,       // Selected result output
    output stall,                // High when FPU is busy
    output finish_adder,          // Pulses high when addition done
    output finish_div,            // Pulses high when division done
    output finish_mul,            // Pulses high when multiplication done
    output finish_sqr             // Pulses high when square root done
);

    // ---------------------------------------------------------
    // Handshake / acknowledge signals for submodules
    // ---------------------------------------------------------
    wire A_ack_adder, B_ack_adder;
    wire A_ack_div, B_ack_div;
    wire A_ack_mul, B_ack_mul;
    wire A_ack_sqr, B_ack_sqr;

    // ---------------------------------------------------------
    // Active signals from each submodule
    // ---------------------------------------------------------
    wire active_div, active_mul, active_adder, active_sqr;

    // ---------------------------------------------------------
    // Submodule results
    // ---------------------------------------------------------
    wire [31:0] FResult_adder, FResult_div, FResult_mul, FResult_sqr;

    // ---------------------------------------------------------
    // Stall FPU if any submodule is active
    // ---------------------------------------------------------
    assign stall = active_div || active_mul || active_adder || active_sqr;

    // ---------------------------------------------------------
    // Map FPUControl to handshake signals for each submodule
    // Only one module is active at a time
    // ---------------------------------------------------------
    assign A_ack_adder = (FPUControl == 3'd1);  
    assign B_ack_adder = (FPUControl == 3'd1);

    assign A_ack_mul   = (FPUControl == 3'd2);    
    assign B_ack_mul   = (FPUControl == 3'd2);

    assign A_ack_div   = (FPUControl == 3'd3);  
    assign B_ack_div   = (FPUControl == 3'd3);

    assign A_ack_sqr   = (FPUControl == 3'd4);  
    assign B_ack_sqr   = (FPUControl == 3'd4);

    // ---------------------------------------------------------
    // Division finish signal (internal)
    // ---------------------------------------------------------
    wire finish_d;
    assign finish_div = (finish_d) ? 1'b1 : 1'b0;

    // ---------------------------------------------------------
    // Result selection: priority based on finished operation
    // ---------------------------------------------------------
    assign FResult = (finish_adder) ? FResult_adder :
                     (finish_mul)   ? FResult_mul   :
                     (finish_div)   ? FResult_div   :
                     (finish_sqr)   ? FResult_sqr   :
                     32'd0;  // Default if no operation finished

    // =========================================================
    // Instantiate submodules
    // =========================================================

    // ------------------------
    // Floating-point adder
    // ------------------------
    adder fadder(
        .clk(clk),          
        .rst_n(rst_n),
        .input_a(A),
        .input_a_stb(A_ack_adder),   // Pulse to start addition
        .input_b(B),
        .input_b_stb(B_ack_adder),
        .output_z(FResult_adder),
        .output_z_stb(finish_adder), // Pulses high when done
        .active(active_adder)       // High while computing
    );

    // ------------------------
    // Floating-point divider
    // ------------------------
    divider fdiv(
        .clk(clk),          
        .rst_n(rst_n),
        .input_a(A),
        .input_a_stb(A_ack_div),
        .input_b(B),
        .input_b_stb(B_ack_div),
        .output_z(FResult_div),
        .output_z_stb(finish_d),
        .active(active_div)
    );

    // ------------------------
    // Floating-point multiplier
    // ------------------------
    multiplier fmul(
        .clk(clk),          
        .rst_n(rst_n),
        .input_a(A),
        .input_a_stb(A_ack_mul),
        .input_b(B),
        .input_b_stb(B_ack_mul),
        .output_z(FResult_mul),
        .output_z_stb(finish_mul),
        .active(active_mul)
    );

    // ------------------------
    // Floating-point square root using Newton-Raphson
    // ------------------------
    fsqrt sqr(
        .clk(clk),
        .rst_n(rst_n),
        .start(A_ack_sqr && B_ack_sqr), // Start pulse (1 cycle)
        .operand(A),                     // Input operand
        .result(FResult_sqr),            // Result
        .done(finish_sqr),               // High when done
        .busy(active_sqr)                // High while computing
    );

endmodule
