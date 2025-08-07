module control_unit_top(op,RegWrite,funct3,funct7,ALUControl,ResultSrc,MemWrite,ALUSrc,ImmSrc,branch);
input [6:0]funct7;
input[6:0]op;
input[2:0]funct3;
output RegWrite,ALUSrc,MemWrite,ResultSrc,branch;
output [1:0]ImmSrc;
output [2:0]ALUControl;
 wire [1:0]ALUOp_reg;

 main_decoder dut1(.op(op),.ResultSrc(ResultSrc),.MemWrite(MemWrite),.ALUSrc(ALUSrc),
 	.ImmSrc(ImmSrc),.RegWrite(RegWrite),.ALUOp(ALUOp_reg),.branch(branch));
   

 ALU_DECODER dut2(.ALUOp(ALUOp_reg),.op5(op),.funct3(funct3),.funct7(funct7),.ALUControl(ALUControl));
endmodule




















