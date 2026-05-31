
`include "uvm_macros.svh"
import riscv_pkg::*;
import uvm_pkg::*;// =============================================================================
// riscv_tests.sv  –  UVM Test Classes
//
// Every test follows the same 4-step pattern in build_phase:
//   1. Create riscv_env_config
//   2. Get vif from config_db and assign to cfg.vif
//   3. Set all knobs on the config object
//   4. Call cfg.validate() then push it into config_db BEFORE super.build_phase
//      so the env and all sub-components see it during their build_phase.
// =============================================================================

// ---------------------------------------------------------------------------
// Base test
// ---------------------------------------------------------------------------
class riscv_base_test extends uvm_test;
    `uvm_component_utils(riscv_base_test)

    riscv_env        env;
    riscv_env_config cfg;
 virtual riscv_if vif;
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // ------------------------------------------------------------------
    // build_phase
    // Child tests call super.build_phase AFTER setting cfg fields so
    // the env already sees the fully configured object.
    // ------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
       

        // 1. Create config object
        cfg = riscv_env_config::type_id::create("cfg");

        // 2. Pull vif from config_db (set by tb_top)
        if (!uvm_config_db #(virtual riscv_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "riscv_base_test: vif not in config_db")
        cfg.vif = vif;

        // 3. Apply defaults — child overrides these before calling super
        apply_config();

        // 4. Validate knobs
        cfg.validate();

        // 5. Push into config_db so env + all children can get it
        uvm_config_db #(riscv_env_config)::set(this, "env*", "cfg", cfg);

        // 6. Now build env (it will find cfg in config_db)
        super.build_phase(phase);
        env = riscv_env::type_id::create("env", this);
    endfunction

    // Override in child to set cfg fields
    virtual function void apply_config();
        // base defaults are already set in riscv_env_config constructor
    endfunction

    // Override in child to set scoreboard expected values
    virtual function void configure_scoreboard();
    endfunction

    // ------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        phase.raise_objection(this, "test running");
        configure_scoreboard();
        run_sequences();
        #100;
        env.agent.monitor.publish_stats();
        phase.drop_objection(this, "test done");
    endtask

    virtual task run_sequences();
        `uvm_fatal("BASE","run_sequences() not implemented")
    endtask

endclass

// ===========================================================================
// Smoke test – directed program from memfile.hex
// ===========================================================================
class riscv_smoke_test extends riscv_base_test;
    `uvm_component_utils(riscv_smoke_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void apply_config();
        cfg.stim_mode          = riscv_env_config::HEX_FILE;
        cfg.hex_file           = "memfile.hex";
        cfg.run_cycles         = 10000;
        cfg.reset_cycles       = 5;
        cfg.min_ipc            = 0.1;
        cfg.enable_reg_checks  = 1;
        cfg.enable_ipc_check   = 1;
        cfg.sentinel_reg       = 30;
        cfg.sentinel_value     = 32'h0DEADBEF;
        cfg.verbosity          = UVM_MEDIUM;
    endfunction

    function void configure_scoreboard();
        env.scoreboard.expected = riscv_seq_item::type_id::create("exp");
        env.scoreboard.expected.stim_mode          = riscv_seq_item::HEX_FILE;
        env.scoreboard.expected.hex_file           = cfg.hex_file;
        env.scoreboard.expected.exp_int_regs[30]   = 32'h0DEADBEF;
        env.scoreboard.expected.min_ipc            = cfg.min_ipc;
    endfunction

    task run_sequences();
        riscv_full_test_seq seq;
        seq = riscv_full_test_seq::type_id::create("seq");
        seq.start(env.agent.sequencer);
    endtask

endclass

// ===========================================================================
// Fully random test – N random programs, no expected register values
// ===========================================================================
class riscv_random_test extends riscv_base_test;
    `uvm_component_utils(riscv_random_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void apply_config();
        cfg.stim_mode         = riscv_env_config::RANDOM_PROGRAM;
        cfg.num_instrs        = 80;
        cfg.run_cycles        = 5000;
        cfg.iterations        = 10;
        cfg.enable_reg_checks = 0;   // no oracle for random
        cfg.enable_mem_checks = 0;
        cfg.enable_ipc_check  = 1;
        cfg.min_ipc           = 0.20;
        cfg.verbosity         = UVM_MEDIUM;
    endfunction

    task run_sequences();
        riscv_random_seq seq;
        seq = riscv_random_seq::type_id::create("seq");
        seq.iterations = cfg.iterations;
        seq.start(env.agent.sequencer);
    endtask

endclass

// ===========================================================================
// Integer ALU test – R-type + I-type heavy, no FP
// ===========================================================================
class riscv_int_alu_test extends riscv_base_test;
    `uvm_component_utils(riscv_int_alu_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void apply_config();
        cfg.stim_mode    = riscv_env_config::RANDOM_PROGRAM;
        cfg.num_instrs   = 100;
        cfg.run_cycles   = 2000;
        cfg.w_r_type     = 35;
        cfg.w_i_alu      = 30;
        cfg.w_load       = 8;
        cfg.w_store      = 7;
        cfg.w_branch     = 8;
        cfg.w_u_type     = 5;
        cfg.w_fp_arith   = 0;    // no FP
        cfg.w_fp_mem     = 0;
        cfg.min_ipc      = 0.50;
        cfg.enable_reg_checks = 0;   // random program — no oracle
        cfg.enable_ipc_check  = 1;
        cfg.verbosity    = UVM_MEDIUM;
    endfunction

    task run_sequences();
        riscv_int_alu_seq seq;
        seq = riscv_int_alu_seq::type_id::create("seq");
        seq.start(env.agent.sequencer);
    endtask

endclass

// ===========================================================================
// Load/Store test – memory-biased
// ===========================================================================
class riscv_load_store_test extends riscv_base_test;
    `uvm_component_utils(riscv_load_store_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void apply_config();
        cfg.stim_mode          = riscv_env_config::RANDOM_PROGRAM;
        cfg.num_instrs         = 100;
        cfg.run_cycles         = 4000;
        cfg.w_r_type           = 10;
        cfg.w_i_alu            = 10;
        cfg.w_load             = 25;
        cfg.w_store            = 20;
        cfg.w_branch           = 8;
        cfg.w_u_type           = 4;
        cfg.w_fp_arith         = 8;
        cfg.w_fp_mem           = 8;
        cfg.min_ipc            = 0.25;
        cfg.detailed_cache_stats = 1;
        cfg.enable_reg_checks  = 0;
        cfg.enable_ipc_check   = 1;
        cfg.verbosity          = UVM_MEDIUM;
    endfunction

    task run_sequences();
        riscv_load_store_seq seq;
        seq = riscv_load_store_seq::type_id::create("seq");
        seq.start(env.agent.sequencer);
    endtask

endclass

// ===========================================================================
// Branch test – branch-heavy random programs
// ===========================================================================
class riscv_branch_test extends riscv_base_test;
    `uvm_component_utils(riscv_branch_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void apply_config();
        cfg.stim_mode        = riscv_env_config::RANDOM_PROGRAM;
        cfg.num_instrs       = 100;
        cfg.run_cycles       = 5000;
        cfg.w_r_type         = 15;
        cfg.w_i_alu          = 15;
        cfg.w_load           = 8;
        cfg.w_store          = 7;
        cfg.w_branch         = 30;
        cfg.w_u_type         = 4;
        cfg.w_fp_arith       = 0;
        cfg.w_fp_mem         = 0;
        cfg.min_ipc          = 0.40;
        cfg.track_mispredicts = 1;
        cfg.enable_reg_checks = 0;
        cfg.enable_ipc_check  = 1;
        cfg.verbosity        = UVM_MEDIUM;
    endfunction

    task run_sequences();
        riscv_branch_stress_seq seq;
        seq = riscv_branch_stress_seq::type_id::create("seq");
        seq.start(env.agent.sequencer);
    endtask

endclass

// ===========================================================================
// FPU test – floating-point heavy
// ===========================================================================
class riscv_fpu_test extends riscv_base_test;
    `uvm_component_utils(riscv_fpu_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void apply_config();
        cfg.stim_mode    = riscv_env_config::RANDOM_PROGRAM;
        cfg.num_instrs   = 60;
        cfg.run_cycles   = 8000;
        cfg.w_r_type     = 5;
        cfg.w_i_alu      = 5;
        cfg.w_load       = 5;
        cfg.w_store      = 5;
        cfg.w_branch     = 3;
        cfg.w_u_type     = 2;
        cfg.w_fp_arith   = 35;
        cfg.w_fp_mem     = 12;
        cfg.min_ipc      = 0.08;
        cfg.enable_reg_checks = 0;
        cfg.enable_ipc_check  = 1;
        cfg.verbosity    = UVM_MEDIUM;
    endfunction

    task run_sequences();
        riscv_fpu_seq seq;
        seq = riscv_fpu_seq::type_id::create("seq");
        seq.start(env.agent.sequencer);
    endtask

endclass

// ===========================================================================
// Reset stress test
// ===========================================================================
class riscv_reset_stress_test extends riscv_base_test;
    `uvm_component_utils(riscv_reset_stress_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void apply_config();
        cfg.stim_mode    = riscv_env_config::RANDOM_PROGRAM;
        cfg.num_instrs   = 40;
        cfg.run_cycles   = 300;
        cfg.reset_cycles = 5;
        cfg.iterations   = 5;
        cfg.enable_reg_checks = 0;
        cfg.enable_ipc_check  = 0;
        cfg.verbosity    = UVM_MEDIUM;
    endfunction

    task run_sequences();
        riscv_reset_stress_seq seq;
        seq = riscv_reset_stress_seq::type_id::create("seq");
        seq.iterations = cfg.iterations;
        seq.start(env.agent.sequencer);
    endtask

endclass

// ===========================================================================
// Regression test – runs all sequence types in sequence on one env
// ===========================================================================
class riscv_regression_test extends riscv_base_test;
    `uvm_component_utils(riscv_regression_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void apply_config();
        // Start with random-program defaults;
        // each sequence overrides what it needs via its own item constraints
        cfg.stim_mode     = riscv_env_config::RANDOM_PROGRAM;
        cfg.run_cycles    = 5000;
        cfg.min_ipc       = 0.0;    // checked per-sequence
        cfg.enable_reg_checks = 0;
        cfg.enable_ipc_check  = 1;
        cfg.track_mispredicts = 1;
        cfg.detailed_cache_stats = 1;
        cfg.verbosity     = UVM_LOW;
    endfunction

    function void configure_scoreboard();
        env.scoreboard.expected = riscv_seq_item::type_id::create("exp");
        // Sentinel set only for the directed phase
        env.scoreboard.expected.exp_int_regs[30] = 32'hX;  // don't care initially
    endfunction

    task run_sequences();
        // Phase 1: directed hex
        begin
            riscv_full_test_seq seq;
            `uvm_info("TEST","== Regression Phase 1: Directed hex ==",UVM_NONE)
            env.scoreboard.expected.exp_int_regs[30] = 32'h0DEADBEF;
            seq = riscv_full_test_seq::type_id::create("p1");
            seq.start(env.agent.sequencer);
            env.scoreboard.expected.exp_int_regs[30] = 32'hX;
        end

        // Phase 2: int ALU random
        begin
            riscv_int_alu_seq seq;
            `uvm_info("TEST","== Regression Phase 2: Int ALU ==",UVM_NONE)
            seq = riscv_int_alu_seq::type_id::create("p2");
            seq.start(env.agent.sequencer);
        end

        // Phase 3: load/store
        begin
            riscv_load_store_seq seq;
            `uvm_info("TEST","== Regression Phase 3: Load/Store ==",UVM_NONE)
            seq = riscv_load_store_seq::type_id::create("p3");
            seq.start(env.agent.sequencer);
        end

        // Phase 4: branch stress
        begin
            riscv_branch_stress_seq seq;
            `uvm_info("TEST","== Regression Phase 4: Branch ==",UVM_NONE)
            seq = riscv_branch_stress_seq::type_id::create("p4");
            seq.start(env.agent.sequencer);
        end

        // Phase 5: FPU
        begin
            riscv_fpu_seq seq;
            `uvm_info("TEST","== Regression Phase 5: FPU ==",UVM_NONE)
            seq = riscv_fpu_seq::type_id::create("p5");
            seq.start(env.agent.sequencer);
        end

        // Phase 6: reset stress
        begin
            riscv_reset_stress_seq seq;
            `uvm_info("TEST","== Regression Phase 6: Reset stress ==",UVM_NONE)
            seq = riscv_reset_stress_seq::type_id::create("p6");
            seq.iterations = 3;
            seq.start(env.agent.sequencer);
        end
    endtask

endclass