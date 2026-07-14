library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- HD44780-compatible 16x2 LCD controller.
-- Initialises the display on reset, then waits for character data.
-- Characters are written sequentially across both lines (32 positions);
-- the display clears automatically after position 31.
entity lcd_controller is
    Port (
        clk           : in  std_logic;                    -- 50 MHz system clock
        Reset         : in  std_logic;                    -- Active-low reset
        char_data     : in  std_logic_vector(7 downto 0); -- ASCII character to write
        new_char      : in  std_logic;                    -- Pulse high for 1 cycle to latch char
        clear_display : in  std_logic;                    -- Pulse high to clear the screen
        lcd_rs        : out std_logic;
        lcd_rw        : out std_logic;
        lcd_e         : out std_logic;
        data          : out std_logic_vector(7 downto 0)
    );
end lcd_controller;

architecture Behavioral of lcd_controller is

    -- One-hot-like state encoding (std_logic_vector for direct comparison in
    -- the combinational lcd_rs / lcd_rw / data outputs below).
    constant ST_IDLE        : std_logic_vector(10 downto 0) := "00000000000";
    constant ST_CLEAR       : std_logic_vector(10 downto 0) := "00000000001";
    constant ST_RETURNCUR   : std_logic_vector(10 downto 0) := "00000000010";
    constant ST_SETMODE     : std_logic_vector(10 downto 0) := "00000000100";
    constant ST_SWITCHMODE  : std_logic_vector(10 downto 0) := "00000001000";
    constant ST_SHIFT       : std_logic_vector(10 downto 0) := "00000010000";
    constant ST_SETFUNCTION : std_logic_vector(10 downto 0) := "00000100000";
    constant ST_SETCGRAM    : std_logic_vector(10 downto 0) := "00001000000";
    constant ST_SETDDRAM    : std_logic_vector(10 downto 0) := "00010000000";
    constant ST_READFLAG    : std_logic_vector(10 downto 0) := "00100000000";
    constant ST_WRITERAM    : std_logic_vector(10 downto 0) := "01000000000";
    constant ST_READRAM     : std_logic_vector(10 downto 0) := "10000000000";
    constant ST_WAITCHAR    : std_logic_vector(10 downto 0) := "10000000001";

    -- HD44780 configuration bits
    constant CUR_INC      : std_logic := '1';  -- cursor moves right after write
    constant CUR_NOSHIFT  : std_logic := '0';  -- display does not shift on write
    constant DISP_ON      : std_logic := '1';  -- display on
    constant CURSOR_ON    : std_logic := '1';  -- cursor visible
    constant BLINK_OFF    : std_logic := '0';  -- cursor does not blink
    constant SHIFT_DISP   : std_logic := '1';  -- shift display (used in SHIFT state)
    constant SHIFT_LEFT   : std_logic := '0';  -- shift direction left
    constant BUS_8BIT     : std_logic := '1';  -- 8-bit data bus
    constant TWO_LINES    : std_logic := '1';  -- 2-line display
    constant FONT_5X10    : std_logic := '1';  -- 5x10 dot character font

    signal state        : std_logic_vector(10 downto 0) := ST_IDLE;
    signal char_pos     : integer range 0 to 31         := 0;
    signal current_char : std_logic_vector(7 downto 0)  := X"20"; -- space
    signal flag         : std_logic                      := '0';
    signal init_done    : std_logic                      := '0';

    -- Clock divider chain: 50 MHz → clk_int ≈ 10 kHz (100 µs period).
    -- This gives the HD44780 sufficient hold time on each command.
    signal clkcnt    : unsigned(15 downto 0) := (others => '0');
    constant DIVCNT  : unsigned(15 downto 0) := to_unsigned(40000, 16);
    signal tc_clkcnt : std_logic             := '0';
    signal clkdiv    : std_logic             := '0';
    signal clk_int   : std_logic             := '0';
    signal lcd_e_int : std_logic             := '0'; -- internal reg; drives lcd_e output

begin

    -- Route internal register to output (avoids deprecated 'buffer' port mode)
    lcd_e <= lcd_e_int;

    -- -------------------------------------------------------------------------
    -- Clock divider stage 1: divide 50 MHz by 40001 → ~1.25 kHz
    -- -------------------------------------------------------------------------
    p_clk_div : process(clk, Reset)
    begin
        if Reset = '0' then
            clkcnt <= (others => '0');
        elsif rising_edge(clk) then
            if clkcnt = DIVCNT then
                clkcnt <= (others => '0');
            else
                clkcnt <= clkcnt + 1;
            end if;
        end if;
    end process;

    tc_clkcnt <= '1' when clkcnt = DIVCNT else '0';

    -- Stage 2: divide tc_clkcnt by 2 → ~625 Hz
    p_clkdiv : process(tc_clkcnt, Reset)
    begin
        if Reset = '0' then
            clkdiv <= '0';
        elsif rising_edge(tc_clkcnt) then
            clkdiv <= not clkdiv;
        end if;
    end process;

    -- Stage 3: divide clkdiv by 2 → clk_int ≈ 312 Hz (period ≈ 3.2 ms)
    p_clk_int : process(clkdiv, Reset)
    begin
        if Reset = '0' then
            clk_int <= '0';
        elsif rising_edge(clkdiv) then
            clk_int <= not clk_int;
        end if;
    end process;

    -- lcd_e toggles on the falling edge of clkdiv (half-cycle offset from
    -- clk_int) to satisfy HD44780 data-setup and hold-time requirements.
    p_lcd_e : process(clkdiv, Reset)
    begin
        if Reset = '0' then
            lcd_e_int <= '0';
        elsif falling_edge(clkdiv) then
            lcd_e_int <= not lcd_e_int;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- Combinational output: lcd_rs, lcd_rw, data
    -- -------------------------------------------------------------------------
    lcd_rs <= '1' when state = ST_WRITERAM or state = ST_READRAM else '0';

    lcd_rw <= '0' when state = ST_CLEAR      or state = ST_RETURNCUR   or
                       state = ST_SETMODE    or state = ST_SWITCHMODE   or
                       state = ST_SHIFT      or state = ST_SETFUNCTION  or
                       state = ST_SETCGRAM   or state = ST_SETDDRAM     or
                       state = ST_WRITERAM
              else '1';

    data <=
        X"01"                                                when state = ST_CLEAR       else
        X"02"                                                when state = ST_RETURNCUR   else
        "000001" & CUR_INC   & CUR_NOSHIFT                  when state = ST_SETMODE     else
        "00001"  & DISP_ON   & CURSOR_ON & BLINK_OFF        when state = ST_SWITCHMODE  else
        "0001"   & SHIFT_DISP & SHIFT_LEFT & "00"           when state = ST_SHIFT       else
        "001"    & BUS_8BIT  & TWO_LINES  & FONT_5X10 & "00" when state = ST_SETFUNCTION else
        X"40"                                                when state = ST_SETCGRAM    else
        X"80" when state = ST_SETDDRAM and char_pos < 16    else  -- line 1 base address
        X"C0" when state = ST_SETDDRAM and char_pos >= 16   else  -- line 2 base address
        current_char                                         when state = ST_WRITERAM    else
        "ZZZZZZZZ";

    -- -------------------------------------------------------------------------
    -- Main FSM (clocked by the slow clk_int)
    -- -------------------------------------------------------------------------
    p_fsm : process(clk_int, Reset)
    begin
        if Reset = '0' then
            state        <= ST_IDLE;
            char_pos     <= 0;
            flag         <= '0';
            init_done    <= '0';
            current_char <= X"20";
        elsif rising_edge(clk_int) then
            case state is

                when ST_IDLE =>
                    if flag = '0' then
                        -- First power-on: run the initialisation sequence
                        state <= ST_SETFUNCTION;
                        flag  <= '1';
                    elsif clear_display = '1' then
                        state    <= ST_CLEAR;
                        char_pos <= 0;
                    elsif new_char = '1' and init_done = '1' then
                        current_char <= char_data;
                        state        <= ST_SETDDRAM;
                    else
                        state <= ST_WAITCHAR;
                    end if;

                when ST_WAITCHAR =>
                    if clear_display = '1' then
                        state    <= ST_CLEAR;
                        char_pos <= 0;
                    elsif new_char = '1' then
                        current_char <= char_data;
                        state        <= ST_SETDDRAM;
                    else
                        state <= ST_WAITCHAR;
                    end if;

                when ST_CLEAR =>
                    state    <= ST_SETMODE;
                    char_pos <= 0;

                when ST_SETMODE =>
                    init_done <= '1';
                    state     <= ST_WAITCHAR;

                when ST_RETURNCUR =>
                    state <= ST_WAITCHAR;

                when ST_SWITCHMODE =>
                    state <= ST_CLEAR;

                when ST_SHIFT =>
                    state <= ST_IDLE;

                when ST_SETFUNCTION =>
                    state <= ST_SWITCHMODE;

                when ST_SETCGRAM =>
                    state <= ST_IDLE;

                when ST_SETDDRAM =>
                    state <= ST_WRITERAM;

                when ST_READFLAG =>
                    state <= ST_IDLE;

                when ST_WRITERAM =>
                    if char_pos >= 31 then
                        char_pos <= 0;
                        state    <= ST_CLEAR;
                    else
                        char_pos <= char_pos + 1;
                        state    <= ST_WAITCHAR;
                    end if;

                when ST_READRAM =>
                    state <= ST_IDLE;

                when others =>
                    state <= ST_IDLE;

            end case;
        end if;
    end process;

end Behavioral;
