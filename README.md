# RISC-V Pipelined Processor with Floating-Point Unit

## Overview
A fully functional 5-stage pipelined RISC-V processor implementing the RV32I base integer instruction set with the F (single-precision floating-point) extension. Features include IEEE 754 compliant floating-point operations, a 4-way set-associative cache, comprehensive hazard detection, and data forwarding mechanisms.
<img width="1422" height="412" alt="2-Figure1-1" src="https://github.com/user-attachments/assets/1c18e7c9-3c56-41fd-90e7-634b14ddcd05" />



✨Features
## Core Features

✅ 5-Stage Pipeline: Fetch → Decode → Execute → Memory → Writeback

✅ RISC-V RV32I Base ISA: Complete integer instruction support

✅ RV32F Extension: Single-precision floating-point operations

✅ IEEE 754 Compliant FPU: Add, subtract, multiply, divide, square root

✅ 4-Way Set-Associative Cache: Write-back policy with dirty bit tracking

✅ Hazard Detection Unit: Comprehensive data hazard detection

✅ Data Forwarding: Both integer and floating-point register forwarding
✅ Branch Handling: Jump and branch target calculation
✅ Multi-Cycle Operation Support: Synchronized stall mechanism for FPU

### pic from simulation
<img width="954" height="324" alt="Capture" src="https://github.com/user-attachments/assets/13f9f2ce-61b2-4f82-9b86-60e72d25504b" />

## Technical Highlights

Synthesizable Design: Verified on Xilinx Vivado
Modular Architecture: Clean separation of concerns
Parameterizable Cache: Configurable cache size and associativity
Separate Register Files: Independent integer (32×32-bit) and FP (32×32-bit) register files

📋 Instruction Set Support
RV32I - Base Integer Instructions

✅ Arithmetic: ADD, SUB, ADDI
✅ Logical: AND, OR, XOR, ANDI, ORI, XORI
✅ Shifts: SLL, SRL, SRA, SLLI, SRLI, SRAI
✅ Comparisons: SLT, SLTU, SLTI, SLTIU
✅ Branches: BEQ, BNE, BLT, BGE, BLTU, BGEU
✅ Jumps: JAL, JALR
✅ Loads: LW
✅ Stores: SW
✅ Upper Immediates: LUI, AUIPC

RV32F - Single-Precision Floating-Point

✅ Arithmetic: FADD.S, FSUB.S, FMUL.S, FDIV.S
✅ Square Root: FSQRT.S
✅ Load/Store: FLW, FSW

🧪 Testing & Verification
Test Coverage

✅ Basic arithmetic operations (integer and FP)
✅ Back-to-back FP operations (dependency testing)
✅ Load-use hazards (stall verification)
✅ Branch/jump operations (control flow)
✅ Cache hit/miss scenarios
✅ Data forwarding paths (both integer and FP)
✅ Multi-cycle FPU operations (stall synchronization)

## Verification Methodology

 Unit Testing: Each module tested independently
Integration Testing: Pipeline stages tested together
System Testing: Complete programs executed
Corner Cases: Edge conditions verified (zero operations, denormals, etc.)
