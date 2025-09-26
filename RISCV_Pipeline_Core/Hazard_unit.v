module hazard_unit( input rst, RegWriteM, RegWriteW, FRegWriteM, FRegWriteW,
    input [4:0] RD_M, RD_W, RD_E, Rs1_E, Rs2_E,  // Added RD_E for load-use detection
    input ResultSrcE, // To detect load-use hazards
    output [1:0] ForwardAE, ForwardBE,
    output StallF, StallD, FlushE); // Pipeline control signals

    wire lwStall; // Load-use hazard detection
    
    // Integer forwarding logic
    assign ForwardAE = (rst == 1'b0) ? 2'b00 : 
                       // EX hazard (higher priority)
                       ((RegWriteM == 1'b1) & (RD_M != 5'h00) & (RD_M == Rs1_E)) ? 2'b10 :
                       // MEM hazard  
                       ((RegWriteW == 1'b1) & (RD_W != 5'h00) & (RD_W == Rs1_E) & 
                        ~((RegWriteM == 1'b1) & (RD_M != 5'h00) & (RD_M == Rs1_E))) ? 2'b01 : 
                       2'b00;
                       
    assign ForwardBE = (rst == 1'b0) ? 2'b00 : 
                       // EX hazard (higher priority)
                       ((RegWriteM == 1'b1) & (RD_M != 5'h00) & (RD_M == Rs2_E)) ? 2'b10 :
                       // MEM hazard
                       ((RegWriteW == 1'b1) & (RD_W != 5'h00) & (RD_W == Rs2_E) & 
                        ~((RegWriteM == 1'b1) & (RD_M != 5'h00) & (RD_M == Rs2_E))) ? 2'b01 : 
                       2'b00;

    // FIXED: Load-use hazard detection - check RD_E not RD_M
    assign lwStall = ((ResultSrcE == 1'b1) & 
                     ((RD_E == Rs1_E) | (RD_E == Rs2_E)) & 
                     (RD_E != 5'h00));

    // Pipeline control signals
    assign StallF = lwStall;
    assign StallD = lwStall;
    assign FlushE = lwStall;

endmodule
