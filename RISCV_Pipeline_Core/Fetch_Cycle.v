// Instruction Fetch Stage (IF stage) of pipeline
// Handles PC update, branch/jump logic, instruction fetch from memory,
// pipeline registers for D stage, and stall/flush handling.
module fetch_cycle(
    input clk, rst_n,                 // Clock and synchronous reset
    input PCSrcE, JumpE, stall_f,     // Branch/Jump signals and stall from hazard unit
    input [31:0] PCTargetE,           // Branch/Jump target address
    output [31:0] InstrD,             // Instruction to D stage
    output [31:0] PCD, PCPlus4D,      // PC values passed to D stage
    input  stall, pass, is_FOP,  // Stall signals and floating-point pass control

   // Branch prediction signals from Execute stage
    input exec_is_branch,      // Is current instruction in Execute a branch?
    input exec_actual_taken,   // Was the branch actually taken?
    input [31:0] exec_pc,
    output mispredict       // PC of the branch in Execute stage
);

    // -----------------------------
    // Wires for PC and instruction fetch
    // -----------------------------
    wire [31:0] PC_F, PCF, PCPlus4F;  // Next PC, current PC, PC + 4
    wire [31:0] InstrF;               // Instruction read from memory
    wire [31:0] PCNext;               // Next PC selection
    wire FlushD;                       // Flush signal for pipeline registers
    
     // ================================================================
    // Branch Prediction signals
    // ================================================================
    wire predict_taken;
    wire [31:0] predict_target;
   
    wire [31:0] correct_target;

    // -----------------------------
    // Pipeline registers for IF -> D stage
    // -----------------------------
    reg [31:0] InstrF_reg;
    reg [31:0] PCF_reg, PCPlus4F_reg;

    // Flush D-stage pipeline register if branch or jump is taken
    assign FlushD = mispredict | JumpE;

    
    
 branch_predictor_2bit bp (
        .clk(clk),
        .rst_n(rst_n),
        
        // Fetch stage - make prediction
        .fetch_pc(PCF),
        .fetch_valid(1'b1),
        .predict_taken(predict_taken),
        .predict_target(predict_target),
        
        // Execute stage - update prediction
        .exec_pc(exec_pc),
        .exec_is_branch(exec_is_branch),
        .exec_actual_taken(exec_actual_taken),
        .exec_actual_target(PCTargetE),
        
        // Misprediction handling
        .mispredict(mispredict),
        .correct_target(correct_target)
    );
    // ================================================================
    //  PC Selection with Prediction
    // ================================================================
    // Priority:
    // 1. Misprediction correction (highest priority)
    // 2. Unconditional jump
    // 3. Branch prediction
    // 4. Sequential (PC + 4)
    
    assign PCNext = (mispredict) ? (correct_target-4) :      // Fix misprediction
                    (JumpE) ? PCTargetE :                // Unconditional jump
                    (predict_taken) ? predict_target :   // Predicted branch
                    PCPlus4F;                            // Sequential
    
    // Optional MUX: chooses between sequential PC and branch/jump target
    Mux PC_MUX (
        .a(PCPlus4F),
        .b(PCNext),
        .s(PCSrcE | JumpE | mispredict),
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
                 // Insert NOP on flush (misprediction or jump)
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
