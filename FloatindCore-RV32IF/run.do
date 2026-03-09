vlib work
vlog -f src_files.list 
vsim  -voptargs=+acc work.test 
add wave -position insertpoint  \
sim:/test/dut/ALU_ResultM \
sim:/test/dut/ALU_ResultW \
sim:/test/dut/ALUControlE \
sim:/test/dut/ALUSrcE \
sim:/test/dut/BranchE \
sim:/test/dut/clk \
sim:/test/dut/faddE \
sim:/test/dut/fdivE \
sim:/test/dut/floadE \
sim:/test/dut/floadM \
sim:/test/dut/FlushD \
sim:/test/dut/FlushE \
sim:/test/dut/fmulE \
sim:/test/dut/ForwardAE \
sim:/test/dut/ForwardBE \
sim:/test/dut/FPU_ResultEM \
sim:/test/dut/FPU_ResultEW \
sim:/test/dut/FRD1_E \
sim:/test/dut/FRD2_E \
sim:/test/dut/FRegWrite_E \
sim:/test/dut/FRegWrite_M \
sim:/test/dut/FRegWriteMW \
sim:/test/dut/FResultSrcE \
sim:/test/dut/FResultSrcM \
sim:/test/dut/FResultSrcW \
sim:/test/dut/FResultW \
sim:/test/dut/fsqrtE \
sim:/test/dut/fstoreE \
sim:/test/dut/fstoreM \
sim:/test/dut/fsubE \
sim:/test/dut/funct3E \
sim:/test/dut/Imm_Ext_E \
sim:/test/dut/InstrD \
sim:/test/dut/InstrDE \
sim:/test/dut/InstrDM \
sim:/test/dut/is_FOP \
sim:/test/dut/JumpE \
sim:/test/dut/MemWriteE \
sim:/test/dut/MemWriteM \
sim:/test/dut/o_p_readdata_valid \
sim:/test/dut/o_p_waitrequest \
sim:/test/dut/OpE \
sim:/test/dut/PCD \
sim:/test/dut/PCE \
sim:/test/dut/PCPlus4D \
sim:/test/dut/PCPlus4E \
sim:/test/dut/PCPlus4M \
sim:/test/dut/PCPlus4W \
sim:/test/dut/PCSrcE \
sim:/test/dut/PCTargetE \
sim:/test/dut/RD1_E \
sim:/test/dut/RD2_E \
sim:/test/dut/RD_E \
sim:/test/dut/RD_M \
sim:/test/dut/RDW \
sim:/test/dut/ReadDataW \
sim:/test/dut/RegWriteE \
sim:/test/dut/RegWriteM \
sim:/test/dut/RegWriteW \
sim:/test/dut/Result \
sim:/test/dut/ResultSrcE \
sim:/test/dut/ResultSrcM \
sim:/test/dut/ResultSrcW \
sim:/test/dut/ResultW \
sim:/test/dut/RS1_E \
sim:/test/dut/RS2_E \
sim:/test/dut/rst_n \
sim:/test/dut/stall \
sim:/test/dut/StallD \
sim:/test/dut/StallF \
sim:/test/dut/WriteDataM
add wave -position insertpoint  \
sim:/test/dut/Decode/frf/F_RD1 \
sim:/test/dut/Decode/frf/F_RD2 \
sim:/test/dut/Decode/frf/F_register \
sim:/test/dut/Decode/frf/F_WD \
sim:/test/dut/Decode/frf/rd \
sim:/test/dut/Decode/frf/rs1 \
sim:/test/dut/Decode/frf/rs2 \
sim:/test/dut/Decode/frf/WE
add wave -position insertpoint  \
sim:/test/dut/Decode/rf/A1 \
sim:/test/dut/Decode/rf/A2 \
sim:/test/dut/Decode/rf/A3 \
sim:/test/dut/Decode/rf/RD1 \
sim:/test/dut/Decode/rf/RD2 \
sim:/test/dut/Decode/rf/Register \
sim:/test/dut/Decode/rf/WD3 \
sim:/test/dut/Decode/rf/WE3
add wave -position insertpoint  \
sim:/test/dut/Execute/fpu_unit/A
add wave -position insertpoint  \
sim:/test/dut/Execute/fpu_unit/B
add wave -position insertpoint  \
sim:/test/dut/Execute/fpu_unit/fadder/active \
sim:/test/dut/Execute/fpu_unit/fadder/input_a \
sim:/test/dut/Execute/fpu_unit/fadder/input_a_stb \
sim:/test/dut/Execute/fpu_unit/fadder/input_b \
sim:/test/dut/Execute/fpu_unit/fadder/input_b_stb
add wave -position insertpoint  \
sim:/test/dut/Execute/fpu_unit/fadder/output_z
add wave -position insertpoint  \
sim:/test/dut/Execute/fpu_unit/fadder/output_z_stb
add wave -position insertpoint  \
sim:/test/dut/Memory/dut/i_p_addr
add wave -position insertpoint  \
sim:/test/dut/Memory/dut/i_p_read
add wave -position insertpoint  \
sim:/test/dut/Memory/dut/i_p_write
add wave -position insertpoint  \
sim:/test/dut/Memory/dut/i_p_writedata
add wave -position insertpoint  \
sim:/test/dut/Memory/dut/o_p_readdata
add wave -position insertpoint  \
sim:/test/dut/Memory/dut/o_p_readdata_valid
add wave -position insertpoint  \
sim:/test/dut/Memory/dut/state
add wave -position insertpoint  \
sim:/test/dut/Memory/o_p_waitrequest
add wave -position insertpoint  \
sim:/test/dut/Execute/fpu_srcb_mux/a \
sim:/test/dut/Execute/fpu_srcb_mux/b \
sim:/test/dut/Execute/fpu_srcb_mux/c \
sim:/test/dut/Execute/fpu_srcb_mux/d \
sim:/test/dut/Execute/fpu_srcb_mux/s

run -all
# quit -sim
# vcover report FIFO.ucdb -details -annotate -all -output Coverage_rpt.txt