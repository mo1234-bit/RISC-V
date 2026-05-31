`include "uvm_macros.svh"
import riscv_pkg::*;
import uvm_pkg::*;
// =============================================================================
// riscv_program_gen.sv  –  Constrained-Random Program Generator
// Builds a complete randomized instruction stream, resolves branch targets,
// initializes base registers, and writes the program to instruction memory
// via backdoor ($readmemh or direct array write).
// =============================================================================
class riscv_program_gen extends uvm_object;
    `uvm_object_utils(riscv_program_gen)

    // -----------------------------------------------------------------------
    // Configuration knobs  (set before calling generate_program)
    // -----------------------------------------------------------------------
    int unsigned num_instrs     = 50;     // total instructions to generate
    int unsigned data_base_reg  = 8;      // x8 used as base for loads/stores
    int unsigned data_base_addr = 32'h10000000; // byte address of data region

    // Weights for instruction mix (out of 100)
    int unsigned w_r_type    = 25;
    int unsigned w_i_alu     = 20;
    int unsigned w_load      = 15;
    int unsigned w_store     = 10;
    int unsigned w_branch    = 10;
    int unsigned w_u_type    = 5;
    int unsigned w_fp_arith  = 10;
    int unsigned w_fp_mem    = 5;
    // remaining weight → NOP

    // -----------------------------------------------------------------------
    // Generated program
    // -----------------------------------------------------------------------
    logic [31:0] program_mem[];     // instruction words
    int unsigned actual_len;        // may differ from num_instrs after fixup
    int unsigned written_offsets[$]; // offsets written via stores (for safe load generation)

    // Disassembly log (for debug)
    string       asm_listing[$];

    // -----------------------------------------------------------------------
    function new(string name = "riscv_program_gen");
        super.new(name);
    endfunction

    // -----------------------------------------------------------------------
    // Main entry point
    // -----------------------------------------------------------------------
    function void generate_program();
        int unsigned total_w;
        program_mem = new[num_instrs + 20];  // +20: prologue=14 + epilogue=3 + margin=3

        asm_listing.delete();
        actual_len = 0;
        written_offsets.delete();
        written_offsets.push_back(0);   // prologue stores 1.0f at offset 0
        written_offsets.push_back(4);   // prologue stores 2.0f at offset 4

        // -- Prologue: initialise base registers so loads/stores are safe --
        emit_prologue();

        // -- Random body --
        for (int i = 0; i < num_instrs; i++) begin
            emit_random_instr();
        end

        // -- Epilogue: write sentinel so TB knows program finished --
        emit_epilogue();

        // -- Resize to actual length --
        program_mem = new[actual_len](program_mem);

        `uvm_info("PGEN",
            $sformatf("Generated program: %0d instructions", actual_len),
            UVM_MEDIUM)
    endfunction

    // -----------------------------------------------------------------------
    // Prologue: set up base pointer + a few known register values
    // -----------------------------------------------------------------------
    local function void emit_prologue();
        // LUI x8, data_base_addr[31:12]   → x8 = base address upper
        emit_word(lui_encode(data_base_reg, data_base_addr[31:12]),
                  $sformatf("LUI    x%0d, 0x%05h  # data base hi", data_base_reg, data_base_addr[31:12]));

        // ADDI x8, x8, data_base_addr[11:0]
        emit_word(i_encode(data_base_reg, data_base_reg,
                           3'b000, data_base_addr[11:0], 7'b0010011),
                  $sformatf("ADDI   x%0d, x%0d, %0d  # data base lo",
                             data_base_reg, data_base_reg, data_base_addr[11:0]));

        // ADDI x1, x0, 1  through  ADDI x7, x0, 7  (seed integer registers)
        for (int r = 1; r <= 7; r++) begin
            emit_word(i_encode(r, 0, 3'b000, r, 7'b0010011),
                      $sformatf("ADDI   x%0d, x0, %0d", r, r));
        end

        // Store a known float (1.0 = 0x3F800000) to data memory for FLW tests
        // LUI x9, 0x3F800       → x9 = 0x3F800000
        emit_word(lui_encode(9, 20'h3F800),    "LUI    x9, 0x3F800  # 1.0f");
        // SW  x9, 0(x8)
        emit_word(sw_encode(data_base_reg, 9, 12'd0),
                  $sformatf("SW     x9, 0(x%0d)", data_base_reg));

        // LUI x10, 0x40000      → x10 = 0x40000000  (2.0f)
        emit_word(lui_encode(10, 20'h40000),   "LUI    x10, 0x40000 # 2.0f");
        emit_word(sw_encode(data_base_reg, 10, 12'd4),
                  $sformatf("SW     x10, 4(x%0d)", data_base_reg));

        // FLW f0, 0(x8)  ;  FLW f1, 4(x8)
        emit_word(flw_encode(0, data_base_reg, 12'd0), "FLW    f0, 0(x8)");
        emit_word(flw_encode(1, data_base_reg, 12'd4), "FLW    f1, 4(x8)");
    endfunction

    // -- Epilogue: write completion sentinel to x30 --
    // Target: x30 = 0x0DEADBEF
    // 0xBEF bit[11]=1 → sign-extends to 0xFFFFFBEF in ADDI.
    // So LUI must load 0x0DEAE000 (0x0DEAE) to compensate:
    //   0x0DEAE000 + 0xFFFFFBEF = 0x0DEADBEF  ✓
    local function void emit_epilogue();
        // LUI x30, 0x0DEAE  (NOT 0x0DEAD — see comment above)
        emit_word(lui_encode(30, 20'h0DEAE),  "LUI    x30, 0x0DEAE  # sentinel hi (compensated)");
        // ADDI x30, x30, 0xBEF  (sign-extended)
        emit_word(i_encode(30, 30, 3'b000, 12'hBEF, 7'b0010011),
                  "ADDI   x30, x30, 0xBEF  # sentinel lo");
        // Infinite loop: JAL x0, 0
        emit_word(32'h0000006F,               "JAL    x0, 0  # infinite loop");
    endfunction

    // -----------------------------------------------------------------------
    // Emit one randomly chosen instruction
    // -----------------------------------------------------------------------
    local function void emit_random_instr();
        int pick;
        pick = $urandom_range(0, 99);

        if      (pick < w_r_type)                    emit_r_type();
        else if (pick < w_r_type + w_i_alu)          emit_i_alu();
        else if (pick < w_r_type + w_i_alu + w_load) emit_load();
        else if (pick < w_r_type + w_i_alu + w_load + w_store)  emit_store();
        else if (pick < w_r_type + w_i_alu + w_load + w_store + w_branch) emit_branch();
        else if (pick < w_r_type + w_i_alu + w_load + w_store + w_branch + w_u_type) emit_u_type();
        else if (pick < w_r_type + w_i_alu + w_load + w_store + w_branch + w_u_type + w_fp_arith) emit_fp_arith();
        else if (pick < w_r_type + w_i_alu + w_load + w_store + w_branch + w_u_type + w_fp_arith + w_fp_mem) emit_fp_mem();
        else    emit_nop();
    endfunction

    // -----------------------------------------------------------------------
    // Instruction emitters
    // -----------------------------------------------------------------------
    local function void emit_r_type();
        riscv_r_instr instr = riscv_r_instr::type_id::create("r");
        if (!instr.randomize() with {
            rd  inside {[1:7],[9:15]};   // exclude x8 (base ptr) and x30 (sentinel)
            rs1 inside {[1:15]};
            rs2 inside {[1:15]};
        }) `uvm_fatal("PGEN","R-type randomize failed")
        instr.encode();
        emit_word(instr.bits, instr.to_asm());
    endfunction

    local function void emit_i_alu();
        riscv_i_alu_instr instr = riscv_i_alu_instr::type_id::create("i");
        if (!instr.randomize() with {
            rd  inside {[1:7],[9:15]};   // exclude x8 (base ptr) and x30 (sentinel)
            rs1 inside {[1:15]};
        }) `uvm_fatal("PGEN","I-ALU randomize failed")
        instr.encode();
        emit_word(instr.bits, instr.to_asm());
    endfunction

    local function void emit_load();
        riscv_load_instr instr = riscv_load_instr::type_id::create("ld");
        // Pick a safe offset from the set already written by stores or prologue
        begin
            int unsigned safe_off;
            int unsigned n = written_offsets.size();
            safe_off = written_offsets[$urandom_range(0, n-1)];
            if (!instr.randomize() with {
                rd    inside {[1:7]};
                rs1   == data_base_reg;
                func  == riscv_load_instr::LW;  // LW only — always word aligned
                imm12 == 12'(safe_off);
            }) `uvm_fatal("PGEN","Load randomize failed")
        end
        instr.encode();
        emit_word(instr.bits, instr.to_asm());
    endfunction

    local function void emit_store();
        riscv_store_instr instr = riscv_store_instr::type_id::create("st");
        if (!instr.randomize() with {
            rs1  == data_base_reg;
            rs2  inside {[1:7]};
            // Word-aligned offsets only to avoid alignment issues
            imm12 inside {[0:15]};
            imm12[1:0] == 2'b00;
        }) `uvm_fatal("PGEN","Store randomize failed")
        instr.encode();
        emit_word(instr.bits, instr.to_asm());
        // Record this offset so loads can safely reference it
        if (written_offsets.find_index(i) with (i == int'(instr.imm12)) == '{})
            written_offsets.push_back(int'(instr.imm12));
    endfunction

    local function void emit_branch();
        riscv_branch_instr instr = riscv_branch_instr::type_id::create("br");
        if (!instr.randomize() with {
            rs1 inside {[1:7]};
            rs2 inside {[1:7]};
            // Only forward short branches so we don't jump out of program
            offset inside {4};
            offset[0] == 0;
        }) `uvm_fatal("PGEN","Branch randomize failed")
        instr.encode();
        emit_word(instr.bits, instr.to_asm());
    endfunction

    local function void emit_u_type();
        riscv_u_instr instr = riscv_u_instr::type_id::create("u");
        if (!instr.randomize() with {
            rd inside {[1:7],[9:15]};    // exclude x8 (base ptr) and x30 (sentinel)
        }) `uvm_fatal("PGEN","U-type randomize failed")
        instr.encode();
        emit_word(instr.bits, instr.to_asm());
    endfunction

    local function void emit_fp_arith();
        riscv_fp_instr instr = riscv_fp_instr::type_id::create("fp");
        if (!instr.randomize() with {
            rd  inside {[2:7]};
            rs1 inside {[0:1]};   // f0=1.0 f1=2.0 loaded in prologue
            rs2 inside {[0:1]};
            // Avoid FDIV/FSQRT most of the time (very slow)
            func dist { riscv_fp_instr::FADD := 35,
                        riscv_fp_instr::FSUB := 35,
                        riscv_fp_instr::FMUL := 20,
                        riscv_fp_instr::FDIV  := 5,
                        riscv_fp_instr::FSQRT := 5 };
        }) `uvm_fatal("PGEN","FP randomize failed")
        instr.encode();
        emit_word(instr.bits, instr.to_asm());
    endfunction

    local function void emit_fp_mem();
        riscv_fp_mem_instr instr = riscv_fp_mem_instr::type_id::create("fpm");
        if (!instr.randomize() with {
            rs1 == data_base_reg;
            rs2 inside {[0:3]};
            rd  inside {[0:3]};
            imm12 inside {[0:12]};
            imm12[1:0] == 2'b00;
        }) `uvm_fatal("PGEN","FP-mem randomize failed")
        instr.encode();
        emit_word(instr.bits, instr.to_asm());
    endfunction

    local function void emit_nop();
        emit_word(32'h00000013, "NOP");
    endfunction

    // -----------------------------------------------------------------------
    // Low-level helpers
    // -----------------------------------------------------------------------
    local function void emit_word(logic [31:0] w, string comment = "");
        program_mem[actual_len] = w;
        asm_listing.push_back($sformatf("[%04d] %08h  %s", actual_len, w, comment));
        actual_len++;
    endfunction

    // ---- Encoding helpers ----
    local function logic [31:0] lui_encode(int rd, logic [19:0] imm20);
        return {imm20, 5'(rd), 7'b0110111};
    endfunction

    local function logic [31:0] i_encode(int rd, int rs1, logic [2:0] f3,
                                          logic [11:0] imm, logic [6:0] op);
        return {imm, 5'(rs1), f3, 5'(rd), op};
    endfunction

    local function logic [31:0] sw_encode(int rs1, int rs2, logic [11:0] imm);
        return {imm[11:5], 5'(rs2), 5'(rs1), 3'b010, imm[4:0], 7'b0100011};
    endfunction

    local function logic [31:0] flw_encode(int rd_fp, int rs1, logic [11:0] imm);
        return {imm, 5'(rs1), 3'b010, 5'(rd_fp), 7'b0000111};
    endfunction

    // -----------------------------------------------------------------------
    // Write generated program into DUT instruction memory (backdoor)
    // -----------------------------------------------------------------------
    task backdoor_load(ref logic [31:0] imem[]);
        for (int i = 0; i < actual_len && i < imem.size(); i++)
            imem[i] = program_mem[i];
        // Zero out remaining entries
        for (int i = actual_len; i < imem.size(); i++)
            imem[i] = 32'h00000013;   // NOP
        `uvm_info("PGEN",
            $sformatf("Loaded %0d instructions into IMEM", actual_len), UVM_LOW)
    endtask

    // -----------------------------------------------------------------------
    // Write generated program to a .hex file (for $readmemh)
    // -----------------------------------------------------------------------
    function void write_hex(string filename);
        int fd;
        fd = $fopen(filename, "w");
        if (!fd) begin
            `uvm_error("PGEN", $sformatf("Cannot open %s", filename))
            return;
        end
        for (int i = 0; i < actual_len; i++)
            $fwrite(fd, "%08h\n", program_mem[i]);
        $fclose(fd);
        `uvm_info("PGEN", $sformatf("Wrote hex to %s", filename), UVM_LOW)
    endfunction

    // -----------------------------------------------------------------------
    // Print disassembly listing
    // -----------------------------------------------------------------------
    function void print_listing();
        `uvm_info("PGEN", "\n=== Generated Program Listing ===", UVM_LOW)
        foreach (asm_listing[i])
            `uvm_info("PGEN", asm_listing[i], UVM_LOW)
        `uvm_info("PGEN", "=================================", UVM_LOW)
    endfunction

endclass : riscv_program_gen