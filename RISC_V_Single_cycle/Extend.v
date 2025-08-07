module sige_Extend(IN,Imm_ext,ImmSrc);
input [31:0]IN;
input ImmSrc;
output [31:0]Imm_ext;


assign Imm_ext =(ImmSrc)?{{20{IN[31]}},IN[30:25],IN[11:7]}:{{20{IN[31]}},IN[31:20]} ;
endmodule