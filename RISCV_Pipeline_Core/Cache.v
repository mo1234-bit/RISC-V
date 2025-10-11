  module cache( input wire         clk, rst_n,
    input wire [24:0]  i_p_addr,
    input wire [3:0]   i_p_byte_en,
    input wire [31:0]  i_p_writedata,
    input wire         i_p_read, i_p_write,
    output reg [31:0]  o_p_readdata,
    output reg         o_p_readdata_valid,
    output wire        o_p_waitrequest,
    input  wire            stall,
    output reg [25:0]  o_m_addr,
    output reg [31:0] o_m_writedata,
    output reg         o_m_read, o_m_write,
    input wire [31:0] i_m_readdata,
    input wire         i_m_readdata_valid,
    input wire         i_m_waitrequest
);
    parameter cache_entry = 14;
    wire [3:0]    hit;
    wire [3:0]    modify;
    wire [3:0]    miss;
    wire [3:0]    valid;
    wire [31:0]  readdata0, readdata1, readdata2, readdata3;
    wire [31:0]  writedata;
    wire          write0, write1, write2, write3;
    wire [3:0]    word_en;
    wire [3:0] 	  byte_en;
    wire [22:0]   addr;
    wire [22:0]   wb_addr0, wb_addr1, wb_addr2, wb_addr3;
    wire [1:0] 	  hit_num;

    reg  [2:0] 	  state;
    reg  [31:0]  writedata_buf;
    reg  [24:0]   write_addr_buf;
    reg  [3:0] 	  byte_en_buf;
    reg 		  write_buf, read_buf;
    reg  [3:0]    write_set,count;
    reg  [3:0]    fetch_write;
    localparam IDLE = 0;
    localparam COMP = 1;
    localparam HIT  = 2;
    localparam FETCH1 = 3;
    localparam FETCH2 = 4;
    localparam WB1 = 5;
    localparam WB2 = 6;
    set #(.cache_entry(cache_entry))
    set0(.clk(clk),
         .rst_n(rst_n),
         .entry(addr[cache_entry-1:0]),
         .o_tag(addr[22:cache_entry]),
         .writedata(writedata),
         .byte_en(byte_en),
         .write(write0),
         .word_en(word_en),  
         .readdata(readdata0),
         .wb_addr(wb_addr0),
         .hit(hit[0]),
         .modify(modify[0]),
         .miss(miss[0]),
         .valid(valid[0]),
         .read_miss(read_buf));

    set #(.cache_entry(cache_entry))
    set1(.clk(clk),
         .rst_n(rst_n),
         .entry(addr[cache_entry-1:0]),
         .o_tag(addr[22:cache_entry]),
         .writedata(writedata),
         .byte_en(byte_en),
         .write(write1),
         .word_en(word_en), 
         .readdata(readdata1),
         .wb_addr(wb_addr1),
         .hit(hit[1]),
         .modify(modify[1]),
         .miss(miss[1]),
         .valid(valid[1]),
         .read_miss(read_buf));

    set #(.cache_entry(cache_entry))
    set2(.clk(clk),
         .rst_n(rst_n),
         .entry(addr[cache_entry-1:0]),
         .o_tag(addr[22:cache_entry]),
         .writedata(writedata),
         .byte_en(byte_en),
         .write(write2),
         .word_en(word_en), 
         .readdata(readdata2),
         .wb_addr(wb_addr2),
         .hit(hit[2]),
         .modify(modify[2]),
         .miss(miss[2]),
         .valid(valid[2]),
         .read_miss(read_buf));

    set #(.cache_entry(cache_entry))
    set3(.clk(clk),
         .rst_n(rst_n),
         .entry(addr[cache_entry-1:0]),
         .o_tag(addr[22:cache_entry]),
         .writedata(writedata),
         .byte_en(byte_en),
         .write(write3),
         .word_en(word_en),
         .readdata(readdata3),
         .wb_addr(wb_addr3),
         .hit(hit[3]),
         .modify(modify[3]),
         .miss(miss[3]),
         .valid(valid[3]),
         .read_miss(read_buf));

    assign writedata = (|fetch_write) ?	i_m_readdata : writedata_buf; 
    assign write0 = (fetch_write[0]) ? i_m_readdata_valid : write_set[0];
    assign write1 = (fetch_write[1]) ? i_m_readdata_valid : write_set[1];
    assign write2 = (fetch_write[2]) ? i_m_readdata_valid : write_set[2];
    assign write3 = (fetch_write[3]) ? i_m_readdata_valid : write_set[3];
    assign addr = (o_p_waitrequest) ? write_addr_buf[24:2] : i_p_addr[24:2]; // set module input addr is 23bit 
    assign byte_en = (|fetch_write) ? 4'b1111 : byte_en_buf;
    assign o_p_waitrequest = (state != IDLE)?1:0;
   
    assign hit_num = (hit[0]) ? 0 : (hit[1]) ? 1 : (hit[2]) ? 2 : 3;
    assign word_en = (|fetch_write) ? 4'b1111 : 
                     (write_addr_buf[1:0] == 2'b00) ? 4'b0001 :
                     (write_addr_buf[1:0] == 2'b01) ? 4'b0010 :
                     (write_addr_buf[1:0] == 2'b10) ? 4'b0100 : 4'b1000;

    always @(posedge clk) begin
        if(!rst_n) begin
            o_p_readdata_valid <= 0;
            {o_m_read, o_m_write} <= 0;
            o_m_addr <= 0;
            write_addr_buf <= 0;
            byte_en_buf <= 0;
            writedata_buf <= 0;
            {write_buf, read_buf} <= 0;
            write_set <= 0;
            fetch_write <= 0;
            o_p_readdata<=0;
            o_m_writedata<=0;
            state <= IDLE;
        end
        else  begin
            case (state)
                IDLE: begin
                    write_set <= 0;
                    o_p_readdata_valid <= 0;
                    writedata_buf <= {i_p_writedata};
                    write_addr_buf <= i_p_addr;
                    byte_en_buf <= i_p_byte_en;
                    write_buf <= i_p_write;
                    read_buf <= i_p_read;
                    if(i_p_read) begin
                        state <= COMP;
                    end else if(i_p_write) begin
                        state <= COMP;
                    end
                end
                COMP: begin
                    if((|hit) && write_buf) begin
                        state <= HIT;
                        write_set <= hit;
                    end 
                    else if((|hit) && read_buf) begin
                         o_p_readdata <= (hit[0]) ? readdata0 : (hit[1]) ? readdata1 : (hit[2]) ? readdata2 : readdata3;
                        o_p_readdata_valid <= 1;
                        state <= IDLE;
                    end 
                    else if(!(&valid)) begin
                        state <= FETCH1;
                        if(!valid[0]) begin
                            fetch_write <= 4'b0001;
                        end 
                        else if(!valid[1]) begin
                            fetch_write <= 4'b0010;
                        end 
                        else if(!valid[2]) begin
                            fetch_write <= 4'b0100;
                        end 
                        else if(!valid[3]) begin
                            fetch_write <= 4'b1000;
                        end 
                        o_m_addr <= {write_addr_buf[24:2], 3'b000};
                        o_m_read <= 1;
                    end 
                    else begin
                        state <= WB1;
                    end
                end
                HIT: begin
                    write_set <= 0;
                    state <= IDLE;
                end 
               
                FETCH1: begin
                    if(!i_m_waitrequest) begin
                        o_m_read <= 0;
                    if(i_m_readdata_valid) begin
                        fetch_write <= 0;            
                        if(write_buf) begin
                            state <= FETCH2;
                            write_set <= fetch_write;
		                end else if(read_buf) begin
                            state <= IDLE;
		                    o_p_readdata_valid <= 1;
		                    o_p_readdata <= i_m_readdata;
		                end
                    end
                    end 
                end
                FETCH2: begin
                    state <= IDLE;
                    write_set <= 0;
                end
                WB1: begin
                    o_m_addr <= (fetch_write[0]) ? {wb_addr0, 3'b000} :
                                (fetch_write[1]) ? {wb_addr1, 3'b000} :
                                (fetch_write[2]) ? {wb_addr2, 3'b000} : {wb_addr3, 3'b000};
                    o_m_writedata <= (fetch_write[0]) ? readdata0 : 
                                     (fetch_write[1]) ? readdata1 : 
                                     (fetch_write[2]) ? readdata2 : readdata3;
                    o_m_write <= 1;
                    state <= WB2;
                end
                WB2: begin
                    if(!i_m_waitrequest) begin
                        o_m_write <= 0;
                        o_m_addr <= {write_addr_buf[24:2], 3'b000};
                        o_m_read <= 1;
                        state <= FETCH1;
                    end
                end
            endcase
        end
    end

endmodule 

module set(clk,
           rst_n,
           entry,
           o_tag,
           writedata,
           byte_en,
           write,
           word_en,

           readdata,
           wb_addr,
           hit,
           modify,
           miss,
           valid,
           read_miss);
    parameter cache_entry = 14;
    input wire                    clk, rst_n;
    input wire [cache_entry-1:0]  entry;
    input wire [22-cache_entry:0] o_tag;
    input wire [31:0] 		      writedata;
    input wire [3:0] 		      byte_en;
    input wire       	          write;
    input wire [3:0]              word_en;
    input wire 			          read_miss;

    output wire [31:0] 		  readdata;
    output wire [22:0] 		      wb_addr;
    output wire 			      hit, modify, miss, valid;



    wire [22-cache_entry:0] 	 i_tag;
    wire 			             dirty;
    wire [24-cache_entry:0] 	 write_tag_data;

    assign hit = valid && (o_tag == i_tag);
    assign modify = valid && (o_tag != i_tag) && dirty;
    assign miss = !valid || ((o_tag != i_tag) && !dirty);

    assign wb_addr = {i_tag, entry};
    simple_ram #(.width(8), .widthad(cache_entry)) ram00_3(clk, entry, write && word_en[0]  && byte_en[3], writedata[31:24], entry, readdata[31:24]);
    simple_ram #(.width(8), .widthad(cache_entry)) ram00_2(clk, entry, write && word_en[0]  && byte_en[2], writedata[23:16], entry, readdata[23:16]);
    simple_ram #(.width(8), .widthad(cache_entry)) ram00_1(clk, entry, write && word_en[0]  && byte_en[1], writedata[15: 8], entry, readdata[15:8]);
    simple_ram #(.width(8), .widthad(cache_entry)) ram00_0(clk, entry, write && word_en[0]  && byte_en[0], writedata[ 7: 0], entry, readdata[ 7:0]);
    assign write_tag_data = (read_miss) ? {1'b0, 1'b1, o_tag} : (modify || miss ) ? {1'b1, 1'b1, o_tag} : {1'b1, 1'b1, i_tag};
    simple_ram #(.width(25-cache_entry), .widthad(cache_entry)) ram_tag(clk, entry, write, write_tag_data, entry, {dirty, valid, i_tag});
    integer i;

    initial begin
        for(i = 0; i <=(2**cache_entry-1); i=i+1) begin
	        ram_tag.mem[i] = 0;
        end
    end
endmodule
