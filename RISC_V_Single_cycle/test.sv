module test();
reg rst,clk;

 top dut(.rst(rst),.clk(clk));
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
	rst=0;
	
	for(i=0;i<100;i=i+1)begin
	@(negedge clk);
	rst=1;
	end

	$stop;
end

endmodule