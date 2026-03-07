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
    input [4:0] Rs2_D, Rs1_D, Rs1_M,Rs2_M,        // Source registers in Decode stage
    input [4:0] DRD_W,                // Delayed writeback destination

    // Counters for memory / store latency handling
    input [4:0] counter, counter_1,

    // Pipeline control signals
    input ResultSrcE, ResultSrcW,     // EX-stage instruction is a load
    input PCSrcE,          // Branch/jump taken in EX stage
    input ResultSrcM,      // MEM-stage instruction is a load
    input finish1,         // Floating-point operation finished
    input is_FOP,          // Floating-point operation in progress
    input is_store_1,JumpW,JumpE, FResultSrcE,     // Store instruction in later stage

    // Instructions (used for opcode-based hazard checks)
    input [31:0] InstrDE, InstrD,InstrDB,InstrDM,

    // Forwarding controls
    output [1:0] ForwardAE, ForwardBE,ForwardA_E_FPU,ForwardB_E_FPU,

    // Pipeline stall / flush controls
    output StallF, StallD,
    output FlushE, FlushD,

    // Indicates when pipeline is allowed to advance
    output pass,

    // Internal counter used to delay writeback until data is stable
    output reg [4:0] counter1,

    output reg regfile_en,
    output n,
    output pass_load,
    input w
);

    // Load-use hazard signals
    reg [3:0]counter_2;
    reg en_J;
    wire lwStall, lwstall2,JumpW_1;
    wire [4:0]Rs1_E_1,RD_M_1;
    wire Jump_dep=(Rs1_E==RD_M && JumpE);
    // Delayed versions of hazard signal (used for store forwarding)
    wire w1,w2,w3,w4,w5,w6;


    //when a load comes after store then an flouting point operation is executing we need to forward the result of loading
    wire load_after_store_forwarding1,load_after_store_forwarding2,load_after_store_forwarding3,
    wire load_after_store_forwarding4,load_after_store_forwarding5;
      wire s_1, s_2, s_3, s_4, s_5,en_forward_1;

 wire load_after_store_forwarding=(InstrDM[6:0]==7'b0000111 && InstrDM[14:12]==3'b010 && InstrDB[6:0]==7'b0100111 &&
  InstrDB[14:12]==3'b010)?1:0;

    wire en_forward=((DRD_W == Rs1_D || DRD_W == Rs2_D)&& load_after_store_forwarding5 )?1:0;

    // when a load is follwed by another load then an integer operation that used the rd of the two prev loades we need to forward 
    wire forward=(RD_W==Rs1_E)&& (RD_M==Rs1_E || RD_M==Rs2_E) && Rs1_E!=5'd0 &&InstrDB!=InstrDM&&
    (InstrDB[6:0]==7'b0000011 && InstrDM[6:0]==7'b0000011 && InstrDB[14:12]==3'b010 &&InstrDM[14:12]==3'b010);

    wire forward_b=( RD_W==Rs2_E)&& (RD_M==Rs2_E ||RD_M==Rs1_E ) && Rs2_E!=5'd0&& InstrDB!=InstrDM&&
    (InstrDB[6:0]==7'b0000011 && InstrDM[6:0]==7'b0000011&& InstrDB[14:12]==3'b010 &&InstrDM[14:12]==3'b010);

 // when there is a chain of loades followed each followed with an interger operation depend on it's prev load LW ->INT ->LW ->INT 
 //so we need to stall and then forward

  wire p_1,p_2,p_3,p_4,p2_1,p2_2,p2_3,p2_4,p_5,p_6,p_7,p2_5,p2_6,p2_7;
   
   

wire p1=(ResultSrcE  && ResultSrcW) && !FResultSrcE&&
        ((RD_E == Rs1_D) ) && InstrDM!=InstrDB&&
        (RD_E != 5'h00) && (RD_W==Rs1_M) ;

wire p2=(ResultSrcE && ResultSrcW) &&
        ( (RD_E == Rs2_D)) && InstrDM!=InstrDB&&
        (RD_E != 5'h00) && ( RD_W==Rs2_M ) ; 

// when an Integer operation depend on two prev LW operations so we need to stall both
wire m=(ResultSrcM  && ResultSrcE && !ResultSrcD)&& InstrDM!=InstrDE&&
((Rs1_D==RD_E && Rs2_D==RD_M) || (Rs2_D==RD_E||Rs1_D==RD_M) && (Rs2_D!=Rs1_D));

// this is an load hazard with this sequence sw -> load depended(sw) -> integer depended(lw) operation not coverd in lwstall
wire o=(InstrDE[6:0]==7'b0000011 && 
        ((RD_E == Rs1_D) || (RD_E == Rs2_D)) &&
        (RD_E != 5'h00) && InstrDM[6:0]==7'b0100011 && counter==3&&
       ( (DRD_W == Rs1_D || DRD_W == Rs2_D))) && !lwstall2;

//this for a load hazaed which is not covered in lwstall 
 wire a1,a2,a3,a4,a5,a6,a7;
wire a= ( (ResultSrcE == 1'b1) &&InstrD[6:0]!= 7'b1100011&&
        ((RD_E == Rs1_D) || (RD_E == Rs2_D)) &&
        (RD_E != 5'h00) ) &&!lwstall2 && counter1!=5'd0 && counter_1!=2;
    // ---------------------------------------------------------
    // Forwarding logic for ALU input A (Rs1)
    // ---------------------------------------------------------
    assign ForwardAE =
        (rst_n == 1'b0) ? 2'b00 :
        // Forward from MEM stage
        ((RegWriteM ) &&
         (RD_M != 5'h00) &&
         (RD_M == Rs1_E) &&
         !ResultSrcM) ? 2'b10 :
        // Forward from WB stage
        (((RegWriteW ) &&
         (RD_W != 5'h00) &&
         (RD_W == Rs1_E) &&
         !ResultSrcM))||forward || (p_4 || p_5 || p_6 || p_7)||(w3||w4||w5||w6)||(a4||a5||a6||a7)? 2'b01 :
        2'b00;

    // ---------------------------------------------------------
    // Forwarding logic for ALU input B (Rs2)
    // ---------------------------------------------------------
    assign ForwardBE =
        (rst_n == 1'b0) ? 2'b00 :
        // Forward from MEM stage
        ((RegWriteM ) &&
         (RD_M != 5'h00) &&
         (RD_M == Rs2_E) &&
         !ResultSrcM) ? 2'b10 :
        // Forward from WB stage OR delayed store forwarding
        (((RegWriteW ) &&
          (RD_W != 5'h00) &&
          (RD_W == Rs2_E) &&
          !ResultSrcM) ||
          (s_5 && is_store_1)) ||forward_b || (p2_4 || p2_5 || p2_6 || p2_7)? 2'b01 :
        2'b00;

 // ---------------------------------------------------------
    // Forwarding logic for FPU input A (Rs2)
    // ---------------------------------------------------------
        assign ForwardA_E_FPU =
        (rst_n == 1'b0) ? 2'b00 :
        // Forward from MEM stage
        (( FRegWriteM) &&
         (RD_M != 5'h00) &&
         (RD_M == Rs1_E) &&
         !ResultSrcM) ? 2'b10 :
        // Forward from WB stage
        ((( FRegWriteW) &&
         (RD_W != 5'h00) &&
         (RD_W == Rs1_E) &&
         !ResultSrcM)|| en_forward_1) ? 2'b01 :
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
              (InstrD[6:0]  == 7'b0100011 && InstrDE[6:0] == 7'b0000011  &&InstrDE[14:12]==3'b010  &&InstrD[14:12]==3'b010) || // SW after LW
              (InstrDE[6:0] == 7'b0000111 && InstrD[6:0]  == 7'b0100111  &&InstrDE[14:12]==3'b010  &&InstrD[14:12]==3'b010)     // FSW after FLW
             ) &&
             ((RD_E == Rs1_D) || (RD_E == Rs2_D)) &&
             (RD_E != 5'h00));

    // ---------------------------------------------------------
    // Load-use hazard detection
    // Stall if EX-stage load is needed by Decode-stage instruction
    // ---------------------------------------------------------
      
    assign lwStall =
       ( (ResultSrcE == 1'b1) &&
        ((RD_E == Rs1_D) || (RD_E == Rs2_D)) &&
        (RD_E != 5'h00) &&
       ( (DRD_W != Rs1_D && DRD_W != Rs2_D)||p1||p2||m))||o||a;
   
    // ---------------------------------------------------------
    // Stall due to memory latency or store waiting for data 
    // counter_1 for number of cycles a read from cache need
    // counter for number of cycles a write in cache need
    // ---------------------------------------------------------
    assign lwstall2 =
        ((counter_1 != 5'd2 && ResultSrcM == 1'b1) ||
         (counter != 5'd3 && is_store)) ? 1'b1 : 1'b0;

    // ---------------------------------------------------------
    // Pipeline flush and stall control
    // ---------------------------------------------------------
    assign FlushD = PCSrcE && (InstrDE[6:0]!=7'b1100011);              // Flush Decode on branch/jump
    assign pass   = ((lwStall && !lwstall2&& !o&&!a ) || (counter_2==1)||
                     (is_FOP && finish1)) ? 1'b1 : 1'b0;
    assign pass_load=o||a;
    assign StallF = lwStall || lwstall2; // Stall Fetch
    assign StallD = lwStall || lwstall2; // Stall Decode
    assign FlushE = lwStall || lwstall2; // Flush Execute

    // ---------------------------------------------------------
    // Counter logic
    // Ensures writeback occurs only when cache/memory data is stable
    // 17 is number of cycles which after it the system is stable
    // as in this cycles the WD in REGFILE has Corrupted data and must not be writen
    // Except for the load hazard cases
    // and after two of that is the time need for finishing the operation(19)
    // ---------------------------------------------------------
    reg en;
    wire [31:0]InstrDB1;
    assign n=(counter1>9 && InstrDB[6:0]!=7'b0100011 && RegWriteW && InstrDB1!=InstrDB)?1:0;
    reg en_1;
    always @(posedge clk) begin
        if (!rst_n) begin
            en       <= 1'b0;
            counter1 <= 5'd0;
            counter_2<=0;
            en_1<=0;
        end
        else begin
            // Enable counter when Decode depends on MEM load
            if ((Rs1_D == RD_M) && ResultSrcD )
                en <= 1'b1;

            // Disable counter after timeout or hazard resolution
            if (counter1 > 5'd17 || s )
                en <= 1'b0;

            // Increment counter while enabled
            if (en)
                counter1 <= counter1 + 1'b1;

            // Reset counter after completion or hazard
            if (counter1 == 5'd19 || s || forward ||m)
                counter1 <= 5'd0;
        end

        if(o||a)
        en_1<=1;

        if(en_1)
        counter_2<=counter_2+1;
        if(counter_2==1)begin
        counter_2<=0;
        en_1<=0;
        end
    end

     always @(posedge clk) begin
        if (!rst_n) begin
            en_J       <= 1'b0;
            regfile_en<=0;
        end
        else begin
           if(Jump_dep)
           en_J<=1;

           if(en_J)begin
           regfile_en<=1;
           en_J<=0;
           end
           else 
           regfile_en<=0;
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
    D #(1) flip10 (.in(en_forward), .out(en_forward_1), .clk(clk), .rst_n(rst_n));
    D #(5) flip11 (.in(Rs1_E), .out(Rs1_E_1), .clk(clk), .rst_n(rst_n));
    D #(5) flip12 (.in(RD_M), .out(RD_M_1), .clk(clk), .rst_n(rst_n));
    D #(1) flip13 (.in(JumpW), .out(JumpW_1), .clk(clk), .rst_n(rst_n));
    D #(1) flip14 (.in(p1), .out(p_1), .clk(clk), .rst_n(rst_n));
    D #(1) flip15 (.in(p_1), .out(p_2), .clk(clk), .rst_n(rst_n));
    D #(1) flip16 (.in(p_2), .out(p_3), .clk(clk), .rst_n(rst_n));
    D #(1) flip17 (.in(p_3), .out(p_4), .clk(clk), .rst_n(rst_n));
    D #(1) flip18 (.in(p_4), .out(p_5), .clk(clk), .rst_n(rst_n));
    D #(1) flip19 (.in(p_5), .out(p_6), .clk(clk), .rst_n(rst_n));
    D #(1) flip20 (.in(p_6), .out(p_7), .clk(clk), .rst_n(rst_n));
    D #(1) flip21 (.in(p2), .out(p2_1), .clk(clk), .rst_n(rst_n));
    D #(1) flip22 (.in(p2_1), .out(p2_2), .clk(clk), .rst_n(rst_n));
    D #(1) flip23 (.in(p2_2), .out(p2_3), .clk(clk), .rst_n(rst_n));
    D #(1) flip24 (.in(p2_3), .out(p2_4), .clk(clk), .rst_n(rst_n));
    D #(1) flip25 (.in(p2_4), .out(p2_5), .clk(clk), .rst_n(rst_n));
    D #(1) flip26 (.in(p2_5), .out(p2_6), .clk(clk), .rst_n(rst_n));
    D #(1) flip27 (.in(p2_6), .out(p2_7), .clk(clk), .rst_n(rst_n));
    D #(32) flip28 (.in(InstrDB), .out(InstrDB1), .clk(clk), .rst_n(rst_n));
    D #(1) flip29 (.in(w), .out(w1), .clk(clk), .rst_n(rst_n));
    D #(1) flip30 (.in(w1), .out(w2), .clk(clk), .rst_n(rst_n));
    D #(1) flip31 (.in(w2), .out(w3), .clk(clk), .rst_n(rst_n));
    D #(1) flip32 (.in(w3), .out(w4), .clk(clk), .rst_n(rst_n));
    D #(1) flip33 (.in(w4), .out(w5), .clk(clk), .rst_n(rst_n));
    D #(1) flip34 (.in(w5), .out(w6), .clk(clk), .rst_n(rst_n));
    D #(1) flip35 (.in(a), .out(a1), .clk(clk), .rst_n(rst_n));
    D #(1) flip36 (.in(a1), .out(a2), .clk(clk), .rst_n(rst_n));
    D #(1) flip37 (.in(a2), .out(a3), .clk(clk), .rst_n(rst_n));
    D #(1) flip38 (.in(a3), .out(a4), .clk(clk), .rst_n(rst_n));
    D #(1) flip39 (.in(a4), .out(a5), .clk(clk), .rst_n(rst_n));
    D #(1) flip40 (.in(a5), .out(a6), .clk(clk), .rst_n(rst_n));
    D #(1) flip41 (.in(a6), .out(a7), .clk(clk), .rst_n(rst_n));
endmodule
