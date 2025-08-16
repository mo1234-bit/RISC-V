module FPU (
	input rst_n,input [31:0]A,B,output [31:0]FResult,input [2:0]FPUControl,output stall );


wire A_ack_adder,B_ack_adder,A_ack_div,B_ack_div,A_ack_mul,B_ack_mul,finish_adder,finish_div,finish_mul,active_div,active_mul,active_adder;
wire [31:0]FResult_adder,FResult_div,FResult_mul;
assign stall =(active_div||active_mul||active_adder) ;
assign A_ack_adder=(FPUControl==3'd1);
assign B_ack_adder=(FPUControl==3'd1);
assign A_ack_div=(FPUControl==3'd2);
assign B_ack_div=(FPUControl==3'd2);
assign A_ack_mul=(FPUControl==3'd3);
assign B_ack_mul=(FPUControl==3'd3);
assign FResult=(FPUControl==3'd1)?FResult_adder:(FPUControl==3'd2)?FResult_div:(FPUControl==3'd3)?FResult_mul:32'd0;

adder fadder(
    rst_n,
    A,
    A_ack_adder,
    B,
    B_ack_adder,
    FResult_adder,
    finish_adder,
    active_adder
       );

divider fdiv(
    rst_n,
    A,
    A_ack_div,
    B,
    B_ack_div,
    FResult_div,
    finish_div,
    active_div
       );

multiplier fmul(
    rst_n,
    A,
    A_ack_mul,
    B,
    B_ack_mul,
    FResult_mul,
    finish_mul,
    active_mul
       );
endmodule