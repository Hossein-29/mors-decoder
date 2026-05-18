--   	    www.DSPCore.ir
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;



entity lcd is
    Port ( clk : in std_logic;				 --50Mhz/16=3.125Mhz
           Reset : in std_logic;
           lcd_rs : out std_logic;
           lcd_rw : out std_logic;
			  lcd_e  : buffer std_logic;
			  data : out std_logic_vector(7 downto 0)
			  --stateout: out std_logic_vector(10 downto 0)
		   );
end lcd;


architecture Behavioral of lcd is

constant IDLE :         std_logic_vector(10 downto 0) :="00000000000";
constant CLEAR :        std_logic_vector(10 downto 0) :="00000000001";
constant RETURNCURSOR : std_logic_vector(10 downto 0) :="00000000010" ;
constant SETMODE      : std_logic_vector(10 downto 0) :="00000000100";
constant SWITCHMODE   : std_logic_vector(10 downto 0) :="00000001000";
constant SHIFT        : std_logic_vector(10 downto 0) :="00000010000";
constant SETFUNCTION  : std_logic_vector(10 downto 0) :="00000100000";
constant SETCGRAM     : std_logic_vector(10 downto 0) :="00001000000";
constant SETDDRAM     : std_logic_vector(10 downto 0) :="00010000000";
constant READFLAG     : std_logic_vector(10 downto 0) :="00100000000";
constant WRITERAM     : std_logic_vector(10 downto 0) :="01000000000";
constant READRAM      : std_logic_vector(10 downto 0) :="10000000000";




constant cur_inc      : std_logic :='1';  -- 1 / D direction of cursor movement direction, high shifted to the right, low left
constant cur_dec      : std_logic :='0';
constant cur_shift    : std_logic :='1'; --S instructions on the screen all the text, whether left or right, high effective
constant cur_noshift  : std_logic :='0'; 
constant open_display : std_logic :='1'; --D to control the overall display of the switch, that open display high and low for the relevant display
constant open_cur     : std_logic :='0'; --C switches the cursor control, high expressed cursor
constant blank_cur    : std_logic :='0'; --B control the cursor is blinking, flashing high
constant shift_display: std_logic :='1'; --S / C control whether the mobile display text or cursor, high for mobile text, low to move the cursor
constant shift_cur    : std_logic :='0'; 
constant right_shift  : std_logic :='1'; --R / L control the movement of text or cursor direction is shifted to the right high, low for the left
constant left_shift   : std_logic :='0';
constant datawidth8   : std_logic :='1'; --DL set to the median 8-bit bus
constant datawidth4   : std_logic :='0'; --DL set the bus multiplier to 4
constant twoline      : std_logic :='1'; --N high time for the two-line display, low for the single line display
constant oneline      : std_logic :='0';
constant font5x10     : std_logic :='1'; --F high time for the 5 * 10 dot character
constant font5x7      : std_logic :='0'; --F low, 5 * 7 dot matrix


signal stateout: std_logic_vector(10 downto 0);

signal state : std_logic_vector(10 downto 0);
signal counter : integer range 0 to 127;
signal div_counter : integer range 0 to 15;
signal flag        : std_logic;
constant DIVSS : integer :=15;

signal char_addr : std_logic_vector(5 downto 0);
signal data_in   : std_logic_vector(7 downto 0);
component char_ram
          port( address : in std_logic_vector(5 downto 0) ;
	             data    : out std_logic_vector(7 downto 0)
		         );
end component;--call the module declaration


signal clk_int: std_logic; --cycle 2 * 51.2us = 102.4us

signal clkcnt: std_logic_vector(15 downto 0);
constant divcnt: std_logic_vector(15 downto 0):="1001110001000000"; --40000
signal clkdiv: std_logic; --cycle 2 * 25.6us = 51.2us
signal tc_clkcnt: std_logic; --cycle 20 * 16ns * 80000 = 25.6us
begin



process(clk,reset)
begin
  if(reset='0')then
  clkcnt<="0000000000000000";
  elsif(clk'event and clk='1')then
     if(clkcnt=divcnt)then
     clkcnt<="0000000000000000";
     else
     clkcnt<=clkcnt+1;
     end if;
  end if;
end process;
tc_clkcnt<='1' when clkcnt=divcnt else
           '0';

process(tc_clkcnt,reset)
begin
   if(reset='0')then
   clkdiv<='0';
   elsif(tc_clkcnt'event and tc_clkcnt='1')then
   clkdiv<=not clkdiv;
   end if;
end process;

process(clkdiv,reset)
begin
  if(reset='0')then
    clk_int<='0';
  elsif(clkdiv'event and clkdiv='1')then
    clk_int<= not clk_int;
  end if;
end process;

process(clkdiv,reset) --take falling, will lcd_e compared clk_in half clock cycle delay to meet the timing requirements
begin
   if(reset='0')then
     lcd_e<='0';
   elsif(clkdiv'event and clkdiv='0')then
     lcd_e<= not lcd_e;
   end if;
end process;

aa:char_ram
   port map( address=>char_addr,data=>data_in);

    lcd_rs <= '1' when state =WRITERAM or state = READRAM else '0'; --rs for the register selection, select the data register high and low for the instruction register
	lcd_rw <= '0' when state =CLEAR or state = RETURNCURSOR or state=SETMODE or state=SWITCHMODE or state=SHIFT or state= SETFUNCTION or state=SETCGRAM or state =SETDDRAM or state =WRITERAM else
	          '1'; --Rw to read and write signal lines, high to read, low for write
     data <=    "00000001" when state =CLEAR else --a clear indication: Enter the command used to clear 0000_0001
	           "00000010" when state =RETURNCURSOR else  --the cursor reset: input command for the cursor to return 0000_0010
			 "000001"& cur_inc & cur_noshift  when state = SETMODE else --the cursor and display mode settings: the cursor shifts to the right direction, all the text does not move
			 "00001" & open_display &open_cur & blank_cur when state =SWITCHMODE else--show switch control: open display, no cursor, no blinking
			 "0001" & shift_display &left_shift &"00" when state = SHIFT else --cursor or display shift: the text to the left
			 "001" & datawidth8 & twoline &font5x10 & "00" when state=SETFUNCTION else  --feature set: the bus is 8 bits, dual-line display, 5 * 10 dot matrix
			 "01000000" when state =SETCGRAM else --set character generator address
			 "10000000" when state =SETDDRAM and counter =0 else --set data store address, the first is 1, after seven starting address for the DRAM's to
			 "11000000" when state =SETDDRAM and counter /=0 else --to set the starting address of the second line shows
			  data_in when state = WRITERAM else
			 "ZZZZZZZZ";

   char_addr  <=conv_std_logic_vector( counter,6) when state =WRITERAM and counter<40 else --the counter as the address, select the output of the characters, by char_ram module, output the corresponding character in CGROM (character generator storage) in the address
	            conv_std_logic_vector( counter-41+8,6) when state= WRITERAM and counter>40 and counter<81-8 else --+8 is to allow the second line from the R beginning to show results as  www.DSPCore.ir
			    conv_std_logic_vector( counter-81+8,6) when state= WRITERAM and counter>81-8 and counter<81 else 
				"000000";
						
						
  stateout<=state;
--State machines, temporal logic, used to describe the state transition
  process(clk_int,Reset) --input clock cycle is about 100us
  begin
      if(Reset='0')then 
		   state<=IDLE;
		   counter<=0;
		   flag<='0';
           div_counter<=0;
      elsif(clk_int'event and clk_int='1')then 
		   case state is
			when IDLE =>
			        if(flag='0')then 
						     state<=SETFUNCTION; --enter the function setting status
							 flag<='1';
							 counter<=0;
							 div_counter<=0;
                    else
						 if(div_counter<DIVSS )then
							 div_counter<=div_counter +1;
                             state<=IDLE;
                         else
							 div_counter<=0;
							 state <=SHIFT;
                         end if;
                    end if;
         when CLEAR    => --clear screen
			           state<=SETMODE;
         when SETMODE  => --cursor and display mode settings
			          -- state<=WRITERAM;
					   state <= SETDDRAM;  --counter = 0, the first set shows the first line of address
         when RETURNCURSOR => --reset the cursor, this module is not used
			           state<=WRITERAM;
         when SWITCHMODE => --Show off control
			           state<=CLEAR;
         when SHIFT      =>
			           state<=IDLE;
         when SETFUNCTION => --feature set
			           state<=SWITCHMODE;
         when SETCGRAM   =>
			           state<=IDLE;
         when SETDDRAM   => --set the DRAM
			           state<=WRITERAM;
         when READFLAG   =>
			           state<=IDLE;
         when WRITERAM   => 
			           if(counter =40)then --used to display the " www.DSPCore.ir" (a line can be displayed only 16 characters), and stay for some time
						     state<=SETDDRAM; --show finished after the first line, to re-set the DRAM addresses, used to display the second line
							 counter<=counter+1;
                        elsif(counter/=40 and counter<81)then -- used to display the "www.DSPCore.ir"
						     state<=WRITERAM;
							 counter<=counter+1;
                        else
						    state<=SHIFT;
                    end if;
         when READRAM => --read the value of DRAM, this module is not used
			           state<=IDLE;
         when others  =>
			           state<=IDLE;
         end case;
    end if;
  end process;

  
end Behavioral;
