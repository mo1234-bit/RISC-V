module fetch_cycle( input clk, rst_n,
    input PCSrcE, JumpE,
    input [31:0] PCTargetE,
    output [31:0] InstrD,
    output [31:0] PCD, PCPlus4D,
    input o_p_waitrequest, stall);

    wire [31:0] PC_F, PCF, PCPlus4F;
    wire [31:0] InstrF;
    wire [31:0] PCNext;
    wire FlushD; 

    reg [31:0] InstrF_reg;
    reg [31:0] PCF_reg, PCPlus4F_reg;

    assign FlushD = PCSrcE | JumpE;

 
    assign PCNext = (JumpE) ? PCTargetE :           // Jump 
                   (PCSrcE) ? PCTargetE :           // Branch taken
                   PCPlus4F;                        // Default: PC + 4

    Mux PC_MUX (
        .a(PCPlus4F),
        .b(PCNext),
        .s(PCSrcE | JumpE),
        .c(PC_F)
    );

    PC_Module Program_Counter (
        .clk(clk),
        .rst_n(rst_n),
        .PC(PCF),
        .o_p_waitrequest(o_p_waitrequest | stall),
        .PC_Next(PC_F)
    );

    Instruction_Memory IMEM (
        .rst_n(rst_n),
        .A(PCF),
        .RD(InstrF),
        .o_p_waitrequest(o_p_waitrequest)
    );

    PC_Adder PC_adder (
        .a(PCF),
        .b(32'h00000004),
        .c(PCPlus4F)
    );

    always @(posedge clk) begin
        if(rst_n == 1'b0) begin
            InstrF_reg <= 32'h00000000;
            PCF_reg <= 32'h00000000;
            PCPlus4F_reg <= 32'h00000000;
        end
        else if(!o_p_waitrequest && !stall) begin
            if(FlushD) begin
                InstrF_reg <= 32'h00000013; 
                PCF_reg <= 32'h00000000;
                PCPlus4F_reg <= 32'h00000000;
            end
            else begin
                InstrF_reg <= InstrF;
                PCF_reg <= PCF;
                PCPlus4F_reg <= PCPlus4F;
            end
        end
    end

    assign InstrD = (rst_n == 1'b0) ? 32'h00000000 : InstrF_reg;
    assign PCD = (rst_n == 1'b0) ? 32'h00000000 : PCF_reg;
    assign PCPlus4D = (rst_n == 1'b0) ? 32'h00000000 : PCPlus4F_reg;

endmodule
