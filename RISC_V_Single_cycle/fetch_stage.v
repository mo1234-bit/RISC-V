module fetch_stage (input clk,PCsrcE,rst,input [31:0]PCTargetE,output reg[31:0]InstrD,PCD,PCPlus4D);
wire[31:0]PCF,PCPlus4F,PC_F,Instr;
//reg[31:0]RD_OUT,PCD_reg,PCPlus4D_reg;
wire [31:0]RD_OUT;
instr_memo dut(.A(PCF),.rst(rst),.RD(RD_OUT));

mux dut1(.A(PCPlus4F),.B(PCTargetE),.sel(PCsrcE),.C(PC_F));

adder dut2(.a(PCF),.b(32'd4),.c(PCPlus4F));

PC dut3(.PC_next(PC_F),.PC(PCF),.rst(rst),.clk(clk));

always@(posedge clk)begin
if(rst==0)begin
InstrD<=0;
PCD<=0;
PCPlus4D<=0;	
end else begin
	InstrD<=RD_OUT;
	PCD<=PCF;
	PCPlus4D<=PCPlus4F;
end
end
// assign InstrD=(rst==0)?0:RD_OUT;
// 	assign PCD=(rst==0)?0:PCD_reg;
// 	assign PCPlus4D=(rst==0)?0:PCPlus4D_reg;
endmodule