module PC(PC_next,PC,rst,clk);
input [31:0]PC_next;
input clk,rst;
output reg[31:0]PC;

always @(posedge clk) begin
	if (~rst) begin
	PC<=0;
		
	end
	else begin
		PC<=PC_next;
	end
end
endmodule