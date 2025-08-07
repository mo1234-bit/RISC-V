vlib work
vlog ALU.v main_decoder.v ALU_Decoder.v adder.v control_unit.v DATA_MEM.v Extend.v instr_mem.v mux.v PC.v register_file.v top.v test.v 
vsim -voptargs=+acc work.test
add wave *
add wave -position insertpoint  \
sim:/test/dut/dut1/PC_next \
sim:/test/dut/dut1/PC
add wave -position insertpoint  \
sim:/test/dut/dut2/A \
sim:/test/dut/dut2/RD \
sim:/test/dut/dut2/MEM
add wave -position insertpoint  \
sim:/test/dut/dut3/A1 \
sim:/test/dut/dut3/A2 \
sim:/test/dut/dut3/A3 \
sim:/test/dut/dut3/WD3 \
sim:/test/dut/dut3/WE3 \
sim:/test/dut/dut3/RD1 \
sim:/test/dut/dut3/RD2 \
sim:/test/dut/dut3/register
add wave -position insertpoint  \
sim:/test/dut/dut4/Imm_ext
add wave -position insertpoint  \
sim:/test/dut/dut5/A \
sim:/test/dut/dut5/B \
sim:/test/dut/dut5/ALUControl
add wave -position insertpoint  \
sim:/test/dut/dut6/funct7 \
sim:/test/dut/dut6/op \
sim:/test/dut/dut6/funct3 \
sim:/test/dut/dut6/RegWrite \
sim:/test/dut/dut6/ALUSrc \
sim:/test/dut/dut6/MemWrite \
sim:/test/dut/dut6/ResultSrc \
sim:/test/dut/dut6/ImmSrc
run -all
#quit -sim