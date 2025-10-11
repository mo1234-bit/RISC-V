module test();
reg rst_n,clk;
wire [15:0]Result;
 Pipeline_top1 dut(.rst_n(rst_n),.clk(clk),.Result(Result));
 initial begin
 	clk=0;
 	forever #1 clk=~clk;
 end
 initial begin
	$dumpfile("single cycle.vcd");
	$dumpvars(0);
end
integer i=0;
initial begin
	rst_n=0;
	
	for(i=0;i<250;i=i+1)begin
	@(negedge clk);
	rst_n=1;
	end

	$stop;
end

endmodule
