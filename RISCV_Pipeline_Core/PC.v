module PC_Module(input clk,rst_n,o_p_waitrequest,
    input [31:0]PC_Next,
    output reg[31:0]PC);
    


    always @(posedge clk)
    begin
        if(rst_n == 1'b0)
            PC <= 0;
        else if (!o_p_waitrequest)
            PC <= PC_Next;
    end
endmodule
