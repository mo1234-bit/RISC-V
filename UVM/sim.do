vlib work
vlog -f src_files.list \
     +cover -covercells \
     +define+UVM_NO_DEPRECATED \
     -suppress 2583

vsim -voptargs=+acc \
     work.tb_top \
     -classdebug \
     -uvmcontrol=all \
     -cover \
     +UVM_TESTNAME=riscv_int_alu_test \
     +UVM_VERBOSITY=UVM_MEDIUM

add wave -position insertpoint \
sim:/tb_top/clk \
sim:/tb_top/dut_if/rst_n \
sim:/tb_top/dut_if/Result

# -- Waves: fetch / decode ----------------------------------------------------

add wave -position insertpoint \
sim:/tb_top/dut_if/PCD \
sim:/tb_top/dut_if/PCPlus4D \
sim:/tb_top/dut_if/InstrD \
sim:/tb_top/dut_if/InstrDE \
sim:/tb_top/dut_if/InstrDM

# -- Waves: execute -----------------------------------------------------------

add wave -position insertpoint \
sim:/tb_top/dut_if/RegWriteE \
sim:/tb_top/dut_if/ALUControlE \
sim:/tb_top/dut_if/BranchE \
sim:/tb_top/dut_if/JumpE \
sim:/tb_top/dut_if/PCSrcE \
sim:/tb_top/dut_if/PCTargetE

# -- Waves: memory ------------------------------------------------------------
add wave -position insertpoint \
sim:/tb_top/dut_if/ALU_ResultM \
sim:/tb_top/dut_if/MemWriteM \
sim:/tb_top/dut_if/ResultSrcM \
sim:/tb_top/dut_if/WriteDataM

# -- Waves: write-back --------------------------------------------------------

add wave -position insertpoint \
sim:/tb_top/dut_if/RegWriteW \
sim:/tb_top/dut_if/RDW \
sim:/tb_top/dut_if/ResultW

# -- Waves: hazard unit -------------------------------------------------------

add wave -position insertpoint \
sim:/tb_top/dut_if/StallF \
sim:/tb_top/dut_if/StallD \
sim:/tb_top/dut_if/FlushE \
sim:/tb_top/dut_if/mispredict \
sim:/tb_top/dut_if/stall

# -- Waves: FPU ---------------------------------------------------------------

add wave -position insertpoint \
sim:/tb_top/dut_if/faddE \
sim:/tb_top/dut_if/fsubE \
sim:/tb_top/dut_if/fmulE \
sim:/tb_top/dut_if/fdivE \
sim:/tb_top/dut_if/fsqrtE \
sim:/tb_top/dut_if/floadE \
sim:/tb_top/dut_if/fstoreE \
sim:/tb_top/dut_if/FRegWriteMW \
sim:/tb_top/dut_if/FRdW \
sim:/tb_top/dut_if/FResultW

# -- Waves: cache -------------------------------------------------------------

add wave -position insertpoint \
sim:/tb_top/dut_if/cache_state
add wave -position insertpoint  \
sim:/tb_top/dut/Decode/rf/clk \
sim:/tb_top/dut/Decode/rf/rst_n \
sim:/tb_top/dut/Decode/rf/WE3 \
sim:/tb_top/dut/Decode/rf/A1 \
sim:/tb_top/dut/Decode/rf/A2 \
sim:/tb_top/dut/Decode/rf/A3 \
sim:/tb_top/dut/Decode/rf/WD3 \
sim:/tb_top/dut/Decode/rf/RD1 \
sim:/tb_top/dut/Decode/rf/RD2 \
sim:/tb_top/dut/Decode/rf/Register \
sim:/tb_top/dut/Decode/rf/i
add wave -position insertpoint  \
sim:/tb_top/dut/Decode/frf/clk \
sim:/tb_top/dut/Decode/frf/rst_n \
sim:/tb_top/dut/Decode/frf/F_WD \
sim:/tb_top/dut/Decode/frf/rs1 \
sim:/tb_top/dut/Decode/frf/rs2 \
sim:/tb_top/dut/Decode/frf/rd \
sim:/tb_top/dut/Decode/frf/WE \
sim:/tb_top/dut/Decode/frf/F_RD1 \
sim:/tb_top/dut/Decode/frf/F_RD2 \
sim:/tb_top/dut/Decode/frf/F_register \
sim:/tb_top/dut/Decode/frf/i


# -- Run ----------------------------------------------------------------------
run -all

# -- Save coverage ------------------------------------------------------------
coverage save riscv_uvm.ucdb
# vcover report riscv_uvm.ucdb -details -annotate -all -output coverage_rpt.txt

# quit -sim
