module DATA_MEM(A,WD,clk,WE,RD,rst);

input [31:0]A,WD;
input clk,WE,rst;
output [31:0]RD;

reg[31:0]MEM[1023:0];

assign RD =(WE==0&&rst)?MEM[A]:0 ;

always @(posedge clk ) begin
     if (WE) begin
    MEM[A]<=WD;
		
	end
	
end

endmodule