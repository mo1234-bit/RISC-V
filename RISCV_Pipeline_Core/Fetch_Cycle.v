// Instruction Fetch Stage (IF stage) of pipeline
// Handles PC update, branch/jump logic, instruction fetch from memory,
// pipeline registers for D stage, and stall/flush handling.
module fetch_cycle(
    input clk, rst_n,                 // Clock and synchronous reset
    input PCSrcE, JumpE, stall_f,     // Branch/Jump signals and stall from hazard unit
    input [31:0] PCTargetE,           // Branch/Jump target address
    output [31:0] InstrD,             // Instruction to D stage
    output [31:0] PCD, PCPlus4D,      // PC values passed to D stage
    input  stall, pass, is_FOP  // Stall signals and floating-point pass control
);

    // -----------------------------
    // Wires for PC and instruction fetch
    // -----------------------------
    wire [31:0] PC_F, PCF, PCPlus4F;  // Next PC, current PC, PC + 4
    wire [31:0] InstrF;               // Instruction read from memory
    wire [31:0] PCNext;               // Next PC selection
    wire FlushD;                       // Flush signal for pipeline registers

    // -----------------------------
    // Pipeline registers for IF -> D stage
    // -----------------------------
    reg [31:0] InstrF_reg;
    reg [31:0] PCF_reg, PCPlus4F_reg;

    // Flush D-stage pipeline register if branch or jump is taken
    assign FlushD = PCSrcE | JumpE;

    // -----------------------------
    // Select next PC value
    // -----------------------------
    assign PCNext = (JumpE) ? PCTargetE :       // If jump, go to target
                    (PCSrcE) ? PCTargetE :     // If branch taken, go to branch target
                    PCPlus4F;                  // Default: PC + 4

    // Optional MUX: chooses between sequential PC and branch/jump target
    Mux PC_MUX (
        .a(PCPlus4F),
        .b(PCNext),
        .s(PCSrcE | JumpE),
        .c(PC_F)
    );

    // -----------------------------
    // Program Counter (PC) module
    // -----------------------------
    // Updates PC each cycle unless stalled or waiting on memory/FPU
    PC_Module Program_Counter (
        .clk(clk),
        .rst_n(rst_n),
        .PC(PCF),
        .o_p_waitrequest((stall | stall_f) && !(is_FOP && pass)), // Stall PC if needed
        .PC_Next(PC_F)
    );

    // -----------------------------
    // Instruction Memory
    // -----------------------------
    Instruction_Memory IMEM (
        .rst_n(rst_n),
        .A(PCF),
        .RD(InstrF),
        .o_p_waitrequest(1'b0)
    );

    // -----------------------------
    // PC Adder: calculates PC + 4
    // -----------------------------
    PC_Adder PC_adder (
        .a(PCF),
        .b(32'h00000004),
        .c(PCPlus4F)
    );

    // -----------------------------
    // IF -> D pipeline registers
    // -----------------------------
    always @(posedge clk) begin
        if(rst_n == 1'b0) begin
            // Reset IF/D pipeline registers
            InstrF_reg <= 32'h00000000;
            PCF_reg <= 32'h00000000;
            PCPlus4F_reg <= 32'h00000000;
        end
        else if((!stall && !stall_f) || (is_FOP && pass)) begin
            // Only latch new PC and instruction if pipeline not stalled or FPU op finished
            if(FlushD) begin
                // Insert NOP (addi x0,x0,0 = 0x13) into pipeline on branch/jump flush
                InstrF_reg <= 32'h00000013; 
                PCF_reg <= 32'h00000000;
                PCPlus4F_reg <= 32'h00000000;
            end
            else begin
                // Latch normal PC and instruction values
                InstrF_reg <= InstrF;
                PCF_reg <= PCF;
                PCPlus4F_reg <= PCPlus4F;
            end
        end
    end

    // -----------------------------
    // Output assignments to D stage
    // -----------------------------
    assign InstrD = (rst_n == 1'b0) ? 32'h00000000 : InstrF_reg;
    assign PCD = (rst_n == 1'b0) ? 32'h00000000 : PCF_reg;
    assign PCPlus4D = (rst_n == 1'b0) ? 32'h00000000 : PCPlus4F_reg;

endmodule
