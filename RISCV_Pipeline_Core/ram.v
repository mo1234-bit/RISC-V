module simple_ram
  #(parameter width     = 1,
    parameter widthad   = 1
    )
   (
    input 		   clk,
    
    input [widthad-1:0]    wraddress,
    input 		   wren,
    input [width-1:0] 	   data,
    
    input [widthad-1:0]    rdaddress,
    output reg [width-1:0] q
    );

reg [width-1:0] mem [(2**widthad)-1:0];

always @(posedge clk) begin
    if(wren) mem[wraddress] <= data;
    
    q <= mem[rdaddress];
end

endmodule
