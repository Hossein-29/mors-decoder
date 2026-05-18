SetActiveLib -work
comp -include "$dsn\src\main.vhd" 
comp -include "$dsn\src\TestBench\morse_decoder_TB.vhd" 
asim +access +r TESTBENCH_FOR_morse_decoder 
wave 
wave -noreg clk
wave -noreg reset
wave -noreg btn_in
wave -noreg decoded_index
wave -noreg new_char_ready
# The following lines can be used for timing simulation
# acom <backannotated_vhdl_file_name>
# comp -include "$dsn\src\TestBench\morse_decoder_TB_tim_cfg.vhd" 
# asim +access +r TIMING_FOR_morse_decoder 
