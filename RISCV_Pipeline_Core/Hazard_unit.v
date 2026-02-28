// Hazard Detection and Forwarding Unit
// Handles data hazards, load-use hazards, store dependencies,
// forwarding, pipeline stalls, and flush control
module hazard_unit(
    input clk, rst_n,

    // Register write enables from MEM and WB stages (integer + FP)
    input RegWriteM, RegWriteW,
    input FRegWriteM, FRegWriteW,

    // Decode-stage control signals
    input ResultSrcD,      // Decode-stage instruction reads from memory
    input is_store,        // Store instruction indicator

    // Register destination and source fields
    input [4:0] RD_M, RD_W, RD_E,     // Destination registers (MEM, WB, EX)
    input [4:0] Rs1_E, Rs2_E,         // Source registers in EX stage
    input [4:0] Rs2_D, Rs1_D,         // Source registers in Decode stage
    input [4:0] DRD_W,                // Delayed writeback destination

    // Counters for memory / store latency handling
    input [4:0] counter, counter_1,

    // Pipeline control signals
    input ResultSrcE,      // EX-stage instruction is a load
    input PCSrcE,          // Branch/jump taken in EX stage
    input ResultSrcM,      // MEM-stage instruction is a load
    input finish1,         // Floating-point operation finished
    input is_FOP,          // Floating-point operation in progress
    input is_store_1,      // Store instruction in later stage

    // Instructions (used for opcode-based hazard checks)
    input [31:0] InstrDE, InstrD,InstrDB,InstrDM,

    // Forwarding controls
    output [1:0] ForwardAE, ForwardBE,ForwardA_E_FPU,ForwardB_E_FPU,

    // Pipeline stall / flush controls
    output StallF, StallD,
    output FlushE, FlushD,en_forword_1,

    // Indicates when pipeline is allowed to advance
    output pass,

    // Internal counter used to delay writeback until data is stable
    output reg [4:0] counter1
);

    // Load-use hazard signals
    wire lwStall, lwstall2;
    wire [4:0]Rs1_D_1;
    // Delayed versions of hazard signal (used for store forwarding)
    wire s_1, s_2, s_3, s_4, s_5;
    wire load_after_store_forwarding1,load_after_store_forwarding2,load_after_store_forwarding3,load_after_store_forwarding4,load_after_store_forwarding5;
 wire load_after_store_forwarding=(InstrDM[6:0]==7'b0000111 && InstrDM[14:12]==3'b010 && InstrDB[6:0]==7'b0100111 && InstrDB[14:12]==3'b010)?1:0;
    wire en_forword=((DRD_W == Rs1_D || DRD_W == Rs2_D)&& load_after_store_forwarding5 )?1:0;
    // ---------------------------------------------------------
    // Forwarding logic for ALU input A (Rs1)
    // ---------------------------------------------------------
    assign ForwardAE =
        (rst_n == 1'b0) ? 2'b00 :
        // Forward from MEM stage
        ((RegWriteM || FRegWriteM) &&
         (RD_M != 5'h00) &&
         (RD_M == Rs1_E) &&
         !ResultSrcM) ? 2'b10 :
        // Forward from WB stage
        (((RegWriteW || FRegWriteW) &&
         (RD_W != 5'h00) &&
         (RD_W == Rs1_E) &&
         !ResultSrcM)) ? 2'b01 :
        2'b00;

    // ---------------------------------------------------------
    // Forwarding logic for ALU input B (Rs2)
    // ---------------------------------------------------------
    assign ForwardBE =
        (rst_n == 1'b0) ? 2'b00 :
        // Forward from MEM stage
        ((RegWriteM || FRegWriteM) &&
         (RD_M != 5'h00) &&
         (RD_M == Rs2_E) &&
         !ResultSrcM) ? 2'b10 :
        // Forward from WB stage OR delayed store forwarding
        (((RegWriteW || FRegWriteW) &&
          (RD_W != 5'h00) &&
          (RD_W == Rs2_E) &&
          !ResultSrcM) ||
          (s_5 && is_store_1)) ? 2'b01 :
        2'b00;

 // ---------------------------------------------------------
    // Forwarding logic for FPU input A (Rs2)
    // ---------------------------------------------------------
        assign ForwardA_E_FPU =
        (rst_n == 1'b0) ? 2'b00 :
        // Forward from MEM stage
        ((RegWriteM || FRegWriteM) &&
         (RD_M != 5'h00) &&
         (RD_M == Rs1_E) &&
         !ResultSrcM) ? 2'b10 :
        // Forward from WB stage
        (((RegWriteW || FRegWriteW) &&
         (RD_W != 5'h00) &&
         (RD_W == Rs1_E) &&
         !ResultSrcM)|| en_forword_1) ? 2'b01 :
        2'b00;

    // ---------------------------------------------------------
    // Forwarding logic for FPU input B (Rs2)
    // ---------------------------------------------------------
    assign ForwardB_E_FPU =
        (rst_n == 1'b0) ? 2'b00 :
        // Forward from MEM stage
        (((RegWriteM || FRegWriteM) &&
         (RD_M != 5'h00) &&
         (RD_M == Rs2_E) &&
         !ResultSrcM)) ? 2'b10 :
        // Forward from WB stage OR delayed store forwarding
        (((RegWriteW || FRegWriteW) &&
          (RD_W != 5'h00) &&
          (RD_W == Rs2_E) &&
          !ResultSrcM) ||
          (s_5 && is_store_1)) ? 2'b01 :
        2'b00;


    // ---------------------------------------------------------
    // Detect store depending on a previous load (opcode-based)
    // Used to handle memory hazards correctly
    // ---------------------------------------------------------
    wire s = ((ResultSrcE == 1'b1) &&
             (
              (InstrD[6:0]  == 7'b0100011 && InstrDE[6:0] == 7'b0000011) || // SW after LW
              (InstrDE[6:0] == 7'b0000111 && InstrD[6:0]  == 7'b0100111)     // FSW after FLW
             ) &&
             ((RD_E == Rs1_D) || (RD_E == Rs2_D)) &&
             (RD_E != 5'h00));

    // ---------------------------------------------------------
    // Load-use hazard detection
    // Stall if EX-stage load is needed by Decode-stage instruction
    // ---------------------------------------------------------
   
    assign lwStall =
        (ResultSrcE == 1'b1) &&
        ((RD_E == Rs1_D) || (RD_E == Rs2_D)) &&
        (RD_E != 5'h00) &&
        (DRD_W != Rs1_D && DRD_W != Rs2_D);
   wire q= (RD_W==Rs1_D_1);
    // ---------------------------------------------------------
    // Stall due to memory latency or store waiting for data
    // ---------------------------------------------------------
    assign lwstall2 =
        ((counter_1 != 5'd2 && ResultSrcM == 1'b1) ||
         (counter != 5'd3 && is_store)) ? 1'b1 : 1'b0;

    // ---------------------------------------------------------
    // Pipeline flush and stall control
    // ---------------------------------------------------------
    assign FlushD = PCSrcE && (InstrDE[6:0]!=7'b1100011);              // Flush Decode on branch/jump
    assign pass   = ((lwStall && !lwstall2) ||
                     (is_FOP && finish1)) ? 1'b1 : 1'b0;

    assign StallF = lwStall || lwstall2; // Stall Fetch
    assign StallD = lwStall || lwstall2; // Stall Decode
    assign FlushE = lwStall || lwstall2; // Flush Execute

    // ---------------------------------------------------------
    // Counter logic
    // Ensures writeback occurs only when cache/memory data is stable
    // ---------------------------------------------------------
    reg en;

    always @(posedge clk) begin
        if (!rst_n) begin
            en       <= 1'b0;
            counter1 <= 5'd0;
        end
        else begin
            // Enable counter when Decode depends on MEM load
            if ((Rs1_D == RD_M) && ResultSrcD)
                en <= 1'b1;

            // Disable counter after timeout or hazard resolution
            if (counter1 > 5'd17 || s)
                en <= 1'b0;

            // Increment counter while enabled
            if (en)
                counter1 <= counter1 + 1'b1;

            // Reset counter after completion or hazard
            if (counter1 == 5'd19 || s)
                counter1 <= 5'd0;
        end
    end

    // ---------------------------------------------------------
    // Delay hazard signal for store forwarding alignment
    // ---------------------------------------------------------
    D #(1) flip  (.in(s),   .out(s_1), .clk(clk), .rst_n(rst_n));
    D #(1) flip1 (.in(s_1), .out(s_2), .clk(clk), .rst_n(rst_n));
    D #(1) flip2 (.in(s_2), .out(s_3), .clk(clk), .rst_n(rst_n));
    D #(1) flip3 (.in(s_3), .out(s_4), .clk(clk), .rst_n(rst_n));
    D #(1) flip4 (.in(s_4), .out(s_5), .clk(clk), .rst_n(rst_n));


    D #(1) flip5  (.in(load_after_store_forwarding),   .out(load_after_store_forwarding1), .clk(clk), .rst_n(rst_n));
    D #(1) flip6 (.in(load_after_store_forwarding1), .out(load_after_store_forwarding2), .clk(clk), .rst_n(rst_n));
    D #(1) flip7 (.in(load_after_store_forwarding2), .out(load_after_store_forwarding3), .clk(clk), .rst_n(rst_n));
    D #(1) flip8 (.in(load_after_store_forwarding3), .out(load_after_store_forwarding4), .clk(clk), .rst_n(rst_n));
    D #(1) flip9 (.in(load_after_store_forwarding4), .out(load_after_store_forwarding5), .clk(clk), .rst_n(rst_n));
     D #(1) flip10 (.in(en_forword), .out(en_forword_1), .clk(clk), .rst_n(rst_n));
          D #(5) flip11 (.in(Rs1_D), .out(Rs1_D_1), .clk(clk), .rst_n(rst_n));
endmodule
