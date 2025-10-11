module D#(parameter size=32)(input clk,rst_n,input[size-1:0]in,output reg [size-1:0]out);

always @(posedge clk ) begin
	if (!rst_n) begin
	 out<=0;
		
	end
	else  begin
		out<=in;
	end
end
endmodule