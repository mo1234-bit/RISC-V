module address (
    input wire wr,
    input wire clk,    // Clock
    input wire rst_n,  //synchronous reset active low
    input wire valid,  // when it come it activate the addrees block (no need for handcheck)
    input wire [4:0]rs1,//base address is the  starting point or reference location in memory
    input wire [4:0]rs2,// An offset is a value that indicates how far you need to move from the base address.
    output wire [24:0]cache_address_i,
    output wire[3:0]byte_en
);
wire [9:0]rs1_rs2;
assign rs1_rs2={rs2,rs1};
reg [31:0]address;//BaseAddress+Offset
reg[31:0]mem[1024:0];
integer w;
always @(posedge clk) begin
    if (!rst_n) begin
        address<=0;
    end
    else if (valid)
        address<=mem[rs1_rs2];
    

end
assign cache_address_i=(wr)?{address[24:2],2'b11}:address[24:0];
assign byte_en=address[6:3];

initial begin
w=0;
for (w = 0; w < 1024; w = w + 1)
    mem[w]={7'd0,w[13:0],w[8:0],2'b00};
end
endmodule
