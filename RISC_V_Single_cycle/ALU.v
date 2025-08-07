module ALU(A,B,ALUControl,Result,carry,overflow,neg,zero);

//inputs declaration
input [31:0]A,B;
input [2:0]ALUControl;

//output declaration.
output [31:0]Result;
output carry,overflow,neg,zero;


wire [31:0]B_or_Bnot;

assign B_or_Bnot =(ALUControl[0]==3'b0)?B:~B ;

wire [31:0]A_and_B;

assign A_and_B =A&B ;

wire [31:0]A_or_B;

assign A_or_B =A|B ;

wire [31:0]sum;

wire cout;

assign {cout,sum} =(ALUControl[0]==3'b0)?(A+B+ALUControl[0]):(A+B_or_Bnot+ALUControl[0]) ;

wire[31:0]slt;
assign slt ={31'b0000000000000000000000000000000,sum[31]} ;

//Result 4to1 mux
assign Result = (ALUControl == 3'b000 || ALUControl == 3'b001) ? sum :         // For ALUControl 000 and 001, assign sum
                (ALUControl == 3'b010) ? A_and_B :                             // For ALUControl 010, assign A_and_B
                (ALUControl == 3'b011) ? A_or_B :                              // For ALUControl 011, assign A_or_B
                (ALUControl == 3'b101) ? slt :                                 // For ALUControl 101, assign slt
                32'b0;  
// always @(*) begin
// 	case(ALUControl)
// 	3'b000:Result=sum;
// 	3'b001:Result=sum;
// 	3'b010:Result=A_and_B;
// 	3'b011:Result=A_or_B;
//     3'b101:Result=slt;
// 	default:Result=0;
// endcase
// end

//flags
assign carry =cout&~ALUControl[1] ;   //carry flag
assign neg =Result[31] ;    //negitve flag
assign zero =~&Result ;     //zero flag
assign overflow =~ALUControl[1]&(sum[31]^A[31])&~(ALUControl[0]^A[31]^B[31]) ;//overflow flag
endmodule