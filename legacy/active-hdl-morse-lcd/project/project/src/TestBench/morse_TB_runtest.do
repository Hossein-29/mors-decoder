SetActiveLib -work
comp -include "$dsn\src\main.vhd" 
comp -include "$dsn\src\TestBench\morse_TB.vhd" 
asim +access +r TESTBENCH_FOR_morse 
wave 
wave -noreg clk
wave -noreg input
wave -noreg outleddot
wave -noreg outleddas
wave -noreg outledsep
wave -noreg state_iden1
wave -noreg state_iden2
wave -noreg output
wave -noreg counter_o
# The following lines can be used for timing simulation
# acom <backannotated_vhdl_file_name>
# comp -include "$dsn\src\TestBench\morse_TB_tim_cfg.vhd" 
# asim +access +r TIMING_FOR_morse 
