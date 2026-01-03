module writeback_cycle(input ResultSrcW,FResultSrcW,
input [31:0] PCPlus4W, ALU_ResultW, ReadDataW,FPU_ResultW,fReadDataW,
output [31:0] ResultW,fResultW,
output ResultSrcR);

assign ResultSrcR =ResultSrcW ;

Mux result_mux (    
                .a(ALU_ResultW),
                .b(ReadDataW),
                .s(ResultSrcW),
                .c(ResultW)
                );
Mux fpu_result_mux (    
                .a(FPU_ResultW),
                .b(fReadDataW),
                .s(FResultSrcW),
                .c(fResultW)
                );
endmodule