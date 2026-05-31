
`include "uvm_macros.svh"

import uvm_pkg::*;import riscv_pkg::*;// =============================================================================
// riscv_coverage.sv  -  Functional Coverage
// Covergroups use explicit sample() calls from run_phase to avoid
// SIGSEGV from vif-referenced triggers being evaluated before vif is set.
// =============================================================================
class riscv_coverage extends uvm_subscriber #(reg_write_txn);
    `uvm_component_utils(riscv_coverage)

    virtual riscv_if vif;

    // -----------------------------------------------------------------------
    // Covergroups — NO clock triggers here; sampled explicitly in run_phase.
    // -----------------------------------------------------------------------

    // ---------- Instruction opcode coverage ----------
    covergroup cg_opcodes;
        cp_opcode: coverpoint vif.InstrD[6:0] {
            bins R_type   = {7'b0110011};
            bins I_alu    = {7'b0010011};
            bins load     = {7'b0000011};
            bins store    = {7'b0100011};
            bins branch   = {7'b1100011};
            bins jal      = {7'b1101111};
            bins jalr     = {7'b1100111};
            bins lui      = {7'b0110111};
            bins auipc    = {7'b0010111};
            bins fp_op    = {7'b1010011};
            bins fp_load  = {7'b0000111};
            bins fp_store = {7'b0100111};
            bins other    = default;
        }
    endgroup

    // ---------- ALU operation coverage ----------
    covergroup cg_alu_ctrl;
        cp_ctrl: coverpoint vif.ALUControlE {
            bins ADD  = {4'b0000};
            bins SUB  = {4'b0001};
            bins AND  = {4'b0010};
            bins OR   = {4'b0011};
            bins XOR  = {4'b0100};
            bins SLT  = {4'b0101};
            bins SLTU = {4'b0110};
            bins SLL  = {4'b0111};
            bins SRL  = {4'b1000};
            bins SRA  = {4'b1001};
        }
    endgroup

    // ---------- Hazard / stall coverage ----------
    covergroup cg_hazards;
        cp_stall_f:   coverpoint vif.StallF    { bins stalled = {1}; bins free = {0}; }
        cp_stall_d:   coverpoint vif.StallD    { bins stalled = {1}; bins free = {0}; }
        cp_fp_stall:  coverpoint vif.stall     { bins stalled = {1}; bins free = {0}; }
        cp_mispredict:coverpoint vif.mispredict{ bins mis = {1};     bins ok  = {0}; }
        cx_stall_types: cross cp_stall_f, cp_stall_d, cp_fp_stall;
    endgroup

    // ---------- Branch outcome coverage ----------
    covergroup cg_branch;
        cp_taken:     coverpoint vif.PCSrcE    { bins taken = {1}; bins not_taken = {0}; }
        cp_mispredict:coverpoint vif.mispredict{ bins mis = {1};   bins ok = {0}; }
        cx_branch: cross cp_taken, cp_mispredict;
    endgroup

    // ---------- Cache state coverage ----------
    covergroup cg_cache;
        cp_state: coverpoint vif.cache_state {
            bins IDLE   = {3'd0};
            bins COMP   = {3'd1};
            bins HIT    = {3'd2};
            bins FETCH1 = {3'd3};
            bins FETCH2 = {3'd4};
            bins WB1    = {3'd5};
            bins WB2    = {3'd6};
        }
    endgroup

    // ---------- Register destination coverage ----------
    covergroup cg_rd_dest;
        cp_rd: coverpoint vif.RDW {
            bins zero     = {0};
            bins ra       = {1};
            bins sp       = {2};
            bins gp       = {3};
            bins tp       = {4};
            bins temp[3]  = {[5:7]};
            bins saved[12]= {[8:19]};
            bins args[8]  = {[10:17]};
            bins upper[6] = {[26:31]};
        }
    endgroup

    // ---------- FP operation coverage ----------
    covergroup cg_fpu;
        cp_fadd:  coverpoint vif.faddE  { bins active = {1}; }
        cp_fsub:  coverpoint vif.fsubE  { bins active = {1}; }
        cp_fmul:  coverpoint vif.fmulE  { bins active = {1}; }
        cp_fdiv:  coverpoint vif.fdivE  { bins active = {1}; }
        cp_fsqrt: coverpoint vif.fsqrtE { bins active = {1}; }
        cp_fload: coverpoint vif.floadE { bins active = {1}; }
        cp_fstore:coverpoint vif.fstoreE{ bins active = {1}; }
    endgroup

    // -----------------------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);
        // Safe: no vif access in covergroup body at construction time
        // because triggers have been removed.
        cg_opcodes   = new();
        cg_alu_ctrl  = new();
        cg_hazards   = new();
        cg_branch    = new();
        cg_cache     = new();
        cg_rd_dest   = new();
        cg_fpu       = new();
    endfunction

    function void build_phase(uvm_phase phase);
        riscv_env_config cfg;
        super.build_phase(phase);
        if (!uvm_config_db #(riscv_env_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("NOCFG", "riscv_coverage: riscv_env_config not found")
        vif = cfg.vif;
        if (vif == null)
            `uvm_fatal("NOVIF", "riscv_coverage: cfg.vif is null")
    endfunction

    // -----------------------------------------------------------------------
    // Explicit sampling loop — runs after vif is guaranteed non-null
    // -----------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        forever begin
            @(posedge vif.clk);
            if (vif.rst_n) begin
                // Sample every cycle
                cg_alu_ctrl.sample();
                cg_hazards.sample();
                cg_cache.sample();
                cg_fpu.sample();

                // Gate on valid instruction in Decode
                if (vif.InstrD != 0)
                    cg_opcodes.sample();

                // Gate on branch in Execute
                if (vif.BranchE)
                    cg_branch.sample();

                // Gate on integer register write-back
                if (vif.RegWriteW)
                    cg_rd_dest.sample();
            end
        end
    endtask

    function void write(reg_write_txn t);
        // Sampling driven by run_phase; nothing needed here
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("COV", $sformatf("\n============================================\n  COVERAGE REPORT\n  Opcodes     : %0.1f%%\n  ALU Ctrl    : %0.1f%%\n  Hazards     : %0.1f%%\n  Branches    : %0.1f%%\n  Cache States: %0.1f%%\n  Reg Dest    : %0.1f%%\n  FPU Ops     : %0.1f%%\n============================================", cg_opcodes.get_coverage(), cg_alu_ctrl.get_coverage(), cg_hazards.get_coverage(), cg_branch.get_coverage(), cg_cache.get_coverage(), cg_rd_dest.get_coverage(), cg_fpu.get_coverage()), UVM_NONE)
    endfunction

endclass : riscv_coverage