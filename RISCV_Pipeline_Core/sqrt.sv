module fsqrt(
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [31:0] operand,
    output reg [31:0] result,
    output reg done,
    output reg busy
);

    localparam [3:0] IDLE = 4'd0, CHECK = 4'd1, INIT = 4'd2;
    localparam [3:0] ITER1 = 4'd3, ITER1B = 4'd4, ITER2 = 4'd5, FINALIZE = 4'd6;
    localparam [3:0] MULTIPLY = 4'd7, ITER3 = 4'd8, ITER3B = 4'd9, EXTRACT = 4'd10;
    localparam [3:0] FINALIZE2 = 4'd11, FINAL_MULT = 4'd12, FINAL_EXTRACT = 4'd13, DONE_STATE = 4'd14;

    reg [3:0] state;
    wire sign = operand[31];
    wire [7:0] exp_in = operand[30:23];
    wire [22:0] mant_in = operand[22:0];
    
    reg [7:0] exp_result;
    reg [47:0] x;
    reg [47:0] operand_q;
    reg [47:0] temp;
    reg [47:0] y_times_x_sq;
    
    // LUT stores 1/sqrt(x) for x in [1.0, 2.0) in Q0.24 format
    reg [23:0] rsqrt_lut [0:511];
    
    wire signed [8:0] exp_unbiased = exp_in - 8'd127;
    wire exp_odd = exp_unbiased[0];
    wire [8:0] index = mant_in[22:14];
    
    integer i;
    real lut_input, rsqrt_val;
    initial begin
        for (i = 0; i < 512; i = i + 1) begin
            lut_input = 1.0 + (i / 512.0);
            rsqrt_val = 1.0 / $sqrt(lut_input);
            rsqrt_lut[i] = $rtoi(rsqrt_val * (2.0 ** 23));
        end
    end
    
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 1'b0;
            busy <= 1'b0;
            result <= 32'h0;
        end 
        else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    busy <= 1'b0;
                    if (start) begin
                        busy <= 1'b1;
                        state <= CHECK;
                    end
                end
                
                CHECK: begin
                    if (operand[30:0] == 31'h0) begin
                        result <= 32'h00000000;
                        done <= 1'b1;
                        busy <= 1'b0;
                        state <= IDLE;
                    end else if (operand == 32'h80000000) begin
                        result <= 32'h80000000;
                        done <= 1'b1;
                        busy <= 1'b0;
                        state <= IDLE;
                    end else if (sign) begin
                        result <= 32'h7FC00000;
                        done <= 1'b1;
                        busy <= 1'b0;
                        state <= IDLE;
                    end else if (exp_in == 8'hFF && mant_in == 23'h0) begin
                        result <= 32'h7F800000;
                        done <= 1'b1;
                        busy <= 1'b0;
                        state <= IDLE;
                    end else if (exp_in == 8'hFF) begin
                        result <= operand;
                        done <= 1'b1;
                        busy <= 1'b0;
                        state <= IDLE;
                    end else if(start) begin
                        state <= INIT;
                    end else 
                    state<=IDLE;
                end
                
                INIT: begin
                    exp_result <= ((exp_unbiased - exp_odd) >>> 1) + 8'd127;
                    
                    if (exp_odd) begin
                        operand_q <= {22'd0, 1'b1, mant_in, 2'd0};
                    end else begin
                        operand_q <= {23'd0, 1'b1, mant_in, 1'd0};
                    end
                    
                    // LUT is Q1.23 (bit 23 = 1.0), convert to Q24.24 (bit 24 = 1.0)
                    // Shift left by 1: {rsqrt_lut[index], 24'd0} gives bit 47, we want bit 24
                    // So we need to shift right by 23 to move bit 47 to bit 24
                    // Actually: {lut, 24'd0} puts lut[23] at bit 47, shift right 23 puts it at bit 24
                    x <= {24'd0, rsqrt_lut[index]} << 1;
                    
                    if (exp_odd) begin
                        // 1/sqrt(2) = 0.707... in Q1.23 is 0x5A827A (5931642 decimal)
                        temp <= {24'd0, 24'd5931642} << 1;
                    end else begin
                        temp <= 48'd0;
                    end
                    state <= ITER1;
                end
                
                ITER1: begin
                    if (exp_odd) begin
                        x <= (({24'd0, x} * {24'd0, temp}) >> 24);
                    end
                    state <= ITER1B;
                end
                
                ITER1B: begin
                    temp <= (({24'd0, x} * {24'd0, x}) >> 24);
                    state <= ITER2;
                end
                
                ITER2: begin
                    y_times_x_sq <= (({24'd0, operand_q} * {24'd0, temp}) >> 24);
                    state <= FINALIZE;
                end
                
                FINALIZE: begin
                    temp <= (48'd3 << 24) - y_times_x_sq;
                    state <= MULTIPLY;
                end
                
                MULTIPLY: begin
                    x <= (({24'd0, x} * {24'd0, temp}) >> 25);
                    state <= ITER3;
                end
                
                ITER3: begin
                    state <= ITER3B;
                end
                
                ITER3B: begin
                    temp <= (({24'd0, x} * {24'd0, x}) >> 24);
                    state <= EXTRACT;
                end
                
                EXTRACT: begin
                    y_times_x_sq <= (({24'd0, operand_q} * {24'd0, temp}) >> 24);
                    state <= FINALIZE2;
                end
                
                FINALIZE2: begin
                    temp <= (({24'd0, x} * {24'd0, ((48'd3 << 24) - y_times_x_sq)}) >> 25);
                    state <= FINAL_MULT;
                end
                
                FINAL_MULT: begin
                    x <= (({24'd0, operand_q} * {24'd0, temp}) >> 24);
                    state <= FINAL_EXTRACT;
                end
                
                FINAL_EXTRACT: begin
                    state <= DONE_STATE;
                end
                
                DONE_STATE: begin
                    if (x[30]) begin
                        result <= {1'b0, exp_result + 8'd6, x[29:7]};
                    end else if (x[29]) begin
                        result <= {1'b0, exp_result + 8'd5, x[28:6]};
                    end else if (x[28]) begin
                        result <= {1'b0, exp_result + 8'd4, x[27:5]};
                    end else if (x[27]) begin
                        result <= {1'b0, exp_result + 8'd3, x[26:4]};
                    end else if (x[26]) begin
                        result <= {1'b0, exp_result + 8'd2, x[25:3]};
                    end else if (x[25]) begin
                        result <= {1'b0, exp_result + 8'd1, x[24:2]};
                    end else if (x[24]) begin
                        result <= {1'b0, exp_result, x[23:1]};
                    end else if (x[23]) begin
                        result <= {1'b0, exp_result - 8'd1, x[22:0]};
                    end else if (x[22]) begin
                        result <= {1'b0, exp_result - 8'd2, x[21:0], 1'b0};
                    end else if (x[21]) begin
                        result <= {1'b0, exp_result - 8'd3, x[20:0], 2'b00};
                    end else begin
                        result <= {1'b0, exp_result - 8'd4, x[19:0], 3'b000};
                    end
                    
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
