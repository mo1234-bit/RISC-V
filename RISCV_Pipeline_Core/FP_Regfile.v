module freg_file(input clk,rst_n,
	input [31:0]F_WD,
	input [4:0]rs1,rs2,rd,
	input WE,
	output [31:0]F_RD1,F_RD2);

reg [31:0]F_register[31:0];

assign F_RD1=(!rst_n)?32'd0:F_register[rs1];
assign F_RD2=(!rst_n)?32'd0:F_register[rs2];
integer i=0;
always @(posedge clk) begin
   if(!rst_n)begin
        for(i=0;i<32;i=i+1)  
       F_register[i] = 32'h00000000;
  end
  else if(WE)
  F_register[rd]<=F_WD;
end
endmodule