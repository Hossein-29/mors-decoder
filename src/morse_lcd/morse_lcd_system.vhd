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
	signal last_index       : integer range 0 to 7 := 7;

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
				
				
			if state /= IDLE or char_index = 7 then
               	done_counter <= 0;
			end if;
            
		end if;
	 end process;
	 
	 
	 process(clk) 
	 	variable complement_element : std_logic_vector(7 downto 0) := (others => '-');
	 begin
        if rising_edge(clk) then
            case state is
                when IDLE =>
                    if input = '0' then -- button pressed
                        state <= PRESSED;
                        counter <= 0;
								
                    elsif timer_done = '1' and char_index /= 7 then
                        state <= PROCESSING;
                    end if;

                when PRESSED =>
                    counter <= counter + 1;
                    if input = '1' then -- button released
                        state <= RELEASED;
                    end if;

                when RELEASED =>
                    if counter >= DASH_TIME then
                        char_pattern(char_index) <= '1';
                        outleddas <= '1';
                        outleddot <= '0';
                        char_index <= char_index - 1;
								
                    elsif counter >= DOT_TIME then
                        char_pattern(char_index) <= '0';
                        outleddot <= '1';
                        outleddas <= '0';
                        char_index <= char_index - 1;
								
                    else
                        -- ignored (too short)
                        state <= IDLE;
                    end if;
                    
                    if char_index = 0 then
                        state <= PROCESSING;
                    else
                        state <= IDLE;
                        counter <= 0;
                    end if;

                when PROCESSING =>
                    decoded_char <= "11111111";
                    -- Match pattern
                    for i in 0 to 35 loop
                        if char_pattern(7 downto char_index + 1) & complement_element(char_index downto 0) = morse_lut(i) then
                            decoded_char <= std_logic_vector(to_unsigned(i, 8)); -- + to_unsigned(65,8)
                            exit;
                        end if;
                    end loop;
					output <= decoded_char;

                    char_index <= 7;
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Top-level entity that connects Morse decoder to LCD display
entity morse_lcd_system is
    Port ( 
        clk : in std_logic;                           -- 50MHz system clock
        reset : in std_logic;                         -- Reset signal
        morse_input : in std_logic;                   -- Morse code button input
        
        -- LCD interface
        lcd_rs : out std_logic;
        lcd_rw : out std_logic;
        lcd_e  : buffer std_logic;
        lcd_data : out std_logic_vector(7 downto 0);
        
        -- Debug outputs from morse decoder
        outleddot  : out std_logic;
        outleddas  : out std_logic;
        outledsep  : out std_logic;
        state_iden1: out std_logic;
        state_iden2: out std_logic
    );
end morse_lcd_system;

architecture Behavioral of morse_lcd_system is

    -- Morse decoder component
    component morse is
        port(
            clk        : in std_logic;
            input      : in std_logic;
            outleddot  : out std_logic;
            outleddas  : out std_logic;
            outledsep  : out std_logic;
            state_iden1: out std_logic;
            state_iden2: out std_logic;
            output     : out std_logic_vector(7 downto 0);
            counter_o  : out integer
        );
    end component;

    -- Modified LCD controller component
    component lcd_controller is
        Port ( 
            clk : in std_logic;
            Reset : in std_logic;
            char_data : in std_logic_vector(7 downto 0);
            new_char : in std_logic;
            clear_display : in std_logic;
            lcd_rs : out std_logic;
            lcd_rw : out std_logic;
            lcd_e  : buffer std_logic;
            data : out std_logic_vector(7 downto 0)
        );
    end component;

    -- Internal signals
    signal morse_output : std_logic_vector(7 downto 0);
    signal morse_counter : integer;
    signal prev_morse_output : std_logic_vector(7 downto 0) := "11111111";
    signal new_char_pulse : std_logic := '0';
    signal ascii_char : std_logic_vector(7 downto 0);
    signal char_position : integer range 0 to 31 := 0;
    signal clear_lcd : std_logic := '0';

    -- Convert morse index to ASCII
    function morse_to_ascii(morse_index : std_logic_vector(7 downto 0)) return std_logic_vector is
    begin
        case to_integer(unsigned(morse_index)) is
            when 0 to 25 => -- A-Z
                return std_logic_vector(to_unsigned(65 + to_integer(unsigned(morse_index)), 8));
            when 26 to 35 => -- 0-9
                return std_logic_vector(to_unsigned(48 + to_integer(unsigned(morse_index)) - 26, 8));
            when others =>
                return "00100000"; -- Space character
        end case;
    end function;

begin

    -- Instantiate Morse decoder (scaled for 50MHz instead of 100MHz)
    morse_decoder : morse 
        port map (
            clk => clk,
            input => morse_input,
            outleddot => outleddot,
            outleddas => outleddas,
            outledsep => outledsep,
            state_iden1 => state_iden1,
            state_iden2 => state_iden2,
            output => morse_output,
            counter_o => morse_counter
        );

    -- Instantiate LCD controller
    lcd_ctrl : lcd_controller
        port map (
            clk => clk,
            Reset => reset,
            char_data => ascii_char,
            new_char => new_char_pulse,
            clear_display => clear_lcd,
            lcd_rs => lcd_rs,
            lcd_rw => lcd_rw,
            lcd_e => lcd_e,
            data => lcd_data
        );

    -- Process to detect new characters and convert to ASCII
    process(clk, reset)
    begin
        if reset = '0' then
            prev_morse_output <= "11111111";
            new_char_pulse <= '0';
            ascii_char <= "00100000"; -- Space
            char_position <= 0;
            clear_lcd <= '1';
        elsif rising_edge(clk) then
            clear_lcd <= '0';
            new_char_pulse <= '0';
            
            -- Detect when a new character is decoded
            if morse_output /= prev_morse_output and morse_output /= "11111111" then
                ascii_char <= morse_to_ascii(morse_output);
                new_char_pulse <= '1';
                prev_morse_output <= morse_output;
                
                -- Track position for line wrapping
                if char_position >= 31 then
                    char_position <= 0;
                    clear_lcd <= '1';
                else
                    char_position <= char_position + 1;
                end if;
            end if;
        end if;
    end process;

end Behavioral;


-- Modified LCD Controller that accepts character input
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lcd_controller is
    Port ( 
        clk : in std_logic;                           -- 50MHz clock
        Reset : in std_logic;
        char_data : in std_logic_vector(7 downto 0);  -- Character to display
        new_char : in std_logic;                      -- Pulse when new character available
        clear_display : in std_logic;                 -- Clear display signal
        lcd_rs : out std_logic;
        lcd_rw : out std_logic;
        lcd_e  : buffer std_logic;
        data : out std_logic_vector(7 downto 0)
    );
end lcd_controller;

architecture Behavioral of lcd_controller is

    constant IDLE :         std_logic_vector(10 downto 0) := "00000000000";
    constant CLEAR :        std_logic_vector(10 downto 0) := "00000000001";
    constant RETURNCURSOR : std_logic_vector(10 downto 0) := "00000000010";
    constant SETMODE      : std_logic_vector(10 downto 0) := "00000000100";
    constant SWITCHMODE   : std_logic_vector(10 downto 0) := "00000001000";
    constant SHIFT        : std_logic_vector(10 downto 0) := "00000010000";
    constant SETFUNCTION  : std_logic_vector(10 downto 0) := "00000100000";
    constant SETCGRAM     : std_logic_vector(10 downto 0) := "00001000000";
    constant SETDDRAM     : std_logic_vector(10 downto 0) := "00010000000";
    constant READFLAG     : std_logic_vector(10 downto 0) := "00100000000";
    constant WRITERAM     : std_logic_vector(10 downto 0) := "01000000000";
    constant READRAM      : std_logic_vector(10 downto 0) := "10000000000";
    constant WAITCHAR     : std_logic_vector(10 downto 0) := "10000000001";

    -- LCD configuration constants
    constant cur_inc      : std_logic := '1';
    constant cur_dec      : std_logic := '0';
    constant cur_shift    : std_logic := '1';
    constant cur_noshift  : std_logic := '0';
    constant open_display : std_logic := '1';
    constant open_cur     : std_logic := '1';  -- Show cursor
    constant blank_cur    : std_logic := '0';
    constant shift_display: std_logic := '1';
    constant shift_cur    : std_logic := '0';
    constant right_shift  : std_logic := '1';
    constant left_shift   : std_logic := '0';
    constant datawidth8   : std_logic := '1';
    constant datawidth4   : std_logic := '0';
    constant twoline      : std_logic := '1';
    constant oneline      : std_logic := '0';
    constant font5x10     : std_logic := '1';
    constant font5x7      : std_logic := '0';

    signal state : std_logic_vector(10 downto 0);
    signal counter : integer range 0 to 127;
    signal div_counter : integer range 0 to 15;
    signal flag : std_logic;
    signal char_position : integer range 0 to 31 := 0;
    signal current_char : std_logic_vector(7 downto 0);
    signal init_done : std_logic := '0';

    -- Clock divider signals
    signal clk_int: std_logic;
    signal clkcnt: unsigned(15 downto 0);
    constant divcnt: unsigned(15 downto 0) := to_unsigned(40000, 16);
    signal clkdiv: std_logic;
    signal tc_clkcnt: std_logic;

begin

    -- Clock divider process (same as original)
    process(clk,reset)
    begin
        if(reset='0')then
            clkcnt <= (others => '0');
        elsif(clk'event and clk='1')then
            if(clkcnt = unsigned(divcnt))then
                clkcnt <= (others => '0');
            else
                clkcnt <= clkcnt + 1;
            end if;
        end if;
    end process;

    tc_clkcnt <= '1' when clkcnt = unsigned(divcnt) else '0';

    process(tc_clkcnt,reset)
    begin
        if(reset='0')then
            clkdiv <= '0';
        elsif(tc_clkcnt'event and tc_clkcnt='1')then
            clkdiv <= not clkdiv;
        end if;
    end process;

    process(clkdiv,reset)
    begin
        if(reset='0')then
            clk_int <= '0';
        elsif(clkdiv'event and clkdiv='1')then
            clk_int <= not clk_int;
        end if;
    end process;

    process(clkdiv,reset)
    begin
        if(reset='0')then
            lcd_e <= '0';
        elsif(clkdiv'event and clkdiv='0')then
            lcd_e <= not lcd_e;
        end if;
    end process;

    -- Control signals
    lcd_rs <= '1' when state = WRITERAM or state = READRAM else '0';
    lcd_rw <= '0' when state = CLEAR or state = RETURNCURSOR or state = SETMODE or 
                      state = SWITCHMODE or state = SHIFT or state = SETFUNCTION or 
                      state = SETCGRAM or state = SETDDRAM or state = WRITERAM else '1';

    -- Data output
    data <= "00000001" when state = CLEAR else
            "00000010" when state = RETURNCURSOR else
            "000001" & cur_inc & cur_noshift when state = SETMODE else
            "00001" & open_display & open_cur & blank_cur when state = SWITCHMODE else
            "0001" & shift_display & left_shift & "00" when state = SHIFT else
            "001" & datawidth8 & twoline & font5x10 & "00" when state = SETFUNCTION else
            "01000000" when state = SETCGRAM else
            "10000000" when state = SETDDRAM and char_position < 16 else
            "11000000" when state = SETDDRAM and char_position >= 16 else
            current_char when state = WRITERAM else
            "ZZZZZZZZ";

    -- Main state machine
    process(clk_int, Reset)
    begin
        if(Reset='0')then 
            state <= IDLE;
            counter <= 0;
            flag <= '0';
            div_counter <= 0;
            char_position <= 0;
            current_char <= "00100000"; -- Space
            init_done <= '0';
        elsif(clk_int'event and clk_int='1')then 
            case state is
                when IDLE =>
                    if(flag='0')then 
                        state <= SETFUNCTION;
                        flag <= '1';
                        counter <= 0;
                        div_counter <= 0;
                    elsif clear_display = '1' then
                        state <= CLEAR;
                        char_position <= 0;
                    elsif new_char = '1' and init_done = '1' then
                        current_char <= char_data;
                        state <= SETDDRAM;
                    else
                        state <= WAITCHAR;
                    end if;

                when WAITCHAR =>
                    if clear_display = '1' then
                        state <= CLEAR;
                        char_position <= 0;
                    elsif new_char = '1' then
                        current_char <= char_data;
                        state <= SETDDRAM;
                    else
                        state <= WAITCHAR;
                    end if;

                when CLEAR =>
                    state <= SETMODE;
                    char_position <= 0;

                when SETMODE =>
                    state <= WAITCHAR;
                    init_done <= '1';

                when RETURNCURSOR =>
                    state <= WAITCHAR;

                when SWITCHMODE =>
                    state <= CLEAR;

                when SHIFT =>
                    state <= IDLE;

                when SETFUNCTION =>
                    state <= SWITCHMODE;

                when SETCGRAM =>
                    state <= IDLE;

                when SETDDRAM =>
                    state <= WRITERAM;

                when READFLAG =>
                    state <= IDLE;

                when WRITERAM =>
                    if char_position >= 31 then
                        char_position <= 0;
                        state <= CLEAR;
                    else
                        char_position <= char_position + 1;
                        state <= WAITCHAR;
                    end if;

                when READRAM =>
                    state <= IDLE;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

end Behavioral;