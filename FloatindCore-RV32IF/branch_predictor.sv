module branch_predictor_2bit(
    input clk, rst_n,
    input [31:0] fetch_pc,
    input fetch_valid,
    output reg predict_taken,
    output reg [31:0] predict_target,
    input stall,
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
     
   assign was_predicted_taken = !stall &&
    exec_is_branch &&
    btb_valid[exec_idx] &&
    (btb_tag[exec_idx] == exec_pc) &&
    btb_counter[exec_idx][1];

            
           assign  target_correct = ( !stall && exec_is_branch && (btb_target[exec_idx] === exec_actual_target))?1:0;

          
    integer i;
    
    // ================================================================
    // PREDICTION
    // ================================================================
   always @(*) begin
    if (fetch_valid && !stall &&
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
        else if (exec_is_branch && !stall ) begin
           
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
// How the 2-bit branch predictor works:
//
// On the first iteration of a branch:
// - There is no valid BTB entry yet (btb_valid at exec index = 0), so the predictor assumes "not taken".
// - When the branch reaches the execution stage (exec_is_branch = 1) and the actual branch is taken (exec_actual_taken = 1):
//     - The BTB entry at the exec index is updated:
//         - btb_valid is set to 1 (marks the entry as valid)
//         - btb_tag is set to exec_pc (to associate this entry with this specific branch)
//         - btb_target is set to exec_actual_target (the correct branch target address)
//     - The 2-bit counter at the exec index is updated from "weakly not taken" to "weakly taken".
//       This ensures that the next prediction will be taken, based on the MSB of the counter.
//
// On subsequent iterations of the same branch:
// - The predictor checks btb_valid at the exec index:
//     - If it is 0 → first iteration → predict weakly not taken
//     - If it is 1 → the counter at that index determines the predicted direction:
//         - "weakly taken" or "strongly taken" → predict taken
//         - Otherwise → predict not taken
// - The BTB tag must match the fetch_pc to ensure that the prediction belongs to this specific branch
//   and is not accidentally used for another branch.
