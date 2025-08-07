module reg_file(A1,A2,A3,WD3,WE3,RD1,RD2,clk,rst);
input [4:0]A1,A2,A3;
input [31:0]WD3;
input WE3;
input clk,rst;
output [31:0]RD1,RD2;

reg[31:0]register[31:0];
assign RD1 =(~rst)?0:register[A1] ;
assign RD2 =(~rst)?0:register[A2] ;
integer i;
always @(posedge clk) begin
	if(~rst)begin
    	for(i=0;i<32;i=i+1)
    	register[i]<=0;
    end
	else
	if (WE3) begin
	register[A3]<=WD3;	
	end
	
end
//initial begin
//	register[9]=32'h00000020;
//	register[6]=32'h00000040;
//	register[11]=32'h00000028;
//	register[12]=32'h00000030;
//	register[5]=32'h00000025;
   
//end
endmodule
















