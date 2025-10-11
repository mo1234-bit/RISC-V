module Instruction_Memory(input rst_n,
  input [31:0]A,
  output [31:0]RD,
  input o_p_waitrequest
);

  (* rom_style = "block" *)reg [31:0] mem [1023:0];
  

  wire [9:0] addr_index;
  assign addr_index = A[11:2];
  
  (* keep = "true" *) assign RD = (rst_n==1'b0) ? 32'd0 : mem[addr_index];

  initial begin
    $readmemh("memfile.hex", mem);
  end

endmodule
