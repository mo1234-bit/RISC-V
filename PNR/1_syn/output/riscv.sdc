###################################################################

# Created by write_sdc on Thu Aug  1 16:15:29 2019

###################################################################
set sdc_version 1.9

set_units -time ns -resistance MOhm -capacitance fF -voltage V -current mA
create_clock [get_ports clk]  -period 5  -waveform {0 2.5}
set_clock_uncertainty 0.25  [get_clocks clk]
set_false_path -hold   -from [get_ports rst]
set_false_path -hold   -to [list [get_ports {Result[15]}] [get_ports {Result[14]}] [get_ports        \
{Result[13]}] [get_ports {Result[12]}] [get_ports {Result[11]}] [get_ports     \
{Result[10]}] [get_ports {Result[9]}] [get_ports {Result[8]}] [get_ports       \
{Result[7]}] [get_ports {Result[6]}] [get_ports {Result[5]}] [get_ports        \
{Result[4]}] [get_ports {Result[3]}] [get_ports {Result[2]}] [get_ports        \
{Result[1]}] [get_ports {Result[0]}]]
set_input_delay -clock clk  -max 0.5  [get_ports rst]
set_output_delay -clock clk  -max 0.5  [get_ports {Result[15]}]
set_output_delay -clock clk  -max 0.5  [get_ports {Result[14]}]
set_output_delay -clock clk  -max 0.5  [get_ports {Result[13]}]
set_output_delay -clock clk  -max 0.5  [get_ports {Result[12]}]
set_output_delay -clock clk  -max 0.5  [get_ports {Result[11]}]
set_output_delay -clock clk  -max 0.5  [get_ports {Result[10]}]
set_output_delay -clock clk  -max 0.5  [get_ports {Result[9]}]
set_output_delay -clock clk  -max 0.5  [get_ports {Result[8]}]
set_output_delay -clock clk  -max 0.5  [get_ports {Result[7]}]
set_output_delay -clock clk  -max 0.5  [get_ports {Result[6]}]
set_output_delay -clock clk  -max 0.5  [get_ports {Result[5]}]
set_output_delay -clock clk  -max 0.5  [get_ports {Result[4]}]
set_output_delay -clock clk  -max 0.5  [get_ports {Result[3]}]
set_output_delay -clock clk  -max 0.5  [get_ports {Result[2]}]
set_output_delay -clock clk  -max 0.5  [get_ports {Result[1]}]
set_output_delay -clock clk  -max 0.5  [get_ports {Result[0]}]
