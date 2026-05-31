`include "uvm_macros.svh"
import riscv_pkg::*;
import uvm_pkg::*;

class riscv_driver extends uvm_driver #(riscv_seq_item);
    `uvm_component_utils(riscv_driver)

    virtual riscv_if   vif;
    riscv_env_config   cfg;
    riscv_program_gen  prog_gen;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // -----------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(riscv_env_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("NOCFG", "riscv_driver: riscv_env_config not found")

        // VIF comes from the config object
        vif = cfg.vif;
        if (vif == null)
            `uvm_fatal("NOVIF", "riscv_driver: cfg.vif is null")

       
        prog_gen = riscv_program_gen::type_id::create("prog_gen");
    endfunction

    // -----------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        riscv_seq_item item;
        vif.drv_cb.rst_n <= 1'b0;
        repeat(5) @(vif.drv_cb);

        forever begin
            seq_item_port.get_next_item(item);
            `uvm_info("DRV", $sformatf("Got item: %s", item.convert2string()), UVM_MEDIUM)
            drive_item(item);
            seq_item_port.item_done();
        end
    endtask

    // -----------------------------------------------------------------------
    task drive_item(riscv_seq_item item);
        // Assert reset
        vif.drv_cb.rst_n <= 1'b0;
        repeat(item.reset_cycles) @(vif.drv_cb);

        // Load stimulus
        case (item.stim_mode)
            riscv_seq_item::RANDOM_PROGRAM: load_random_program(item);
            riscv_seq_item::HEX_FILE:       load_hex_file(item.hex_file);
        endcase

        // Release reset
        @(vif.drv_cb);
        vif.drv_cb.rst_n <= 1'b1;

        // Run
        repeat(item.run_cycles) @(vif.drv_cb);
    endtask

    // -----------------------------------------------------------------------
    task load_random_program(riscv_seq_item item);
        string tmp_hex;

        // Apply item-level overrides on top of cfg defaults
        prog_gen.num_instrs     = item.num_instrs;
        prog_gen.w_r_type       = item.w_r_type;
        prog_gen.w_i_alu        = item.w_i_alu;
        prog_gen.w_load         = item.w_load;
        prog_gen.w_store        = item.w_store;
        prog_gen.w_branch       = item.w_branch;
        prog_gen.w_u_type       = item.w_u_type;
        prog_gen.w_fp_arith     = item.w_fp_arith;
        prog_gen.w_fp_mem       = item.w_fp_mem;
        prog_gen.data_base_addr = cfg.data_base_addr;

        prog_gen.generate_program();

        if (uvm_report_enabled(UVM_HIGH))
            prog_gen.print_listing();

        tmp_hex = $sformatf("riscv_rand_%0t.hex", $time);
        prog_gen.write_hex(tmp_hex);

        `uvm_info("DRV",
            $sformatf("Random program written to %s (%0d instrs)",
                      tmp_hex, prog_gen.actual_len), UVM_LOW)

        load_hex_file(tmp_hex);
    endtask

    // -----------------------------------------------------------------------
    task load_hex_file(string hex_file);
        uvm_config_db #(string)::set(null, "*", "hex_file", hex_file);
        -> riscv_pkg::load_program_ev;
        @(riscv_pkg::program_loaded_ev);
        `uvm_info("DRV", $sformatf("Hex file loaded: %s", hex_file), UVM_LOW)
    endtask

endclass : riscv_driver