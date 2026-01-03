module freg_file(input clk,
   input rst_n,
	input [31:0] F_WD,
	input [4:0] rs1,
   input [4:0] rs2,
   input [4:0] rd,
	input WE,
	output [31:0] F_RD1,
   output [31:0] F_RD2);

//register ram 
reg [31:0]F_register[31:0];

// read operation
assign F_RD1=(!rst_n)?32'd0:F_register[rs1];
assign F_RD2=(!rst_n)?32'd0:F_register[rs2];
integer i=0;

//write operation
always @(posedge clk) begin
   if(!rst_n)begin
        for(i=0;i<32;i=i+1)  
       F_register[i] = 32'h00000000;
  end
  else if(WE)
  F_register[rd]<=F_WD;
end
endmodule