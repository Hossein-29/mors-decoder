
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

hdi::project new -name SevenSegTest -dir "E:/3s400/AZ_Project/test-all-AVA/patmp"
hdi::project setArch -name SevenSegTest -arch spartan3
hdi::design setOptions -project SevenSegTest -top lcd_top  
hdi::param set -name project.paUcfFile -svalue "SevenSegTest.ucf"
hdi::floorplan new -name floorplan_1 -part xc3s400pq208-4 -project SevenSegTest
hdi::port import -project SevenSegTest \
    -vhdl {char_ram.vhd work} \
    -vhdl {SevenSegTest.vhd work} \
    -vhdl {lcd_rtl/lcd.vhd work} \
    -verilog {lcd_rtl/DIV16.v verilog} \
    -vhdl {lcd_top.vhf work}
hdi::port export -project SevenSegTest -file SevenSegTest_pa_ports.v -format verilog
hdi::pconst import -project SevenSegTest -floorplan floorplan_1 -file "SevenSegTest.ucf"
