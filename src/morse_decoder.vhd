library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Morse code decoder.
--
-- Classifies button press durations as dots or dashes, accumulates up to 8
-- symbols per character, then matches the pattern against a 36-entry LUT
-- (A-Z, 0-9) and outputs the LUT index on decoded_index together with a
-- single-cycle new_char_ready pulse.
--
-- Button convention : btn_in = '1' → pressed, '0' → released (active-high).
-- Reset convention  : reset  = '1' → synchronous reset (active-high).
entity morse_decoder is
    port (
        clk           : in  std_logic;                    -- System clock (100 MHz)
        reset         : in  std_logic;                    -- Active-high synchronous reset
        btn_in        : in  std_logic;                    -- Button input (active-high)
        decoded_index : out std_logic_vector(7 downto 0); -- LUT index; X"FF" = no match
        new_char_ready: out std_logic                     -- 1-cycle pulse when index is valid
    );
end entity;

architecture Behavioral of morse_decoder is

    -- -------------------------------------------------------------------------
    -- Timing thresholds in clock cycles (50 MHz → 1 cycle = 20 ns)
    -- These will be replaced by generics in Step 3.
    -- At 50 MHz, 1 ms = 50,000 cycles.
    --
    --   DOT_TIME  : minimum press for a dot   (60 ms)
    --   DASH_TIME : minimum press for a dash  (180 ms)
    --   IDLE_TIME : silence duration to trigger inter-character decode (175 ms).
    --               Must sit between inter-symbol gap (100 ms) and the
    --               end-of-character gap (250 ms) used by the testbench.
    -- -------------------------------------------------------------------------
    constant DOT_TIME  : integer := 3_000_000;  -- 60 ms  @ 50 MHz
    constant DASH_TIME : integer := 9_000_000;  -- 180 ms @ 50 MHz
    constant IDLE_TIME : integer := 8_750_000;  -- 175 ms @ 50 MHz

    -- -------------------------------------------------------------------------
    -- FSM
    -- -------------------------------------------------------------------------
    type state_type is (IDLE, PRESSED, RELEASED, PROCESSING);
    signal state : state_type := IDLE;

    -- -------------------------------------------------------------------------
    -- Datapath registers
    -- -------------------------------------------------------------------------
    -- char_pattern accumulates dots/dashes MSB-first (char_index starts at 7
    -- and decrements with each accepted symbol).
    signal char_index   : integer range 0 to 7 := 7;
    signal symbol_count : integer range 0 to 8 := 0;
    signal char_pattern : std_logic_vector(7 downto 0) := (others => '0');

    -- counter measures how long the button is held down (in clock cycles).
    signal counter      : integer := 0;

    -- done_counter counts consecutive IDLE cycles; timer_done flags expiry.
    signal done_counter : integer := 0;
    signal timer_done   : std_logic := '0';

    -- -------------------------------------------------------------------------
    -- Morse LUT: '0' = dot, '1' = dash, '-' = unused padding.
    -- Index 0-25 = A-Z, 26-35 = 0-9.
    -- -------------------------------------------------------------------------
    type morse_rom is array (0 to 35) of std_logic_vector(7 downto 0);
    constant MORSE_LUT : morse_rom := (
        "01------",  -- A  .-        0
        "1000----",  -- B  -...      1
        "1010----",  -- C  -.-.      2
        "100-----",  -- D  -..       3
        "0-------",  -- E  .         4
        "0010----",  -- F  ..-.      5
        "110-----",  -- G  --.       6
        "0000----",  -- H  ....      7
        "00------",  -- I  ..        8
        "0111----",  -- J  .---      9
        "101-----",  -- K  -.-       10
        "0100----",  -- L  .-..      11
        "11------",  -- M  --        12
        "10------",  -- N  -.        13
        "111-----",  -- O  ---       14
        "0110----",  -- P  .--.      15
        "1101----",  -- Q  --.-      16
        "010-----",  -- R  .-.       17
        "000-----",  -- S  ...       18
        "1-------",  -- T  -         19
        "001-----",  -- U  ..-       20
        "0001----",  -- V  ...-      21
        "011-----",  -- W  .--       22
        "1001----",  -- X  -..-      23
        "1011----",  -- Y  -.--      24
        "1100----",  -- Z  --..      25
        "11111---",  -- 0  -----     26
        "01111---",  -- 1  .----     27
        "00111---",  -- 2  ..---     28
        "00011---",  -- 3  ...--     29
        "00001---",  -- 4  ....-     30
        "00000---",  -- 5  .....     31
        "10000---",  -- 6  -....     32
        "11000---",  -- 7  --...     33
        "11100---",  -- 8  ---..     34
        "11110---"   -- 9  ----.     35
    );

begin

    -- =========================================================================
    -- Process 1: inter-character silence timer
    --
    -- Counts consecutive cycles the FSM spends in IDLE while at least one
    -- symbol has been received.  Resets to zero the moment the FSM leaves
    -- IDLE or the pattern buffer is empty.
    -- =========================================================================
    p_timer : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                done_counter <= 0;
                timer_done   <= '0';
            elsif state /= IDLE or symbol_count = 0 then
                -- Not waiting: keep counter zeroed
                done_counter <= 0;
                timer_done   <= '0';
            elsif done_counter = IDLE_TIME then
                -- Threshold reached: assert flag, hold counter
                timer_done   <= '1';
            else
                -- Counting up
                done_counter <= done_counter + 1;
                timer_done   <= '0';
            end if;
        end if;
    end process;

    -- =========================================================================
    -- Process 2: main FSM + datapath
    -- =========================================================================
    p_fsm : process(clk)
        variable decoded_value  : std_logic_vector(7 downto 0);
        variable lookup_pattern : std_logic_vector(7 downto 0);
        variable recv_sym       : std_logic;
        variable sym_valid      : boolean;
    begin
        if rising_edge(clk) then
            -- Default: pulse outputs low every cycle unless explicitly set below
            new_char_ready <= '0';

            if reset = '1' then
                -- Synchronous reset: return all state to power-on values
                state         <= IDLE;
                char_index    <= 7;
                symbol_count  <= 0;
                char_pattern  <= (others => '0');
                counter       <= 0;
                decoded_index <= X"FF";

            else
                case state is

                    -- ---------------------------------------------------------
                    when IDLE =>
                        if btn_in = '1' then
                            -- Button pressed: start timing
                            state   <= PRESSED;
                            counter <= 0;
                        elsif timer_done = '1' and symbol_count /= 0 then
                            -- Silence timeout with buffered symbols: decode now
                            state <= PROCESSING;
                        end if;

                    -- ---------------------------------------------------------
                    when PRESSED =>
                        counter <= counter + 1;
                        if btn_in = '0' then
                            -- Button released: classify the press
                            state <= RELEASED;
                        end if;

                    -- ---------------------------------------------------------
                    when RELEASED =>
                        sym_valid := false;

                        if counter >= DASH_TIME then
                            recv_sym  := '1';   -- dash
                            sym_valid := true;
                        elsif counter >= DOT_TIME then
                            recv_sym  := '0';   -- dot
                            sym_valid := true;
                        -- else: press too short → ignore, fall back to IDLE
                        end if;

                        if sym_valid then
                            char_pattern(char_index) <= recv_sym;
                            if symbol_count = 7 then
                                -- Buffer full (8 symbols): decode immediately
                                symbol_count <= 8;
                                state        <= PROCESSING;
                            else
                                symbol_count <= symbol_count + 1;
                                char_index   <= char_index - 1;
                                state        <= IDLE;
                            end if;
                        else
                            state <= IDLE;
                        end if;

                        counter <= 0;

                    -- ---------------------------------------------------------
                    when PROCESSING =>
                        -- Build the '-'-padded lookup key from the accumulated
                        -- pattern and search the LUT with a linear scan.
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

                        -- Write result and raise the ready pulse for one cycle
                        decoded_index  <= decoded_value;
                        new_char_ready <= '1';

                        -- Clear the pattern buffer and return to IDLE
                        char_index   <= 7;
                        symbol_count <= 0;
                        char_pattern <= (others => '0');
                        state        <= IDLE;

                end case;
            end if;
        end if;
    end process;

end architecture;
