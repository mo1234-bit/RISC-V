module fetch_cycle(clk, rst, PCSrcE, PCTargetE, InstrD, PCD, PCPlus4D,o_p_waitrequest);

    input clk, rst;
    input PCSrcE;
    input [31:0] PCTargetE;
    output [31:0] InstrD;
    output [31:0] PCD, PCPlus4D;
    input o_p_waitrequest;

    wire [31:0] PC_F, PCF, PCPlus4F;
    wire [31:0] InstrF;

    reg [31:0] InstrF_reg;
    reg [31:0] PCF_reg, PCPlus4F_reg;

    Mux PC_MUX (.a(PCPlus4F),
                .b(PCTargetE),
                .s(PCSrcE),
                .c(PC_F)
                );

    PC_Module Program_Counter (
                .clk(clk),
                .rst(rst),
                .PC(PCF),
                .PC_Next(PC_F)
                );

    Instruction_Memory IMEM (
                .rst(rst),
                .A(PCF),
                .RD(InstrF)
                );

    PC_Adder PC_adder (
                .a(PCF),
                .b(32'h00000004),
                .c(PCPlus4F)
                );

    always @(posedge clk or negedge rst) begin
        if(rst == 1'b0) begin
            InstrF_reg <= 32'h00000000;
            PCF_reg <= 32'h00000000;
            PCPlus4F_reg <= 32'h00000000;
        end
        else if(!o_p_waitrequest) begin
            InstrF_reg <= InstrF;
            PCF_reg <= PCF;
            PCPlus4F_reg <= PCPlus4F;
        end
    end

    assign  InstrD = (rst == 1'b0) ? 32'h00000000 : InstrF_reg;
    assign  PCD = (rst == 1'b0) ? 32'h00000000 : PCF_reg;
    assign  PCPlus4D = (rst == 1'b0) ? 32'h00000000 : PCPlus4F_reg;


endmodule
