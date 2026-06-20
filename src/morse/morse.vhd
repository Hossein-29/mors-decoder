library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity morse is
    port(
        clk        : in std_logic;                    -- 100 MHz clock
        input      : in std_logic;                    -- Button input (active low/high)
        
        outleddot  : out std_logic;                   -- Lit during dot
        outleddas  : out std_logic;                   -- Lit during dash
        outledsep  : out std_logic;                   -- Lit when idle (separator)
		
		state_iden1: out std_logic;
		state_iden2: out std_logic;
        
		output     : out std_logic_vector(7 downto 0);-- ASCII/mapped output
		
		counter_o  : out integer
    );
end entity;

architecture Behavioral of morse is

    constant DOT_TIME    : integer := 20;  -- ~200 ns @ 100MHz
    constant DASH_TIME   : integer := 40;  -- ~400 ns
    constant IDLE_TIME   : integer := 80;  -- ~800 ns between characters

    type state_type is (IDLE, PRESSED, RELEASED, PROCESSING);
    signal state : state_type := IDLE;

    signal char_index       : integer range 0 to 7 := 7; 
    signal symbol_count     : integer range 0 to 8 := 0;

    signal char_pattern     : std_logic_vector(7 downto 0) := (others => '0');
    signal decoded_char     : std_logic_vector(7 downto 0) := "00000000";

    signal counter          : integer := 0;
    signal done_counter     : integer := 0;

    signal timer_done       : std_logic := '0';

    -- Morse code lookup table (A-Z, 0-9)
    type morse_rom is array (0 to 35) of std_logic_vector(7 downto 0);
    constant morse_lut : morse_rom := (
        "01------", -- A  .-	  0
        "1000----", -- B  -...	  1
        "1010----", -- C  -.-.	  2
        "100-----", -- D  -..	  3
        "0-------", -- E  .		  4
        "0010----", -- F  ..-.	  5
        "110-----", -- G  --.	  6
        "0000----", -- H  ....	  7
        "00------", -- I  ..	  8
        "0111----", -- J  .---	  9
        "101-----", -- K  -.-	  10
        "0100----", -- L  .-..	  11
        "11------", -- M  --	  12
        "10------", -- N  -.	  13
        "111-----", -- O  ---	  14
        "0110----", -- P  .--.	  15
        "1101----", -- Q  --.-	  16
        "010-----", -- R  .-.	  17
        "000-----", -- S  ...	  18
        "1-------", -- T  -		  19
        "001-----", -- U  ..-	  20
        "0001----", -- V  ...-	  21
        "011-----", -- W  .--	  22
        "1001----", -- X  -..-	  23
        "1011----", -- Y  -.--	  24
        "1100----", -- Z  --..	  25

        "11111---", -- 0 (-----)  26
    	"01111---", -- 1 (.----)  27
    	"00111---", -- 2 (..---)  28
    	"00011---", -- 3 (...--)  29
    	"00001---", -- 4 (....-)  30
    	"00000---", -- 5 (.....)  31
    	"10000---", -- 6 (-....)  32
    	"11000---", -- 7 (--...)  33
    	"11100---", -- 8 (---..)  34
    	"11110---"  -- 9 (----.)  35 
		
		-- "000000--", -- 'space' 	  36
		-- "000001--" -- 'reserved' 37
    );

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if done_counter = IDLE_TIME then
                timer_done <= '1';
			elsif state = IDLE then
                done_counter <= done_counter + 1;
                timer_done <= '0';
            end if;
				
				
			if state /= IDLE or symbol_count = 0 then
               	done_counter <= 0;
			end if;
            
		end if;
	 end process;
	 
	 
	 process(clk)
	 	variable decoded_value : std_logic_vector(7 downto 0);
	 	variable lookup_pattern : std_logic_vector(7 downto 0);
	 	variable received_symbol : std_logic;
	 	variable valid_symbol : boolean;
	 begin
        if rising_edge(clk) then
            case state is
                when IDLE =>
                    outleddot <= '0';
                    outleddas <= '0';

                    if input = '0' then -- button pressed
                        state <= PRESSED;
                        counter <= 0;
								
                    elsif timer_done = '1' and symbol_count /= 0 then
                        state <= PROCESSING;
                    end if;

                when PRESSED =>
                    outleddot <= '0';
                    outleddas <= '0';
                    counter <= counter + 1;
                    if input = '1' then -- button released
                        state <= RELEASED;
                    end if;

                when RELEASED =>
                    valid_symbol := false;

                    if counter >= DASH_TIME then
                        received_symbol := '1';
                        valid_symbol := true;
                        outleddas <= '1';
                        outleddot <= '0';
								
                    elsif counter >= DOT_TIME then
                        received_symbol := '0';
                        valid_symbol := true;
                        outleddot <= '1';
                        outleddas <= '0';
								
                    else
                        -- ignored (too short)
                        outleddot <= '0';
                        outleddas <= '0';
                        state <= IDLE;
                    end if;

                    if valid_symbol then
                        char_pattern(char_index) <= received_symbol;

                        if symbol_count = 7 then
                            symbol_count <= 8;
                            state <= PROCESSING;
                        else
                            symbol_count <= symbol_count + 1;
                            char_index <= char_index - 1;
                            state <= IDLE;
                        end if;
                    end if;

                    counter <= 0;

                when PROCESSING =>
                    outleddot <= '0';
                    outleddas <= '0';
                    decoded_value := "11111111";
                    lookup_pattern := (others => '-');

                    for bit_index in 0 to 7 loop
                        if bit_index >= 8 - symbol_count then
                            lookup_pattern(bit_index) := char_pattern(bit_index);
                        end if;
                    end loop;

                    -- Match pattern
                    for i in 0 to 35 loop
                        if lookup_pattern = morse_lut(i) then
                            decoded_value := std_logic_vector(to_unsigned(i, 8));
                            exit;
                        end if;
                    end loop;

                    decoded_char <= decoded_value;
                    output <= decoded_value;

                    char_index <= 7;
                    symbol_count <= 0;
                    char_pattern <= (others => '0');
                    state <= IDLE;
                    
            end case;
        end if;
    end process;
	 
	 process (clk)
	 begin
		if    state = IDLE then
			state_iden1 <= '0';
			state_iden2 <= '0';

		elsif state = PRESSED then
			state_iden1 <= '1';
			state_iden2 <= '0';

		elsif state = RELEASED then
			state_iden1 <= '0';
			state_iden2 <= '1';

		elsif state = PROCESSING then
			state_iden1 <= '1';
			state_iden2 <= '1';

		end if;
	 end process;

	 outledsep <= not input;
	 counter_o <= counter;
end architecture;
