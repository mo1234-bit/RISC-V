module main_decoder(op,ResultSrc,MemWrite,ALUSrc,ImmSrc,RegWrite,ALUOp,branch);
input [6:0]op;
output  ResultSrc,MemWrite,ALUSrc,RegWrite;
output  branch;
output [1:0]ImmSrc,ALUOp;
localparam LW      = 7'b0000011; // Load Word
localparam SW      = 7'b0100011; // Store Word
localparam R_TYPE  = 7'b0110011; // R-type instructions
localparam BEQ     = 7'b1100011; // Branch if equal
 
 assign ResultSrc =(op==LW)?1:0 ;
 assign  MemWrite=(op==SW)?1:0 ;
 assign  ALUSrc=(op==LW||op==SW)?1:0 ;
 assign  RegWrite=(op==LW||op==R_TYPE)?1:0 ;
 assign  branch=(op==BEQ)?1:0 ;
 assign ALUOp =(op==R_TYPE)?2'b10:(op==BEQ)?2'b01:2'b00 ;
 assign ImmSrc =(op==SW)?2'b01:(op==BEQ)?2'b10:2'b00 ;
// always @(*) begin
// 	case(op)
// 	LW:begin
// 		ResultSrc=1;
// 		MemWrite=0;
// 		ALUSrc=1;
// 		RegWrite=1;
// 		branch=0;
// 		ImmSrc=2'b00;
// 		ALUOp=2'b00;
// 	end
// 	SW:begin
// 		MemWrite=1;
// 		ALUSrc=1;
// 		RegWrite=0;
// 		branch=0;
// 		ImmSrc=2'b01;
// 		ALUOp=2'b00;
// 	end
// 	R_TYPE:begin
// 		ResultSrc=0;
// 		MemWrite=0;
// 		ALUSrc=0;
// 		RegWrite=1;
// 		branch=0;
// 		ALUOp=2'b10;
// 		ImmSrc=2'b00;
// 	end
// 	BEQ:begin
// 		MemWrite=0;
// 		ALUSrc=0;
// 		RegWrite=0;
// 		branch=1;
// 		ImmSrc=2'b10;
// 		ALUOp=2'b01;
// 	end
// 	default:begin
// 		ResultSrc=0;
// 		MemWrite=0;
// 		ALUSrc=0;
// 		RegWrite=0;
// 		branch=0;
// 		ImmSrc=2'b00;
// 		ALUOp=2'b00;
// 	end
// 	endcase
// end

endmodule