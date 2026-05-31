`include "uvm_macros.svh"
import riscv_pkg::*;
import uvm_pkg::*;
class riscv_base_seq extends uvm_sequence #(riscv_seq_item);
    `uvm_object_utils(riscv_base_seq)
    function new(string name = "riscv_base_seq");

     super.new(name);
     
      endfunction

    virtual task body();
        
    endtask

    task send_random();
        riscv_seq_item item;
        item = riscv_seq_item::type_id::create("item");
        start_item(item);
        if (!item.randomize())
            `uvm_fatal("SEQ","Randomization failed")
        `uvm_info("SEQ", $sformatf("Sending: %s", item.convert2string()), UVM_MEDIUM)
        finish_item(item);
    endtask
endclass

// ---------------------------------------------------------------------------
// Fully random – N randomly generated programs back-to-back
// ---------------------------------------------------------------------------
class riscv_random_seq extends riscv_base_seq;
    `uvm_object_utils(riscv_random_seq)
    int unsigned iterations = 10;
    function new(string name = "riscv_random_seq");
     super.new(name);
     endfunction

    task body();
        for (int i = 0; i < iterations; i++) begin
            `uvm_info("SEQ",$sformatf("=== Random iteration %0d/%0d ===",i+1,iterations),UVM_LOW)
            send_random();
        end
    endtask
endclass

// ---------------------------------------------------------------------------
// Integer-ALU biased
// ---------------------------------------------------------------------------
class riscv_int_alu_seq extends riscv_base_seq;
    `uvm_object_utils(riscv_int_alu_seq)
    function new(string name = "riscv_int_alu_seq"); super.new(name); endfunction

    task body();
        riscv_seq_item item = riscv_seq_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
            stim_mode  == RANDOM_PROGRAM;
            num_instrs inside {[50:150]};
            w_r_type   inside {[30:40]};
            w_i_alu    inside {[25:35]};
            w_load     inside {[5:10]};
            w_store    inside {[5:10]};
            w_branch   inside {[5:10]};
            w_u_type   inside {[2:5]};
            w_fp_arith == 0;
            w_fp_mem   == 0;
            run_cycles inside {[1000:3000]};
        }) `uvm_fatal("SEQ","int_alu randomize failed")
        item.min_ipc = 0.50;
        finish_item(item);
    endtask
endclass

// ---------------------------------------------------------------------------
// Load/Store biased
// ---------------------------------------------------------------------------
class riscv_load_store_seq extends riscv_base_seq;
    `uvm_object_utils(riscv_load_store_seq)
    function new(string name = "riscv_load_store_seq"); super.new(name); endfunction

    task body();
        riscv_seq_item item = riscv_seq_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
            stim_mode  == RANDOM_PROGRAM;
            num_instrs inside {[50:120]};
            w_r_type   inside {[5:15]};
            w_i_alu    inside {[5:15]};
            w_load     inside {[20:30]};
            w_store    inside {[15:25]};
            w_branch   inside {[5:10]};
            w_u_type   inside {[2:5]};
            w_fp_arith inside {[5:10]};
            w_fp_mem   inside {[5:10]};
            run_cycles inside {[2000:5000]};
        }) `uvm_fatal("SEQ","load_store randomize failed")
        item.min_ipc = 0.25;
        finish_item(item);
    endtask
endclass

// ---------------------------------------------------------------------------
// Branch-stress
// ---------------------------------------------------------------------------
class riscv_branch_stress_seq extends riscv_base_seq;
    `uvm_object_utils(riscv_branch_stress_seq)
    function new(string name = "riscv_branch_stress_seq"); super.new(name); endfunction

    task body();
        for (int i = 0; i < 3; i++) begin
            riscv_seq_item item = riscv_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with {
                stim_mode  == RANDOM_PROGRAM;
                num_instrs inside {[60:120]};
                w_r_type   inside {[10:20]};
                w_i_alu    inside {[10:20]};
                w_load     inside {[5:10]};
                w_store    inside {[5:10]};
                w_branch   inside {[25:35]};
                w_u_type   inside {[2:5]};
                w_fp_arith == 0;
                w_fp_mem   == 0;
                run_cycles inside {[3000:6000]};
            }) `uvm_fatal("SEQ","branch randomize failed")
            item.min_ipc = 0.40;
            finish_item(item);
        end
    endtask
endclass

// ---------------------------------------------------------------------------
// FPU heavy
// ---------------------------------------------------------------------------
class riscv_fpu_seq extends riscv_base_seq;
    `uvm_object_utils(riscv_fpu_seq)
    function new(string name = "riscv_fpu_seq"); super.new(name); endfunction

    task body();
        riscv_seq_item item = riscv_seq_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
            stim_mode  == RANDOM_PROGRAM;
            num_instrs inside {[30:80]};
            w_r_type   inside {[5:10]};
            w_i_alu    inside {[5:10]};
            w_load     inside {[5:10]};
            w_store    inside {[5:10]};
            w_branch   inside {[2:5]};
            w_u_type   inside {[2:5]};
            w_fp_arith inside {[30:40]};
            w_fp_mem   inside {[10:15]};
            run_cycles inside {[5000:10000]};
        }) `uvm_fatal("SEQ","fpu randomize failed")
        item.min_ipc = 0.08;
        finish_item(item);
    endtask
endclass

// ---------------------------------------------------------------------------
// Reset stress
// ---------------------------------------------------------------------------
class riscv_reset_stress_seq extends uvm_sequence #(riscv_seq_item);
    `uvm_object_utils(riscv_reset_stress_seq)
    int unsigned iterations = 5;
    function new(string name = "riscv_reset_stress_seq"); super.new(name); endfunction

    task body();
        for (int i = 0; i < iterations; i++) begin
            riscv_seq_item item = riscv_seq_item::type_id::create($sformatf("item_%0d",i));
            start_item(item);
            if (!item.randomize() with {
                run_cycles   inside {[100:500]};
                reset_cycles inside {[2:8]};
                num_instrs   inside {[20:60]};
                stim_mode    == RANDOM_PROGRAM;
            }) `uvm_fatal("SEQ","reset_stress randomize failed")
            `uvm_info("SEQ",$sformatf("Reset iter %0d: %s",i,item.convert2string()),UVM_MEDIUM)
            finish_item(item);
        end
    endtask
endclass

// ---------------------------------------------------------------------------
// Full hex-file sequence (keeps directed regression against memfile.hex)
// ---------------------------------------------------------------------------
class riscv_full_test_seq extends riscv_base_seq;
    `uvm_object_utils(riscv_full_test_seq)
    function new(string name = "riscv_full_test_seq"); super.new(name); endfunction

    task body();
        riscv_seq_item item = riscv_seq_item::type_id::create("item");
        start_item(item);
        item.stim_mode        = riscv_seq_item::HEX_FILE;
        item.hex_file         = "memfile.hex";
        item.run_cycles       = 10000;
        item.min_ipc          = 0.35;
        item.exp_int_regs[30] = 32'h0DEADBEF;
        finish_item(item);
    endtask
endclass