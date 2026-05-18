////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995-2003 Xilinx, Inc.
// All Right Reserved.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____ 
//  /   /\/   / 
// /___/  \  /    Vendor: Xilinx 
// \   \   \/     Version : 7.1i
//  \   \         Application : sch2verilog
//  /   /         Filename : lcd_top.vf
// /___/   /\     Timestamp : 10/11/2006 23:16:16
// \   \  /  \ 
//  \___\/\___\ 
//
//Command: D:/Xilinx/bin/nt/sch2verilog.exe -intstyle ise -family spartan3 -w lcd_top.sch lcd_top.vf
//Design Name: lcd_top
//Device: spartan3
//Purpose:
//    This verilog netlist is translated from an ECS schematic.It can be 
//    synthesized and simulated, but it should not be modified. 
//
`timescale 1ns / 1ps

module lcd_top(clk, 
               rst_n, 
               data, 
               lcd_e, 
               lcd_rs, 
               lcd_rw);

    input clk;
    input rst_n;
   output [7:0] data;
   output lcd_e;
   output lcd_rs;
   output lcd_rw;
   
   wire XLXN_3;
   
   lcd XLXI_1 (.clk(XLXN_3), 
               .Reset(rst_n), 
               .data(data[7:0]), 
               .lcd_e(lcd_e), 
               .lcd_rs(lcd_rs), 
               .lcd_rw(lcd_rw), 
               .stateout());
   div16 XLXI_2 (.clk(clk), 
                 .rst(rst_n), 
                 .clk_16(XLXN_3));
endmodule
