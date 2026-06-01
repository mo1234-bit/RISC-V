# FloatCore-RV32IF — Pipelined RISC-V Processor with FPU and UVM Verification

## What problem does this project solve?

Implementing a pipelined processor with floating-point support requires solving 
three hard problems simultaneously: pipeline hazard correctness across integer 
and FP instruction streams, IEEE 754 compliant arithmetic at acceptable 
throughput, and verifying that all hazard combinations are actually exercised. 

Many educational processor projects focus on only one of these dimensions. 
This project attempts to address all three in a single integrated design: 
microarchitecture, floating-point execution, and coverage-driven verification.


## What was implemented?

### RTL Design — FloatingCore-RV32IF

A complete 5-stage RV32IF processor synthesized on Xilinx Artix-7, meeting 
timing at 50 MHz (17K LUTs, 20K registers, 55 DSPs).

<img width="1422" height="412" alt="2-Figure1-1" src="https://github.com/user-attachments/assets/1c18e7c9-3c56-41fd-90e7-634b14ddcd05" />

**Pipeline stages:** Fetch → Decode → Execute → Memory → Writeback

**Hazard detection unit** handles seven distinct hazard categories:
- Load-use hazards (standard and late-detected)
- Chained load hazards (consecutive dependent loads)
- Store-after-load dependencies
- Dual load source dependencies
- Cache write-read conflicts
- FPU stall forwarding across integer instructions
- Jump-register memory dependencies

**Floating-Point Unit** — IEEE-754-style single-precision:
- Addition/subtraction: iterative alignment with guard/round/sticky bits
- Multiplication: 48-bit product with normalization and rounding
- Division: Goldschmidt algorithm with 256-entry reciprocal LUT for 
  initial approximation — achieves 3× throughput vs. restoring division
- Square root: Newton-Raphson refinement with 512-entry rsqrt LUT

**4-way set-associative cache:**
- Write-back policy with dirty bit tracking
- Parameterizable cache depth and index width.
- State machine: IDLE → COMP → HIT/FETCH/WB with full miss handling

**2-bit branch predictor:**
- Branch Target Buffer (BTB) with 512 entries
- Saturating counter (Strongly NT / Weakly NT / Weakly T / Strongly T)
- Misprediction detection and pipeline flush in Execute stage

---
## My contributions

- Designed and integrated the 5-stage RV32IF pipeline datapath/control around integer and floating-point execution.
- Implemented and debugged the hazard detection/forwarding logic for load-use, chained-load, store-after-load, cache, FPU stall, and branch recovery cases.
- Optimized the FPU divider using Goldschmidt division and improved square-root execution using Newton-Raphson / reciprocal-square-root refinement.
- Built the UVM verification environment, including constrained-random program generation, scoreboard models, functional coverage, and regression tests.
- Synthesized the complete design on Artix-7 and collected utilization/timing results.
- Some FPU modules were initially based on open-source educational implementations and were modified/optimized
  
### UVM Verification Environment

A complete UVM testbench verifying the full RV32IF pipeline.

**Constrained-random program generator** produces legal RV32IF instruction 
streams with configurable instruction mix weights across R-type, I-type, 
load/store, branch, FP arithmetic, and FP memory instructions. Prologue 
seeds registers and FP memory with known values; epilogue writes a sentinel 
for test completion detection.

**Scoreboard** maintains shadow models of:
- Integer register file (32 × 32-bit)
- Floating-point register file (32 × 32-bit)  
- Data memory (associative array)

**7 functional covergroups:**

| Covergroup | What it covers |
|---|---|
| cg_opcodes | All 12 opcode categories including FP load/store |
| cg_alu_ctrl | All 10 ALU operations (ADD through SRA) |
| cg_hazards | StallF, StallD, FPU stall with illegal-bin cross |
| cg_branch | Taken/not-taken × mispredicted/correct |
| cg_cache | All 7 cache FSM states |
| cg_rd_dest | Register destination distribution across x0–x31 |
| cg_fpu | All 7 FP operations individually |

**8 named test classes:**

| Test | Focus |
|---|---|
| riscv_smoke_test | Directed hex file, sentinel check |
| riscv_random_test | 10 iterations of fully random programs |
| riscv_int_alu_test | Integer-heavy mix, IPC ≥ 0.50 |
| riscv_load_store_test | Memory-heavy mix, cache stress |
| riscv_branch_test | Branch-heavy mix, predictor stress |
| riscv_fpu_test | FP-heavy mix, IPC ≥ 0.08 |
| riscv_reset_stress_test | Random mid-execution resets |
| riscv_regression_test | All phases sequentially |

---
## Verification status

- Functional coverage reached 95.2%.
- 8 UVM test classes cover directed, random, integer-heavy, memory-heavy, branch-heavy, FPU-heavy, reset-stress, and full regression scenarios.
- Scoreboard tracks architectural integer registers, FP registers, and data memory.

## Bugs found
  During verification, several hazard cases were identified and fixed, including:
- chained load dependencies,
- store-after-load forwarding cases,
- jump-register memory dependency,
- FPU stall interaction with integer pipeline forwarding,
- branch misprediction flush interactions.

These cases are now covered by directed and constrained-random tests.

## What are the key results?

| Metric | Result |
|---|---|
| Target frequency | 50 MHz on Artix-7 |
| LUT utilization |18,219 LUTs |
| Register utilization | 21,044 registers |
| DSP blocks | 55 |
| FPU division throughput | 3× improvement over baseline (Goldschmidt vs restoring) |
| Functional coverage closure | 95.2% |
| Hazard categories handled | 7 distinct types |
| UVM test classes | 8 |
| Covergroups | 7 |

---

## How to run

**Tools required:** QuestaSim (Siemens EDA), Xilinx Vivado (for synthesis)

**Simulation — directed test:**
```tcl
cd FloatingCore-RV32IF
vsim -do run.do
```

**Simulation — UVM regression:**
```tcl
cd UVM
vsim -do regress.do
```

**Synthesis:**  
Open `FloatingCore-RV32IF` in Vivado, target Artix-7 (xc7a35t), run 
implementation. Timing constraints target 50 MHz.

---

## Reports:
- Vivado utilization report: `reports/Pipeline_top1_utilization_synth.rpt`
- Vivado timing report: `reports/timing_report.txt`
- Questa coverage report: `reports/coverage_merged_rpt.txt`


## Repository structure
```
RISC-V/
├── FloatingCore-RV32IF/    # RTL design: pipeline, FPU, cache, branch predictor
│   ├── Pipeline_Top.v      # Top-level integration
│   ├── Hazard_unit.v       # Hazard detection and forwarding
│   ├── FPU.v               # Floating-point unit top
│   ├── adder.v             # IEEE 754 adder (guard/round/sticky)
│   ├── divider.v           # Goldschmidt division with reciprocal LUT
│   ├── multiplier.v        # IEEE 754 multiplier
│   ├── sqrt.sv             # Newton-Raphson square root
│   ├── Cache.v             # 4-way set-associative cache
│   ├── branch_predictor.sv # 2-bit saturating counter BTB
│   └── ...
├── UVM/                    # Verification environment
│   ├── riscv_pkg.sv        # UVM package: all components
│   ├── riscv_coverage.sv   # 7 covergroups
│   ├── riscv_scoreboard.sv # Shadow register/memory model
│   ├── riscv_progrem_gen.sv# Constrained-random program generator
│   ├── riscv_tests.sv      # 8 test classes
    └── ...
                  
```
---

## Known limitations and future work

- **LB/LH/LBU/LHU:** Sub-word load sign-extension is implemented in the 
  memory stage but not fully verified across all alignment combinations.
- **RV32M:** Integer multiply/divide extension not implemented.
- **FP exceptions:** IEEE 754 exception flags (overflow, underflow, inexact) 
  are not propagated to a CSR.
- **Branch predictor:** BTB uses PC bits [10:2] as index — aliasing possible 
  with large programs. A more robust tagged predictor is future work.
- **Formal verification:** SVA properties exist for the SPI project. 
  Applying formal methods to pipeline hazard properties is planned.
