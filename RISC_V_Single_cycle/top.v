module top (clk,rst);
input clk,rst;

wire[31:0] PC,pc_plus4;
wire[31:0] RD_out;
wire[31:0] RD1_reg;
wire [31:0]RD2_reg;
wire[31:0] Imm_ext_reg;
wire [2:0]ALUControl_top;
wire [31:0]ALU_Result;
wire [31:0]Read_data;
wire regwrite,MemWrite;
wire[1:0]ImmSrc;
wire ALUSrc_reg;
wire [31:0]srcB;
wire ResultSrc_reg;
wire [31:0]Result;

PC dut1(.PC_next(pc_plus4),.PC(PC),.rst(rst),.clk(clk));


instr_memo dut2(.A(PC),.rst(rst),.RD(RD_out));


reg_file dut3(.A1(RD_out[19:15]),.A2(RD_out[24:20]),.A3(RD_out[11:7]),.WD3(Result),.WE3(regwrite),.RD1(RD1_reg),
	.RD2(RD2_reg),.clk(clk),.rst(rst));

sige_Extend dut4(.IN(RD_out),.Imm_ext(Imm_ext_reg),.ImmSrc(ImmSrc[0]));


ALU dut5(.A(RD1_reg),.B(srcB),.ALUControl(ALUControl_top),.Result(ALU_Result),.carry(),.overflow(),.neg(),.zero());

control_unit_top dut6(.op(RD_out[6:0]),.RegWrite(regwrite),.funct3(RD_out[14:12]),.funct7(RD_out[6:0]),
	.ALUControl(ALUControl_top),.ResultSrc(ResultSrc_reg),.MemWrite(MemWrite),.ALUSrc(ALUSrc_reg),.ImmSrc(ImmSrc),.branch());

DATA_MEM dut7(.A(ALU_Result),.WD(RD2_reg),.clk(clk),.WE(MemWrite),.RD(Read_data),.rst(rst));

mux dut9(.A(RD2_reg),.B(Imm_ext_reg),.sel(ALUSrc_reg),.C(srcB));

adder dut8(.a(PC),.b(32'd4),.c(pc_plus4));

mux dut10(.A(ALU_Result),.B(Read_data),.sel(ResultSrc_reg),.C(Result));


endmodule