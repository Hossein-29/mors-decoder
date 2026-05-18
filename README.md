# Morse Decoder FPGA Project

This repository contains VHDL/Verilog work for a Morse-code decoder and related FPGA display experiments.

## Layout

- `src/morse/` - Clean copy of the standalone Morse decoder source.
- `testbench/morse/` - Test bench for the standalone Morse decoder.
- `src/morse_lcd/` - Morse decoder plus LCD display integration source.
- `testbench/morse_lcd/` - Test bench related to the LCD-oriented Morse decoder version.
- `src/lcd/` - Standalone LCD controller reference source.
- `docs/` - Project PDF documentation.
- `legacy/` - Original tool project folders and generated files, kept for reference.

## Notes

The source files under `src/` and `testbench/` are the easiest entry points for reading and editing the design. The `legacy/` folder preserves the original Active-HDL and Xilinx ISE project structures, including generated synthesis, simulation, and implementation artifacts.

