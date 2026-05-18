----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    01:43:08 03/16/2011 
-- Design Name: 
-- Module Name:    SevenSegTest - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SevenSegTest is
    Port ( GCLK : in  STD_LOGIC;
			  Reset : in  STD_LOGIC;
			  LEDS : out  STD_LOGIC_VECTOR (7 downto 0);
           SEG_SEL : out  STD_LOGIC_VECTOR (4 downto 0);
           SEG_DATA : out  STD_LOGIC_VECTOR (7 downto 0)
			  );
end SevenSegTest;

architecture Behavioral of SevenSegTest is
signal count_period : std_logic_vector(7 downto 0);
signal  clk_2 : std_logic ; ----------for clk_div----------
signal CLK10MS,CLK1S: std_logic;
signal CounterSeg1sig,CounterSeg2sig,CounterSeg3sig,CounterSeg4sig: std_logic_vector(3 downto 0);

signal SEG_DATA_reg1,SEG_DATA_reg2,SEG_DATA_reg3,SEG_DATA_reg4: std_logic_vector(7 downto 0);
begin
-----------------------counter------------------------------------
process(GCLK)
variable count_div : integer range 0 to 1000000 :=0;
begin

     if (rising_edge(GCLK)) then

          if count_div < 1000000 then
				 count_div := count_div + 1 ;   	  
				 if count_div < 500000 then
					 clk_2 <= '1';
					 else 
					 clk_2 <= '0';
				 end if;
             else count_div := 0;
			 end if; 
	  end if;
end process;
------------------------------------- 
process(clk_2)
begin
	if rising_edge (clk_2) then
		if( Reset = '0') then
			count_period <= x"ff";
		else
			count_period <= (count_period) + '1' ; 
		end if;					
	ledS <= count_period;
	end if;
end process;
	------------------------TEST-I/O--------------
	------------------------7segment-----------------------------

with CounterSeg1sig select
	SEG_DATA_reg1 <= "00111111"  when "0000",
	"00000110"  when "0001",
	"01011011"  when "0010",
	"01001111"  when "0011",
	"01100110"  when "0100",
	"01101101"  when "0101",
	"01111101"  when "0110",
	"00000111"  when "0111",
	"01111111"  when "1000",
	"01101111"  when "1001",
	"00000000"  when others;
	
with CounterSeg2sig select
	SEG_DATA_reg2 <= "00111111"  when "0000",
	"00000110"  when "0001",
	"01011011"  when "0010",
	"01001111"  when "0011",
	"01100110"  when "0100",
	"01101101"  when "0101",
	"01111101"  when "0110",
	"00000111"  when "0111",
	"01111111"  when "1000",
	"01101111"  when "1001",
	"00000000"  when others;	
	
with CounterSeg3sig select
	SEG_DATA_reg3 <= "00111111"  when "0000",
	"00000110"  when "0001",
	"01011011"  when "0010",
	"01001111"  when "0011",
	"01100110"  when "0100",
	"01101101"  when "0101",
	"01111101"  when "0110",
	"00000111"  when "0111",
	"01111111"  when "1000",
	"01101111"  when "1001",
	"00000000"  when others;
	
with CounterSeg4sig select
	SEG_DATA_reg4 <= "00111111"  when "0000",
	"00000110"  when "0001",
	"01011011"  when "0010",
	"01001111"  when "0011",
	"01100110"  when "0100",
	"01101101"  when "0101",
	"01111101"  when "0110",
	"00000111"  when "0111",
	"01111111"  when "1000",
	"01101111"  when "1001",
	"00000000"  when others;
	
--------------------------------------------------
process(CLK10MS)
variable RefreshSEG : integer range 0 to 4 :=0;

begin
    if (rising_edge(CLK10MS)) then
			if RefreshSEG < 4 then
				 RefreshSEG := RefreshSEG + 1 ;
			else RefreshSEG := 0;
			end if; 
			
			case RefreshSEG is
				when 0 =>
					SEG_SEL(4) <='0';
					SEG_SEL(0) <='1';
					SEG_DATA <= SEG_DATA_reg1;
				when 1 => 
					SEG_SEL(0) <='0';
					SEG_SEL(1) <='1';
					SEG_DATA <= SEG_DATA_reg2;
				when 2 =>
					SEG_SEL(1) <='0';
					SEG_SEL(2) <='1';
					SEG_DATA <= SEG_DATA_reg3;
				when 3 => 
					SEG_SEL(2) <='0';
					SEG_SEL(3) <='1';
					SEG_DATA <= SEG_DATA_reg4;
				when 4 => 
					SEG_SEL(3) <='0';
					SEG_SEL(4) <='1';
					SEG_DATA <= "00000000";					
				when others => null;
			end case;
		end if;
end process;	

process(GCLK)
variable count_div : integer range 0 to 100000 :=0;
begin
     if (rising_edge(GCLK)) then

          if count_div < 80000 then
				 count_div := count_div + 1 ;  
          else 
				count_div := 0;
				CLK10MS <= not CLK10MS;
			 end if; 
	  end if;
end process;


process(GCLK)
variable count_div : integer range 0 to 20000000 :=0;
VARIABLE CounterSeg1,CounterSeg2,CounterSeg3,CounterSeg4: STD_LOGIC_VECTOR(3 DOWNTO 0);
begin
     if (rising_edge(GCLK)) then
			 if count_div < 5000000 then
				 count_div := count_div + 1 ;  
			 else 
				count_div := 0;
				CLK1S <= not CLK1S;
				if( Reset = '0') then
					CounterSeg1 :="0000";
					CounterSeg2 :="0000";
					CounterSeg3 :="0000";
					CounterSeg4 :="0000";
				else
					if(CounterSeg1 < "1001") then
						CounterSeg1 := CounterSeg1 + 1;
					else
						CounterSeg1 :="0000";
						if(CounterSeg2 < "1001") then
							CounterSeg2 := CounterSeg2 + 1;
						else
							CounterSeg2 :="0000";
							if(CounterSeg3 < "1001") then
								CounterSeg3 := CounterSeg3 + 1;
							else
								CounterSeg3 :="0000";
								if(CounterSeg4 < "1001") then
									CounterSeg4 := CounterSeg4 + 1;
								else
									CounterSeg4 :="0000";
								end if;
							end if;
						end if;
					end if;
				 end if;					
					CounterSeg1sig <= CounterSeg1;
					CounterSeg2sig <= CounterSeg2;
					CounterSeg3sig <= CounterSeg3;
					CounterSeg4sig <= CounterSeg4;
			end if; 
	  end if;
end process;

end Behavioral;

