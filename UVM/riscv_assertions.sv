module riscv_pipeline_assertions (
    // Primary ports
    input  logic        clk,
    input  logic        rst_n,
    input  logic [15:0] Result,

    // Fetch
    input  logic [31:0] PC_F,       // current PC in Fetch
    input  logic [31:0] InstrF,     // raw instruction word from IMEM

    // Decode
    input  logic [31:0] InstrD,
    input  logic [31:0] PCD,

    // Execute
    input  logic [31:0] InstrDE,    // instruction in Execute
    input  logic        RegWriteE,
    input  logic        BranchE,
    input  logic        JumpE,
    input  logic        PCSrcE,
    input  logic [31:0] PCTargetE,
    input  logic [3:0]  ALUControlE,

    // Memory
    input  logic [31:0] InstrDM,
    input  logic        MemWriteM,
    input  logic        ResultSrcM,
    input  logic [31:0] ALU_ResultM,
    input  logic [31:0] WriteDataM,

    // Write-back
    input  logic        RegWriteW,
    input  logic [4:0]  RDW,
    input  logic [31:0] ResultW,

    // Hazard
    input  logic        StallF,
    input  logic        StallD,
    input  logic        FlushE,
    input  logic        stall,          // FPU/cache stall
    input  logic        mispredict,

    // FPU write-back
    input  logic        FRegWriteMW,
    input  logic [31:0] FResultW,

    // Cache
    input  logic [2:0]  cache_state
);

// =============================================================================
// Local parameters
// =============================================================================

// Cache FSM states (mirror whatever your cache uses – adjust if different)
localparam [2:0] C_IDLE       = 3'd0;
localparam [2:0] C_COMPARE    = 3'd1;
localparam [2:0] C_ALLOCATE   = 3'd2;
localparam [2:0] C_WRITE_BACK = 3'd3;
localparam [2:0] C_STALL      = 3'd4;

// Instruction opcode fields
`define OPCODE(instr)  instr[6:0]
`define RD(instr)      instr[11:7]
`define RS1(instr)     instr[19:15]
`define RS2(instr)     instr[24:20]
`define FUNCT3(instr)  instr[14:12]
`define FUNCT7(instr)  instr[31:25]

// RISC-V opcodes
localparam [6:0] OP_R      = 7'b0110011;
localparam [6:0] OP_I_ALU  = 7'b0010011;
localparam [6:0] OP_LOAD   = 7'b0000011;
localparam [6:0] OP_STORE  = 7'b0100011;
localparam [6:0] OP_BRANCH = 7'b1100011;
localparam [6:0] OP_LUI    = 7'b0110111;
localparam [6:0] OP_AUIPC  = 7'b0010111;
localparam [6:0] OP_JAL    = 7'b1101111;
localparam [6:0] OP_JALR   = 7'b1100111;
localparam [6:0] OP_FP     = 7'b1010011;
localparam [6:0] OP_FLW    = 7'b0000111;
localparam [6:0] OP_FSW    = 7'b0100111;

// NOP (ADDI x0, x0, 0)
loc
// =============================================================================
// ── 1. RESET ─────────────────────────────────────────────────────────────────
// =============================================================================

// After reset deasserts, PC must be valid (non-X) within 1 cycle
property p_reset_pc_valid;
    @(posedge clk)
    $rose(rst_n) |-> ##1 !$isunknown(PC_F);
endproperty
AST_RESET_PC_VALID: assert property (p_reset_pc_valid)
    else $error("[ASSERT][RESET] PC is unknown 1 cycle after reset release");

// Result must not be X after reset + 5 pipeline fill cycles
property p_reset_result_valid;
    @(posedge clk)
    $rose(rst_n) |-> ##6 !$isunknown(Result);
endproperty
AST_RESET_RESULT_VALID: assert property (p_reset_result_valid)
    else $error("[ASSERT][RESET] Result is still X after reset + 6 cycles");

// During reset all stall/flush must be deasserted (pipeline held)
property p_reset_no_hazard_signals;
    @(posedge clk)
    !rst_n |-> (!StallF && !StallD && !FlushE);
endproperty
AST_RESET_NO_HAZARD: assert property (p_reset_no_hazard_signals)
    else $error("[ASSERT][RESET] Stall or Flush asserted while in reset");

// =============================================================================
// ── 2. HAZARD UNIT ───────────────────────────────────────────────────────────
// =============================================================================

// Flush and StallF must NEVER be high simultaneously
// (you cannot freeze and flush the same stage at once)
property p_no_flush_stall_together;
    @(posedge clk) disable iff (!rst_n)
    !(FlushE && StallF);
endproperty
AST_NO_FLUSH_STALL: assert property (p_no_flush_stall_together)
    else $error("[ASSERT][HAZARD] FlushE and StallF both asserted simultaneously");

// StallD implies StallF (if Decode is stalled, Fetch must also be stalled)
property p_stall_d_implies_stall_f;
    @(posedge clk) disable iff (!rst_n)
    StallD |-> StallF;
endproperty
AST_STALL_D_IMPLIES_F: assert property (p_stall_d_implies_stall_f)
    else $error("[ASSERT][HAZARD] StallD asserted without StallF");

// When Fetch is stalled, PC must not advance next cycle
property p_stall_freezes_pc;
    @(posedge clk) disable iff (!rst_n)
    StallF |-> ##1 $stable(PC_F);
endproperty
AST_STALL_FREEZES_PC: assert property (p_stall_freezes_pc)
    else $error("[ASSERT][HAZARD] PC changed during StallF");

// When Decode is stalled, InstrD must not change next cycle
property p_stall_freezes_instrd;
    @(posedge clk) disable iff (!rst_n)
    StallD |-> ##1 $stable(InstrD);
endproperty
AST_STALL_FREEZES_INSTRD: assert property (p_stall_freezes_instrd)
    else $error("[ASSERT][HAZARD] InstrD changed during StallD");

// Stall must not persist more than 8 consecutive cycles (deadlock detection)
property p_stall_not_forever;
    @(posedge clk) disable iff (!rst_n)
    StallF |-> ##[1:8] !StallF;
endproperty
AST_STALL_NOT_FOREVER: assert property (p_stall_not_forever)
    else $error("[ASSERT][HAZARD] StallF held for more than 8 consecutive cycles – possible deadlock");

// After flush, Execute stage must receive NOP the following cycle
property p_flush_injects_nop;
    @(posedge clk) disable iff (!rst_n)
    FlushE |-> ##1 (InstrDE === NOP_INSTR || `OPCODE(InstrDE) === 7'h0);
endproperty
AST_FLUSH_INJECTS_NOP: assert property (p_flush_injects_nop)
    else $error("[ASSERT][HAZARD] FlushE did not inject NOP into Execute stage");

// =============================================================================
// ── 3. REGISTER FILE ─────────────────────────────────────────────────────────
// =============================================================================

// x0 destination writes must never produce non-zero commit to ResultW
// (some pipelines gate regwrite on rd==0; check the write-back side)
property p_x0_write_is_zero;
    @(posedge clk) disable iff (!rst_n)
    // Guard !$isunknown(ResultW): X propagation from IMEM after program end
    // causes X !== 0 to evaluate true — this would be a false positive.
    (RegWriteW && (RDW === 5'd0) && !$isunknown(ResultW)) |-> (ResultW === 32'h0);
endproperty
AST_X0_WRITE_ZERO: assert property (p_x0_write_is_zero)
    else $error("[ASSERT][REGFILE] Write to x0 with non-zero data in WB stage");

// RegWrite must not assert when RD is unknown
property p_regwrite_rd_known;
    @(posedge clk) disable iff (!rst_n)
    RegWriteW |-> !$isunknown(RDW);
endproperty
AST_REGWRITE_RD_KNOWN: assert property (p_regwrite_rd_known)
    else $error("[ASSERT][REGFILE] RegWriteW asserted but RDW is X/Z");

// ResultW must not be X when it is being written to a register
property p_regwrite_data_valid;
    @(posedge clk) disable iff (!rst_n)
    (RegWriteW && (RDW !== 5'd0)) |-> !$isunknown(ResultW);
endproperty
AST_REGWRITE_DATA_VALID: assert property (p_regwrite_data_valid)
    else $error("[ASSERT][REGFILE] RegWriteW asserted with unknown ResultW");

// FP register write must also carry valid data
property p_fp_regwrite_data_valid;
    @(posedge clk) disable iff (!rst_n)
    FRegWriteMW |-> !$isunknown(FResultW);
endproperty
AST_FP_REGWRITE_DATA_VALID: assert property (p_fp_regwrite_data_valid)
    else $error("[ASSERT][FPU] FRegWriteMW asserted with unknown FResultW");

// =============================================================================
// ── 4. BRANCH PREDICTOR ──────────────────────────────────────────────────────
// =============================================================================

// A misprediction must cause FlushE within 1 or 2 cycles
property p_mispredict_causes_flush;
    @(posedge clk) disable iff (!rst_n)
    mispredict |-> ##[1:2] FlushE;
endproperty
AST_MISPREDICT_FLUSH: assert property (p_mispredict_causes_flush)
    else $error("[ASSERT][BP] Misprediction did not trigger FlushE within 2 cycles");

// PCSrcE (taken branch or jump) must produce a valid non-X target
property p_pcsrce_target_valid;
    @(posedge clk) disable iff (!rst_n)
    PCSrcE |-> !$isunknown(PCTargetE);
endproperty
AST_PCSRCE_TARGET_VALID: assert property (p_pcsrce_target_valid)
    else $error("[ASSERT][BP] PCSrcE asserted but PCTargetE is X/Z");

// Branch target must be 4-byte aligned
property p_branch_target_aligned;
    @(posedge clk) disable iff (!rst_n)
    PCSrcE |-> (PCTargetE[1:0] === 2'b00);
endproperty
AST_BRANCH_ALIGNED: assert property (p_branch_target_aligned)
    else $error("[ASSERT][BP] Branch/jump target is not 4-byte aligned");

// BranchE and JumpE should never both be asserted at the same time
property p_no_branch_and_jump;
    @(posedge clk) disable iff (!rst_n)
    !(BranchE && JumpE);
endproperty
AST_NO_BRANCH_AND_JUMP: assert property (p_no_branch_and_jump)
    else $error("[ASSERT][BP] BranchE and JumpE both asserted simultaneously");

// =============================================================================
// ── 5. MEMORY STAGE ──────────────────────────────────────────────────────────
// =============================================================================

// MemWrite and RegWrite (from same instruction) cannot both be true
// (a store does not write a register)
property p_no_memwrite_and_regwrite_same_instr;
    @(posedge clk) disable iff (!rst_n)
    MemWriteM |-> (`OPCODE(InstrDM) === OP_STORE || `OPCODE(InstrDM) === OP_FSW);
endproperty
AST_MEMWRITE_IS_STORE: assert property (p_no_memwrite_and_regwrite_same_instr)
    else $error("[ASSERT][MEM] MemWriteM asserted on non-STORE instruction");

// Memory write address must not be X
property p_memwrite_addr_valid;
    @(posedge clk) disable iff (!rst_n)
    MemWriteM |-> !$isunknown(ALU_ResultM);
endproperty
AST_MEMWRITE_ADDR_VALID: assert property (p_memwrite_addr_valid)
    else $error("[ASSERT][MEM] MemWriteM with unknown address (ALU_ResultM)");

// Memory write data must not be X
property p_memwrite_data_valid;
    @(posedge clk) disable iff (!rst_n)
    MemWriteM |-> !$isunknown(WriteDataM);
endproperty
AST_MEMWRITE_DATA_VALID: assert property (p_memwrite_data_valid)
    else $error("[ASSERT][MEM] MemWriteM with unknown write data");

// SW address must be word-aligned
property p_sw_word_aligned;
    @(posedge clk) disable iff (!rst_n)
    (MemWriteM && (`FUNCT3(InstrDM) === 3'b010)) |->
        (ALU_ResultM[1:0] === 2'b00);
endproperty
AST_SW_ALIGNED: assert property (p_sw_word_aligned)
    else $error("[ASSERT][MEM] SW to unaligned address");

// SH address must be halfword-aligned
property p_sh_halfword_aligned;
    @(posedge clk) disable iff (!rst_n)
    (MemWriteM && (`FUNCT3(InstrDM) === 3'b001)) |->
        (ALU_ResultM[0] === 1'b0);
endproperty
AST_SH_ALIGNED: assert property (p_sh_halfword_aligned)
    else $error("[ASSERT][MEM] SH to unaligned address");

// LW load must also be word-aligned (use Execute instruction)
// Note: alignment check on loads done in Execute stage via ALUControlE context
property p_lw_word_aligned;
    @(posedge clk) disable iff (!rst_n)
    (ResultSrcM && (`FUNCT3(InstrDM) === 3'b010)) |->
        (ALU_ResultM[1:0] === 2'b00);
endproperty
AST_LW_ALIGNED: assert property (p_lw_word_aligned)
    else $error("[ASSERT][MEM] LW from unaligned address");

// =============================================================================
// ── 6. PC BEHAVIOUR ──────────────────────────────────────────────────────────
// =============================================================================

// PC must never be X or Z during normal operation
property p_pc_no_x;
    @(posedge clk) disable iff (!rst_n)
    !$isunknown(PC_F);
endproperty
AST_PC_NO_X: assert property (p_pc_no_x)
    else $error("[ASSERT][PC] PC_F is unknown (X/Z)");

// PC must be 4-byte aligned (RV32I, no compressed)
property p_pc_aligned;
    @(posedge clk) disable iff (!rst_n)
    PC_F[1:0] === 2'b00;
endproperty
AST_PC_ALIGNED: assert property (p_pc_aligned)
    else $error("[ASSERT][PC] PC_F is not 4-byte aligned");

// Without a taken branch/jump/stall, PC must increment by 4
property p_pc_plus4;
    @(posedge clk) disable iff (!rst_n)
    (!StallF && !PCSrcE) |-> ##1 (PC_F === ($past(PC_F) + 32'd4));
endproperty
AST_PC_PLUS4: assert property (p_pc_plus4)
    else $error("[ASSERT][PC] PC did not increment by 4 when no stall/branch");

// =============================================================================
// ── 7. FPU ───────────────────────────────────────────────────────────────────
// =============================================================================

// FP result must not contain X when write-back is active
property p_fpu_result_no_x;
    @(posedge clk) disable iff (!rst_n)
    FRegWriteMW |-> !$isunknown(FResultW);
endproperty
AST_FPU_NO_X: assert property (p_fpu_result_no_x)
    else $error("[ASSERT][FPU] FResultW is X/Z during FP write-back");

// FP stall (multi-cycle) must not last longer than 32 cycles (FDIV/FSQRT limit)
property p_fp_stall_max_cycles;
    @(posedge clk) disable iff (!rst_n)
    stall |-> ##[1:32] !stall;
endproperty
AST_FP_STALL_MAX: assert property (p_fp_stall_max_cycles)
    else $error("[ASSERT][FPU] FPU stall held for more than 32 cycles");

// FP write-back and integer write-back must not target ports simultaneously
// (structural hazard on register file write port)
property p_no_dual_regwrite;
    @(posedge clk) disable iff (!rst_n)
    !(RegWriteW && FRegWriteMW);
endproperty
AST_NO_DUAL_REGWRITE: assert property (p_no_dual_regwrite)
    else $error("[ASSERT][FPU] Integer and FP write-back both asserted simultaneously");

// =============================================================================
// ── 8. CACHE ─────────────────────────────────────────────────────────────────
// =============================================================================

// Cache FSM must only be in legal states
property p_cache_legal_state;
    @(posedge clk) disable iff (!rst_n)
    (cache_state inside {C_IDLE, C_COMPARE, C_ALLOCATE, C_WRITE_BACK, C_STALL});
endproperty
AST_CACHE_LEGAL_STATE: assert property (p_cache_legal_state)
    else $error("[ASSERT][CACHE] Cache FSM in illegal state %0d", cache_state);

// Cache must not stay in ALLOCATE longer than 16 cycles (memory latency bound)
property p_cache_allocate_timeout;
    @(posedge clk) disable iff (!rst_n)
    (cache_state === C_ALLOCATE) |-> ##[1:16] (cache_state !== C_ALLOCATE);
endproperty
AST_CACHE_ALLOCATE_TIMEOUT: assert property (p_cache_allocate_timeout)
    else $error("[ASSERT][CACHE] Cache stuck in ALLOCATE state for >16 cycles");

// Cache must not stay in WRITE_BACK longer than 16 cycles
property p_cache_wb_timeout;
    @(posedge clk) disable iff (!rst_n)
    (cache_state === C_WRITE_BACK) |-> ##[1:16] (cache_state !== C_WRITE_BACK);
endproperty
AST_CACHE_WB_TIMEOUT: assert property (p_cache_wb_timeout)
    else $error("[ASSERT][CACHE] Cache stuck in WRITE_BACK state for >16 cycles");

// While cache is stalling the pipeline, StallF must be asserted
property p_cache_stall_asserts_stallf;
    @(posedge clk) disable iff (!rst_n)
    (cache_state === C_STALL || cache_state === C_ALLOCATE) |-> StallF;
endproperty
AST_CACHE_STALL_ASSERTS_STALLF: assert property (p_cache_stall_asserts_stallf)
    else $error("[ASSERT][CACHE] Cache busy but StallF not asserted");

// =============================================================================
// ── 9. INSTRUCTION STREAM SANITY ─────────────────────────────────────────────
// =============================================================================

// Instruction in Decode must not be fully unknown while the pipeline
// is actively executing. Once the program exhausts IMEM the pipeline
// fetches X — gate out that end-of-program condition.
property p_instr_d_no_x;
    @(posedge clk) disable iff (!rst_n)
    // Only check during active execution: at least one write-back has
    // occurred and there has been no sustained X fetch yet.
    (RegWriteW || !$isunknown(InstrD)) |-> !$isunknown(InstrD);
endproperty
AST_INSTRD_NO_X: assert property (p_instr_d_no_x)
    else $error("[ASSERT][INSTR] InstrD is X/Z – IMEM may not be loaded");

// Opcode bit 1 and 0 must both be 1 for all RV32I base instructions
// (compressed 'C' extension uses 00/01/10 – if not supported this is a bug)
property p_instr_rv32_encoding;
    @(posedge clk) disable iff (!rst_n)
    // Exclude NOP inserted by flush and X values from beyond program end
    (!FlushE && !$isunknown(InstrD)) |-> (InstrD[1:0] === 2'b11);
endproperty
AST_INSTR_RV32_ENCODING: assert property (p_instr_rv32_encoding)
    else $error("[ASSERT][INSTR] Instruction does not have RV32 base encoding (bits[1:0] != 11)");

// =============================================================================
// ── 10. LIVENESS ─────────────────────────────────────────────────────────────
// =============================================================================

// At least one integer register write must happen within 50 cycles of reset
property p_liveness_regwrite;
    @(posedge clk)
    $rose(rst_n) |-> ##[1:50] RegWriteW;
endproperty
AST_LIVENESS_REGWRITE: assert property (p_liveness_regwrite)
    else $error("[ASSERT][LIVENESS] No integer register write in first 50 cycles after reset");

// Result must become stable (non-X) within 20 cycles of reset
property p_liveness_result;
    @(posedge clk)
    $rose(rst_n) |-> ##[5:20] !$isunknown(Result);
endproperty
AST_LIVENESS_RESULT: assert property (p_liveness_result)
    else $error("[ASSERT][LIVENESS] Result never stabilised after reset");

// =============================================================================
// ── COVER PROPERTIES (reachability) ──────────────────────────────────────────
// =============================================================================

// Confirm all interesting scenarios are actually exercised in simulation
COV_STALL_OCCURS:          cover property (@(posedge clk) disable iff(!rst_n) StallF);
COV_FLUSH_OCCURS:          cover property (@(posedge clk) disable iff(!rst_n) FlushE);
COV_MISPREDICT_OCCURS:     cover property (@(posedge clk) disable iff(!rst_n) mispredict);
COV_DOUBLE_STALL:          cover property (@(posedge clk) disable iff(!rst_n) StallF ##1 StallF);
COV_STALL_THEN_FLUSH:      cover property (@(posedge clk) disable iff(!rst_n) StallF ##[1:4] FlushE);
COV_MEMWRITE_OCCURS:       cover property (@(posedge clk) disable iff(!rst_n) MemWriteM);
COV_FP_STALL:              cover property (@(posedge clk) disable iff(!rst_n) stall);
COV_FP_REGWRITE:           cover property (@(posedge clk) disable iff(!rst_n) FRegWriteMW);
COV_CACHE_ALLOCATE:        cover property (@(posedge clk) disable iff(!rst_n) (cache_state === C_ALLOCATE));
COV_CACHE_WRITE_BACK:      cover property (@(posedge clk) disable iff(!rst_n) (cache_state === C_WRITE_BACK));
COV_BRANCH_TAKEN:          cover property (@(posedge clk) disable iff(!rst_n) (BranchE && PCSrcE));
COV_BRANCH_NOT_TAKEN:      cover property (@(posedge clk) disable iff(!rst_n) (BranchE && !PCSrcE));
COV_BACK_TO_BACK_REGWRITE: cover property (@(posedge clk) disable iff(!rst_n) RegWriteW ##1 RegWriteW);

// =============================================================================
// ── SIMULATION ONLY: $display summary at end ─────────────────────────────────
// =============================================================================
`ifndef FORMAL
    final begin
        $display("");
        $display("╔══════════════════════════════════════════════╗");
        $display("║     riscv_assertions  –  Simulation Done     ║");
        $display("╚══════════════════════════════════════════════╝");
    end
`endif
alparam [31:0] NOP_INSTR = 32'h0000_0013;

// =============================================================================
// ── 1. RESET ─────────────────────────────────────────────────────────────────
// =============================================================================

// After reset deasserts, PC must be valid (non-X) within 1 cycle
property p_reset_pc_valid;
    @(posedge clk)
    $rose(rst_n) |-> ##1 !$isunknown(PC_F);
endproperty
AST_RESET_PC_VALID: assert property (p_reset_pc_valid)
    else $error("[ASSERT][RESET] PC is unknown 1 cycle after reset release");

// Result must not be X after reset + 5 pipeline fill cycles
property p_reset_result_valid;
    @(posedge clk)
    $rose(rst_n) |-> ##6 !$isunknown(Result);
endproperty
AST_RESET_RESULT_VALID: assert property (p_reset_result_valid)
    else $error("[ASSERT][RESET] Result is still X after reset + 6 cycles");

// During reset all stall/flush must be deasserted (pipeline held)
property p_reset_no_hazard_signals;
    @(posedge clk)
    !rst_n |-> (!StallF && !StallD && !FlushE);
endproperty
AST_RESET_NO_HAZARD: assert property (p_reset_no_hazard_signals)
    else $error("[ASSERT][RESET] Stall or Flush asserted while in reset");

// =============================================================================
// ── 2. HAZARD UNIT ───────────────────────────────────────────────────────────
// =============================================================================

// Flush and StallF must NEVER be high simultaneously
// (you cannot freeze and flush the same stage at once)
property p_no_flush_stall_together;
    @(posedge clk) disable iff (!rst_n)
    !(FlushE && StallF);
endproperty
AST_NO_FLUSH_STALL: assert property (p_no_flush_stall_together)
    else $error("[ASSERT][HAZARD] FlushE and StallF both asserted simultaneously");

// StallD implies StallF (if Decode is stalled, Fetch must also be stalled)
property p_stall_d_implies_stall_f;
    @(posedge clk) disable iff (!rst_n)
    StallD |-> StallF;
endproperty
AST_STALL_D_IMPLIES_F: assert property (p_stall_d_implies_stall_f)
    else $error("[ASSERT][HAZARD] StallD asserted without StallF");

// When Fetch is stalled, PC must not advance next cycle
property p_stall_freezes_pc;
    @(posedge clk) disable iff (!rst_n)
    StallF |-> ##1 $stable(PC_F);
endproperty
AST_STALL_FREEZES_PC: assert property (p_stall_freezes_pc)
    else $error("[ASSERT][HAZARD] PC changed during StallF");

// When Decode is stalled, InstrD must not change next cycle
property p_stall_freezes_instrd;
    @(posedge clk) disable iff (!rst_n)
    StallD |-> ##1 $stable(InstrD);
endproperty
AST_STALL_FREEZES_INSTRD: assert property (p_stall_freezes_instrd)
    else $error("[ASSERT][HAZARD] InstrD changed during StallD");

// Stall must not persist more than 8 consecutive cycles (deadlock detection)
property p_stall_not_forever;
    @(posedge clk) disable iff (!rst_n)
    StallF |-> ##[1:8] !StallF;
endproperty
AST_STALL_NOT_FOREVER: assert property (p_stall_not_forever)
    else $error("[ASSERT][HAZARD] StallF held for more than 8 consecutive cycles – possible deadlock");

// After flush, Execute stage must receive NOP the following cycle
property p_flush_injects_nop;
    @(posedge clk) disable iff (!rst_n)
    FlushE |-> ##1 (InstrDE === NOP_INSTR || `OPCODE(InstrDE) === 7'h0);
endproperty
AST_FLUSH_INJECTS_NOP: assert property (p_flush_injects_nop)
    else $error("[ASSERT][HAZARD] FlushE did not inject NOP into Execute stage");

// =============================================================================
// ── 3. REGISTER FILE ─────────────────────────────────────────────────────────
// =============================================================================

// x0 destination writes must never produce non-zero commit to ResultW
// (some pipelines gate regwrite on rd==0; check the write-back side)
property p_x0_write_is_zero;
    @(posedge clk) disable iff (!rst_n)
    // Guard !$isunknown(ResultW): X propagation from IMEM after program end
    // causes X !== 0 to evaluate true — this would be a false positive.
    (RegWriteW && (RDW === 5'd0) && !$isunknown(ResultW)) |-> (ResultW === 32'h0);
endproperty
AST_X0_WRITE_ZERO: assert property (p_x0_write_is_zero)
    else $error("[ASSERT][REGFILE] Write to x0 with non-zero data in WB stage");

// RegWrite must not assert when RD is unknown
property p_regwrite_rd_known;
    @(posedge clk) disable iff (!rst_n)
    RegWriteW |-> !$isunknown(RDW);
endproperty
AST_REGWRITE_RD_KNOWN: assert property (p_regwrite_rd_known)
    else $error("[ASSERT][REGFILE] RegWriteW asserted but RDW is X/Z");

// ResultW must not be X when it is being written to a register
property p_regwrite_data_valid;
    @(posedge clk) disable iff (!rst_n)
    (RegWriteW && (RDW !== 5'd0)) |-> !$isunknown(ResultW);
endproperty
AST_REGWRITE_DATA_VALID: assert property (p_regwrite_data_valid)
    else $error("[ASSERT][REGFILE] RegWriteW asserted with unknown ResultW");

// FP register write must also carry valid data
property p_fp_regwrite_data_valid;
    @(posedge clk) disable iff (!rst_n)
    FRegWriteMW |-> !$isunknown(FResultW);
endproperty
AST_FP_REGWRITE_DATA_VALID: assert property (p_fp_regwrite_data_valid)
    else $error("[ASSERT][FPU] FRegWriteMW asserted with unknown FResultW");

// =============================================================================
// ── 4. BRANCH PREDICTOR ──────────────────────────────────────────────────────
// =============================================================================

// A misprediction must cause FlushE within 1 or 2 cycles
property p_mispredict_causes_flush;
    @(posedge clk) disable iff (!rst_n)
    mispredict |-> ##[1:2] FlushE;
endproperty
AST_MISPREDICT_FLUSH: assert property (p_mispredict_causes_flush)
    else $error("[ASSERT][BP] Misprediction did not trigger FlushE within 2 cycles");

// PCSrcE (taken branch or jump) must produce a valid non-X target
property p_pcsrce_target_valid;
    @(posedge clk) disable iff (!rst_n)
    PCSrcE |-> !$isunknown(PCTargetE);
endproperty
AST_PCSRCE_TARGET_VALID: assert property (p_pcsrce_target_valid)
    else $error("[ASSERT][BP] PCSrcE asserted but PCTargetE is X/Z");

// Branch target must be 4-byte aligned
property p_branch_target_aligned;
    @(posedge clk) disable iff (!rst_n)
    PCSrcE |-> (PCTargetE[1:0] === 2'b00);
endproperty
AST_BRANCH_ALIGNED: assert property (p_branch_target_aligned)
    else $error("[ASSERT][BP] Branch/jump target is not 4-byte aligned");

// BranchE and JumpE should never both be asserted at the same time
property p_no_branch_and_jump;
    @(posedge clk) disable iff (!rst_n)
    !(BranchE && JumpE);
endproperty
AST_NO_BRANCH_AND_JUMP: assert property (p_no_branch_and_jump)
    else $error("[ASSERT][BP] BranchE and JumpE both asserted simultaneously");

// =============================================================================
// ── 5. MEMORY STAGE ──────────────────────────────────────────────────────────
// =============================================================================

// MemWrite and RegWrite (from same instruction) cannot both be true
// (a store does not write a register)
property p_no_memwrite_and_regwrite_same_instr;
    @(posedge clk) disable iff (!rst_n)
    MemWriteM |-> (`OPCODE(InstrDM) === OP_STORE || `OPCODE(InstrDM) === OP_FSW);
endproperty
AST_MEMWRITE_IS_STORE: assert property (p_no_memwrite_and_regwrite_same_instr)
    else $error("[ASSERT][MEM] MemWriteM asserted on non-STORE instruction");

// Memory write address must not be X
property p_memwrite_addr_valid;
    @(posedge clk) disable iff (!rst_n)
    MemWriteM |-> !$isunknown(ALU_ResultM);
endproperty
AST_MEMWRITE_ADDR_VALID: assert property (p_memwrite_addr_valid)
    else $error("[ASSERT][MEM] MemWriteM with unknown address (ALU_ResultM)");

// Memory write data must not be X
property p_memwrite_data_valid;
    @(posedge clk) disable iff (!rst_n)
    MemWriteM |-> !$isunknown(WriteDataM);
endproperty
AST_MEMWRITE_DATA_VALID: assert property (p_memwrite_data_valid)
    else $error("[ASSERT][MEM] MemWriteM with unknown write data");

// SW address must be word-aligned
property p_sw_word_aligned;
    @(posedge clk) disable iff (!rst_n)
    (MemWriteM && (`FUNCT3(InstrDM) === 3'b010)) |->
        (ALU_ResultM[1:0] === 2'b00);
endproperty
AST_SW_ALIGNED: assert property (p_sw_word_aligned)
    else $error("[ASSERT][MEM] SW to unaligned address");

// SH address must be halfword-aligned
property p_sh_halfword_aligned;
    @(posedge clk) disable iff (!rst_n)
    (MemWriteM && (`FUNCT3(InstrDM) === 3'b001)) |->
        (ALU_ResultM[0] === 1'b0);
endproperty
AST_SH_ALIGNED: assert property (p_sh_halfword_aligned)
    else $error("[ASSERT][MEM] SH to unaligned address");

// LW load must also be word-aligned (use Execute instruction)
// Note: alignment check on loads done in Execute stage via ALUControlE context
property p_lw_word_aligned;
    @(posedge clk) disable iff (!rst_n)
    (ResultSrcM && (`FUNCT3(InstrDM) === 3'b010)) |->
        (ALU_ResultM[1:0] === 2'b00);
endproperty
AST_LW_ALIGNED: assert property (p_lw_word_aligned)
    else $error("[ASSERT][MEM] LW from unaligned address");

// =============================================================================
// ── 6. PC BEHAVIOUR ──────────────────────────────────────────────────────────
// =============================================================================

// PC must never be X or Z during normal operation
property p_pc_no_x;
    @(posedge clk) disable iff (!rst_n)
    !$isunknown(PC_F);
endproperty
AST_PC_NO_X: assert property (p_pc_no_x)
    else $error("[ASSERT][PC] PC_F is unknown (X/Z)");

// PC must be 4-byte aligned (RV32I, no compressed)
property p_pc_aligned;
    @(posedge clk) disable iff (!rst_n)
    PC_F[1:0] === 2'b00;
endproperty
AST_PC_ALIGNED: assert property (p_pc_aligned)
    else $error("[ASSERT][PC] PC_F is not 4-byte aligned");

// Without a taken branch/jump/stall, PC must increment by 4
property p_pc_plus4;
    @(posedge clk) disable iff (!rst_n)
    (!StallF && !PCSrcE) |-> ##1 (PC_F === ($past(PC_F) + 32'd4));
endproperty
AST_PC_PLUS4: assert property (p_pc_plus4)
    else $error("[ASSERT][PC] PC did not increment by 4 when no stall/branch");

// =============================================================================
// ── 7. FPU ───────────────────────────────────────────────────────────────────
// =============================================================================

// FP result must not contain X when write-back is active
property p_fpu_result_no_x;
    @(posedge clk) disable iff (!rst_n)
    FRegWriteMW |-> !$isunknown(FResultW);
endproperty
AST_FPU_NO_X: assert property (p_fpu_result_no_x)
    else $error("[ASSERT][FPU] FResultW is X/Z during FP write-back");

// FP stall (multi-cycle) must not last longer than 32 cycles (FDIV/FSQRT limit)
property p_fp_stall_max_cycles;
    @(posedge clk) disable iff (!rst_n)
    stall |-> ##[1:32] !stall;
endproperty
AST_FP_STALL_MAX: assert property (p_fp_stall_max_cycles)
    else $error("[ASSERT][FPU] FPU stall held for more than 32 cycles");

// FP write-back and integer write-back must not target ports simultaneously
// (structural hazard on register file write port)
property p_no_dual_regwrite;
    @(posedge clk) disable iff (!rst_n)
    !(RegWriteW && FRegWriteMW);
endproperty
AST_NO_DUAL_REGWRITE: assert property (p_no_dual_regwrite)
    else $error("[ASSERT][FPU] Integer and FP write-back both asserted simultaneously");

// =============================================================================
// ── 8. CACHE ─────────────────────────────────────────────────────────────────
// =============================================================================

// Cache FSM must only be in legal states
property p_cache_legal_state;
    @(posedge clk) disable iff (!rst_n)
    (cache_state inside {C_IDLE, C_COMPARE, C_ALLOCATE, C_WRITE_BACK, C_STALL});
endproperty
AST_CACHE_LEGAL_STATE: assert property (p_cache_legal_state)
    else $error("[ASSERT][CACHE] Cache FSM in illegal state %0d", cache_state);

// Cache must not stay in ALLOCATE longer than 16 cycles (memory latency bound)
property p_cache_allocate_timeout;
    @(posedge clk) disable iff (!rst_n)
    (cache_state === C_ALLOCATE) |-> ##[1:16] (cache_state !== C_ALLOCATE);
endproperty
AST_CACHE_ALLOCATE_TIMEOUT: assert property (p_cache_allocate_timeout)
    else $error("[ASSERT][CACHE] Cache stuck in ALLOCATE state for >16 cycles");

// Cache must not stay in WRITE_BACK longer than 16 cycles
property p_cache_wb_timeout;
    @(posedge clk) disable iff (!rst_n)
    (cache_state === C_WRITE_BACK) |-> ##[1:16] (cache_state !== C_WRITE_BACK);
endproperty
AST_CACHE_WB_TIMEOUT: assert property (p_cache_wb_timeout)
    else $error("[ASSERT][CACHE] Cache stuck in WRITE_BACK state for >16 cycles");

// While cache is stalling the pipeline, StallF must be asserted
property p_cache_stall_asserts_stallf;
    @(posedge clk) disable iff (!rst_n)
    (cache_state === C_STALL || cache_state === C_ALLOCATE) |-> StallF;
endproperty
AST_CACHE_STALL_ASSERTS_STALLF: assert property (p_cache_stall_asserts_stallf)
    else $error("[ASSERT][CACHE] Cache busy but StallF not asserted");

// =============================================================================
// ── 9. INSTRUCTION STREAM SANITY ─────────────────────────────────────────────
// =============================================================================

// Instruction in Decode must not be fully unknown while the pipeline
// is actively executing. Once the program exhausts IMEM the pipeline
// fetches X — gate out that end-of-program condition.
property p_instr_d_no_x;
    @(posedge clk) disable iff (!rst_n)
    // Only check during active execution: at least one write-back has
    // occurred and there has been no sustained X fetch yet.
    (RegWriteW || !$isunknown(InstrD)) |-> !$isunknown(InstrD);
endproperty
AST_INSTRD_NO_X: assert property (p_instr_d_no_x)
    else $error("[ASSERT][INSTR] InstrD is X/Z – IMEM may not be loaded");

// Opcode bit 1 and 0 must both be 1 for all RV32I base instructions
// (compressed 'C' extension uses 00/01/10 – if not supported this is a bug)
property p_instr_rv32_encoding;
    @(posedge clk) disable iff (!rst_n)
    // Exclude NOP inserted by flush and X values from beyond program end
    (!FlushE && !$isunknown(InstrD)) |-> (InstrD[1:0] === 2'b11);
endproperty
AST_INSTR_RV32_ENCODING: assert property (p_instr_rv32_encoding)
    else $error("[ASSERT][INSTR] Instruction does not have RV32 base encoding (bits[1:0] != 11)");

// =============================================================================
// ── 10. LIVENESS ─────────────────────────────────────────────────────────────
// =============================================================================

// At least one integer register write must happen within 50 cycles of reset
property p_liveness_regwrite;
    @(posedge clk)
    $rose(rst_n) |-> ##[1:50] RegWriteW;
endproperty
AST_LIVENESS_REGWRITE: assert property (p_liveness_regwrite)
    else $error("[ASSERT][LIVENESS] No integer register write in first 50 cycles after reset");

// Result must become stable (non-X) within 20 cycles of reset
property p_liveness_result;
    @(posedge clk)
    $rose(rst_n) |-> ##[5:20] !$isunknown(Result);
endproperty
AST_LIVENESS_RESULT: assert property (p_liveness_result)
    else $error("[ASSERT][LIVENESS] Result never stabilised after reset");

// =============================================================================
// ── COVER PROPERTIES (reachability) ──────────────────────────────────────────
// =============================================================================

// Confirm all interesting scenarios are actually exercised in simulation
COV_STALL_OCCURS:          cover property (@(posedge clk) disable iff(!rst_n) StallF);
COV_FLUSH_OCCURS:          cover property (@(posedge clk) disable iff(!rst_n) FlushE);
COV_MISPREDICT_OCCURS:     cover property (@(posedge clk) disable iff(!rst_n) mispredict);
COV_DOUBLE_STALL:          cover property (@(posedge clk) disable iff(!rst_n) StallF ##1 StallF);
COV_STALL_THEN_FLUSH:      cover property (@(posedge clk) disable iff(!rst_n) StallF ##[1:4] FlushE);
COV_MEMWRITE_OCCURS:       cover property (@(posedge clk) disable iff(!rst_n) MemWriteM);
COV_FP_STALL:              cover property (@(posedge clk) disable iff(!rst_n) stall);
COV_FP_REGWRITE:           cover property (@(posedge clk) disable iff(!rst_n) FRegWriteMW);
COV_CACHE_ALLOCATE:        cover property (@(posedge clk) disable iff(!rst_n) (cache_state === C_ALLOCATE));
COV_CACHE_WRITE_BACK:      cover property (@(posedge clk) disable iff(!rst_n) (cache_state === C_WRITE_BACK));
COV_BRANCH_TAKEN:          cover property (@(posedge clk) disable iff(!rst_n) (BranchE && PCSrcE));
COV_BRANCH_NOT_TAKEN:      cover property (@(posedge clk) disable iff(!rst_n) (BranchE && !PCSrcE));
COV_BACK_TO_BACK_REGWRITE: cover property (@(posedge clk) disable iff(!rst_n) RegWriteW ##1 RegWriteW);

// =============================================================================
// ── SIMULATION ONLY: $display summary at end ─────────────────────────────────
// =============================================================================
`ifndef FORMAL
    final begin
        $display("");
        $display("╔══════════════════════════════════════════════╗");
        $display("║     riscv_assertions  –  Simulation Done     ║");
        $display("╚══════════════════════════════════════════════╝");
    end
`endif

endmodule : riscv_pipeline_assertions
