module writeback_cycle(input clk, rst, ResultSrcW,fResultSrcW,
input [31:0] PCPlus4W, ALU_ResultW, ReadDataW,FPU_ResultW,fReadDataW,
input o_p_waitrequest,
output [31:0] ResultW,fResultW);



Mux result_mux (    
                .a(ALU_ResultW),
                .b(ReadDataW),
                .s(ResultSrcW),
                .c(ResultW)
                );
Mux fpu_result_mux (    
                .a(FPU_ResultW),
                .b(fReadDataW),
                .s(fResultSrcW),
                .c(fResultW)
                );
endmodule