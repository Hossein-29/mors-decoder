--------------------------------------------------------------------------------
-- Copyright (c) 1995-2009 Xilinx, Inc.  All rights reserved.
--------------------------------------------------------------------------------
--   ____  ____ 
--  /   /\/   / 
-- /___/  \  /    Vendor: Xilinx 
-- \   \   \/     Version : 11.1
--  \   \         Application : sch2hdl
--  /   /         Filename : lcd_top.vhf
-- /___/   /\     Timestamp : 12/02/2011 23:34:53
-- \   \  /  \ 
--  \___\/\___\ 
--
--Command: sch2hdl -intstyle ise -family spartan3 -flat -suppress -vhdl E:/test-all-AVA-LCD/lcd_top.vhf -w E:/test-all-AVA-LCD/lcd_rtl/lcd_top.sch
--Design Name: lcd_top
--Device: spartan3
--Purpose:
--    This vhdl netlist is translated from an ECS schematic. It can be 
--    synthesized and simulated, but it should not be modified. 
--

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
library UNISIM;
use UNISIM.Vcomponents.ALL;

entity lcd_top is
   port ( a_b_not      : in    std_logic; 
          c_start_not  : in    std_logic; 
          down_in_not  : in    std_logic; 
          GCLK         : in    std_logic; 
          left_in_not  : in    std_logic; 
          right_in_not : in    std_logic; 
          rst_n        : in    std_logic; 
          up_in_not    : in    std_logic; 
          Buzzer       : out   std_logic; 
          data         : out   std_logic_vector (7 downto 0); 
          lcd_e        : out   std_logic; 
          lcd_rs       : out   std_logic; 
          lcd_rw       : out   std_logic; 
          LEDS         : out   std_logic_vector (7 downto 0); 
          SEG_DATA     : out   std_logic_vector (7 downto 0); 
          SEG_SEL      : out   std_logic_vector (4 downto 0); 
          vga_blue0    : out   std_logic; 
          vga_blue1    : out   std_logic; 
          vga_green0   : out   std_logic; 
          vga_green1   : out   std_logic; 
          vga_hsync    : out   std_logic; 
          vga_red0     : out   std_logic; 
          vga_red1     : out   std_logic; 
          vga_vsync    : out   std_logic);
end lcd_top;

architecture BEHAVIORAL of lcd_top is
   attribute BOX_TYPE   : string ;
   signal XLXN_3       : std_logic;
   signal XLXN_20      : std_logic;
   component div16
      port ( clk    : in    std_logic; 
             rst    : in    std_logic; 
             clk_16 : out   std_logic);
   end component;
   
   component lcd
      port ( clk    : in    std_logic; 
             Reset  : in    std_logic; 
             lcd_rs : out   std_logic; 
             lcd_rw : out   std_logic; 
             lcd_e  : out   std_logic; 
             data   : out   std_logic_vector (7 downto 0));
   end component;
   
   component SevenSegTest
      port ( GCLK     : in    std_logic; 
             LEDS     : out   std_logic_vector (7 downto 0); 
             SEG_SEL  : out   std_logic_vector (4 downto 0); 
             SEG_DATA : out   std_logic_vector (7 downto 0); 
             Reset    : in    std_logic);
   end component;
   
   component vga_pong_top
      port ( clock40m     : in    std_logic; 
             reset        : in    std_logic; 
             right_in_not : in    std_logic; 
             left_in_not  : in    std_logic; 
             c_start_not  : in    std_logic; 
             a_b_not      : in    std_logic; 
             down_in_not  : in    std_logic; 
             up_in_not    : in    std_logic; 
             vga_hsync    : out   std_logic; 
             vga_red1     : out   std_logic; 
             vga_blue1    : out   std_logic; 
             vga_blue0    : out   std_logic; 
             vga_red0     : out   std_logic; 
             vga_vsync    : out   std_logic; 
             vga_green1   : out   std_logic; 
             vga_green0   : out   std_logic);
   end component;
   
   component BUFG
      port ( I : in    std_logic; 
             O : out   std_logic);
   end component;
   attribute BOX_TYPE of BUFG : component is "BLACK_BOX";
   
   component INV
      port ( I : in    std_logic; 
             O : out   std_logic);
   end component;
   attribute BOX_TYPE of INV : component is "BLACK_BOX";
   
begin
   DIVIDER : div16
      port map (clk=>GCLK,
                rst=>rst_n,
                clk_16=>XLXN_3);
   
   LCD_TEST : lcd
      port map (clk=>XLXN_3,
                Reset=>rst_n,
                data(7 downto 0)=>data(7 downto 0),
                lcd_e=>lcd_e,
                lcd_rs=>lcd_rs,
                lcd_rw=>lcd_rw);
   
   SEG_TEST : SevenSegTest
      port map (GCLK=>GCLK,
                Reset=>rst_n,
                LEDS(7 downto 0)=>LEDS(7 downto 0),
                SEG_DATA(7 downto 0)=>SEG_DATA(7 downto 0),
                SEG_SEL(4 downto 0)=>SEG_SEL(4 downto 0));
   
   VGA_GAME : vga_pong_top
      port map (a_b_not=>a_b_not,
                clock40m=>XLXN_20,
                c_start_not=>c_start_not,
                down_in_not=>down_in_not,
                left_in_not=>left_in_not,
                reset=>rst_n,
                right_in_not=>right_in_not,
                up_in_not=>up_in_not,
                vga_blue0=>vga_blue0,
                vga_blue1=>vga_blue1,
                vga_green0=>vga_green0,
                vga_green1=>vga_green1,
                vga_hsync=>vga_hsync,
                vga_red0=>vga_red0,
                vga_red1=>vga_red1,
                vga_vsync=>vga_vsync);
   
   XLXI_19 : BUFG
      port map (I=>GCLK,
                O=>XLXN_20);
   
   XLXI_27 : INV
      port map (I=>rst_n,
                O=>Buzzer);
   
end BEHAVIORAL;


