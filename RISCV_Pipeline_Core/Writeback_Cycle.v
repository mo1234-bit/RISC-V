module writeback_cycle(clk, rst, ResultSrcW, PCPlus4W, ALU_ResultW, ReadDataW, ResultW,o_p_waitrequest);

input clk, rst, ResultSrcW;
input [31:0] PCPlus4W, ALU_ResultW, ReadDataW;
input o_p_waitrequest;
output [31:0] ResultW;

Mux result_mux (    
                .a(ALU_ResultW),
                .b(ReadDataW),
                .s(ResultSrcW),
                .c(ResultW)
                );
endmodule