module test_de();
reg op5,funct7;
reg [2:0]funct3;
reg[1:0]ALUOp;
wire[2:0]ALUControl;
wire [2:0]test;
ALU_DECODER dut(ALUOp,op5,funct3,funct7,ALUControl);
ALU_DECODER_1 dut1(ALUOp,op5,funct3,funct7,test);
integer i=0;
initial begin
	for(i=0;i<100;i=i+1)begin
	op5=$random;
	funct7=$random;
funct3=$random;
ALUOp=$random;	
#10;
if(test!=ALUControl)begin
	$display("error");
end
	end
	$stop;
end
endmodule