// Memory Stage (MEM stage) of the pipeline
// Handles memory read/write, floating-point writeback, pipeline registers, and cache interface
module memory_cycle(
    input clk, rst_n,                     // Clock and synchronous reset
    input RegWriteM, FRegWriteM, MemWriteM, pass, stall,
    input ResultSrcM, FResultSrcM,        // Control signals
    input [4:0] RD_M,                     // Destination register
    input [31:0] PCPlus4M, WriteDataM, ALU_ResultM, FPU_ResultEM, InstrDM,  // Data from EX stage
    output RegWriteW, ResultSrcW, 
    output [4:0] RD_W, DRDW,
    output [31:0] PCPlus4W, ALU_ResultW, ReadDataW, FPU_ResultEW, fReadDataW,
    output FRegWriteMW, FResultSrcW,
    output reg [31:0] instr,             // Instruction for debugging / pipeline trace
    output reg [4:0] counter, counter_1  // Counters for stall/wait management
);

    // -----------------------------
    // Pipeline registers (MEM -> WB)
    // -----------------------------
    wire [31:0] ReadDataM;
    reg RegWriteM_r, FRegWriteM_r, ResultSrcM_r, FResultSrcM_r;
    reg [4:0] RD_M_r, mem_tag_M_r;
    reg [31:0] PCPlus4M_r, ALU_ResultM_r, ReadDataM_r, FPU_ResultEM_r, fReadDataM_r;
   
    // -----------------------------
    // Cache interface signals
    // -----------------------------
    wire [24:0] i_p_addr;
    wire [3:0] i_p_byte_en;
    wire [31:0] i_p_writedata;
    wire i_p_read;
     wire o_p_readdata_valid;
    wire i_p_write;
    wire [31:0] o_p_readdata;
    wire [25:0] o_m_addr;
    wire [31:0] o_m_writedata;
    wire o_m_read, o_m_write;
    wire [31:0] i_m_readdata;
    wire i_m_readdata_valid;
    wire i_m_waitrequest, o_p_waitrequest1;

    // -----------------------------
    // Cache memory control
    // -----------------------------
    assign i_p_addr = ALU_ResultM[24:0];  // Memory address from ALU
    assign i_p_byte_en = 4'b1111;         // Full word access
    assign i_p_writedata = WriteDataM;    // Data to write to memory
    assign i_p_read = (ResultSrcM || FResultSrcM) && !MemWriteM; // Read if load/floating load
    assign i_p_write = MemWriteM;         // Write if store
    assign ReadDataM = o_p_readdata;      // Read data from cache
    wire [31:0] fReadDataM = o_p_readdata; // Floating-point memory read

    wire stall_C;  // Cache stall signal

    // -----------------------------
    // Cache module
    // -----------------------------
    cache dut(
        .clk(clk),
        .rst_n(rst_n),
        .i_p_addr(i_p_addr),
        .i_p_byte_en(i_p_byte_en),
        .i_p_writedata(i_p_writedata),
        .i_p_read(i_p_read),
        .i_p_write(i_p_write),
        .stall(stall_C),
        .o_p_readdata(o_p_readdata),
        .o_p_readdata_valid(o_p_readdata_valid),
        .o_p_waitrequest(o_p_waitrequest1),
        .o_m_addr(o_m_addr),
        .o_m_writedata(o_m_writedata),
        .o_m_read(o_m_read),
        .o_m_write(o_m_write),
        .i_m_readdata(i_m_readdata),
        .i_m_readdata_valid(i_m_readdata_valid),
        .i_m_waitrequest(i_m_waitrequest)
    );

    // -----------------------------
    // Data memory (main memory)
    // -----------------------------
    Data_Memory dmem(
        .clk(clk),
        .rst_n(rst_n),
        .WE(o_m_write),
        .WD(o_m_writedata),
        .i_m_readdata_valid(i_m_readdata_valid),
        .i_m_waitrequest(i_m_waitrequest),
        .ren(o_m_read),
        .A({6'b000000, o_m_addr}),  // Extend address to 32-bit
        .RD(i_m_readdata)
    );

    // -----------------------------
    // Pipeline registers: latch MEM -> WB
    // -----------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset all pipeline registers
            RegWriteM_r <= 1'b0; 
            ResultSrcM_r <= 1'b0;
            RD_M_r <= 5'h00;
            PCPlus4M_r <= 32'h00000000; 
            ALU_ResultM_r <= 32'h00000000; 
            ReadDataM_r <= 32'h00000000;
            FRegWriteM_r <= 1'b0;
            FPU_ResultEM_r <= 32'd0;
            FResultSrcM_r <= 1'b0; 
            fReadDataM_r <= 0;
            instr <= 0;
        end
        else if ((!stall) || pass) begin
            // Latch values when not stalled
            instr <= InstrDM;
            FResultSrcM_r <= FResultSrcM;
            RegWriteM_r <= RegWriteM; 
            ResultSrcM_r <= ResultSrcM;
            RD_M_r <= RD_M;
            PCPlus4M_r <= PCPlus4M;
            ALU_ResultM_r <= ALU_ResultM; 
            ReadDataM_r <= ReadDataM;
            FRegWriteM_r <= FRegWriteM;
            FPU_ResultEM_r <= FPU_ResultEM;
            fReadDataM_r <= fReadDataM;
        end
    end 

    // -----------------------------
    // Assign outputs to WB stage
    // -----------------------------
    assign fReadDataW = fReadDataM_r;
    assign FResultSrcW = FResultSrcM_r;
    assign RegWriteW = RegWriteM_r;
    assign ResultSrcW = ResultSrcM_r;
    assign RD_W = RD_M_r;
    assign PCPlus4W = PCPlus4M_r;
    assign ALU_ResultW = ALU_ResultM_r;
    assign ReadDataW = ReadDataM_r;
    assign FRegWriteMW = FRegWriteM_r;
    assign FPU_ResultEW = FPU_ResultEM_r;

    // -----------------------------
    // Pipeline register delay for DRDW (WB destination register)
    // -----------------------------
    wire [4:0] DRDW_1, DRDW_2, DRDW_3;
    D #(5) flip(.in(RD_W), .out(DRDW_1), .clk(clk), .rst_n(rst_n));
    D #(5) flip1(.in(DRDW_1), .out(DRDW_2), .clk(clk), .rst_n(rst_n));
    D #(5) flip2(.in(DRDW_2), .out(DRDW_3), .clk(clk), .rst_n(rst_n));
    D #(5) flip3(.in(DRDW_3), .out(DRDW), .clk(clk), .rst_n(rst_n));

    // -----------------------------
    // Counters for memory operations (optional for stalls)
    // -----------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= 0;
            counter_1 <= 0;
        end
        else begin
            if (i_p_write) counter <= counter + 1;
            if (i_p_read)  counter_1 <= counter_1 + 1;

            if (counter == 5'd4) counter <= 0;      // reset after 4 writes
            if (counter_1 == 5'd3) counter_1 <= 0;  // reset after 3 reads
        end
    end

endmodule
