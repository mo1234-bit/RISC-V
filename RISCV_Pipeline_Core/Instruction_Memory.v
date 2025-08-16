module Instruction_Memory(input rst,
  input [31:0]A,
  output [31:0]RD,
  input o_p_waitrequest
);

  
  (* rom_style = "block" *)reg [31:0] mem [1023:0];
  
  (* keep = "true" *) assign RD = (rst==1'b0)?32'd0:mem[A[31:2]];

  initial begin
    $readmemh("memfile.hex", mem);
  end
// integer i=0;
// always@(*)begin
//  mem[0]=32'h00500293;   //  0100011
//  mem[1]=32'h00300313;     //0110011_00101_00000_000_00101_0100011
//  mem[2]=32'h006283B3;
// mem[3]=32'h00002403;
//  mem[4]=32'h00100493;
// mem[5]=32'h00940533;
// for(i=0;i<1019;i=i+1)
// mem[i]=32'd0;
// end
/*
  initial begin
    //mem[0] = 32'hFFC4A303;
    //mem[1] = 32'h00832383;
    // mem[0] = 32'h0064A423;
    // mem[1] = 32'h00B62423;
    mem[0] = 32'h0062E233;
    // mem[1] = 32'h00B62423;

  end
*/
endmodule