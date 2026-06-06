# FloatCore-RV32IF — Pipelined RISC-V Processor with FPU and UVM Verification

FloatCore-RV32IF is a custom 5-stage RISC-V processor implementing the RV32I base ISA with single-precision floating-point support. The project combines RTL microarchitecture, floating-point arithmetic optimization, FPGA synthesis, and a UVM verification environment with constrained-random program generation, scoreboarding, functional coverage, and regression tests.

---

## What Problem Does This Project Solve?

A pipelined processor with floating-point support must handle several interacting correctness challenges: integer/FP pipeline hazards, multi-cycle FPU stalls, cache and memory dependencies, branch misprediction recovery, and floating-point result correctness.

This project addresses these challenges in an integrated processor design and verifies them using coverage-driven UVM tests.

---

## My Contributions

- Designed and integrated the 5-stage RV32IF pipeline datapath/control around integer and floating-point execution.
- Implemented and debugged hazard detection and forwarding logic for load-use, chained-load, store-after-load, cache conflict, FPU stall, and branch recovery cases.
- Integrated and optimized the FPU, including Goldschmidt division and Newton-Raphson / reciprocal-square-root refinement.
- Built the UVM verification environment, including constrained-random program generation, scoreboard models, functional coverage, and regression tests.
- Synthesized the complete design on Artix-7 and collected utilization/timing results.
- Modified and optimized selected baseline FPU modules derived from open-source educational implementations.

> Some FPU modules were initially based on open-source educational implementations and were significantly modified, optimized, or integrated into this RV32IF processor project.

---

## Status

- RTL processor implemented: 5-stage RV32IF pipeline.
- FPU integrated: FADD/FSUB, FMUL, FDIV, and FSQRT.
- Cache and branch predictor implemented.
- UVM verification environment implemented.
- Functional coverage reached 95.2%.
- FPGA synthesis completed on Artix-7 at 50 MHz.
- Further formal verification of pipeline hazard properties is planned.

---

## RTL Design — FloatCore-RV32IF

A complete 5-stage RV32IF processor synthesized on Xilinx Artix-7, meeting timing at 50 MHz.

```text
Target: Xilinx Artix-7
Frequency: 50 MHz
LUTs: 18,219
Registers: 21,044
DSPs: 55
```

<img width="1422" height="412" alt="FloatCore-RV32IF architecture" src="https://github.com/user-attachments/assets/1c18e7c9-3c56-41fd-90e7-634b14ddcd05" />

### Pipeline Stages

```text
Fetch → Decode → Execute → Memory → Writeback
```

---

## Hazard Detection and Forwarding

The hazard unit handles seven distinct hazard categories:

- Load-use hazards, including standard and late-detected cases.
- Chained load hazards from consecutive dependent loads.
- Store-after-load dependencies.
- Dual load source dependencies.
- Cache write-read conflicts.
- FPU stall forwarding across integer instructions.
- Jump-register memory dependencies.

During verification, several hazard cases were identified, debugged, and fixed, including chained-load dependencies, store-after-load forwarding, jump-register memory dependencies, FPU stall interaction with integer forwarding, and branch misprediction flush interactions.

These cases are now covered by directed and constrained-random tests.

---

## Floating-Point Unit

The processor integrates an IEEE-754-style single-precision FPU.

### Supported Operations

- FADD.S / FSUB.S
- FMUL.S
- FDIV.S
- FSQRT.S

### FPU Architecture Highlights

- Addition/subtraction with alignment, normalization, and guard/round/sticky logic.
- Multiplication using a 48-bit mantissa product with normalization and rounding.
- Division using Goldschmidt iteration with a 256-entry reciprocal LUT for initial approximation.
- Square root using Newton-Raphson / reciprocal-square-root refinement with a 512-entry LUT.

> The FPU is IEEE-754-style, not a fully standards-complete IEEE-754 implementation. Exception flags are not currently propagated to architectural CSRs.

---

## Cache

The processor includes a 4-way set-associative cache.

### Features

- Write-back policy with dirty-bit tracking.
- Parameterizable cache depth and index width.
- Full cache miss handling.

### Cache FSM

```text
IDLE → COMP → HIT / FETCH / WB
```

---

## Branch Predictor

The branch predictor uses a 2-bit saturating counter and BTB.

### Features

- 512-entry Branch Target Buffer.
- 2-bit saturating prediction states:
  - Strongly Not Taken
  - Weakly Not Taken
  - Weakly Taken
  - Strongly Taken
- Misprediction detection and pipeline flush in Execute stage.

---

## UVM Verification Environment

A complete UVM testbench verifies the full RV32IF pipeline.

<img width="631" height="741" alt="Untitled Diagram drawio (1)" src="https://github.com/user-attachments/assets/5ab395b9-9278-4bdc-9c90-dbebaa0d3951" />

The UVM environment drives randomized instruction programs into the processor, monitors architectural state, compares against scoreboard models, and collects coverage across opcodes, hazards, cache states, branch outcomes, and FPU operations.

### Constrained-Random Program Generator

The constrained-random generator produces legal RV32IF instruction streams with configurable instruction-mix weights across:

- R-type instructions
- I-type instructions
- Load/store instructions
- Branch instructions
- FP arithmetic instructions
- FP memory instructions

Each generated test program includes:

- A prologue to seed integer registers and FP memory with known values.
- Randomized legal instruction streams.
- An epilogue that writes a sentinel value for test-completion detection.

---

## Scoreboard

The scoreboard maintains architectural shadow models of:

- Integer register file: 32 × 32-bit
- Floating-point register file: 32 × 32-bit
- Data memory: associative array model

---

## Functional Coverage

Functional coverage reached **95.2%** across seven covergroups.

| Covergroup | What It Covers |
|---|---|
| `cg_opcodes` | All 12 opcode categories, including FP load/store |
| `cg_alu_ctrl` | 10 ALU operations from ADD through SRA |
| `cg_hazards` | StallF, StallD, FPU stall, and illegal-bin crosses |
| `cg_branch` | Taken/not-taken × mispredicted/correct |
| `cg_cache` | All 7 cache FSM states |
| `cg_rd_dest` | Register destination distribution across x0–x31 |
| `cg_fpu` | All 7 FP operations individually |

---

## UVM Test Classes

| Test | Focus |
|---|---|
| `riscv_smoke_test` | Directed hex file and sentinel check |
| `riscv_random_test` | 10 iterations of fully random programs |
| `riscv_int_alu_test` | Integer-heavy instruction mix, IPC ≥ 0.50 |
| `riscv_load_store_test` | Memory-heavy instruction mix and cache stress |
| `riscv_branch_test` | Branch-heavy instruction mix and predictor stress |
| `riscv_fpu_test` | FP-heavy instruction mix, IPC ≥ 0.08 |
| `riscv_reset_stress_test` | Random mid-execution resets |
| `riscv_regression_test` | All phases sequentially |

---

## SystemVerilog Assertions

Implemented 30+ SVA properties covering:

- PC progression
- Cache timeout behavior
- Memory alignment
- FPU stall limits
- Pipeline liveness
- Reset correctness
  These assertions were used during simulation-based verification. Formal proof of pipeline hazard properties is planned as future work.

  ---
  
## Verification Status

- Functional coverage reached 95.2%.
- 8 UVM test classes cover directed, random, integer-heavy, memory-heavy, branch-heavy, FPU-heavy, reset-stress, and full regression scenarios.
- Scoreboard tracks architectural integer registers, FP registers, and data memory.
- Directed and constrained-random tests cover multiple pipeline hazard classes.
- Formal verification of pipeline hazard properties is planned as future work.

---

## Bugs Found During Verification

Several non-trivial pipeline and control issues were identified and fixed during verification:

- Chained load dependencies.
- Store-after-load forwarding cases.
- Jump-register memory dependency.
- FPU stall interaction with integer pipeline forwarding.
- Branch misprediction flush interactions.

These cases are now covered by directed and constrained-random tests.

---

## Key Results

| Metric | Result |
|---|---:|
| Target frequency | 50 MHz on Artix-7 |
| LUT utilization | 18,219 LUTs |
| Register utilization | 21,044 registers |
| DSP blocks | 55 |
| FPU division throughput | 3× improvement over restoring baseline |
| Functional coverage closure | 95.2% |
| Hazard categories handled | 7 |
| UVM test classes | 8 |
| Functional covergroups | 7 |

---

## Reports

- Vivado utilization report: `reports/Pipeline_top1_utilization_synth.rpt`
- Vivado timing report: `reports/timing_report.txt`
- Questa coverage report: `reports/coverage_merged_rpt.txt`

---

## How to Run

### Tools Required

- QuestaSim / ModelSim
- Xilinx Vivado

### Directed Simulation

```tcl
cd FloatingCore-RV32IF
vsim -do run.do
```

### UVM Regression

```tcl
cd UVM
vsim -do regress.do
```

### FPGA Synthesis

Open the `FloatingCore-RV32IF` project in Vivado, target Artix-7 `xc7a35t`, and run implementation.

Timing constraint:

```text
50 MHz
```

---

## Repository Structure

```text
RISC-V/
├── FloatingCore-RV32IF/       # RTL design: pipeline, FPU, cache, branch predictor
│   ├── Pipeline_Top.v         # Top-level integration
│   ├── Hazard_unit.v          # Hazard detection and forwarding
│   ├── FPU.v                  # Floating-point unit top
│   ├── adder.v                # IEEE-754-style adder
│   ├── divider.v              # Goldschmidt divider / FPU division unit
│   ├── multiplier.v           # IEEE-754-style multiplier
│   ├── sqrt.sv                # Newton-Raphson square-root unit
│   ├── Cache.v                # 4-way set-associative cache
│   ├── branch_predictor.sv    # 2-bit saturating counter BTB
│   └── ...
│
├── UVM/                       # Verification environment
│   ├── riscv_pkg.sv           # UVM package
│   ├── riscv_coverage.sv      # Functional covergroups
│   ├── riscv_scoreboard.sv    # Shadow register/memory model
│   ├── riscv_program_gen.sv   # Constrained-random program generator
│   ├── riscv_tests.sv         # UVM test classes
│   └── ...
│
├── reports/                   # Vivado and Questa reports
│   ├── Pipeline_top1_utilization_synth.rpt
│   ├── timing_report.txt
    └── coverage_merged_rpt.txt

```

---

## Known Limitations and Future Work

- **Sub-word loads:** `LB`, `LH`, `LBU`, and `LHU` sign/zero extension is implemented in the memory stage but not fully verified across all alignment combinations.
- **RV32M:** Integer multiply/divide extension is not implemented.
- **FP exception flags:** IEEE-754 exception flags such as overflow, underflow, invalid, divide-by-zero, and inexact are not currently propagated to architectural CSRs.
- **Branch predictor aliasing:** BTB uses PC bits `[10:2]` as index, so aliasing is possible with larger programs. A tagged predictor is future work.
- **Formal verification:** SVA properties exist for other verification projects. Applying formal methods to pipeline hazard properties is planned.

---

## Related Project

The optimized FPU used in this processor is documented separately:

[Floating-Point-Unit](https://github.com/mo1234-bit/FloatCore-FPU)

---

## Keywords

`RISC-V` `RV32IF` `Processor Design` `Computer Architecture` `SystemVerilog` `Verilog` `UVM` `Design Verification` `Functional Coverage` `Constrained Random Verification` `FPU` `FPGA` `Vivado` `QuestaSim` `Artix-7` `Digital IC Design`
