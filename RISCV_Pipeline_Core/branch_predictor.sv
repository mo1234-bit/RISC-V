module branch_predictor_2bit(
    input clk, rst_n,
    input [31:0] fetch_pc,
    input fetch_valid,
    output reg predict_taken,
    output reg [31:0] predict_target,
    
    input [31:0] exec_pc,
    input exec_is_branch,
    input exec_actual_taken,
    input [31:0] exec_actual_target,
    
    output reg mispredict,
    output reg [31:0] correct_target
);

    parameter BTB_SIZE = 512;
    
    reg btb_valid [0:BTB_SIZE-1];
    reg [31:0] btb_tag [0:BTB_SIZE-1];
    reg [31:0] btb_target [0:BTB_SIZE-1];
    reg [1:0] btb_counter [0:BTB_SIZE-1];  // 2-bit saturating counter
    
    // Counter states:
    // 2'b00 = Strongly Not Taken
    // 2'b01 = Weakly Not Taken
    // 2'b10 = Weakly Taken
    // 2'b11 = Strongly Taken
    
    wire [8:0] fetch_idx = fetch_pc[10:2];
    wire [8:0] exec_idx = exec_pc[10:2];
     wire was_predicted_taken;
     wire target_correct;
     
   assign was_predicted_taken =
    exec_is_branch &&
    btb_valid[exec_idx] &&
    (btb_tag[exec_idx] == exec_pc) &&
    btb_counter[exec_idx][1];

            
           assign  target_correct = (exec_is_branch && (btb_target[exec_idx] === exec_actual_target))?1:0;

          
    integer i;
    
    // ================================================================
    // PREDICTION
    // ================================================================
   always @(*) begin
    if (fetch_valid &&
        btb_valid[fetch_idx] &&
        btb_tag[fetch_idx] == fetch_pc) begin
        predict_taken  = btb_counter[fetch_idx][1];
        predict_target = btb_target[fetch_idx];
    end else begin
        predict_taken  = 1'b0;
        predict_target = fetch_pc + 4;
    end
end

    
    // ================================================================
    // UPDATE
    // ================================================================
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < BTB_SIZE; i = i + 1) begin
                btb_valid[i] <= 0;
                btb_counter[i] <= 2'b01;  // Weakly not taken
                btb_target[i]<=0;
            end
             correct_target <= 32'b0;
             mispredict<=0;
        end
        else if (exec_is_branch) begin
           
            correct_target <= exec_actual_taken ? exec_actual_target : (exec_pc + 4);
                mispredict <=( (was_predicted_taken != exec_actual_taken) ||
                         (exec_actual_taken && !target_correct));
            // Update BTB entry
            btb_valid[exec_idx] <= 1;
            btb_tag[exec_idx] <= exec_pc;
            btb_target[exec_idx] <= exec_actual_target;
            
            // Update 2-bit counter
            if (exec_actual_taken) begin
                // Taken: increment (saturate at 2'b11)
                if (btb_counter[exec_idx] != 2'b11)
                    btb_counter[exec_idx] <= btb_counter[exec_idx] + 1;
            end else begin
                // Not taken: decrement (saturate at 2'b00)
                if (btb_counter[exec_idx] != 2'b00)
                    btb_counter[exec_idx] <= btb_counter[exec_idx] - 1;
            end
        end
        else begin
            mispredict<=0;
        end
        
    end



endmodule
module tb_branch_predictor;

    reg clk, rst_n;

    reg [31:0] fetch_pc;
    reg fetch_valid;

    reg [31:0] exec_pc;
    reg exec_is_branch;
    reg exec_actual_taken;
    reg [31:0] exec_actual_target;

    wire predict_taken;
    wire [31:0] predict_target;
    wire mispredict;
    wire [31:0] correct_target;

    branch_predictor_2bit dut (
        .clk(clk),
        .rst_n(rst_n),
        .fetch_pc(fetch_pc),
        .fetch_valid(fetch_valid),
        .predict_taken(predict_taken),
        .predict_target(predict_target),
        .exec_pc(exec_pc),
        .exec_is_branch(exec_is_branch),
        .exec_actual_taken(exec_actual_taken),
        .exec_actual_target(exec_actual_target),
        .mispredict(mispredict),
        .correct_target(correct_target)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        fetch_valid = 1;

        fetch_pc = 0;
        exec_pc = 0;
        exec_is_branch = 0;
        exec_actual_taken = 0;
        exec_actual_target = 0;

        #20 rst_n = 1;

        // ===== First time branch (taken) =====
        fetch_pc = 32'h100;
        #10;

        exec_pc = 32'h100;
        exec_is_branch = 1;
        exec_actual_taken = 1;
        exec_actual_target = 32'h080;
        #10;

        // ===== Second time (taken again) =====
        fetch_pc = 32'h100;
        #10;

        exec_actual_taken = 1;
        #10;

        // ===== Loop exit (not taken) =====
        fetch_pc = 32'h100;
        #10;

        exec_actual_taken = 0;
        #10;

        $stop;
    end

endmodule


// ================================================================
// PERFORMANCE IMPACT EXAMPLE
// ================================================================
//
// Code with loop (10 iterations):
//   loop:
//       add x1, x1, x2
//       add x3, x3, x4
//       blt x1, x5, loop    # Taken 9 times, not taken once
//
// WITHOUT PREDICTION:
//   - Every branch flushes 2 instructions
//   - 10 branches × 2 cycles = 20 wasted cycles
//   - Total: 30 useful + 20 wasted = 50 cycles
//   - IPC = 30/50 = 0.60
//
// WITH 2-BIT PREDICTION (~90% accuracy):
//   - 9 correct predictions (no flush!)
//   - 1 misprediction (2 cycle penalty)
//   - Total: 30 useful + 2 wasted = 32 cycles
//   - IPC = 30/32 = 0.94  (57% improvement!)
//
// This is why branch prediction is CRITICAL!