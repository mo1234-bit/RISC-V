module hazard_unit( input rst_n, RegWriteM, RegWriteW, FRegWriteM, FRegWriteW,
    input [4:0] RD_M, RD_W, RD_E, Rs1_E, Rs2_E,Rs2_D,Rs1_D,DRD_W,
    input ResultSrcE, PCSrcE,ResultSrcM,
    output [1:0] ForwardAE, ForwardBE,
    output StallF, StallD, FlushE,FlushD); 

    wire lwStall; 
    
   
    assign ForwardAE = (rst_n == 1'b0) ? 2'b00 : 
                       ((RegWriteM == 1'b1||FRegWriteM==1'b1) && (RD_M != 5'h00) && (RD_M == Rs1_E)) && !ResultSrcM ? 2'b10 :
                       ((RegWriteW == 1'b1||FRegWriteW==1'b1) && (RD_W != 5'h00) && (RD_W == Rs1_E)) && !ResultSrcM ? 2'b01 : 
                       2'b00;
                       
    assign ForwardBE = (rst_n == 1'b0) ? 2'b00 : 
                       ((RegWriteM == 1'b1||FRegWriteM==1'b1) && (RD_M != 5'h00) && (RD_M == Rs2_E)) && !ResultSrcM ? 2'b10 :
                       ((RegWriteW == 1'b1||FRegWriteW==1'b1) && (RD_W != 5'h00) && (RD_W == Rs2_E)) && !ResultSrcM ? 2'b01 : 
                       2'b00;

  
    assign lwStall = ((ResultSrcE == 1'b1) && 
                     ((RD_E == Rs1_D) || (RD_E == Rs2_D)) && 
                     (RD_E != 5'h00))&&(DRD_W!=Rs1_D&&DRD_W!=Rs2_D)?1:0;
     
     assign FlushD=PCSrcE;
    
    assign StallF = lwStall;
    assign StallD = lwStall;
    assign FlushE = lwStall;

endmodule
