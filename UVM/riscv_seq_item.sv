`include "uvm_macros.svh"
import riscv_pkg::*;
import uvm_pkg::*;
// =============================================================================
// riscv_seq_item.sv  –  Updated UVM Sequence Item
// Supports BOTH random program generation AND hex file loading.
// =============================================================================
class riscv_seq_item extends uvm_sequence_item;
    `uvm_object_utils(riscv_seq_item)

    // -----------------------------------------------------------------------
    // Stimulus mode
    // -----------------------------------------------------------------------
    typedef enum { RANDOM_PROGRAM, HEX_FILE } stim_mode_e;
    rand stim_mode_e stim_mode;

    // ---- HEX FILE mode ----
    string hex_file;

    // ---- RANDOM PROGRAM mode ----
    rand int unsigned num_instrs;       // number of random instructions
    rand int unsigned seed;             // per-test seed

    // Instruction mix weights (0–100, must sum ≤ 95)
    rand int unsigned w_r_type;
    rand int unsigned w_i_alu;
    rand int unsigned w_load;
    rand int unsigned w_store;
    rand int unsigned w_branch;
    rand int unsigned w_u_type;
    rand int unsigned w_fp_arith;
    rand int unsigned w_fp_mem;

    // ---- Common ----
    rand int unsigned run_cycles;
    rand int unsigned reset_cycles;

    // -----------------------------------------------------------------------
    // Expected outcomes
    // -----------------------------------------------------------------------
    logic [31:0] exp_int_regs[32];
    logic [31:0] exp_fp_regs[32];
    logic [31:0] exp_mem[bit [31:0]];   // bit (2-state) index — legal in SV
    real         min_ipc;

    // -----------------------------------------------------------------------
    // Constraints
    // -----------------------------------------------------------------------
    constraint c_cycles      { run_cycles   inside {[500:15000]}; }
    constraint c_reset       { reset_cycles inside {[3:8]};       }
    constraint c_num_instrs  { num_instrs   inside {[20:200]};    }

    constraint c_weights {
        // Soft constraints — sequence-level overrides (e.g. w_fp_arith==0)
        // take priority without causing a solver conflict.
        soft w_r_type   inside {[5:30]};
        soft w_i_alu    inside {[5:25]};
        soft w_load     inside {[5:20]};
        soft w_store    inside {[5:15]};
        soft w_branch   inside {[5:15]};
        soft w_u_type   inside {[2:10]};
        soft w_fp_arith inside {[5:15]};
        soft w_fp_mem   inside {[2:10]};
        (w_r_type + w_i_alu + w_load + w_store +
         w_branch + w_u_type + w_fp_arith + w_fp_mem) <= 95;
    }

    // Default: prefer random programs
    constraint c_mode { stim_mode dist { RANDOM_PROGRAM := 70, HEX_FILE := 30 }; }

    // -----------------------------------------------------------------------
    function new(string name = "riscv_seq_item");
        super.new(name);
        hex_file     = "memfile.hex";
        min_ipc      = 0.0;
        reset_cycles = 5;
        run_cycles   = 5000;
        foreach (exp_int_regs[i]) exp_int_regs[i] = 32'hX;
        foreach (exp_fp_regs[i])  exp_fp_regs[i]  = 32'hX;
    endfunction

    // -----------------------------------------------------------------------
    function void do_copy(uvm_object rhs);
        riscv_seq_item rhs_;
        super.do_copy(rhs);
        if (!$cast(rhs_, rhs)) `uvm_fatal("CAST","Type mismatch in do_copy")
        stim_mode    = rhs_.stim_mode;
        hex_file     = rhs_.hex_file;
        num_instrs   = rhs_.num_instrs;
        seed         = rhs_.seed;
        w_r_type     = rhs_.w_r_type;
        w_i_alu      = rhs_.w_i_alu;
        w_load       = rhs_.w_load;
        w_store      = rhs_.w_store;
        w_branch     = rhs_.w_branch;
        w_u_type     = rhs_.w_u_type;
        w_fp_arith   = rhs_.w_fp_arith;
        w_fp_mem     = rhs_.w_fp_mem;
        run_cycles   = rhs_.run_cycles;
        reset_cycles = rhs_.reset_cycles;
        exp_int_regs = rhs_.exp_int_regs;
        exp_fp_regs  = rhs_.exp_fp_regs;
        exp_mem      = rhs_.exp_mem;
        min_ipc      = rhs_.min_ipc;
    endfunction

    function string convert2string();
        if (stim_mode == HEX_FILE)
            return $sformatf("HEX_FILE=%s run=%0d rst=%0d min_ipc=%.2f",
                             hex_file, run_cycles, reset_cycles, min_ipc);
        else
            return $sformatf("RANDOM n=%0d seed=%0d run=%0d rst=%0d mix=[R:%0d I:%0d LD:%0d ST:%0d BR:%0d U:%0d FP:%0d FPM:%0d]",
                             num_instrs, seed, run_cycles, reset_cycles,
                             w_r_type, w_i_alu, w_load, w_store,
                             w_branch, w_u_type, w_fp_arith, w_fp_mem);
    endfunction

endclass : riscv_seq_item