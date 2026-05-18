
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

hdi::project new -name SevenSegTest -dir "E:/3s400/AZ_Project/test-all-AVA/patmp"
hdi::project setArch -name SevenSegTest -arch spartan3
hdi::design setOptions -project SevenSegTest -top netlist_1_EMPTY
hdi::param set -name project.paUcfFile -svalue "SevenSegTest.ucf"
hdi::floorplan new -name floorplan_1 -part xc3s400pq208-4 -project SevenSegTest
hdi::port import -project SevenSegTest -verilog {SevenSegTest_pa_ports.v work}
hdi::pconst import -project SevenSegTest -floorplan floorplan_1 -file "SevenSegTest.ucf"
