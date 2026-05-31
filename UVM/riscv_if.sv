`timescale 1ns/1ps// =============================================================================
// riscv_if.sv  –  Virtual Interface for RISC-V Pipeline
// Exposes primary I/O plus internal probe points needed by monitor/scoreboard.
// =============================================================================
interface riscv_if (input logic clk);

    // -------------------------------------------------------------------------
    // Primary DUT ports
    // -------------------------------------------------------------------------
    logic        rst_n;
    logic [15:0] Result;

    // -------------------------------------------------------------------------
    // Pipeline stage probes  (driven by hierarchical references in tb_top)
    // -------------------------------------------------------------------------
    // Fetch stage
    logic [31:0] InstrD;
    logic [31:0] PCD;
    logic [31:0] PCPlus4D;

    // Decode stage
    logic        RegWriteE;
    logic [31:0] InstrDE;

    // Execute stage
    logic        PCSrcE;
    logic [31:0] PCTargetE;
    logic        BranchE;
    logic        JumpE;
    logic [3:0]  ALUControlE;
    logic [31:0] ALU_ResultM;

    // Memory stage
    logic        MemWriteM;
    logic        ResultSrcM;
    logic [31:0] WriteDataM;
    logic [31:0] InstrDM;

    // Write-back stage
    logic        RegWriteW;
    logic [4:0]  RDW;
    logic [31:0] ResultW;

    // Hazard / stall / flush
    logic        StallF;
    logic        StallD;
    logic        FlushE;
    logic        mispredict;
    logic        stall;         // FPU stall

    // Floating-point write-back
    logic        FRegWriteMW;
    logic [31:0] FResultW;
    logic [4:0]  FRdW;          // BUG 7 FIX: FP destination register (separate from RDW)

    // FP operation decode signals (needed by cg_fpu coverage group)
    // BUG 3 FIX: These were assigned in tb_top but missing from interface declaration
    logic        faddE;
    logic        fsubE;
    logic        fmulE;
    logic        fdivE;
    logic        fsqrtE;
    logic        floadE;
    logic        fstoreE;

    // Cache state
    logic [2:0]  cache_state;

    // -------------------------------------------------------------------------
    // Clocking blocks
    // -------------------------------------------------------------------------
    clocking drv_cb @(posedge clk);
        default input #1 output #1;
        output rst_n;
        input  Result;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1;
        input rst_n;
        input Result;
        input InstrD;
        input PCD;
        input RegWriteW;
        input RDW;
        input ResultW;
        input MemWriteM;
        input WriteDataM;
        input ALU_ResultM;
        input BranchE;
        input PCSrcE;
        input PCTargetE;
        input StallF;
        input StallD;
        input stall;
        input mispredict;
        input cache_state;
        input FRegWriteMW;
        input FResultW;
        input FRdW;
        input faddE;
        input fsubE;
        input fmulE;
        input fdivE;
        input fsqrtE;
        input floadE;
        input fstoreE;
    endclocking

    // -------------------------------------------------------------------------
    // Modports
    // -------------------------------------------------------------------------
    modport DRV (clocking drv_cb, input clk);
    modport MON (clocking mon_cb, input clk);

endinterface : riscv_if