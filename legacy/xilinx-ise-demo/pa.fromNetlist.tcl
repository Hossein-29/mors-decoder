
# PlanAhead Launch Script for Post-Synthesis pin planning, created by Project Navigator

hdi::project new -name SevenSegTest -dir "E:/3s400/AZ_Project/test-all-AVA/patmp" -netlist "lcd_top.ngc" -search_path { {E:/3s400/AZ_Project/test-all-AVA} }
hdi::project setArch -name SevenSegTest -arch spartan3
hdi::param set -name project.pinAheadLayout -bvalue yes
hdi::param set -name project.paUcfFile -svalue "SevenSegTest.ucf"
hdi::floorplan new -name floorplan_1 -part xc3s400pq208-4 -project SevenSegTest
hdi::pconst import -project SevenSegTest -floorplan floorplan_1 -file "SevenSegTest.ucf"
