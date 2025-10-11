module memory_cycle(input clk, rst_n, RegWriteM,FRegWriteM, MemWriteM,
     stall, ResultSrcM,fstoreM,floadM,FResultSrcM,
    input [4:0] RD_M,
    input [31:0] PCPlus4M, WriteDataM, ALU_ResultM,FPU_ResultEM,InstrDM,
    output RegWriteW, ResultSrcW, 
    output [4:0] RD_W,DRDW,
    output [31:0] PCPlus4W, ALU_ResultW, ReadDataW,FPU_ResultEW,fReadDataW,
    output o_p_waitrequest,FRegWriteMW,FResultSrcW,o_p_readdata_valid);
    
    
    wire [31:0] ReadDataM;
    reg RegWriteM_r,FRegWriteM_r, ResultSrcM_r,FResultSrcM_r;
    reg [4:0] RD_M_r;
    reg [31:0] PCPlus4M_r, ALU_ResultM_r, ReadDataM_r, FPU_ResultEM_r,o_p_readdata_past,fReadDataM_r;
    
    // Cache signals
    wire [24:0] i_p_addr;
    wire [3:0] i_p_byte_en;
    wire [31:0] i_p_writedata;
    wire i_p_read;
    wire i_p_write;
    wire [31:0] o_p_readdata;
    wire [25:0] o_m_addr;
    wire [31:0] o_m_writedata;
    wire o_m_read;
    wire o_m_write;
    wire [31:0] i_m_readdata;
    wire i_m_readdata_valid;
    wire i_m_waitrequest,o_p_waitrequest1;
    assign i_p_addr = ALU_ResultM[24:0]; 
    assign i_p_byte_en = 4'b1111;
    assign i_p_writedata = WriteDataM;
   assign i_p_read = (ResultSrcM | FResultSrcM) & !MemWriteM;
    assign i_p_write = MemWriteM;
    assign ReadDataM = o_p_readdata;
   wire[31:0] fReadDataM=o_p_readdata;
    assign o_p_waitrequest=(i_p_read&&!o_p_readdata_valid)?1:(i_p_read&&o_p_readdata_valid)?0:o_p_waitrequest1;
  
    // Cache instance
    cache dut(
        .clk(clk),
        .rst_n(rst_n),
        .i_p_addr(i_p_addr),
        .i_p_byte_en(i_p_byte_en),
        .i_p_writedata(i_p_writedata),
        .i_p_read(i_p_read),
        .i_p_write(i_p_write),
        .stall(stall),
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

    Data_Memory dmem (
        .clk(clk),
        .rst_n(rst_n),
        .WE(o_m_write),
        .WD(o_m_writedata),             
        .i_m_readdata_valid(i_m_readdata_valid),
        .i_m_waitrequest(i_m_waitrequest),
        .ren(o_m_read),
        .A({6'b000000, o_m_addr}),        
        .RD(i_m_readdata)                  
    );

    always @(posedge clk) begin
        if (rst_n == 1'b0) begin
            RegWriteM_r <= 1'b0; 
            ResultSrcM_r <= 1'b0;
            RD_M_r <= 5'h00;
            PCPlus4M_r <= 32'h00000000; 
            ALU_ResultM_r <= 32'h00000000; 
            ReadDataM_r <= 32'h00000000;
            FRegWriteM_r <= 1'b0;
            FPU_ResultEM_r <= 32'd0;
            FResultSrcM_r <= 1'b0; 
            fReadDataM_r<=0;
        end
        else if(!o_p_waitrequest) begin
        FResultSrcM_r <= FResultSrcM;
            RegWriteM_r <= RegWriteM; 
            ResultSrcM_r <= ResultSrcM;
            RD_M_r <= RD_M;
            PCPlus4M_r <= PCPlus4M; 
            ALU_ResultM_r <= ALU_ResultM; 
            ReadDataM_r <= ReadDataM;
            FRegWriteM_r <= FRegWriteM;
            FPU_ResultEM_r <= FPU_ResultEM;
            fReadDataM_r<=fReadDataM;
        end
    end 
    assign fReadDataW=fReadDataM_r;
    assign FResultSrcW = FResultSrcM_r;
    assign RegWriteW = RegWriteM_r;
    assign ResultSrcW = ResultSrcM_r;
    assign RD_W = RD_M_r;
    assign PCPlus4W = PCPlus4M_r;
    assign ALU_ResultW = ALU_ResultM_r;
    assign ReadDataW = ReadDataM_r;
    assign FRegWriteMW = FRegWriteM_r;
    assign FPU_ResultEW = FPU_ResultEM_r;
    wire [4:0]DRDW_1,DRDW_2,DRDW_3;
    D #(5)flip(.in(RD_W),.out(DRDW_1),.clk(clk),.rst_n(rst_n));
    D #(5)flip1(.in(DRDW_1),.out(DRDW_2),.clk(clk),.rst_n(rst_n));
    D #(5)flip2(.in(DRDW_2),.out(DRDW_3),.clk(clk),.rst_n(rst_n));
    D #(5)flip3(.in(DRDW_3),.out(DRDW),.clk(clk),.rst_n(rst_n));
endmodule
