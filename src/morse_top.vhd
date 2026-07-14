library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Top-level structural wrapper.
--
-- Signal path:
--   morse_input → morse_decoder → (ASCII conversion) → lcd_controller
--
-- The double-character bug present in Step 1 is eliminated here: the
-- p_char_detect process is now driven entirely by the new_char_ready pulse
-- emitted by morse_decoder.  Each rising edge of new_char_ready represents
-- exactly one decoded character, so two identical consecutive characters
-- (e.g. 'S', 'O', 'S') are always captured as distinct events.
entity morse_top is
    Port (
        clk         : in  std_logic;                    -- 50 MHz system clock
        reset       : in  std_logic;                    -- Active-high system reset
        morse_input : in  std_logic;                    -- Raw button (active-low)
        -- HD44780 LCD interface
        lcd_rs      : out std_logic;
        lcd_rw      : out std_logic;
        lcd_e       : out std_logic;
        lcd_data    : out std_logic_vector(7 downto 0)
    );
end morse_top;

architecture Structural of morse_top is

    -- Decoder outputs
    signal morse_index    : std_logic_vector(7 downto 0);
    signal new_char_ready : std_logic;

    -- LCD driver inputs
    signal ascii_char  : std_logic_vector(7 downto 0) := X"20"; -- space
    signal new_char_lc : std_logic                     := '0';
    signal clear_lcd   : std_logic                     := '0';
    signal char_count  : integer range 0 to 31         := 0;

    -- lcd_controller uses active-low reset; derive a static signal
    signal lcd_reset_n  : std_logic;
    -- Physical button is active-low (pull-down); invert to active-high for decoder
    signal btn_active_h : std_logic;

    -- -------------------------------------------------------------------------
    -- Converts a Morse LUT index (0-35) to its ASCII code.
    --   0-25  → 'A'-'Z'  (0x41-0x5A)
    --   26-35 → '0'-'9'  (0x30-0x39)
    --   other → '?'      (0x3F) — covers X"FF" no-match sentinel
    -- -------------------------------------------------------------------------
    function morse_to_ascii(idx : std_logic_vector(7 downto 0))
        return std_logic_vector is
        variable n : integer;
    begin
        n := to_integer(unsigned(idx));
        if n <= 25 then
            return std_logic_vector(to_unsigned(65 + n, 8));       -- A-Z
        elsif n <= 35 then
            return std_logic_vector(to_unsigned(48 + (n - 26), 8)); -- 0-9
        else
            return X"3F";                                           -- '?'
        end if;
    end function;

begin

    -- Invert the active-high system reset for the active-low LCD controller
    lcd_reset_n  <= not reset;
    -- Invert active-low board button to active-high for the decoder
    btn_active_h <= not morse_input;

    -- =========================================================================
    -- Morse decoder
    -- =========================================================================
    u_decoder : entity work.morse_decoder
        port map (
            clk            => clk,
            reset          => reset,
            btn_in         => btn_active_h,
            decoded_index  => morse_index,
            new_char_ready => new_char_ready
        );

    -- =========================================================================
    -- LCD controller
    -- =========================================================================
    u_lcd : entity work.lcd_controller
        port map (
            clk           => clk,
            Reset         => lcd_reset_n, -- lcd_controller uses active-LOW reset
            char_data     => ascii_char,
            new_char      => new_char_lc,
            clear_display => clear_lcd,
            lcd_rs        => lcd_rs,
            lcd_rw        => lcd_rw,
            lcd_e         => lcd_e,
            data          => lcd_data
        );

    -- =========================================================================
    -- Character detect & ASCII conversion
    --
    -- Fires exactly once per new_char_ready pulse.  Because new_char_ready is
    -- a single-cycle pulse from the decoder, consecutive identical characters
    -- (e.g. "SS" in SOS) each generate their own independent pulse and are
    -- forwarded to the LCD as separate writes.
    -- =========================================================================
    p_char_detect : process(clk)
    begin
        if rising_edge(clk) then
            -- Defaults: pulses are off unless set below
            new_char_lc <= '0';
            clear_lcd   <= '0';

            if reset = '1' then
                ascii_char  <= X"20";
                new_char_lc <= '0';
                clear_lcd   <= '0';
                char_count  <= 0;
            elsif new_char_ready = '1' then
                ascii_char  <= morse_to_ascii(morse_index);
                new_char_lc <= '1';

                -- Auto-wrap: clear display and restart after 32 characters
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
