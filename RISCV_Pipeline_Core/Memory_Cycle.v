
module memory_cycle(
    input clk, rst_n,
    input RegWriteM, FRegWriteM, MemWriteM, pass, stall, pass_load,
    input ResultSrcM, FResultSrcM, JumpM,
    input [4:0] RD_M,
    input [31:0] PCPlus4M, WriteDataM, ALU_ResultM, FPU_ResultEM, InstrDM,

    // ---- NEW: funct3 from EX/MEM register ----
    input [2:0] funct3M,

    output RegWriteW, ResultSrcW,
    output [4:0] RD_W, DRDW,
    output [31:0] PCPlus4W, ALU_ResultW, ReadDataW, FPU_ResultEW, fReadDataW,
    output FRegWriteMW, FResultSrcW, JumpW,
    output reg [31:0] instr,
    output reg [4:0] counter, counter_1,
    output w
);

    // -----------------------------
    // Pipeline registers (MEM -> WB)
    // -----------------------------
    wire [31:0] ReadDataM;
    reg RegWriteM_r, FRegWriteM_r, ResultSrcM_r, FResultSrcM_r, JumpW_r;
    reg [4:0] RD_M_r;
    reg [31:0] PCPlus4M_r, ALU_ResultM_r, ReadDataM_r, FPU_ResultEM_r, fReadDataM_r;
    reg [31:0] fReadDataW_reg, ReadDataW_reg;

    // -----------------------------
    // Cache interface signals
    // -----------------------------
    wire [31:0] i_p_addr;
    reg  [31:0] i_p_addr_reg;
    reg  en, i_p_write_reg;
    wire [3:0]  i_p_byte_en;
    wire [31:0] i_p_writedata;
    wire        i_p_read;
    wire        o_p_readdata_valid;
    wire        i_p_write;
    wire [31:0] o_p_readdata;
    wire [31:0] o_m_addr;
    wire [31:0] o_m_writedata;
    wire        o_m_read, o_m_write;
    wire [31:0] i_m_readdata;
    wire        i_m_readdata_valid;
    wire        i_m_waitrequest, o_p_waitrequest1;
    wire [2:0]  state;

    wire s = (InstrDM == instr && i_p_read) && (i_p_addr != i_p_addr_reg);

    // -----------------------------
    // Cache memory control
    // -----------------------------
    assign i_p_addr = ALU_ResultM;

    // ---- NEW: byte_en from funct3 and address[1:0] ----
    // addr[1:0] selects byte/half position within the 32-bit word
    wire [1:0] byte_offset = ALU_ResultM[1:0];

    assign i_p_byte_en =
        (funct3M == 3'b000) ? (4'b0001 << byte_offset)            :  // SB: 1 byte
        (funct3M == 3'b001) ? (4'b0011 << {byte_offset[1], 1'b0}) :  // SH: 2 bytes
        4'b1111;                                                       // SW / FLW / FSW

    // ---- NEW: replicate write data to all byte lanes for SB/SH ----
    // Cache byte_en determines which lanes are actually written.
    // Replication lets the cache see valid data in every lane it selects.
    assign i_p_writedata =
        (funct3M == 3'b000) ? {4{WriteDataM[7:0]}}  :  // SB: byte  → 4 copies
        (funct3M == 3'b001) ? {2{WriteDataM[15:0]}} :  // SH: half  → 2 copies
        WriteDataM;                                      // SW: word as-is

    assign i_p_read  = (ResultSrcM || FResultSrcM) && !MemWriteM;
    assign i_p_write = MemWriteM;

    // ---- NEW: raw word from cache (before sign extension) ----
    wire [31:0] raw_rdata = (en && i_p_read) ? ReadDataW_reg
                          : (i_p_read)       ? o_p_readdata
                          :                    ReadDataW_reg;

    // ---- NEW: select byte / halfword from raw word ----
    wire [7:0] byte_rdata =
        (byte_offset == 2'b00) ? raw_rdata[ 7: 0] :
        (byte_offset == 2'b01) ? raw_rdata[15: 8] :
        (byte_offset == 2'b10) ? raw_rdata[23:16] :
                                 raw_rdata[31:24];

    wire [15:0] half_rdata =
        byte_offset[1] ? raw_rdata[31:16] : raw_rdata[15:0];

    // ---- NEW: sign/zero extend based on funct3 ----
    assign ReadDataM =
        (funct3M == 3'b000) ? {{24{byte_rdata[7]}},  byte_rdata} :  // LB
        (funct3M == 3'b001) ? {{16{half_rdata[15]}}, half_rdata} :  // LH
        (funct3M == 3'b100) ? {24'b0, byte_rdata}                :  // LBU
        (funct3M == 3'b101) ? {16'b0, half_rdata}                :  // LHU
        raw_rdata;                                                    // LW / FLW

    // FP loads are always word-width — use raw data directly
    wire [31:0] fReadDataM = (en && i_p_read) ? fReadDataW_reg
                           : (i_p_read)       ? o_p_readdata
                           :                    fReadDataW_reg;

    assign w = (i_p_write_reg && i_p_read && (i_p_addr != i_p_addr_reg) && state != 3'd0);
    wire stall_C;

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
        .i_m_waitrequest(i_m_waitrequest),
        .state(state),
        .m(w)
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
        .A(o_m_addr),
        .RD(i_m_readdata)
    );

    // -----------------------------
    // Pipeline registers: latch MEM -> WB
    // -----------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            RegWriteM_r  <= 1'b0;
            ResultSrcM_r <= 1'b0;
            RD_M_r       <= 5'h00;
            PCPlus4M_r   <= 32'h0;
            ALU_ResultM_r<= 32'h0;
            ReadDataM_r  <= 32'h0;
            FRegWriteM_r <= 1'b0;
            FPU_ResultEM_r <= 32'd0;
            FResultSrcM_r  <= 1'b0;
            fReadDataM_r   <= 0;
            instr          <= 0;
            JumpW_r        <= 0;
        end
        else if ((!stall) || pass || pass_load) begin
            instr          <= InstrDM;
            FResultSrcM_r  <= FResultSrcM;
            RegWriteM_r    <= RegWriteM;
            ResultSrcM_r   <= ResultSrcM;
            RD_M_r         <= RD_M;
            PCPlus4M_r     <= PCPlus4M;
            ALU_ResultM_r  <= ALU_ResultM;
            ReadDataM_r    <= ReadDataM;       // sign-extended value
            FRegWriteM_r   <= FRegWriteM;
            FPU_ResultEM_r <= FPU_ResultEM;
            fReadDataM_r   <= fReadDataM;
            JumpW_r        <= JumpM;
        end
    end

    // -----------------------------
    // Outputs to WB stage
    // -----------------------------
    assign fReadDataW  = fReadDataM_r;
    assign FResultSrcW = FResultSrcM_r;
    assign RegWriteW   = RegWriteM_r;
    assign ResultSrcW  = ResultSrcM_r;
    assign RD_W        = RD_M_r;
    assign PCPlus4W    = PCPlus4M_r;
    assign ALU_ResultW = ALU_ResultM_r;
    assign ReadDataW   = ReadDataM_r;
    assign FRegWriteMW = FRegWriteM_r;
    assign FPU_ResultEW= FPU_ResultEM_r;
    assign JumpW       = JumpW_r;

    // -----------------------------
    // Pipeline register delay for DRDW (WB destination register)
    // -----------------------------
    wire [4:0] DRDW_1, DRDW_2, DRDW_3;
    D #(5) flip (.in(RD_W),    .out(DRDW_1), .clk(clk), .rst_n(rst_n));
    D #(5) flip1(.in(DRDW_1),  .out(DRDW_2), .clk(clk), .rst_n(rst_n));
    D #(5) flip2(.in(DRDW_2),  .out(DRDW_3), .clk(clk), .rst_n(rst_n));
    D #(5) flip3(.in(DRDW_3),  .out(DRDW),   .clk(clk), .rst_n(rst_n));

    // -----------------------------
    // Counters for memory operations
    // -----------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            counter         <= 0;
            counter_1       <= 0;
            i_p_addr_reg    <= 32'd0;
            en              <= 0;
            fReadDataW_reg  <= 0;
            ReadDataW_reg   <= 0;
            i_p_write_reg   <= 0;
        end
        else begin
            if (i_p_write) counter   <= counter + 1;
            if (i_p_read)  counter_1 <= counter_1 + 1;

            if (counter   == 5'd4) counter   <= 0;
            if (counter_1 == 5'd3) counter_1 <= 0;

            i_p_addr_reg  <= i_p_addr;

            if (s)         en <= 1;
            if (!i_p_read) en <= 0;

            if (!en && i_p_read) begin
                fReadDataW_reg <= o_p_readdata;
                ReadDataW_reg  <= o_p_readdata;
            end

            i_p_write_reg <= i_p_write;
        end
    end

endmodule
