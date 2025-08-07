module test();
reg clk,PCsrcE,rst;
reg [31:0]PCTargetE;
wire[31:0]InstrD,PCD,PCPlus4D;
fetch_stage dut ( clk,PCsrcE,rst,PCTargetE,InstrD,PCD,PCPlus4D);
initial begin
	clk=0;
	forever
#50	   clk=~clk;
end
initial begin
	rst=0;
	PCsrcE=0;
	PCTargetE=0;
	#200;
	rst=1;
	PCsrcE=0;
	PCTargetE=0;
	#1000;
	$stop;
end
endmodule
