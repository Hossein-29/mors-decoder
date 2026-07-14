library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Top-level structural wrapper.
-- Connects: button input → morse_decoder → ASCII conversion → lcd_controller.
--
-- NOTE (Step 2): The current character-detection process compares successive
-- decoder outputs, which has a known double-character bug (two consecutive
-- identical characters are merged). This is replaced in Step 2 with the
-- new_char_ready pulse signal.
entity morse_top is
    Port (
        clk         : in  std_logic;                    -- 50 MHz system clock
        reset       : in  std_logic;                    -- Active-low system reset
        morse_input : in  std_logic;                    -- Raw button (active-low)
        -- LCD interface (direct connection to HD44780)
        lcd_rs      : out std_logic;
        lcd_rw      : out std_logic;
        lcd_e       : out std_logic;
        lcd_data    : out std_logic_vector(7 downto 0);
        -- LED indicators driven directly by the decoder
        led_dot     : out std_logic;
        led_dash    : out std_logic;
        led_sep     : out std_logic
    );
end morse_top;

architecture Structural of morse_top is

    signal morse_index       : std_logic_vector(7 downto 0);
    signal prev_morse_index  : std_logic_vector(7 downto 0) := X"FF";
    signal new_char_pulse    : std_logic                     := '0';
    signal ascii_char        : std_logic_vector(7 downto 0) := X"20";
    signal clear_lcd         : std_logic                     := '0';
    signal char_count        : integer range 0 to 31         := 0;

    -- Converts a Morse LUT index to ASCII.
    -- 0-25  → 'A'-'Z' (0x41-0x5A)
    -- 26-35 → '0'-'9' (0x30-0x39)
    -- other → '?'     (0x3F)
    function morse_to_ascii(idx : std_logic_vector(7 downto 0))
        return std_logic_vector is
        variable n : integer;
    begin
        n := to_integer(unsigned(idx));
        if n <= 25 then
            return std_logic_vector(to_unsigned(65 + n, 8));
        elsif n <= 35 then
            return std_logic_vector(to_unsigned(48 + (n - 26), 8));
        else
            return X"3F";
        end if;
    end function;

begin

    -- -------------------------------------------------------------------------
    -- Morse decoder
    -- state_iden1/2 are debug-only; connected to open pending removal in Step 2.
    -- -------------------------------------------------------------------------
    u_decoder : entity work.morse_decoder
        port map (
            clk           => clk,
            btn_in        => morse_input,
            outleddot     => led_dot,
            outleddas     => led_dash,
            outledsep     => led_sep,
            state_iden1   => open,
            state_iden2   => open,
            decoded_index => morse_index
        );

    -- -------------------------------------------------------------------------
    -- LCD controller
    -- -------------------------------------------------------------------------
    u_lcd : entity work.lcd_controller
        port map (
            clk           => clk,
            Reset         => reset,
            char_data     => ascii_char,
            new_char      => new_char_pulse,
            clear_display => clear_lcd,
            lcd_rs        => lcd_rs,
            lcd_rw        => lcd_rw,
            lcd_e         => lcd_e,
            data          => lcd_data
        );

    -- -------------------------------------------------------------------------
    -- Character detection: edge-detect on decoder output, convert to ASCII.
    -- BUG (to be fixed in Step 2): two identical consecutive characters are
    -- merged because detection relies on value change, not on a ready pulse.
    -- -------------------------------------------------------------------------
    p_char_detect : process(clk, reset)
    begin
        if reset = '0' then
            prev_morse_index <= X"FF";
            new_char_pulse   <= '0';
            ascii_char       <= X"20";
            clear_lcd        <= '1';
            char_count       <= 0;
        elsif rising_edge(clk) then
            clear_lcd      <= '0';
            new_char_pulse <= '0';

            if morse_index /= prev_morse_index and morse_index /= X"FF" then
                ascii_char       <= morse_to_ascii(morse_index);
                new_char_pulse   <= '1';
                prev_morse_index <= morse_index;

                if char_count >= 31 then
                    char_count <= 0;
                    clear_lcd  <= '1';
                else
                    char_count <= char_count + 1;
                end if;
            end if;
        end if;
    end process;

end Structural;
