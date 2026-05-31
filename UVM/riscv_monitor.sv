
`include "uvm_macros.svh"
import riscv_pkg::*;
import uvm_pkg::*;// =============================================================================
// riscv_monitor.sv  –  UVM Monitor
// Reads riscv_env_config to control what gets logged and tracked.
// =============================================================================

// =============================================================================
// riscv_monitor.sv  –  UVM Monitor
// Reads riscv_env_config to control what gets logged and tracked.
// =============================================================================

class reg_write_txn extends uvm_sequence_item;
    `uvm_object_utils(reg_write_txn)
    logic [4:0]  rd;
    logic [31:0] data;
    logic [31:0] pc;
    bit          is_fp;
    function new(string name="reg_write_txn"); super.new(name); endfunction
    function string convert2string();
        return $sformatf("%s[%0d]=0x%08h @ PC=0x%08h", is_fp?"f":"x", rd, data, pc);
    endfunction
endclass

class mem_txn extends uvm_sequence_item;
    `uvm_object_utils(mem_txn)
    logic [31:0] addr;
    logic [31:0] data;
    bit          is_write;
    function new(string name="mem_txn"); super.new(name); endfunction
    function string convert2string();
        return $sformatf("MEM_%s addr=0x%08h data=0x%08h",
                         is_write?"WR":"RD", addr, data);
    endfunction
endclass

class branch_txn extends uvm_sequence_item;
    `uvm_object_utils(branch_txn)
    logic [31:0] pc;
    logic [31:0] target;
    bit          taken;
    bit          mispredicted;
    function new(string name="branch_txn"); super.new(name); endfunction
    function string convert2string();
        return $sformatf("BRANCH @ 0x%08h %s target=0x%08h mispredict=%0b",
                         pc, taken?"TAKEN":"NOT_TAKEN", target, mispredicted);
    endfunction
endclass

class pipeline_stats_txn extends uvm_sequence_item;
    `uvm_object_utils(pipeline_stats_txn)
    int unsigned total_cycles;
    int unsigned instr_retired;
    int unsigned stall_cycles;
    int unsigned branch_count;
    int unsigned mispredicts;
    int unsigned cache_misses;
    real         ipc;
    function new(string name="pipeline_stats_txn"); super.new(name); endfunction
    function string convert2string();
        return $sformatf(
            "STATS: cycles=%0d retired=%0d stalls=%0d IPC=%.3f branches=%0d mispredict=%0d cache_miss=%0d",
            total_cycles, instr_retired, stall_cycles, ipc,
            branch_count, mispredicts, cache_misses);
    endfunction
endclass

// ===========================================================================
class riscv_monitor extends uvm_monitor;
    `uvm_component_utils(riscv_monitor)

    virtual riscv_if  vif;
    riscv_env_config  cfg;

    uvm_analysis_port #(reg_write_txn)      ap_reg_write;
    uvm_analysis_port #(mem_txn)            ap_mem;
    uvm_analysis_port #(branch_txn)         ap_branch;
    uvm_analysis_port #(pipeline_stats_txn) ap_stats;

    // Internal counters
    int unsigned total_cycles;
    int unsigned instr_retired;
    int unsigned stall_cycles;
    int unsigned branch_count;
    int unsigned mispredicts;
    int unsigned cache_misses;
    logic en=0;
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // -----------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Read config object — get vif and all monitoring knobs from it
        if (!uvm_config_db #(riscv_env_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("NOCFG", "riscv_monitor: riscv_env_config not found")

        vif = cfg.vif;
        if (vif == null)
            `uvm_fatal("NOVIF", "riscv_monitor: cfg.vif is null")

        ap_reg_write = new("ap_reg_write", this);
        ap_mem       = new("ap_mem",       this);
        ap_branch    = new("ap_branch",    this);
        ap_stats     = new("ap_stats",     this);
    endfunction

    // -----------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        reset_counters();
        fork
            monitor_reg_writes();
            monitor_mem_ops();
            monitor_branches();
            monitor_stalls();
            monitor_cache();
        join
    endtask

    task reset_counters();
        total_cycles  = 0; instr_retired = 0;
        stall_cycles  = 0; branch_count  = 0;
        mispredicts   = 0; cache_misses  = 0;
    endtask

    // -----------------------------------------------------------------------
    task monitor_reg_writes();
        forever begin
            @(vif.mon_cb);
            if (!vif.mon_cb.rst_n) continue;
            if(vif.InstrDM==32'h0000006F)
                en=1;
            // Only count cycles while the program is still running.
            // Once InstrD goes X the pipeline is fetching past the end
            // of IMEM — those idle cycles must not inflate the IPC denominator.
            if (en!=1'd1)
                total_cycles++;

            if (vif.mon_cb.RegWriteW && vif.mon_cb.RDW != 5'h0) begin
                reg_write_txn t = reg_write_txn::type_id::create("rwt");
                t.rd = vif.mon_cb.RDW; t.data = vif.mon_cb.ResultW; t.is_fp = 0;
                ap_reg_write.write(t);
                if (cfg.log_every_reg_write)
                    `uvm_info("MON", t.convert2string(), UVM_LOW)
            end

            if (vif.mon_cb.FRegWriteMW) begin
                reg_write_txn t = reg_write_txn::type_id::create("frwt");
                // BUG 7 FIX: FP destination is FRdW, not RDW (integer dest).
                t.rd   = vif.mon_cb.FRdW;
                t.data = vif.mon_cb.FResultW;
                t.is_fp = 1;
                ap_reg_write.write(t);
            end

            if (vif.mon_cb.InstrD != 32'h00000013 &&
                vif.mon_cb.InstrD != 32'h0          &&
                vif.mon_cb.InstrD != 32'h0000006F   &&
                !vif.mon_cb.StallD)
                instr_retired++;
        end
    endtask

    // -----------------------------------------------------------------------
    task monitor_mem_ops();
        forever begin
            @(vif.mon_cb);
            if (!vif.mon_cb.rst_n) continue;
            if (vif.mon_cb.MemWriteM) begin
                mem_txn t = mem_txn::type_id::create("mt");
                t.addr = vif.mon_cb.ALU_ResultM;
                t.data = vif.mon_cb.WriteDataM;
                t.is_write = 1;
                ap_mem.write(t);
                if (cfg.log_every_mem_write)
                    `uvm_info("MON", t.convert2string(), UVM_LOW)
            end
        end
    endtask

    // -----------------------------------------------------------------------
    task monitor_branches();
        forever begin
            @(vif.mon_cb);
            if (!vif.mon_cb.rst_n) continue;
            if (vif.mon_cb.BranchE) begin
                branch_txn t = branch_txn::type_id::create("bt");
                t.pc           = vif.mon_cb.PCD;
                t.target       = vif.mon_cb.PCTargetE;
                t.taken        = vif.mon_cb.PCSrcE;
                t.mispredicted = vif.mon_cb.mispredict;
                ap_branch.write(t);
                branch_count++;
                if (vif.mispredict) begin
                    mispredicts++;
                    if (cfg.track_mispredicts)
                        `uvm_info("MON", $sformatf("MISPREDICT: %s", t.convert2string()), UVM_MEDIUM)
                end
            end
        end
    endtask

    // -----------------------------------------------------------------------
    task monitor_stalls();
        forever begin
            @(vif.mon_cb);
            if (!vif.mon_cb.rst_n) continue;
            if ($isunknown(vif.mon_cb.InstrD)) continue;  // past program end
            if (vif.mon_cb.StallF || vif.mon_cb.StallD || vif.mon_cb.stall)
                stall_cycles++;
        end
    endtask

    // -----------------------------------------------------------------------
    task monitor_cache();
        logic [2:0] prev_state = 0;
        forever begin
            @(vif.mon_cb);
            if (!vif.mon_cb.rst_n) begin prev_state = 0; continue; end
            if (prev_state != 3'd3 && vif.mon_cb.cache_state == 3'd3) begin
                cache_misses++;
                if (cfg.detailed_cache_stats)
                    `uvm_info("MON",
                        $sformatf("CACHE MISS #%0d", cache_misses), UVM_LOW)
            end
            prev_state = vif.mon_cb.cache_state;
        end
    endtask

    // -----------------------------------------------------------------------
    function void publish_stats();
        pipeline_stats_txn s = pipeline_stats_txn::type_id::create("stats");
        s.total_cycles  = total_cycles;
        s.instr_retired = instr_retired;
        s.stall_cycles  = stall_cycles;
        s.branch_count  = branch_count;
        s.mispredicts   = mispredicts;
        s.cache_misses  = cache_misses;
        s.ipc = (total_cycles > 0) ?
                    real'(instr_retired) / real'(total_cycles) : 0.0;
        ap_stats.write(s);
        `uvm_info("MON", s.convert2string(), UVM_LOW)
    endfunction

endclass : riscv_monitor