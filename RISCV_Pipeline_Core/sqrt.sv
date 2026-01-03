module fsqrt_newton_raphson #(
    parameter ITERATIONS = 4  // Number of Newton-Raphson iterations
)(
    input wire clk,
    input wire rst_n,
    input wire start,              // Pulse high for 1 cycle to start
    input wire [31:0] operand,     // Input value (IEEE-754)
    output reg [31:0] result,      // Output sqrt result
    output reg done,               // High when complete
    output reg busy              // High while computing
    
);

    // State definitions
    localparam [3:0] IDLE         = 4'd0;
    localparam [3:0] CHECK_SPECIAL = 4'd1;
    localparam [3:0] INIT_GUESS   = 4'd2;
    localparam [3:0] DIV_START    = 4'd3;
    localparam [3:0] DIV_WAIT     = 4'd4;
    localparam [3:0] ADD_START    = 4'd5;
    localparam [3:0] ADD_WAIT     = 4'd6;
    localparam [3:0] MUL_START    = 4'd7;
    localparam [3:0] MUL_WAIT     = 4'd8;
    localparam [3:0] FINISH       = 4'd9;

    // State register
    reg [3:0] state, next_state;
    reg [3:0] debug_state;
    // Iteration counter
    reg [2:0] iter_count;
    
    // Working registers
    reg [31:0] x;           // Original input
    reg [31:0] y;           // Current approximation
    reg [31:0] temp;        // Temporary storage
    
    // IEEE-754 constant: 0.5
    wire [31:0] HALF = 32'h3F000000;
    
    // FPU interface signals
    reg fdiv_start, fadd_start, fmul_start;
    reg [31:0] fdiv_a, fdiv_b;
    reg [31:0] fadd_a, fadd_b;
    reg [31:0] fmul_a, fmul_b;
    wire [31:0] fdiv_result, fadd_result, fmul_result;
    wire fdiv_done, fadd_done, fmul_done;
    wire fdiv_busy, fadd_busy, fmul_busy;

    // Initial guess from LUT
    wire [31:0] initial_guess;
    
    // Instantiate lookup table for initial guess
    sqrt_lut lut_inst (
        .operand(x),
        .initial_guess(initial_guess)
    );
    
    // FDIV instance
     divider fdiv(
        .clk(clk),          
        .rst_n(rst_n),
        .input_a(fdiv_a),
        .input_a_stb(fdiv_start),
        .input_b(fdiv_b),
        .input_b_stb(fdiv_start),
        .output_z(fdiv_result),
        .output_z_stb(fdiv_done),
        .active(fdiv_busy),
        .o_p_waitrequest(1'b0)
    );

    
   
      adder fadder(
        .clk(clk),          
        .rst_n(rst_n),
        .input_a(fadd_a),
        .input_a_stb(fadd_start),
        .input_b(fadd_b),
        .input_b_stb(fadd_start),
        .output_z(fadd_result),
        .output_z_stb(fadd_done),
        .active(fadd_busy),
        .o_p_waitrequest(1'b0)
    );

  multiplier fmul(
        .clk(clk),          
        .rst_n(rst_n),
        .input_a(fmul_a),
        .input_a_stb(fmul_start),
        .input_b(fmul_b),
        .input_b_stb(fmul_start),
        .output_z(fmul_result),
        .output_z_stb(fmul_done),
        .active(fmul_busy),
        .o_p_waitrequest(1'b0)
    );
    
    // Debug output
    assign debug_state = state;
    
    // Main state machine - Sequential logic
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 1'b0;
            busy <= 1'b0;
            result <= 32'h0;
            iter_count <= 3'd0;
            x <= 32'h0;
            y <= 32'h0;
            temp <= 32'h0;
            
            // Clear all FPU start signals
            fdiv_start <= 1'b0;
            fadd_start <= 1'b0;
            fmul_start <= 1'b0;
        end else begin
            // Default: clear all start pulses (they should only be high for 1 cycle)
            fdiv_start <= 1'b0;
            fadd_start <= 1'b0;
            fmul_start <= 1'b0;
            
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    busy <= 1'b0;
                    iter_count <= 3'd0;
                    
                    if (start && !done) begin
                        x <= operand;
                        busy <= 1'b1;
                        state <= CHECK_SPECIAL;
                    end
                end
                
                CHECK_SPECIAL: begin
                    // Check for special cases
                    
                    // Case 1: Zero (±0)
                    if (x[30:0] == 31'h0 || !start) begin
                        result <= {x[31], 31'h0};  // sqrt(±0) = ±0
                        done <= 1'b1;
                        busy <= 1'b0;
                        state <= IDLE;
                    end 
                    // Case 2: Negative number (not zero)
                    else if (x[31] == 1'b1) begin
                        result <= 32'h7FC00000;    // sqrt(negative) = NaN (quiet NaN)
                        done <= 1'b1;
                        busy <= 1'b0;
                        state <= IDLE;
                    end 
                    // Case 3: Infinity
                    else if (x[30:23] == 8'hFF && x[22:0] == 23'h0) begin
                        result <= 32'h7F800000;    // sqrt(+inf) = +inf
                        done <= 1'b1;
                        busy <= 1'b0;
                        state <= IDLE;
                    end 
                    // Case 4: NaN
                    else if (x[30:23] == 8'hFF && x[22:0] != 23'h0) begin
                        result <= x;               // sqrt(NaN) = NaN (propagate)
                        done <= 1'b1;
                        busy <= 1'b0;
                        state <= IDLE;
                    end 
                    // Case 5: Normal number
                    else begin
                        state <= INIT_GUESS;
                    end
                end
                
                INIT_GUESS: begin
                    // Get initial approximation from LUT
                    y <= initial_guess;
                    iter_count <= 3'd0;
                    state <= DIV_START;
                end
                
                DIV_START: begin
                    // Newton-Raphson iteration: y_new = 0.5 * (y + x/y)
                    // Step 1: Compute x / y
                    fdiv_start <= 1'b1;
                    fdiv_a <= x;
                    fdiv_b <= y;
                    state <= DIV_WAIT;
                end
                
                DIV_WAIT: begin
                    // Wait for division to complete
                    if (fdiv_done) begin
                        temp <= fdiv_result;  // temp = x/y
                        state <= ADD_START;
                    end
                end
                
                ADD_START: begin
                    // Step 2: Compute y + (x/y)
                    fadd_start <= 1'b1;
                    fadd_a <= y;
                    fadd_b <= temp;
                    state <= ADD_WAIT;
                end
                
                ADD_WAIT: begin
                    // Wait for addition to complete
                    if (fadd_done) begin
                        temp <= fadd_result;  // temp = y + x/y
                        state <= MUL_START;
                    end
                end
                
                MUL_START: begin
                    // Step 3: Compute (y + x/y) * 0.5
                    fmul_start <= 1'b1;
                    fmul_a <= temp;
                    fmul_b <= HALF;
                    state <= MUL_WAIT;
                end
                
                MUL_WAIT: begin
                    // Wait for multiplication to complete
                    if (fmul_done) begin
                        y <= fmul_result;         // Update y with new approximation
                        iter_count <= iter_count + 3'd1;
                        
                        // Check if we've done enough iterations
                        if (iter_count >= (ITERATIONS - 1)) begin
                            state <= FINISH;
                        end else begin
                            state <= DIV_START;   // Do another iteration
                        end
                    end
                end
                
                FINISH: begin
                    result <= y;
                    done <= 1'b1;
                    busy <= 1'b0;
                    state <= IDLE;
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
module sqrt_lut (
    input wire [31:0] operand,
    output reg [31:0] initial_guess
);

    // Extract IEEE-754 fields
    wire sign = operand[31];
    wire [7:0] exponent = operand[30:23];
    wire [22:0] mantissa = operand[22:0];
    
    // Handle exponent: sqrt(2^e) = 2^(e/2)
    // For IEEE-754, biased exponent is exp - 127
    // sqrt exponent = (exp - 127)/2 + 127 = (exp + 127)/2
    
    wire [7:0] new_exponent;
    wire exp_is_odd = exponent[0];
    
    assign new_exponent = {1'b0, exponent[7:1]} + 8'd64;  // (exp >> 1) + 64 = (exp + 128)/2
    
    // Lookup table for mantissa
    // Index: top 8 bits of mantissa
    wire [7:0] lut_index = mantissa[22:15];
    
    // 256-entry LUT for sqrt of mantissa in range [1.0, 2.0)
    reg [22:0] sqrt_mantissa [0:255];
    
    // Initialize LUT with pre-computed sqrt values
    initial begin
       $readmemh("sqrt_lut.hex", sqrt_mantissa);
    end
    
    // Handle the case where exponent is odd
    // If exp is odd, we compute sqrt(2*mantissa) instead
    wire [22:0] effective_mantissa;
    wire [7:0] effective_index;
    
    assign effective_index = exp_is_odd ? (lut_index | 8'h80) : lut_index;
    
    // Output the initial guess
    always @(*) begin
        initial_guess = {1'b0, new_exponent, sqrt_mantissa[effective_index]};
    end

endmodule

