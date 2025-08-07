module instr_memo(A,rst,RD);

input[31:0]A;
input rst;

output [31:0]RD;
  
reg[31:0]MEM[1023:0];

assign RD =(~rst)?0:MEM[A[31:2]] ;
initial begin
$readmemh("MEM_FILE.hex",MEM);
end
initial begin
MEM[0]=32'h0064a423;
MEM[1]=32'h00c58000;
MEM[2]=32'h0062E233;
MEM[3]=32'hFFC4A303;

end

endmodule