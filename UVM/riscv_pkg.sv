// =============================================================================
// riscv_pkg.sv  –  UVM Package
// Import this package in your testbench top.
// =============================================================================
package riscv_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // -----------------------------------------------------------------------
    // Global events used to hand-shake program loading between driver & tb_top
    // -----------------------------------------------------------------------
    event load_program_ev;      // driver → tb_top: "please load this hex file"
    event program_loaded_ev;    // tb_top → driver: "done loading"

    // -----------------------------------------------------------------------
    // Include order matters: items before classes that use them
    // -----------------------------------------------------------------------
    `include "riscv_config.sv"    // config object — included first
    `include "riscv_seq_item.sv"
    `include "riscv_instr.sv"         // per-instruction randomized classes
    `include "riscv_progrem_gen.sv"   // constrained-random program builder
    `include "riscv_monitor.sv"       // defines helper txn classes too

    
    `uvm_analysis_imp_decl(_reg)
    `uvm_analysis_imp_decl(_mem)
    `uvm_analysis_imp_decl(_branch)
    `uvm_analysis_imp_decl(_stats)

    `include "riscv_scoreboard.sv"
    `include "riscv_coverage.sv"
    `include "riscv_driver.sv"
    `include "riscv_agent.sv"
    `include "riscv_env.sv"
    `include "riscv_sequences.sv"
    `include "riscv_tests.sv"

endpackage : riscv_pkg