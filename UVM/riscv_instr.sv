// =============================================================================
// riscv_instr.sv  –  Randomized RISC-V Instruction Classes
// Each instruction type is a separate class with legal constraints.
// =============================================================================

`include "uvm_macros.svh"

import uvm_pkg::*;import riscv_pkg::*;
// =============================================================================
// riscv_instr.sv  –  Randomized RISC-V Instruction Classes
// Each instruction type is a separate class with legal constraints.
// =============================================================================

// ---------------------------------------------------------------------------
// Encoding types
// ---------------------------------------------------------------------------
typedef enum logic [6:0] {
    OP_R      = 7'b0110011,   // ADD SUB AND OR XOR SLL SRL SRA SLT SLTU
    OP_I_ALU  = 7'b0010011,   // ADDI ANDI ORI XORI SLTI SLTIU SLLI SRLI SRAI
    OP_LOAD   = 7'b0000011,   // LB LH LW LBU LHU
    OP_STORE  = 7'b0100011,   // SB SH SW
    OP_BRANCH = 7'b1100011,   // BEQ BNE BLT BGE BLTU BGEU
    OP_JAL    = 7'b1101111,
    OP_JALR   = 7'b1100111,
    OP_LUI    = 7'b0110111,
    OP_AUIPC  = 7'b0010111,
    OP_FP     = 7'b1010011,   // FADD FSUB FMUL FDIV FSQRT
    OP_FLOAD  = 7'b0000111,   // FLW
    OP_FSTORE = 7'b0100111    // FSW
} opcode_e;

// ---------------------------------------------------------------------------
// Base instruction item
// ---------------------------------------------------------------------------
class riscv_instr extends uvm_object;
    `uvm_object_utils(riscv_instr)

    rand logic [31:0] bits;          // Final encoded instruction word
    rand opcode_e     opcode;

    // Commonly used fields (set by child class encode())
    rand logic [4:0]  rs1, rs2, rd;
    rand logic [2:0]  funct3;
    rand logic [6:0]  funct7;
    rand logic [11:0] imm12;
    rand logic [19:0] imm20;

    // Prevent writes to x0
    constraint c_no_x0_rd { rd != 5'h0; }

    function new(string name = "riscv_instr");
        super.new(name);
    endfunction

    // Override in child to pack fields into bits[]
    virtual function void encode();
        bits = 32'h00000013; // NOP by default
    endfunction

    virtual function string to_asm();
        return $sformatf("instr=0x%08h", bits);
    endfunction

endclass

// ---------------------------------------------------------------------------
// R-type:  ADD SUB AND OR XOR SLL SRL SRA SLT SLTU
// ---------------------------------------------------------------------------
class riscv_r_instr extends riscv_instr;
    `uvm_object_utils(riscv_r_instr)

    typedef enum logic [9:0] {   // {funct7[5], funct3}
        ADD  = 10'b0_000,
        SUB  = 10'b1_000,
        SLL  = 10'b0_001,
        SLT  = 10'b0_010,
        SLTU = 10'b0_011,
        XOR  = 10'b0_100,
        SRL  = 10'b0_101,
        SRA  = 10'b1_101,
        OR   = 10'b0_110,
        AND  = 10'b0_111
    } r_func_e;

    rand r_func_e func;

    constraint c_opcode { opcode == OP_R; }

    function new(string name = "riscv_r_instr");
        super.new(name);
    endfunction

    function void encode();
        logic f7_5;
        logic [2:0] f3;
        {f7_5, f3} = func;
        funct7 = {1'b0, f7_5, 5'b0};  // bit5 is the discriminating bit (SUB/SRA=0x20, others=0x00)
        funct3 = f3;
        bits   = {funct7, rs2, rs1, funct3, rd, opcode};
    endfunction

    function string to_asm();
        return $sformatf("%-6s x%0d, x%0d, x%0d",
                         func.name(), rd, rs1, rs2);
    endfunction

endclass

// ---------------------------------------------------------------------------
// I-type ALU:  ADDI ANDI ORI XORI SLTI SLTIU SLLI SRLI SRAI
// ---------------------------------------------------------------------------
class riscv_i_alu_instr extends riscv_instr;
    `uvm_object_utils(riscv_i_alu_instr)

    typedef enum logic [3:0] {
        ADDI  = 4'd0,
        SLTI  = 4'd1,
        SLTIU = 4'd2,
        XORI  = 4'd3,
        ORI   = 4'd4,
        ANDI  = 4'd5,
        SLLI  = 4'd6,
        SRLI  = 4'd7,
        SRAI  = 4'd8
    } i_func_e;

    rand i_func_e func;
    rand logic [4:0] shamt;   // shift amount for shift instructions

    constraint c_opcode { opcode == OP_I_ALU; }
    constraint c_shamt  { shamt < 32; }

    // Keep immediates in a small sensible range to avoid extreme values
    constraint c_imm    { imm12 inside {[0:255]}; }

    function new(string name = "riscv_i_alu_instr");
        super.new(name);
    endfunction

    function void encode();
        case (func)
            ADDI:  begin funct3 = 3'b000; bits = {imm12, rs1, funct3, rd, opcode}; end
            SLTI:  begin funct3 = 3'b010; bits = {imm12, rs1, funct3, rd, opcode}; end
            SLTIU: begin funct3 = 3'b011; bits = {imm12, rs1, funct3, rd, opcode}; end
            XORI:  begin funct3 = 3'b100; bits = {imm12, rs1, funct3, rd, opcode}; end
            ORI:   begin funct3 = 3'b110; bits = {imm12, rs1, funct3, rd, opcode}; end
            ANDI:  begin funct3 = 3'b111; bits = {imm12, rs1, funct3, rd, opcode}; end
            SLLI:  begin funct3 = 3'b001; bits = {7'b0000000, shamt, rs1, funct3, rd, opcode}; end
            SRLI:  begin funct3 = 3'b101; bits = {7'b0000000, shamt, rs1, funct3, rd, opcode}; end
            SRAI:  begin funct3 = 3'b101; bits = {7'b0100000, shamt, rs1, funct3, rd, opcode}; end
        endcase
    endfunction

    function string to_asm();
        if (func inside {SLLI, SRLI, SRAI})
            return $sformatf("%-6s x%0d, x%0d, %0d", func.name(), rd, rs1, shamt);
        return $sformatf("%-6s x%0d, x%0d, %0d", func.name(), rd, rs1, $signed(imm12));
    endfunction

endclass

// ---------------------------------------------------------------------------
// Load:  LB LH LW LBU LHU
// Uses a base register + small offset into a safe memory region
// ---------------------------------------------------------------------------
class riscv_load_instr extends riscv_instr;
    `uvm_object_utils(riscv_load_instr)

    typedef enum logic [2:0] {
        LW  = 3'b010
    } load_func_e;

    rand load_func_e func;

    constraint c_opcode { opcode == OP_LOAD; }
    // Offset within first 256 bytes of data memory (word-aligned for LW)
    constraint c_imm_lw { (func == LW)  -> (imm12[1:0] == 2'b00 && imm12 < 12'd256); }
    constraint c_imm    { imm12 < 12'd256; }

    function new(string name = "riscv_load_instr");
        super.new(name);
    endfunction

    function void encode();
        funct3 = func;
        bits   = {imm12, rs1, funct3, rd, opcode};
    endfunction

    function string to_asm();
        return $sformatf("%-6s x%0d, %0d(x%0d)", func.name(), rd, $signed(imm12), rs1);
    endfunction

endclass

// ---------------------------------------------------------------------------
// Store:  SB SH SW
// ---------------------------------------------------------------------------
class riscv_store_instr extends riscv_instr;
    `uvm_object_utils(riscv_store_instr)

    typedef enum logic [2:0] {
        SW = 3'b010
    } store_func_e;

    rand store_func_e func;

    constraint c_opcode  { opcode == OP_STORE; }
    constraint c_imm_sw  { (func == SW) -> (imm12[1:0] == 2'b00 && imm12 < 12'd256); }
    constraint c_imm     { imm12 < 12'd256; }

    // rd not used by store – override parent constraint
    constraint c_no_x0_rd { 1; }

    function new(string name = "riscv_store_instr");
        super.new(name);
    endfunction

    function void encode();
        funct3 = func;
        bits   = {imm12[11:5], rs2, rs1, funct3, imm12[4:0], opcode};
    endfunction

    function string to_asm();
        return $sformatf("%-6s x%0d, %0d(x%0d)", func.name(), rs2, $signed(imm12), rs1);
    endfunction

endclass

// ---------------------------------------------------------------------------
// Branch:  BEQ BNE BLT BGE BLTU BGEU
// Offset is constrained to ±64 bytes (forward + backward, word-aligned)
// ---------------------------------------------------------------------------
class riscv_branch_instr extends riscv_instr;
    `uvm_object_utils(riscv_branch_instr)

    typedef enum logic [2:0] {
        BEQ  = 3'b000,
        BNE  = 3'b001,
        BLT  = 3'b100,
        BGE  = 3'b101,
        BLTU = 3'b110,
        BGEU = 3'b111
    } branch_func_e;

    rand branch_func_e func;
    rand logic signed [12:0] offset;  // signed, bits[12:1] go into B-imm, bit0=0

    constraint c_opcode  { opcode == OP_BRANCH; }
    constraint c_offset  { offset inside {[-64:64]}; offset[0] == 0; }
    // No writes: override parent
    constraint c_no_x0_rd { 1; }

    function new(string name = "riscv_branch_instr");
        super.new(name);
    endfunction

    function void encode();
        logic [12:0] o;
        funct3 = func;
        o      = offset;
        // B-type encoding: imm[12|10:5] | rs2 | rs1 | funct3 | imm[4:1|11] | opcode
        bits   = {o[12], o[10:5], rs2, rs1, funct3, o[4:1], o[11], opcode};
    endfunction

    function string to_asm();
        return $sformatf("%-6s x%0d, x%0d, %0d", func.name(), rs1, rs2, $signed(offset));
    endfunction

endclass

// ---------------------------------------------------------------------------
// LUI / AUIPC
// ---------------------------------------------------------------------------
class riscv_u_instr extends riscv_instr;
    `uvm_object_utils(riscv_u_instr)

    rand bit is_auipc;

    constraint c_imm20 { imm20 != 0; }

    function new(string name = "riscv_u_instr");
        super.new(name);
    endfunction

    function void encode();
        opcode = is_auipc ? OP_AUIPC : OP_LUI;
        bits   = {imm20, rd, opcode};
    endfunction

    function string to_asm();
        return $sformatf("%-6s x%0d, 0x%05h",
                         is_auipc ? "AUIPC" : "LUI", rd, imm20);
    endfunction

endclass

// ---------------------------------------------------------------------------
// FP arithmetic:  FADD FSUB FMUL FDIV FSQRT
// ---------------------------------------------------------------------------
class riscv_fp_instr extends riscv_instr;
    `uvm_object_utils(riscv_fp_instr)

    typedef enum logic [6:0] {
        FADD  = 7'b0000000,
        FSUB  = 7'b0000100,
        FMUL  = 7'b0001000,
        FDIV  = 7'b0001100,
        FSQRT = 7'b0101100
    } fp_func_e;

    rand fp_func_e func;

    constraint c_opcode  { opcode == OP_FP; }
    // FSQRT only uses rs1
    constraint c_fsqrt_rs2 { (func == FSQRT) -> (rs2 == 5'd0); }

    function new(string name = "riscv_fp_instr");
        super.new(name);
    endfunction

    function void encode();
        funct7 = func;
        funct3 = 3'b000;   // RNE rounding
        bits   = {funct7, rs2, rs1, funct3, rd, opcode};
    endfunction

    function string to_asm();
        if (func == FSQRT)
            return $sformatf("FSQRT.S f%0d, f%0d", rd, rs1);
        return $sformatf("%-8s f%0d, f%0d, f%0d", func.name(), rd, rs1, rs2);
    endfunction

endclass

// ---------------------------------------------------------------------------
// FP Load / Store  (FLW / FSW)
// ---------------------------------------------------------------------------
class riscv_fp_mem_instr extends riscv_instr;
    `uvm_object_utils(riscv_fp_mem_instr)

    rand bit is_store;

    constraint c_opcode  { opcode == (is_store ? OP_FSTORE : OP_FLOAD); }
    constraint c_imm_align { imm12[1:0] == 2'b00; imm12 < 12'd256; }
    constraint c_no_x0_rd { 1; }   // FP dest register, not integer

    function new(string name = "riscv_fp_mem_instr");
        super.new(name);
    endfunction

    function void encode();
        funct3 = 3'b010;  // .S (single precision)
        if (is_store)
            bits = {imm12[11:5], rs2, rs1, funct3, imm12[4:0], opcode};
        else
            bits = {imm12, rs1, funct3, rd, opcode};
    endfunction

    function string to_asm();
        if (is_store)
            return $sformatf("FSW    f%0d, %0d(x%0d)", rs2, $signed(imm12), rs1);
        return $sformatf("FLW    f%0d, %0d(x%0d)", rd, $signed(imm12), rs1);
    endfunction

endclass