module divider(
  input     clk,         
  input     rst_n,

  input     [31:0] input_a,
  input     input_a_stb,

  input     [31:0] input_b,
  input     input_b_stb,o_p_waitrequest,
  output    [31:0] output_z,
  output    reg output_z_stb,
  output    wire active
  );

  reg       [31:0] s_output_z;

 reg       [3:0] state,state_1,past_state,state_2,state_3;
  parameter get_a_b       = 4'd0,
            unpack        = 4'd1,
            special_cases = 4'd2,
            normalise_a   = 4'd3,
            normalise_b   = 4'd4,
            divide_0      = 4'd5,
            divide_1      = 4'd6,
            divide_2      = 4'd7,
            divide_3      = 4'd8,
            normalise_1   = 4'd9,
            normalise_2   = 4'd10,
            round         = 4'd11,
            pack          = 4'd12,
            put_z         = 4'd13;
   // active when state is not get_a or get_b and stall another cycle so that it take new data not old
  assign active = (state != get_a_b) || (state_3==put_z && !input_b_stb && !input_a_stb);   

  reg       [31:0] a, b, z;
  reg       [23:0] a_m, b_m, z_m;
  reg       [9:0] a_e, b_e, z_e;
  reg       a_s, b_s, z_s;
  reg       guard, round_bit, sticky;
  reg       [50:0] quotient, divisor, dividend, remainder;
  reg       [5:0] count;

  
  always @(posedge clk)
  begin
    if (rst_n == 0) begin
       state_2<=0;
      state <= get_a_b;
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
      guard <= 0;
      round_bit <= 0;
      sticky <= 0;
      quotient <= 0;
      divisor <= 0;
      dividend <= 0;
      remainder <= 0;
      count <= 0;
    end
    else  begin
     past_state<=state;
    state_3<=past_state;
      case(state)

        get_a_b:
       begin
          output_z_stb <= 0;
          if (input_a_stb) begin
            a <= input_a;
          end
          if (input_b_stb) begin
            b <= input_b;
            
          end
               // used old state so that if there is two consecutive multiply it give it time so it take new input data
          if(past_state==put_z && input_b_stb && input_a_stb)begin
              state_1 <= unpack;
              state_2<=state_1;
              state<=state_2;
              end
              else if(input_b_stb && input_a_stb)
              state<=unpack;
        end

        unpack:
        begin
          a_m <= a[22 : 0];
          b_m <= b[22 : 0];
          a_e <= a[30 : 23] - 127;
          b_e <= b[30 : 23] - 127;
          a_s <= a[31];
          b_s <= b[31];
          
          state <= special_cases;
           state_1 <= 0;
              state_2<=0;
        end

        special_cases:
        begin
          if ((a_e == 128 && a_m != 0) || (b_e == 128 && b_m != 0)) begin
            z[31] <= 1;
            z[30:23] <= 255;
            z[22] <= 1;
            z[21:0] <= 0;
            state <= put_z;
          
          end else if ((a_e == 128) && (b_e == 128)) begin
            z[31] <= 1;
            z[30:23] <= 255;
            z[22] <= 1;
            z[21:0] <= 0;
            state <= put_z;
          
          end else if (a_e == 128) begin
            z[31] <= a_s ^ b_s;
            z[30:23] <= 255;
            z[22:0] <= 0;
            state <= put_z;
          
            if ($signed(b_e == -127) && (b_m == 0)) begin
              z[31] <= 1;
              z[30:23] <= 255;
              z[22] <= 1;
              z[21:0] <= 0;
              state <= put_z;
            end
          
          end else if (b_e == 128) begin
            z[31] <= a_s ^ b_s;
            z[30:23] <= 0;
            z[22:0] <= 0;
            state <= put_z;
        
          end else if (($signed(a_e) == -127) && (a_m == 0)) begin
            z[31] <= a_s ^ b_s;
            z[30:23] <= 0;
            z[22:0] <= 0;
            state <= put_z;
            
            if (($signed(b_e) == -127) && (b_m == 0)) begin
              z[31] <= 1;
              z[30:23] <= 255;
              z[22] <= 1;
              z[21:0] <= 0;
              state <= put_z;
            end
        
          end else if (($signed(b_e) == -127) && (b_m == 0)) begin
            z[31] <= a_s ^ b_s;
            z[30:23] <= 255;
            z[22:0] <= 0;
            state <= put_z;
          end else begin
            
            if ($signed(a_e) == -127) begin
              a_e <= -126;
            end else begin
              a_m[23] <= 1;
            end
            
            if ($signed(b_e) == -127) begin
              b_e <= -126;
            end else begin
              b_m[23] <= 1;
            end
            state <= normalise_a;
          end
        end

        normalise_a:
        begin
          if (a_m[23]) begin
            state <= normalise_b;
          end else begin
            a_m <= a_m << 1;
            a_e <= a_e - 1;
          end
        end

        normalise_b:
        begin
          if (b_m[23]) begin
            state <= divide_0;
          end else begin
            b_m <= b_m << 1;
            b_e <= b_e - 1;
          end
        end

        divide_0:
        begin
          z_s <= a_s ^ b_s;
          z_e <= a_e - b_e;
          quotient <= 0;
          remainder <= 0;
          count <= 0;
          dividend <= a_m << 27;
          divisor <= b_m;
          state <= divide_1;
        end

        divide_1:
        begin
          quotient <= quotient << 1;
          remainder <= remainder << 1;
          remainder[0] <= dividend[50];
          dividend <= dividend << 1;
          state <= divide_2;
        end

        divide_2:
        begin
          if (remainder >= divisor) begin
            quotient[0] <= 1;
            remainder <= remainder - divisor;
          end
          if (count == 49) begin
            state <= divide_3;
          end else begin
            count <= count + 1;
            state <= divide_1;
          end
        end

        divide_3:
        begin
          z_m <= quotient[26:3];
          guard <= quotient[2];
          round_bit <= quotient[1];
          sticky <= quotient[0] | (remainder != 0);
          state <= normalise_1;
        end

        normalise_1:
        begin
          if (z_m[23] == 0 && $signed(z_e) > -126) begin
            z_e <= z_e - 1;
            z_m <= z_m << 1;
            z_m[0] <= guard;
            guard <= round_bit;
            round_bit <= 0;
          end else begin
            state <= normalise_2;
          end
        end

        normalise_2:
        begin
          if ($signed(z_e) < -126) begin
            z_e <= z_e + 1;
            z_m <= z_m >> 1;
            guard <= z_m[0];
            round_bit <= guard;
            sticky <= sticky | round_bit;
          end else begin
            state <= round;
          end
        end

        round:
        begin
          if (guard && (round_bit | sticky | z_m[0])) begin
            z_m <= z_m + 1;
            if (z_m == 24'hffffff) begin
              z_e <= z_e + 1;
            end
          end
          state <= pack;
        end

        pack:
        begin
          z[22 : 0] <= z_m[22:0];
          z[30 : 23] <= z_e[7:0] + 127;
          z[31] <= z_s;
          if ($signed(z_e) == -126 && z_m[23] == 0) begin
            z[30 : 23] <= 0;
          end
          //if overflow occurs, return inf
          if ($signed(z_e) > 127) begin
            z[22 : 0] <= 0;
            z[30 : 23] <= 255;
            z[31] <= z_s;
          end
          state <= put_z;
        end

        put_z:
        begin
          s_output_z <= z;
          output_z_stb <= 1;
          state <= get_a_b;
        end

      endcase
    end
  end
  
  assign output_z = s_output_z;

endmodule