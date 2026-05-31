
`include "uvm_macros.svh"
import riscv_pkg::*;
import uvm_pkg::*;// =============================================================================
// riscv_scoreboard.sv  –  UVM Scoreboard
// Reads riscv_env_config to know which checks are enabled.
// =============================================================================
class riscv_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(riscv_scoreboard)

    uvm_analysis_imp_reg   #(reg_write_txn,      riscv_scoreboard) aimp_reg;
    uvm_analysis_imp_mem   #(mem_txn,            riscv_scoreboard) aimp_mem;
    uvm_analysis_imp_branch#(branch_txn,         riscv_scoreboard) aimp_branch;
    uvm_analysis_imp_stats #(pipeline_stats_txn, riscv_scoreboard) aimp_stats;

    riscv_env_config  cfg;
    riscv_seq_item    expected;   // set by test after build_phase

    // Shadow models
    logic [31:0] shadow_int[32];
    logic [31:0] shadow_fp [32];
    logic [31:0] shadow_mem[bit [31:0]];   // bit index — 2-state, legal

    int unsigned pass_count;
    int unsigned fail_count;
    int unsigned check_count;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // -----------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(riscv_env_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("NOCFG", "riscv_scoreboard: riscv_env_config not found")

        aimp_reg    = new("aimp_reg",    this);
        aimp_mem    = new("aimp_mem",    this);
        aimp_branch = new("aimp_branch", this);
        aimp_stats  = new("aimp_stats",  this);

        reset_shadows();
    endfunction

    function void reset_shadows();
        foreach (shadow_int[i]) shadow_int[i] = 0;
        foreach (shadow_fp[i])  shadow_fp[i]  = 0;
        shadow_mem.delete();
        pass_count = 0; fail_count = 0; check_count = 0;
    endfunction

    // -----------------------------------------------------------------------
    // Write callbacks — update shadow models
    // -----------------------------------------------------------------------
    function void write_reg(reg_write_txn t);
        if (!t.is_fp) begin
            if (t.rd != 0) shadow_int[t.rd] = t.data;
        end else begin
            shadow_fp[t.rd] = t.data;
        end
    endfunction

    function void write_mem(mem_txn t);
        if (t.is_write) shadow_mem[bit'(t.addr)] = t.data;
    endfunction

    function void write_branch(branch_txn t);
        // Accumulated in monitor; no per-branch action needed here
    endfunction

    // -----------------------------------------------------------------------
    // Final check triggered by monitor publish_stats()
    // -----------------------------------------------------------------------
    function void write_stats(pipeline_stats_txn s);
        `uvm_info("SB", $sformatf("\n%s", s.convert2string()), UVM_LOW)

        if (expected == null) begin
            `uvm_info("SB","No expected item set; skipping value checks.",UVM_MEDIUM)
        end else begin
            if (cfg.enable_reg_checks) check_registers();
            if (cfg.enable_mem_checks) check_memory();
            if (cfg.enable_ipc_check)  check_ipc(s);
        end

        // Structural checks always run (don't need an expected item)
        check_x0_zero();

        print_summary();
    endfunction

    // -----------------------------------------------------------------------
    function void check_registers();
        for (int i = 1; i < 32; i++) begin
            if (expected.exp_int_regs[i] === 32'hX) continue;
            check_count++;
            if (shadow_int[i] !== expected.exp_int_regs[i]) begin
                `uvm_error("SB",
                    $sformatf("INT REG MISMATCH x%0d: got=0x%08h exp=0x%08h",
                              i, shadow_int[i], expected.exp_int_regs[i]))
                fail_count++;
            end else pass_count++;
        end
        for (int i = 0; i < 32; i++) begin
            if (expected.exp_fp_regs[i] === 32'hX) continue;
            check_count++;
            if (shadow_fp[i] !== expected.exp_fp_regs[i]) begin
                `uvm_error("SB",
                    $sformatf("FP REG MISMATCH f%0d: got=0x%08h exp=0x%08h",
                              i, shadow_fp[i], expected.exp_fp_regs[i]))
                fail_count++;
            end else pass_count++;
        end
    endfunction

    function void check_memory();
        foreach (expected.exp_mem[addr]) begin
            check_count++;
            if (!shadow_mem.exists(addr)) begin
                `uvm_error("SB",
                    $sformatf("MEM CHECK: addr 0x%08h never written (exp=0x%08h)",
                              addr, expected.exp_mem[addr]))
                fail_count++;
            end else if (shadow_mem[addr] !== expected.exp_mem[addr]) begin
                `uvm_error("SB",
                    $sformatf("MEM MISMATCH addr=0x%08h got=0x%08h exp=0x%08h",
                              addr, shadow_mem[addr], expected.exp_mem[addr]))
                fail_count++;
            end else pass_count++;
        end
    endfunction

    function void check_ipc(pipeline_stats_txn s);
        real effective_min = (expected != null && expected.min_ipc > 0.0)
                             ? expected.min_ipc : cfg.min_ipc;
        if (effective_min <= 0.0) return;
        check_count++;
        if (s.ipc < effective_min) begin
            `uvm_error("SB",
                $sformatf("IPC FAIL: got=%.3f min=%.3f", s.ipc, effective_min))
            fail_count++;
        end else begin
            `uvm_info("SB",
                $sformatf("IPC PASS: %.3f >= %.3f", s.ipc, effective_min), UVM_LOW)
            pass_count++;
        end
    endfunction

    function void check_x0_zero();
        check_count++;
        if (shadow_int[0] !== 32'h0) begin
            `uvm_error("SB", $sformatf("x0 != 0! (got 0x%08h)", shadow_int[0]))
            fail_count++;
        end else pass_count++;
    endfunction

    function void print_summary();
        `uvm_info("SB", $sformatf("\n============================================================\n  SCOREBOARD SUMMARY\n  Total Checks : %0d\n  PASSED       : %0d\n  FAILED       : %0d\n============================================================", check_count, pass_count, fail_count), UVM_LOW)
    endfunction

    function void report_phase(uvm_phase phase);
        if (fail_count > 0)
            `uvm_error("SB", $sformatf("TEST FAILED: %0d check(s) failed", fail_count))
        else if (check_count > 0)
            `uvm_info("SB", "ALL CHECKS PASSED", UVM_NONE)
    endfunction

endclass : riscv_scoreboard