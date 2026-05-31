
`include "uvm_macros.svh"
import riscv_pkg::*;
import uvm_pkg::*;// =============================================================================
// riscv_env.sv  –  UVM Environment
// Creates config object (if not already in db), builds sub-components.
// =============================================================================
class riscv_env extends uvm_env;
    `uvm_component_utils(riscv_env)

    riscv_agent      agent;
    riscv_scoreboard scoreboard;
    riscv_coverage   coverage;

    riscv_env_config cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // -----------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Get config object — MUST be set by the test before env is built
        if (!uvm_config_db #(riscv_env_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("build_phase","unable to get interface in test")

        `uvm_info("ENV", $sformatf("Config loaded: %s", cfg.convert2string()), UVM_HIGH)

        // Apply verbosity from config
        set_report_verbosity_level_hier(cfg.verbosity);

        // Propagate config to all children
        uvm_config_db #(riscv_env_config)::set(this, "agent",      "cfg", cfg);
        uvm_config_db #(riscv_env_config)::set(this, "scoreboard", "cfg", cfg);
        uvm_config_db #(riscv_env_config)::set(this, "coverage",   "cfg", cfg);

        agent      = riscv_agent     ::type_id::create("agent",      this);
        scoreboard = riscv_scoreboard::type_id::create("scoreboard",  this);

        if (cfg.enable_coverage)
            coverage = riscv_coverage::type_id::create("coverage", this);
    endfunction

    // -----------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        agent.monitor.ap_reg_write.connect(scoreboard.aimp_reg);
        agent.monitor.ap_mem      .connect(scoreboard.aimp_mem);
        agent.monitor.ap_branch   .connect(scoreboard.aimp_branch);
        agent.monitor.ap_stats    .connect(scoreboard.aimp_stats);

        if (cfg.enable_coverage)
            agent.monitor.ap_reg_write.connect(coverage.analysis_export);
    endfunction

endclass : riscv_env