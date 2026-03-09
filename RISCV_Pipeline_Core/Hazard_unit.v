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
    wire jump_rs1_mem_dep=(Rs1_E==RD_M && JumpE);
    // Delayed versions of hazard signal (used for store forwarding)
    wire cache_write_read_conflict1,cache_write_read_conflict2,cache_write_read_conflict3,cache_write_read_conflict4,cache_write_read_conflict5,cache_write_read_conflict6;


    //when a load comes after store then an flouting point operation is executing we need to forward the result of loading
    wire load_after_store_forwarding1,load_after_store_forwarding2,load_after_store_forwarding3;
    wire load_after_store_forwarding4,load_after_store_forwarding5;
      wire store_after_load_dep_1, store_after_load_dep_2, store_after_load_dep_3, store_after_load_dep_4, store_after_load_dep_5,fp_store_load_fwd_en_1;

 wire load_after_store_forwarding=(InstrDM[6:0]==7'b0000111 && InstrDM[14:12]==3'b010 && InstrDB[6:0]==7'b0100111 &&
  InstrDB[14:12]==3'b010)?1:0;

    wire fp_store_load_fwd_en=((DRD_W == Rs1_D || DRD_W == Rs2_D)&& load_after_store_forwarding5 )?1:0;

    // when a load is follwed by another load then an integer operation that used the rd of the two prev loades we need to forward 
    wire double_load_wb_fwd_rs1=(RD_W==Rs1_E)&& (RD_M==Rs1_E || RD_M==Rs2_E) && Rs1_E!=5'd0 &&InstrDB!=InstrDM&&
    (InstrDB[6:0]==7'b0000011 && InstrDM[6:0]==7'b0000011 && InstrDB[14:12]==3'b010 &&InstrDM[14:12]==3'b010);

    wire double_load_wb_fwd_rs2=( RD_W==Rs2_E)&& (RD_M==Rs2_E ||RD_M==Rs1_E ) && Rs2_E!=5'd0&& InstrDB!=InstrDM&&
    (InstrDB[6:0]==7'b0000011 && InstrDM[6:0]==7'b0000011&& InstrDB[14:12]==3'b010 &&InstrDM[14:12]==3'b010);

 // when there is a chain of loades followed each followed with an interger operation depend on it's prev load LW ->INT ->LW ->INT 
 //so we need to stall and then forward

  wire consec_load_fwd_rs1_1,consec_load_fwd_rs1_2,consec_load_fwd_rs1_3,consec_load_fwd_rs1_4,consec_load_fwd_rs2_1;
  wire consec_load_fwd_rs2_2,consec_load_fwd_rs2_3,consec_load_fwd_rs2_4,consec_load_fwd_rs1_5,consec_load_fwd_rs1_6;
  wire consec_load_fwd_rs1_7,consec_load_fwd_rs2_5,consec_load_fwd_rs2_6,consec_load_fwd_rs2_7;
   
   

wire consec_load_fwd_rs1=(ResultSrcE  && ResultSrcW) && !FResultSrcE&&
        ((RD_E == Rs1_D) ) && InstrDM!=InstrDB&&
        (RD_E != 5'h00) && (RD_W==Rs1_M) ;

wire consec_load_fwd_rs2=(ResultSrcE && ResultSrcW) &&
        ( (RD_E == Rs2_D)) && InstrDM!=InstrDB&&
        (RD_E != 5'h00) && ( RD_W==Rs2_M ) ; 

// when an Integer operation depend on two prev LW operations so we need to stall both
wire dual_load_src_dep=(ResultSrcM  && ResultSrcE && !ResultSrcD)&& InstrDM!=InstrDE&&
((Rs1_D==RD_E && Rs2_D==RD_M) || (Rs2_D==RD_E||Rs1_D==RD_M) && (Rs2_D!=Rs1_D));

// this is an load hazard with this sequence sw -> load depended(sw) -> integer depended(lw) operation not coverd in lwstall
wire sw_lw_int_chain_hazard=(InstrDE[6:0]==7'b0000011 && 
        ((RD_E == Rs1_D) || (RD_E == Rs2_D)) &&
        (RD_E != 5'h00) && InstrDM[6:0]==7'b0100011 && counter==3&&
       ( (DRD_W == Rs1_D || DRD_W == Rs2_D))) && !lwstall2;

//this for a load hazaed which is not covered in lwstall 
 wire load_hazard_late1 ,load_hazard_late2 ,load_hazard_late3,load_hazard_late4,
 load_hazard_late5,load_hazard_late6,load_hazard_late7;

wire load_hazard_late = ( (ResultSrcE == 1'b1) &&InstrD[6:0]!= 7'b1100011&&
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
         !ResultSrcM))||double_load_wb_fwd_rs1 || (consec_load_fwd_rs1_4 || consec_load_fwd_rs1_5
          || consec_load_fwd_rs1_6 || consec_load_fwd_rs1_7)||
         (cache_write_read_conflict3||cache_write_read_conflict4||cache_write_read_conflict5||cache_write_read_conflict6)
         ||(load_hazard_late4||load_hazard_late5||load_hazard_late6||load_hazard_late7)? 2'b01 :
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
          (store_after_load_dep_5 && is_store_1)) ||double_load_wb_fwd_rs2 || (consec_load_fwd_rs2_4 ||
           consec_load_fwd_rs2_5 || consec_load_fwd_rs2_6 || consec_load_fwd_rs2_7)? 2'b01 :
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
         !ResultSrcM)|| fp_store_load_fwd_en_1) ? 2'b01 :
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
          (store_after_load_dep_5 && is_store_1)) ? 2'b01 :
        2'b00;


    // ---------------------------------------------------------
    // Detect store depending on a previous load (opcode-based)
    // Used to handle memory hazards correctly
    // ---------------------------------------------------------
    wire store_after_load_dep = ((ResultSrcE == 1'b1) &&
             (
              (InstrD[6:0]  == 7'b0100011 && InstrDE[6:0] == 7'b0000011  &&InstrDE[14:12]==3'b010
                &&InstrD[14:12]==3'b010) || (InstrDE[6:0] == 7'b0000111 && InstrD[6:0]  == 7'b0100111 
                 &&InstrDE[14:12]==3'b010  &&InstrD[14:12]==3'b010)     // FSW after FLW
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
       ( (DRD_W != Rs1_D && DRD_W != Rs2_D)||consec_load_fwd_rs1||consec_load_fwd_rs2||dual_load_src_dep))
       ||sw_lw_int_chain_hazard||load_hazard_late;
   
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
    assign pass   = ((lwStall && !lwstall2&& !sw_lw_int_chain_hazard&&!load_hazard_late ) || (counter_2==1)||
                     (is_FOP && finish1)) ? 1'b1 : 1'b0;
    assign pass_load=sw_lw_int_chain_hazard||load_hazard_late;
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
            if (counter1 > 5'd17 || store_after_load_dep )
                en <= 1'b0;

            // Increment counter while enabled
            if (en)
                counter1 <= counter1 + 1'b1;

            // Reset counter after completion or hazard
            if (counter1 == 5'd19 || store_after_load_dep || double_load_wb_fwd_rs1 ||dual_load_src_dep)
                counter1 <= 5'd0;
        end

        if(sw_lw_int_chain_hazard||load_hazard_late)
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
           if(jump_rs1_mem_dep)
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
    D #(1) flip  (.in(store_after_load_dep),   .out(store_after_load_dep_1), .clk(clk), .rst_n(rst_n));
    D #(1) flip1 (.in(store_after_load_dep_1), .out(store_after_load_dep_2), .clk(clk), .rst_n(rst_n));
    D #(1) flip2 (.in(store_after_load_dep_2), .out(store_after_load_dep_3), .clk(clk), .rst_n(rst_n));
    D #(1) flip3 (.in(store_after_load_dep_3), .out(store_after_load_dep_4), .clk(clk), .rst_n(rst_n));
    D #(1) flip4 (.in(store_after_load_dep_4), .out(store_after_load_dep_5), .clk(clk), .rst_n(rst_n));
    D #(1) flip5  (.in(load_after_store_forwarding),   .out(load_after_store_forwarding1), .clk(clk), .rst_n(rst_n));
    D #(1) flip6 (.in(load_after_store_forwarding1), .out(load_after_store_forwarding2), .clk(clk), .rst_n(rst_n));
    D #(1) flip7 (.in(load_after_store_forwarding2), .out(load_after_store_forwarding3), .clk(clk), .rst_n(rst_n));
    D #(1) flip8 (.in(load_after_store_forwarding3), .out(load_after_store_forwarding4), .clk(clk), .rst_n(rst_n));
    D #(1) flip9 (.in(load_after_store_forwarding4), .out(load_after_store_forwarding5), .clk(clk), .rst_n(rst_n));
    D #(1) flip10 (.in(fp_store_load_fwd_en), .out(fp_store_load_fwd_en_1), .clk(clk), .rst_n(rst_n));
    D #(5) flip11 (.in(Rs1_E), .out(Rs1_E_1), .clk(clk), .rst_n(rst_n));
    D #(5) flip12 (.in(RD_M), .out(RD_M_1), .clk(clk), .rst_n(rst_n));
    D #(1) flip13 (.in(JumpW), .out(JumpW_1), .clk(clk), .rst_n(rst_n));
    D #(1) flip14 (.in(consec_load_fwd_rs1), .out(consec_load_fwd_rs1_1), .clk(clk), .rst_n(rst_n));
    D #(1) flip15 (.in(consec_load_fwd_rs1_1), .out(consec_load_fwd_rs1_2), .clk(clk), .rst_n(rst_n));
    D #(1) flip16 (.in(consec_load_fwd_rs1_2), .out(consec_load_fwd_rs1_3), .clk(clk), .rst_n(rst_n));
    D #(1) flip17 (.in(consec_load_fwd_rs1_3), .out(consec_load_fwd_rs1_4), .clk(clk), .rst_n(rst_n));
    D #(1) flip18 (.in(consec_load_fwd_rs1_4), .out(consec_load_fwd_rs1_5), .clk(clk), .rst_n(rst_n));
    D #(1) flip19 (.in(consec_load_fwd_rs1_5), .out(consec_load_fwd_rs1_6), .clk(clk), .rst_n(rst_n));
    D #(1) flip20 (.in(consec_load_fwd_rs1_6), .out(consec_load_fwd_rs1_7), .clk(clk), .rst_n(rst_n));
    D #(1) flip21 (.in(consec_load_fwd_rs2), .out(consec_load_fwd_rs2_1), .clk(clk), .rst_n(rst_n));
    D #(1) flip22 (.in(consec_load_fwd_rs2_1), .out(consec_load_fwd_rs2_2), .clk(clk), .rst_n(rst_n));
    D #(1) flip23 (.in(consec_load_fwd_rs2_2), .out(consec_load_fwd_rs2_3), .clk(clk), .rst_n(rst_n));
    D #(1) flip24 (.in(consec_load_fwd_rs2_3), .out(consec_load_fwd_rs2_4), .clk(clk), .rst_n(rst_n));
    D #(1) flip25 (.in(consec_load_fwd_rs2_4), .out(consec_load_fwd_rs2_5), .clk(clk), .rst_n(rst_n));
    D #(1) flip26 (.in(consec_load_fwd_rs2_5), .out(consec_load_fwd_rs2_6), .clk(clk), .rst_n(rst_n));
    D #(1) flip27 (.in(consec_load_fwd_rs2_6), .out(consec_load_fwd_rs2_7), .clk(clk), .rst_n(rst_n));
    D #(32) flip28 (.in(InstrDB), .out(InstrDB1), .clk(clk), .rst_n(rst_n));
    D #(1) flip29 (.in(w), .out(cache_write_read_conflict1), .clk(clk), .rst_n(rst_n));
    D #(1) flip30 (.in(cache_write_read_conflict1), .out(cache_write_read_conflict2), .clk(clk), .rst_n(rst_n));
    D #(1) flip31 (.in(cache_write_read_conflict2), .out(cache_write_read_conflict3), .clk(clk), .rst_n(rst_n));
    D #(1) flip32 (.in(cache_write_read_conflict3), .out(cache_write_read_conflict4), .clk(clk), .rst_n(rst_n));
    D #(1) flip33 (.in(cache_write_read_conflict4), .out(cache_write_read_conflict5), .clk(clk), .rst_n(rst_n));
    D #(1) flip34 (.in(cache_write_read_conflict5), .out(cache_write_read_conflict6), .clk(clk), .rst_n(rst_n));
    D #(1) flip35 (.in(load_hazard_late), .out(load_hazard_late1 ), .clk(clk), .rst_n(rst_n));
    D #(1) flip36 (.in(load_hazard_late1 ), .out(load_hazard_late2 ), .clk(clk), .rst_n(rst_n));
    D #(1) flip37 (.in(load_hazard_late2 ), .out(load_hazard_late3), .clk(clk), .rst_n(rst_n));
    D #(1) flip38 (.in(load_hazard_late3), .out(load_hazard_late4), .clk(clk), .rst_n(rst_n));
    D #(1) flip39 (.in(load_hazard_late4), .out(load_hazard_late5), .clk(clk), .rst_n(rst_n));
    D #(1) flip40 (.in(load_hazard_late5), .out(load_hazard_late6), .clk(clk), .rst_n(rst_n));
    D #(1) flip41 (.in(load_hazard_late6), .out(load_hazard_late7), .clk(clk), .rst_n(rst_n));
endmodule
