# RISC-V Pipelined Processor with Floating-Point Unit

## Overview
A fully functional 5-stage pipelined RISC-V processor implementing the RV32I base integer instruction set with the F (single-precision floating-point) extension. Features include IEEE 754 compliant floating-point operations, a 4-way set-associative cache, comprehensive hazard detection, and data forwarding mechanisms.

<img width="1422" height="412" alt="2-Figure1-1" src="https://github.com/user-attachments/assets/1c18e7c9-3c56-41fd-90e7-634b14ddcd05" />


## Features 

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


## Instruction Set Support

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
# 🧩 RISC-V Test Programs

This repository contains a set of **RISC-V assembly test programs** covering integer, branch, jump, memory, and floating-point operations.  
Each section below can be expanded to view the corresponding assembly code.

---
# 🧩 RISC-V Test Programs

This repository contains a set of **RISC-V assembly test programs** covering integer, branch, jump, memory, and floating-point operations.  
Each section below can be expanded to view the corresponding assembly code.

---

<details>
<summary><b>🧮 TEST PROGRAM 1: Integer Operations</b></summary>

```assembly
00500293    addi    x5, x0, 5            # x5 = 0 + 5 = 5
00300313    addi    x6, x0, 3            # x6 = 0 + 3 = 3
006283B3    add     x7, x5, x6           # x7 = x5 + x6 = 8
40628433    sub     x8, x5, x6           # x8 = x5 - x6 = 2
0062F4B3    and     x9, x5, x6           # x9 = x5 & x6 = 0x1 (binary: 101 & 011 = 001)
0062E533    or      x10, x5, x6          # x10 = x5 | x6 = 0x7 (binary: 101 | 011 = 111)
0062A5B3    slt     x11, x5, x6          # x11 = (x5 < x6) ? 1 : 0 = 0 (5 not < 3)
</details>
<details> <summary><b>🔁 TEST PROGRAM 2: Branch Instructions</b></summary>
assembly
Copy code
0032C463    blt     x5, x6, skip      # if (x5 < x6) PC = PC + 8, else continue
06400613    addi    x12, x0, 100      # x12 = 100 (executed if branch not taken)
00000013    nop                       # No operation
00100693    addi    x13, x0, 1        # x13 = 1

# skip:
00500713    addi    x14, x0, 5        # x14 = 5
00e68663    beq     x13, x14, end     # if (x13 == x14) jump to end
</details>
<details> <summary><b>🚀 TEST PROGRAM 3: Jump Instructions</b></summary>
assembly
Copy code
0C800793    addi    x15, x0, 200      # x15 = 200
00000013    nop                       # No operation
020000EF    jal     x1, func          # Jump to func, save return address in x1
0FA00893    addi    x17, x0, 250      # x17 = 250 (should be skipped)
0080006F    j       continue          # Unconditional jump

# func:
19000913    addi    x18, x0, 400      # x18 = 400
00008067    jalr    x0, x1, 0         # Return (jump to address in x1)

# continue and padding
00000013    nop
00000013    nop
00000013    nop
00000013    nop
</details>
<details> <summary><b>💾 TEST PROGRAM 4: Memory Operations</b></summary>
assembly
Copy code
00500293    addi    x5, x0, 5         # x5 = 5
00300313    addi    x6, x0, 3         # x6 = 3
40A00397    lui     x7, 0x40A00       # x7 = 0x40A00000 (upper immediate)
00000413    addi    x8, x0, 0         # x8 = 0 (base address)
00742023    sw      x7, 0(x8)         # Memory[0] = x7
40400397    lui     x7, 0x40400       # x7 = 0x40400000
00742223    sw      x7, 4(x8)         # Memory[4] = x7
40000397    lui     x7, 0x40000       # x7 = 0x40000000
00742423    sw      x7, 8(x8)         # Memory[8] = x7

00000013    nop
00000013    nop
</details>
<details> <summary><b>🧠 TEST PROGRAM 5: Floating-Point Operations</b></summary>
assembly
Copy code
00402107    flw     f2, 4(x0)         # f2 = Memory[4] (load FP value)
00802187    flw     f3, 8(x0)         # f3 = Memory[8] (load FP value)
00310253    fadd.s  f4, f2, f3        # f4 = f2 + f3 (FP addition)
00208453    fsub.s  f8, f2, f3        # f8 = f2 - f3 (FP subtraction)
082082D3    fmul.s  f5, f2, f3        # f5 = f2 * f3 (FP multiplication)
10310353    fdiv.s  f6, f2, f3        # f6 = f2 / f3 (FP division)
183303D3    fsqrt.s f7, f6            # f7 = sqrt(f6) (FP square root)
</details>

