module adder(
    input clk, rst_n,
    input [31:0] input_a, input_b,
    input input_a_stb, input_b_stb,
    output [31:0] output_z,
    output reg output_z_stb,
    output wire active
);

    // State machine
reg       [2:0] state,state_1,past_state,state_2,state_3;
    localparam IDLE     = 3'd0,
               UNPACK   = 3'd1,
               SPECIAL  = 3'd2,
               ALIGN    = 3'd3,
               ADD      = 3'd4,
               NORM     = 3'd5,
               ROUND    = 3'd6,
               PACK     = 3'd7;

    // IEEE-754 fields
    reg [31:0] a, b, z;
    reg [26:0] a_m, b_m;
    reg [23:0] z_m;
    reg [9:0] a_e, b_e, z_e;
    reg a_s, b_s, z_s;
    
    // Arithmetic
    reg [27:0] sum;
    reg [9:0] exp_diff;
    reg larger_is_a;
    // Rounding bits
    reg guard, round_bit, sticky;
    reg signed [9:0] shift_amount;
    // Output register
    reg [31:0] s_output_z;
    
    // Leading zero counter
    wire [4:0] sum_lz;
    fast_lzc lzc(.mantissa(sum[26:3]), .leading_zeros(sum_lz));
    
    assign active = (state != IDLE) || ((state_3==PACK ||  past_state==SPECIAL) && !input_b_stb && !input_a_stb); 
    assign output_z = s_output_z;

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
             state_2<=0;
            state_3 <= 0;
            past_state<=0;
            state_1<='b0;
            output_z_stb <= 0;
            s_output_z <= 0;
            a <= 0;
            b <= 0;
            z <= 0;
            a_m <= 0;
            b_m <= 0;
            z_m <= 0;
            a_e <= 0;
            b_e <= 0;
            z_e <= 0;
            a_s <= 0;
            b_s <= 0;
            z_s <= 0;
            sum <= 0;
            exp_diff <= 0;
            larger_is_a <= 0;
            guard <= 0;
            round_bit <= 0;
            sticky <= 0;
        end
        else begin
             // Default
            past_state<=state;
            state_3<=past_state;
             case(state)
                IDLE: begin
                     output_z_stb <= 0;
                   if (input_a_stb) begin
            a <= input_a;
          end
          if (input_b_stb) begin
            b <= input_b;
            
          end
               // used old state so that if there is two consecutive multiply it give it time so it take new input data
          if((past_state==PACK || past_state==SPECIAL) && input_b_stb && input_a_stb)begin
              state_1 <= UNPACK;
              state_2<=state_1;
              state<=state_2;
              end
              else if(input_b_stb && input_a_stb)
              state<=UNPACK;
                end

                UNPACK: begin
                    a_m <= {a[22:0], 3'd0};
                    b_m <= {b[22:0], 3'd0};
                    a_e <= a[30:23] - 127;
                    b_e <= b[30:23] - 127;
                    a_s <= a[31];
                    b_s <= b[31];
                    state_1 <= 0;
                    state_2<=0;
                    // Pre-compute exponent difference
                    if (a[30:23] > b[30:23]) begin
                        exp_diff <= a[30:23] - b[30:23];
                        larger_is_a <= 1;
                    end else begin
                        exp_diff <= b[30:23] - a[30:23];
                        larger_is_a <= 0;
                    end
                    
                    state <= SPECIAL;
                end

                SPECIAL: begin
                    // NaN operands
                    if ((a_e == 128 && a_m[26:3] != 0) || 
                        (b_e == 128 && b_m[26:3] != 0)) begin
                        s_output_z <= 32'h7FC00000;  // Direct assignment
                        output_z_stb <= 1;
                        state <= IDLE;
                    end
                    // Both infinity
                    else if (a_e == 128 && b_e == 128) begin
                        if (a_s == b_s) begin
                            s_output_z <= {a_s, 8'hFF, 23'd0};  
                            output_z_stb <= 1;
                            state <= IDLE;
                        end else begin
                            s_output_z <= 32'h7FC00000;  
                            output_z_stb <= 1;
                            state <= IDLE;
                        end
                    end
                    // One infinity
                    else if (a_e == 128) begin
                        s_output_z <= a;  
                        output_z_stb <= 1;
                        state <= IDLE;
                    end
                    else if (b_e == 128) begin
                        s_output_z <= b;  
                        output_z_stb <= 1;
                        state <= IDLE;
                    end
                   
                   else if ((a_e == -127 && a_m[26:3] == 0) && 
                    (b_e == -127 && b_m[26:3] == 0)) begin
                        s_output_z <= {(a_s & b_s), 31'd0};  
                        output_z_stb <= 1;
                        state <= IDLE;
                    end
                    // One zero
                    else if (a_e == -127 && a_m[26:3] == 0) begin
                        s_output_z <= b;  
                        output_z_stb <= 1;
                        state <= IDLE;
                    end
                    else if (b_e == -127 && b_m[26:3] == 0) begin
                        s_output_z <= a;  
                        output_z_stb <= 1;
                        state <= IDLE;
                    end
                    // Normal numbers
                
                    else begin
                     // Set implicit leading 1 for normal numbers only
                    if ($signed(a_e) > -127) begin
                    a_m[26] <= 1;
                    end else begin
                    // Denormal: no implicit 1, but adjust exponent
                    a_e <= -126;
                     end
    
                    if ($signed(b_e) > -127) begin
                     b_m[26] <= 1;
                     end else begin
                    // Denormal: no implicit 1, but adjust exponent
                    b_e <= -126;
                     end
                        
                        state <= ALIGN;
                    end
                end

                ALIGN: begin
                    z_e <= larger_is_a ? a_e : b_e;
                    
                    // Barrel shift with sticky bit preservation
                    if (larger_is_a) begin
                        if (exp_diff > 27) begin
                            // Complete shift-out: set to zero with sticky
                            b_m <= 27'b1;
                        end
                        else if (exp_diff != 0) begin
                            b_m <= (b_m >> exp_diff) | 
                                   ((|(b_m & ((27'd1 << exp_diff) - 1))) ? 27'b1 : 27'b0);
                        end
                    end else begin
                        if (exp_diff > 27) begin
                            a_m <= 27'b1;
                        end
                        else if (exp_diff != 0) begin
                            a_m <= (a_m >> exp_diff) | 
                                   ((|(a_m & ((27'd1 << exp_diff) - 1))) ? 27'b1 : 27'b0);
                        end
                    end
                    
                    state <= ADD;
                end

                ADD: begin
                    if (a_s == b_s) begin
                        sum <= a_m + b_m;
                        z_s <= a_s;
                    end else begin
                        if (a_m >= b_m) begin
                            sum <= a_m - b_m;
                            z_s <= a_s;
                        end else begin
                            sum <= b_m - a_m;
                            z_s <= b_s;
                        end
                    end
                    state <= NORM;
                end
                   NORM: begin
                    if (sum[27]) begin
                        // Overflow: right shift once
                        z_m <= sum[27:4];
                        guard <= sum[3];
                        round_bit <= sum[2];
                        sticky <= sum[1] | sum[0];
                        z_e <= z_e + 1;
                    end
                    else if (sum == 28'd0) begin
                        // True zero - entire sum is zero
                        z_m <= 24'd0;
                        z_e <= -127;
                        guard <= 0;
                        round_bit <= 0;
                        sticky <= 0;
                    end
                    else if (sum[26]) begin
                        // Already normalized (bit 26 is set)
                        z_m <= sum[26:3];
                        guard <= sum[2];
                        round_bit <= sum[1];
                        sticky <= sum[0];
                        // No exponent adjustment needed
                    end
                    else begin
                        if ($signed(z_e) - $signed({5'd0, sum_lz}) <= -126) begin
                            // Will be denormal: only shift to reach exp = -126
                            
                            shift_amount = z_e + 126;
                            
                            if (shift_amount > 0 && shift_amount < 24) begin
                                z_m <= sum[26:3] << shift_amount;
                            end else if (shift_amount <= 0) begin
                                z_m <= sum[26:3];
                            end else begin
                                z_m <= sum[26:3] << 23;
                            end
                            z_e <= -126;
                            guard <= 0;
                            round_bit <= 0;
                            sticky <= |sum[2:0];
                        end
                        else begin
                            // Normal number: full normalization
                            z_m <= sum[26:3] << sum_lz;
                            z_e <= z_e - sum_lz;
                            
                            // Extract rounding bits
                            if (sum_lz == 0) begin
                                guard <= sum[2];
                                round_bit <= sum[1];
                                sticky <= sum[0];
                            end
                            else if (sum_lz == 1) begin
                                guard <= sum[1];
                                round_bit <= sum[0];
                                sticky <= 0;
                            end
                            else if (sum_lz == 2) begin
                                guard <= sum[0];
                                round_bit <= 0;
                                sticky <= 0;
                            end
                            else begin
                                guard <= 0;
                                round_bit <= 0;
                                sticky <= 0;
                            end
                        end
                    end
                    state <= ROUND;
                end
                ROUND: begin
                    if (guard && (round_bit | sticky | z_m[0])) begin
                        z_m <= z_m + 1;
                        if (z_m == 24'hFFFFFF) begin
                            z_e <= z_e + 1;
                        end
                    end
                    state <= PACK;
                end


              PACK: begin
    s_output_z <= {z_s, 
                   ($signed(z_e) < -126) ? 8'd0 :
                   ($signed(z_e) == -126 && z_m[23]) ? 8'd1 :
                   ($signed(z_e) == -126) ? 8'd0 :
                   ($signed(z_e) > 127) ? 8'd255 :
                   z_e[7:0] + 8'd127,
                   ($signed(z_e) > 127) ? 23'd0 : z_m[22:0]};
                    
                    output_z_stb <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
module fast_lzc(
    input [23:0] mantissa,
    output reg [4:0] leading_zeros
);
    always @(*) begin
        casez(mantissa)
            24'b1???????????????????????: leading_zeros = 5'd0;
            24'b01??????????????????????: leading_zeros = 5'd1;
            24'b001?????????????????????: leading_zeros = 5'd2;
            24'b0001????????????????????: leading_zeros = 5'd3;
            24'b00001???????????????????: leading_zeros = 5'd4;
            24'b000001??????????????????: leading_zeros = 5'd5;
            24'b0000001?????????????????: leading_zeros = 5'd6;
            24'b00000001????????????????: leading_zeros = 5'd7;
            24'b000000001???????????????: leading_zeros = 5'd8;
            24'b0000000001??????????????: leading_zeros = 5'd9;
            24'b00000000001?????????????: leading_zeros = 5'd10;
            24'b000000000001????????????: leading_zeros = 5'd11;
            24'b0000000000001???????????: leading_zeros = 5'd12;
            24'b00000000000001??????????: leading_zeros = 5'd13;
            24'b000000000000001?????????: leading_zeros = 5'd14;
            24'b0000000000000001????????: leading_zeros = 5'd15;
            24'b00000000000000001???????: leading_zeros = 5'd16;
            24'b000000000000000001??????: leading_zeros = 5'd17;
            24'b0000000000000000001?????: leading_zeros = 5'd18;
            24'b00000000000000000001????: leading_zeros = 5'd19;
            24'b000000000000000000001???: leading_zeros = 5'd20;
            24'b0000000000000000000001??: leading_zeros = 5'd21;
            24'b00000000000000000000001?: leading_zeros = 5'd22;
            24'b000000000000000000000001: leading_zeros = 5'd23;
            default: leading_zeros = 5'd24;
        endcase
    end
endmodule
