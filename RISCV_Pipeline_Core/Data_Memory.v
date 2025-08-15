
module Data_Memory(clk,rst,WE,WD,ren,A,RD,i_m_readdata_valid,i_m_waitrequest);
    input wire ren; 
    input clk,rst,WE;
    output wire i_m_readdata_valid;
    output wire i_m_waitrequest;
    input wire [31:0]A,WD;
    output wire[31:0]RD;

    reg [31:0] mem [1023:0];

    always @ (posedge clk)
    begin
        if(WE) 

            mem[A[11:2]] <= WD;
    end

    assign RD = (~rst) ? 32'd0 :(ren==1'b1)? mem[A[11:2]]:32'd0;
    assign i_m_readdata_valid=(ren)?1'b1:1'b0;
    assign i_m_waitrequest=(ren)?1'b0:1'b1;
//    initial begin
//        mem[0] = 32'h00000000;
//        //mem[40] = 32'h00000002;
//    end


endmodule