
module divider(
  input clk, rst_n,
  input [31:0] input_a,      // Numerator
  input input_a_stb,
  input [31:0] input_b,      // Denominator
  input input_b_stb,
  output [31:0] output_z,
  output reg output_z_stb,
  output wire active
);

  reg [31:0] s_output_z;
  reg       [3:0] state,state_1,past_state,state_2,state_3;
  
  parameter IDLE          = 4'd0,
            UNPACK        = 4'd1,
            SPECIAL       = 4'd2,
            NORMALIZE_A   = 4'd3,
            NORMALIZE_B   = 4'd4,
            DIVIDE_0      = 4'd5,
            DIVIDE_1      = 4'd6,
            DIVIDE_2      = 4'd7,
            DIVIDE_3      = 4'd8,
            NORMALISE_1   = 4'd9,
            NORMALISE_2   = 4'd10,
            ROUND         = 4'd11,
            PACK          = 4'd12,
            PUT_Z         = 4'd13;

  reg [31:0] a, b, z;
  reg [23:0] a_m, b_m, z_m;
  reg [9:0] a_e, b_e, z_e;
  reg a_s, b_s, z_s;
  reg guard, round_bit, sticky;
  
  // Goldschmidt iteration registers - 48-bit
  reg [47:0] numerator;
  reg [47:0] denominator;
  reg [47:0] factor;
  reg [5:0] count;
  
  // Wide temporary for multiplication results
  wire [95:0] mult_n;
  wire [95:0] mult_d;
  
  // Initial approximation LUT (256 entries)
  reg [23:0] reciprocal_lut [0:255];
  
  assign active = (state != IDLE) || (state_3==PUT_Z && !input_b_stb && !input_a_stb); 
  
  // Continuous assignments for multiplications
  assign mult_n = numerator * factor;
  assign mult_d = denominator * factor;
  
  // Initialize reciprocal LUT for fast initial approximation
  initial begin
  $readmemh("reciprocal_lut.hex", reciprocal_lut);
end

  
  always @(posedge clk) begin
    if (!rst_n) begin
      state <= IDLE;
      s_output_z <= 0;
      state_2<=0;
past_state<=0;
      state_1<='b0;
      output_z_stb <= 0;
      a <= 0; b <= 0; z <= 0;
      a_m <= 0; b_m <= 0; z_m <= 0;
      a_e <= 0; b_e <= 0; z_e <= 0;
      guard <= 0;
      round_bit <= 0;
      sticky <= 0;
      count <= 0;
      numerator <= 0;
      denominator <= 0;
      factor <= 0;
    end
    else begin
       past_state<=state;
    state_3<=past_state;
      case(state)
        IDLE: begin
          output_z_stb <= 0;
          if (input_a_stb && input_b_stb) begin
            a <= input_a;
            b <= input_b;
            end
            if(past_state==PUT_Z && input_b_stb && input_a_stb)begin
              state_1 <= UNPACK;
              state_2<=state_1;
              state<=state_2;
              end
              else if(input_b_stb && input_a_stb)
              state<=UNPACK;
       
        end

        UNPACK: begin
          a_m <= a[22:0];
          b_m <= b[22:0];
          a_e <= a[30:23] - 127;
          b_e <= b[30:23] - 127;
          a_s <= a[31];
          b_s <= b[31];
          state <= SPECIAL;
          state_1 <= 0;
          state_2<=0;
        end

        SPECIAL: begin
          // Handle special cases (matching original divider exactly)
          if ((a[30:23] == 8'd255 && a[22:0] != 0) || 
              (b[30:23] == 8'd255 && b[22:0] != 0)) begin
            z[31] <= 1;
            z[30:23] <= 255;
            z[22] <= 1;
            z[21:0] <= 0;
            state <= PUT_Z;
          end 
          else if ((a[30:23] == 8'd255) && (b[30:23] == 8'd255)) begin
            z[31] <= 1;
            z[30:23] <= 255;
            z[22] <= 1;
            z[21:0] <= 0;
            state <= PUT_Z;
          end 
          else if (a[30:23] == 8'd255) begin
            z[31] <= a_s ^ b_s;
            z[30:23] <= 255;
            z[22:0] <= 0;
            state <= PUT_Z;
            if ((b[30:23] == 8'd0) && (b[22:0] == 0)) begin
              z[31] <= 1;
              z[30:23] <= 255;
              z[22] <= 1;
              z[21:0] <= 0;
              state <= PUT_Z;
            end
          end 
          else if (b[30:23] == 8'd255) begin
            z[31] <= a_s ^ b_s;
            z[30:23] <= 0;
            z[22:0] <= 0;
            state <= PUT_Z;
          end 
          else if ((a[30:23] == 8'd0) && (a[22:0] == 0)) begin
            z[31] <= a_s ^ b_s;
            z[30:23] <= 0;
            z[22:0] <= 0;
            state <= PUT_Z;
            if ((b[30:23] == 8'd0) && (b[22:0] == 0)) begin
              z[31] <= 1;
              z[30:23] <= 255;
              z[22] <= 1;
              z[21:0] <= 0;
            end
          end 
          else if ((b[30:23] == 8'd0) && (b[22:0] == 0)) begin
            z[31] <= a_s ^ b_s;
            z[30:23] <= 255;
            z[22:0] <= 0;
            state <= PUT_Z;
          end 
          else begin
            if (a[30:23] == 8'd0) begin
              a_e <= -126;
            end else begin
              a_m[23] <= 1;
            end
            
            if (b[30:23] == 8'd0) begin
              b_e <= -126;
            end else begin
              b_m[23] <= 1;
            end
            state <= NORMALIZE_A;
          end
        end

        NORMALIZE_A: begin
          if (a_m[23]) begin
            state <= NORMALIZE_B;
          end else begin
            a_m <= a_m << 1;
            a_e <= a_e - 1;
          end
        end

        NORMALIZE_B: begin
          if (b_m[23]) begin
           
            state <= DIVIDE_0;
          end else begin
            b_m <= b_m << 1;
            b_e <= b_e - 1;
          end
        end

        DIVIDE_0: begin
          z_s <= a_s ^ b_s;
          z_e <= a_e - b_e;
          
         
          numerator <= {1'b0, a_m, 23'd0};
          denominator <= {1'b0, b_m, 23'd0};
          
          count <= 0;
          
          state <= DIVIDE_1;
        end

        DIVIDE_1: begin
          // First iteration: multiply by reciprocal approximation
          // LUT contains 24-bit mantissa, shift to bits [46:23]
          factor <= {1'b0, reciprocal_lut[b_m[22:15]], 23'd0};
          count <= 1;
          state <= DIVIDE_2;
        end

        DIVIDE_2: begin
          if (count == 1) begin
            numerator <= {1'b0, mult_n[92:46]};
            denominator <= {1'b0, mult_d[92:46]};
            factor <= (48'h800000000000 - {1'b0, mult_d[92:46]});
            count <= 2;
          end
          else if (count == 2) begin
            numerator <= {1'b0, mult_n[92:46]};
            denominator <= {1'b0, mult_d[92:46]};
            factor <= (48'h800000000000 - {1'b0, mult_d[92:46]});
            count <= 3;
          end
          else if (count == 3) begin
            numerator <= {1'b0, mult_n[92:46]};
            denominator <= {1'b0, mult_d[92:46]};
            factor <= (48'h800000000000 - {1'b0, mult_d[92:46]});
            count <= 4;
          end
          else if (count == 4) begin
            numerator <= {1'b0, mult_n[92:46]};
            denominator <= {1'b0, mult_d[92:46]};
            factor <= (48'h800000000000 - {1'b0, mult_d[92:46]});
            count <= 5;
          end
          else if (count == 5) begin
            numerator <= {1'b0, mult_n[92:46]};
            denominator <= {1'b0, mult_d[92:46]};
            factor <= (48'h800000000000 - {1'b0, mult_d[92:46]});
            count <= 6;
          end
          else if (count == 6) begin
            numerator <= {1'b0, mult_n[92:46]};
            denominator <= {1'b0, mult_d[92:46]};
            factor <= (48'h800000000000 - {1'b0, mult_d[92:46]});
            count <= 7;
          end
          else begin
            // Final iteration
            numerator <= {1'b0, mult_n[92:46]};
            state <= DIVIDE_3;
          end
        end

        DIVIDE_3: begin
          // Extract quotient from numerator
          // Mantissa is now in bits [46:23]
          z_m <= numerator[46:23];
          guard <= numerator[22];
          round_bit <= numerator[21];
          sticky <= (numerator[20:0] != 0);
          
          state <= NORMALISE_1;
        end

        NORMALISE_1: begin
          if (z_m[23] == 0 && $signed(z_e) > -126) begin
            z_e <= z_e - 1;
            z_m <= z_m << 1;
            z_m[0] <= guard;
            guard <= round_bit;
            round_bit <= 0;
          end else begin
            state <= NORMALISE_2;
          end
        end

        NORMALISE_2: begin
          if ($signed(z_e) < -126) begin
            z_e <= z_e + 1;
            z_m <= z_m >> 1;
            guard <= z_m[0];
            round_bit <= guard;
            sticky <= sticky | round_bit;
          end else begin
            state <= ROUND;
          end
        end

        ROUND: begin
          if (guard && (round_bit | sticky | z_m[0])) begin
            z_m <= z_m + 1;
            if (z_m == 24'hffffff) begin
              z_e <= z_e + 1;
            end
          end
          state <= PACK;
        end

        PACK: begin
          z[22:0] <= z_m[22:0];
          z[30:23] <= z_e[7:0] + 127;
          z[31] <= z_s;
          if ($signed(z_e) == -126 && z_m[23] == 0) begin
            z[30:23] <= 0;
          end
          if ($signed(z_e) > 127) begin
            z[22:0] <= 0;
            z[30:23] <= 255;
            z[31] <= z_s;
          end
          state <= PUT_Z;
        end

        PUT_Z: begin
          s_output_z <= z;
          output_z_stb <= 1;
          state <= IDLE;
        end
      endcase
    end
  end
  
  assign output_z = s_output_z;

endmodule
