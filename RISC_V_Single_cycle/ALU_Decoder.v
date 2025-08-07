module ALU_DECODER(ALUOp,op5,funct3,funct7,ALUControl);
input [6:0]op5,funct7;
input [2:0]funct3;
input [1:0]ALUOp;
output [2:0]ALUControl;

wire [1:0]concatenation;
assign concatenation={op5[5],funct7[5]};
assign ALUControl = (ALUOp == 2'b00) ? 3'b000 :                 // Case when ALUOp is 00
                    (ALUOp == 2'b01) ? 3'b001 :                 // Case when ALUOp is 01
                    (ALUOp == 2'b10 && funct3 == 3'b000 && concatenation == 2'b11) ? 3'b001 :  // Special case for funct3 000 with concatenation 11
                    (ALUOp == 2'b10 && funct3 == 3'b000) ? 3'b000 :  // Case for funct3 000 without concatenation being 11
                    (ALUOp == 2'b10 && funct3 == 3'b010) ? 3'b101 :  // Case for funct3 010
                    (ALUOp == 2'b10 && funct3 == 3'b110) ? 3'b011 :  // Case for funct3 110
                    (ALUOp == 2'b10 && funct3 == 3'b111) ? 3'b010 :  // Case for funct3 111
                    3'b000;                                          // Default case

   // always@(*)begin
   // 	case (ALUOp)
   // 	2'b00:ALUControl=3'b000;
   // 	2'b01:ALUControl=3'b001;
   // 	2'b10:begin
   // 	case(funct3)
   // 	3'b000:begin
   // 		if (concatenation==2'b11)
   //       ALUControl=3'b001;
   //  	else
   // 		ALUControl=3'b000;
   // 	end
   // 	3'b010: ALUControl=3'b101;
   // 	3'b110: ALUControl=3'b011;
   // 	3'b111:ALUControl=3'b010;
   // 	default:ALUControl=3'b000;
   // 	endcase
   // 	// if(funct3==3'b000)begin
   // 	// 	if (concatenation==2'b11)
   //  //      ALUControl=3'b001;
   // 	// 	else
   // 	// 	ALUControl=3'b000;	
   // 	// end
   // 	// else if(funct3==3'b010)
   //  //  ALUControl=3'b101;
   //  //  else if(funct3==3'b110)
   //  //  ALUControl=3'b011;
   //  //  else if(funct3==3'b111)
   //  //  ALUControl=3'b010;
   //  //  else
   //  //  ALUControl=3'b000;
   // 	end
   // 	default:ALUControl=3'b000;
   // 	endcase
   // end
endmodule