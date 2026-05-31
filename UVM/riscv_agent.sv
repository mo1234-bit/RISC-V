// =============================================================================
// riscv_agent.sv  –  UVM Agent
// Reads riscv_env_config and propagates it to driver + monitor.
// =============================================================================

`include "uvm_macros.svh"

import uvm_pkg::*;import riscv_pkg::*;
class riscv_agent extends uvm_agent;
    `uvm_component_utils(riscv_agent)

    riscv_driver                    driver;
    riscv_monitor                   monitor;
    uvm_sequencer #(riscv_seq_item) sequencer;

    riscv_env_config cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // -----------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Read config object
        if (!uvm_config_db #(riscv_env_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("NOCFG", "riscv_agent: riscv_env_config not found")

        // Propagate vif and cfg to children via config_db
        uvm_config_db #(virtual riscv_if)   ::set(this, "*", "vif", cfg.vif);
        uvm_config_db #(riscv_env_config)   ::set(this, "*", "cfg", cfg);

        // Create sub-components based on agent mode
        if (cfg.agent_mode == UVM_ACTIVE) begin
            driver    = riscv_driver::type_id::create("driver", this);
            sequencer = uvm_sequencer #(riscv_seq_item)
                            ::type_id::create("sequencer", this);
        end
        monitor = riscv_monitor::type_id::create("monitor", this);
    endfunction

    // -----------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        if (cfg.agent_mode == UVM_ACTIVE)
            driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

endclass : riscv_agent