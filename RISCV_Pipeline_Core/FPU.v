module FPU (
    input clk,            
    input rst_n,o_p_waitrequest,
    input [31:0]A,B,
    output [31:0]FResult,
    input [2:0]FPUControl,
    output stall,finish_adder, finish_div, finish_mul
);

    wire A_ack_adder, B_ack_adder, A_ack_div, B_ack_div, A_ack_mul, B_ack_mul;
    wire  active_div, active_mul, active_adder;
    wire [31:0]FResult_adder, FResult_div, FResult_mul;
    wire[2:0]FPUControl4,FPUControl3,FPUControl2,FPUControl1,FPUControl6,FPUControl7;
    assign stall = (active_div || active_mul || active_adder);
   
    assign A_ack_adder = (FPUControl == 3'd1);  
    assign B_ack_adder = (FPUControl == 3'd1);
    assign A_ack_mul = (FPUControl == 3'd2);    
    assign B_ack_mul = (FPUControl == 3'd2);
    assign A_ack_div = (FPUControl == 3'd3);  
    assign B_ack_div = (FPUControl == 3'd3);
    wire [31:0]input_b=(FPUControl == 3'd4)?A:B;
 D #(3)flip(.in(FPUControl),.out(FPUControl1),.clk(clk),.rst_n(rst_n));
 D #(3)flip1(.in(FPUControl1),.out(FPUControl2),.clk(clk),.rst_n(rst_n));
 D #(3)fli2(.in(FPUControl2),.out(FPUControl3),.clk(clk),.rst_n(rst_n));
 D #(3)flip3(.in(FPUControl3),.out(FPUControl4),.clk(clk),.rst_n(rst_n));
 D #(3)fli4(.in(FPUControl4),.out(FPUControl6),.clk(clk),.rst_n(rst_n));
 D #(3)flip5(.in(FPUControl6),.out(FPUControl7),.clk(clk),.rst_n(rst_n));
 wire [2:0]FPUControl5=FPUControl7;
    assign FResult = (FPUControl5 == 3'd1) ? FResult_adder :
                     (FPUControl5 == 3'd2) ? FResult_mul :
                     (FPUControl5 == 3'd3) ? FResult_div :
                     (FPUControl5 == 3'd4) ? FResult_mul :  
                     32'd0;

    adder fadder(
        .clk(clk),          
        .rst_n(rst_n),
        .input_a(A),
        .input_a_stb(A_ack_adder),
        .input_b(B),
        .input_b_stb(B_ack_adder),
        .output_z(FResult_adder),
        .output_z_stb(finish_adder),
        .active(active_adder),
        .o_p_waitrequest(o_p_waitrequest)
    );

    divider fdiv(
        .clk(clk),          
        .rst_n(rst_n),
        .input_a(A),
        .input_a_stb(A_ack_div),
        .input_b(B),
        .input_b_stb(B_ack_div),
        .output_z(FResult_div),
        .output_z_stb(finish_div),
        .active(active_div),
        .o_p_waitrequest(o_p_waitrequest)
    );

    multiplier fmul(
        .clk(clk),          
        .rst_n(rst_n),
        .input_a(A),
        .input_a_stb(A_ack_mul),
        .input_b(input_b),
        .input_b_stb(B_ack_mul),
        .output_z(FResult_mul),
        .output_z_stb(finish_mul),
        .active(active_mul),
        .o_p_waitrequest(o_p_waitrequest)
    );

endmodule
