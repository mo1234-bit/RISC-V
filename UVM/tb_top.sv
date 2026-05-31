// =============================================================================
// tb_top.sv  –  UVM Testbench Top Module
// Instantiates DUT + interface, starts UVM test, handles program loading.
// =============================================================================
`timescale 1ns/1ps

`include "uvm_macros.svh"

import uvm_pkg::*;
import riscv_pkg::*;

module tb_top;

    // -----------------------------------------------------------------------
    // Clock
    // -----------------------------------------------------------------------
    logic clk;
    initial clk = 0;
    always #5 clk = ~clk;   // 100 MHz

    // -----------------------------------------------------------------------
    // Interface
    // -----------------------------------------------------------------------
    riscv_if dut_if (.clk(clk));

    // -----------------------------------------------------------------------
    // DUT instance
    // -----------------------------------------------------------------------
    Pipeline_top1 dut (
        .clk   (clk),
        .rst_n (dut_if.rst_n),
        .Result(dut_if.Result)
    );

    // -----------------------------------------------------------------------
    // Probe internal signals → interface
    // -----------------------------------------------------------------------
    assign dut_if.InstrD      = dut.InstrD;
    assign dut_if.PCD         = dut.PCD;
    assign dut_if.PCPlus4D    = dut.PCPlus4D;
    assign dut_if.RegWriteE   = dut.RegWriteE;
    assign dut_if.InstrDE     = dut.InstrDE;
    assign dut_if.PCSrcE      = dut.PCSrcE;
    assign dut_if.PCTargetE   = dut.PCTargetE;
    assign dut_if.BranchE     = dut.BranchE;
    assign dut_if.JumpE       = dut.JumpE;
    assign dut_if.ALUControlE = dut.ALUControlE;
    assign dut_if.ALU_ResultM = dut.ALU_ResultM;
    assign dut_if.MemWriteM   = dut.MemWriteM;
    assign dut_if.ResultSrcM  = dut.ResultSrcM;
    assign dut_if.WriteDataM  = dut.WriteDataM;
    assign dut_if.InstrDM     = dut.InstrDM;
    assign dut_if.RegWriteW   = dut.RegWriteW;
    assign dut_if.RDW         = dut.RDW;
    assign dut_if.ResultW     = dut.ResultW;
    assign dut_if.StallF      = dut.StallF;
    assign dut_if.StallD      = dut.StallD;
    assign dut_if.FlushE      = dut.FlushE;
    assign dut_if.mispredict  = dut.mispredict;
    assign dut_if.stall       = dut.stall;
    assign dut_if.FRegWriteMW = dut.FRegWriteMW;
    assign dut_if.FResultW    = dut.FResultW;
    assign dut_if.FRdW        = dut.RDW;       // BUG 7 FIX: separate FP destination register
    assign dut_if.cache_state = dut.Memory.dut.state;

    // PC in Fetch stage (needed by assertions)
    // Adjust hierarchy if your PC register has a different path
    logic [31:0] PC_F;
    assign PC_F = dut.Fetch.PCF;   // <- update to match your DUT hierarchy

    // Additional coverage signals forwarded directly to interface
    assign dut_if.faddE   = dut.faddE;
    assign dut_if.fsubE   = dut.fsubE;
    assign dut_if.fmulE   = dut.fmulE;
    assign dut_if.fdivE   = dut.fdivE;
    assign dut_if.fsqrtE  = dut.fsqrtE;
    assign dut_if.floadE  = dut.floadE;
    assign dut_if.fstoreE = dut.fstoreE;

    // -----------------------------------------------------------------------
    // Program loading handshake
    // The driver triggers load_program_ev; this block calls $readmemh
    // -----------------------------------------------------------------------
    always @(riscv_pkg::load_program_ev) begin
        string hex_file;
        if (!uvm_config_db #(string)::get(null, "*", "hex_file", hex_file))
            hex_file = "memfile.hex";

        `uvm_info("TB_TOP", $sformatf("Loading program: %s", hex_file), UVM_LOW)
        $readmemh(hex_file, dut.Fetch.IMEM.mem);
        -> riscv_pkg::program_loaded_ev;
    end

    // -----------------------------------------------------------------------
    // Waveform dump
    // -----------------------------------------------------------------------
    initial begin
        $dumpfile("uvm_riscv.vcd");
        $dumpvars(0, tb_top);
    end

    // -----------------------------------------------------------------------
    // Register interface in config_db and start UVM
    // -----------------------------------------------------------------------
     initial begin
        uvm_config_db #(virtual riscv_if)::set(null, "uvm_test_top*", "vif", dut_if);
        run_test();   // test name supplied via +UVM_TESTNAME=...
    end

    // -----------------------------------------------------------------------
    // Bind assertions module to DUT
    // BUG 8 FIX: bind port map must reference signals from the DUT's own
    // hierarchy (or top-level wires), NOT via "tb_top.dut_if.*" cross-module
    // references which are illegal in a bind context.
    // All signals are connected from the DUT's internal hierarchy directly.
    // -----------------------------------------------------------------------
    bind Pipeline_top1 riscv_pipeline_assertions u_assertions (
        .clk         (clk),
        .rst_n       (rst_n),
        .Result      (Result),

        // Fetch — adjust path to match your Fetch module's internal PC register
        .PC_F        (dut.Fetch.PCF),
        .InstrF      (dut.Fetch.InstrF),

        // Decode
        .InstrD      (InstrD),
        .PCD         (PCD),

        // Execute
        .InstrDE     (InstrDE),
        .RegWriteE   (RegWriteE),
        .BranchE     (BranchE),
        .JumpE       (JumpE),
        .PCSrcE      (PCSrcE),
        .PCTargetE   (PCTargetE),
        .ALUControlE (ALUControlE),

        // Memory
        .InstrDM     (InstrDM),
        .MemWriteM   (MemWriteM),
        .ResultSrcM  (ResultSrcM),
        .ALU_ResultM (ALU_ResultM),
        .WriteDataM  (WriteDataM),

        // Write-back
        .RegWriteW   (RegWriteW),
        .RDW         (RDW),
        .ResultW     (ResultW),

        // Hazard
        .StallF      (StallF),
        .StallD      (StallD),
        .FlushE      (FlushE),
        .stall       (stall),
        .mispredict  (mispredict),

        // FPU
        .FRegWriteMW (FRegWriteMW),
        .FResultW    (FResultW),

        // Cache
        .cache_state (Memory.dut.state)
    );

    // -----------------------------------------------------------------------
    // Timeout watchdog
    // -----------------------------------------------------------------------
    initial begin
        #200_000;
        `uvm_fatal("TIMEOUT", "Simulation exceeded 200 us – check for hang")
    end

endmodule : tb_top