library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Morse code decoder.
-- Classifies button press durations as dots/dashes, accumulates up to 8
-- symbols, then matches against a 36-entry LUT and outputs the index.
-- Active-low button convention: btn_in = '0' means pressed.
entity morse_decoder is
    port (
        clk           : in  std_logic;                    -- 100 MHz system clock
        btn_in        : in  std_logic;                    -- Button input (active-low)
        outleddot     : out std_logic;                    -- Asserted when a dot is accepted
        outleddas     : out std_logic;                    -- Asserted when a dash is accepted
        outledsep     : out std_logic;                    -- High when button is released
        state_iden1   : out std_logic;                    -- FSM state bit 0 (debug)
        state_iden2   : out std_logic;                    -- FSM state bit 1 (debug)
        decoded_index : out std_logic_vector(7 downto 0)  -- LUT index; X"FF" = no match
    );
end entity;

architecture Behavioral of morse_decoder is

    -- Timing thresholds (clock cycles at 100 MHz)
    constant DOT_TIME  : integer := 20;   -- 200 ns minimum dot duration
    constant DASH_TIME : integer := 40;   -- 400 ns minimum dash duration
    constant IDLE_TIME : integer := 80;   -- 800 ns inter-character silence

    type state_type is (IDLE, PRESSED, RELEASED, PROCESSING);
    signal state : state_type := IDLE;

    signal char_index   : integer range 0 to 7 := 7;
    signal symbol_count : integer range 0 to 8 := 0;
    signal char_pattern : std_logic_vector(7 downto 0) := (others => '0');
    signal counter      : integer := 0;
    signal done_counter : integer := 0;
    signal timer_done   : std_logic := '0';

    -- Morse LUT: '0' = dot, '1' = dash, '-' = unused padding.
    -- Index 0-25 = A-Z, index 26-35 = 0-9.
    type morse_rom is array (0 to 35) of std_logic_vector(7 downto 0);
    constant MORSE_LUT : morse_rom := (
        "01------",  -- A  .-       0
        "1000----",  -- B  -...     1
        "1010----",  -- C  -.-.     2
        "100-----",  -- D  -..      3
        "0-------",  -- E  .        4
        "0010----",  -- F  ..-.     5
        "110-----",  -- G  --.      6
        "0000----",  -- H  ....     7
        "00------",  -- I  ..       8
        "0111----",  -- J  .---     9
        "101-----",  -- K  -.-      10
        "0100----",  -- L  .-..     11
        "11------",  -- M  --       12
        "10------",  -- N  -.       13
        "111-----",  -- O  ---      14
        "0110----",  -- P  .--.     15
        "1101----",  -- Q  --.-     16
        "010-----",  -- R  .-.      17
        "000-----",  -- S  ...      18
        "1-------",  -- T  -        19
        "001-----",  -- U  ..-      20
        "0001----",  -- V  ...-     21
        "011-----",  -- W  .--      22
        "1001----",  -- X  -..-     23
        "1011----",  -- Y  -.--     24
        "1100----",  -- Z  --..     25
        "11111---",  -- 0  -----    26
        "01111---",  -- 1  .----    27
        "00111---",  -- 2  ..---    28
        "00011---",  -- 3  ...--    29
        "00001---",  -- 4  ....-    30
        "00000---",  -- 5  .....    31
        "10000---",  -- 6  -....    32
        "11000---",  -- 7  --...    33
        "11100---",  -- 8  ---..    34
        "11110---"   -- 9  ----.    35
    );

begin

    -- -------------------------------------------------------------------------
    -- Timer: counts consecutive IDLE cycles; asserts timer_done at IDLE_TIME.
    -- Resets whenever the FSM leaves IDLE or the pattern buffer is empty.
    -- -------------------------------------------------------------------------
    p_timer : process(clk)
    begin
        if rising_edge(clk) then
            if done_counter = IDLE_TIME then
                timer_done   <= '1';
            elsif state = IDLE then
                done_counter <= done_counter + 1;
                timer_done   <= '0';
            end if;

            if state /= IDLE or symbol_count = 0 then
                done_counter <= 0;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- Main FSM
    -- -------------------------------------------------------------------------
    p_fsm : process(clk)
        variable decoded_value   : std_logic_vector(7 downto 0);
        variable lookup_pattern  : std_logic_vector(7 downto 0);
        variable received_symbol : std_logic;
        variable valid_symbol    : boolean;
    begin
        if rising_edge(clk) then
            case state is

                when IDLE =>
                    outleddot <= '0';
                    outleddas <= '0';
                    if btn_in = '0' then
                        state   <= PRESSED;
                        counter <= 0;
                    elsif timer_done = '1' and symbol_count /= 0 then
                        state <= PROCESSING;
                    end if;

                when PRESSED =>
                    outleddot <= '0';
                    outleddas <= '0';
                    counter   <= counter + 1;
                    if btn_in = '1' then
                        state <= RELEASED;
                    end if;

                when RELEASED =>
                    valid_symbol := false;

                    if counter >= DASH_TIME then
                        received_symbol := '1';
                        valid_symbol    := true;
                        outleddas       <= '1';
                        outleddot       <= '0';
                    elsif counter >= DOT_TIME then
                        received_symbol := '0';
                        valid_symbol    := true;
                        outleddot       <= '1';
                        outleddas       <= '0';
                    else
                        outleddot <= '0';
                        outleddas <= '0';
                        state     <= IDLE;
                    end if;

                    if valid_symbol then
                        char_pattern(char_index) <= received_symbol;
                        if symbol_count = 7 then
                            symbol_count <= 8;
                            state        <= PROCESSING;
                        else
                            symbol_count <= symbol_count + 1;
                            char_index   <= char_index - 1;
                            state        <= IDLE;
                        end if;
                    end if;

                    counter <= 0;

                when PROCESSING =>
                    outleddot <= '0';
                    outleddas <= '0';

                    -- Build '-'-padded lookup key from accumulated pattern
                    decoded_value  := X"FF";
                    lookup_pattern := (others => '-');
                    for bit_idx in 0 to 7 loop
                        if bit_idx >= 8 - symbol_count then
                            lookup_pattern(bit_idx) := char_pattern(bit_idx);
                        end if;
                    end loop;

                    for i in 0 to 35 loop
                        if lookup_pattern = MORSE_LUT(i) then
                            decoded_value := std_logic_vector(to_unsigned(i, 8));
                            exit;
                        end if;
                    end loop;

                    decoded_index <= decoded_value;

                    char_index   <= 7;
                    symbol_count <= 0;
                    char_pattern <= (others => '0');
                    state        <= IDLE;

            end case;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- State identifier (combinational, Gray-coded)
    -- -------------------------------------------------------------------------
    p_state_iden : process(state)
    begin
        case state is
            when IDLE       => state_iden1 <= '0'; state_iden2 <= '0';
            when PRESSED    => state_iden1 <= '1'; state_iden2 <= '0';
            when RELEASED   => state_iden1 <= '0'; state_iden2 <= '1';
            when PROCESSING => state_iden1 <= '1'; state_iden2 <= '1';
        end case;
    end process;

    outledsep <= not btn_in;

end architecture;
