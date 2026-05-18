library ieee;
use ieee.NUMERIC_STD.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use std.textio.all;

entity morse_decoder_tb is
end morse_decoder_tb;

architecture TB_ARCHITECTURE of morse_decoder_tb is
	-- Component declaration of the tested unit
	component morse_decoder
	port(
		clk : in STD_LOGIC;
		reset : in STD_LOGIC;
		btn_in : in STD_LOGIC;
		decoded_index : out STD_LOGIC_VECTOR(7 downto 0);
		new_char_ready : out STD_LOGIC );
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal clk : STD_LOGIC := '0';
	signal reset : STD_LOGIC;
	signal btn_in : STD_LOGIC;
	-- Observed signals - signals mapped to the output ports of tested entity
	signal decoded_index : STD_LOGIC_VECTOR(7 downto 0);
	signal new_char_ready : STD_LOGIC;

	-- Clock period for 50 MHz to match the design
	constant clk_period : time := 20 ns;

	-- Timing constants for stimulus generation
	constant DOT_DURATION       : time := 100 ms;
	constant DASH_DURATION      : time := 300 ms;
	constant INTER_SYMBOL_GAP   : time := 100 ms; -- Pause between dits/dahs in a character
	constant END_OF_CHAR_GAP    : time := 250 ms; -- Additional pause to trigger char processing

begin

	-- Unit Under Test port map
	UUT : morse_decoder
		port map (
			clk => clk,
			reset => reset,
			btn_in => btn_in,
			decoded_index => decoded_index,
			new_char_ready => new_char_ready
		);

	-- Clock generation process
	clock_process: process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;

	-- Stimulus process
	stimulus: process
		-- Procedure to simulate pressing the active-high button
		procedure press_button(duration: time) is
		begin
			btn_in <= '1'; -- Button is PRESSED
			wait for duration;
			btn_in <= '0'; -- Button is RELEASED
		end procedure;

		-- Procedure to send a dot symbol
		procedure send_dot is
		begin
			press_button(DOT_DURATION);
			wait for INTER_SYMBOL_GAP;
		end procedure;

		-- Procedure to send a dash symbol
		procedure send_dash is
		begin
			press_button(DASH_DURATION);
			wait for INTER_SYMBOL_GAP;
		end procedure;

		-- Procedure to send a full character pattern and check the result
		procedure send_char(pattern: string; expected_idx: integer) is
			variable msg : string(1 to 200);
		begin
			report "Sending character: " & pattern;
			for i in pattern'range loop
				case pattern(i) is
					when '.' => send_dot;
					when '-' => send_dash;
					when others => null;
				end case;
			end loop;
			
			-- Wait for the end-of-character gap to allow the FSM to process
			wait for END_OF_CHAR_GAP; 
			
			-- Check the output after the FSM has had time to process
			-- The new_char_ready pulse from the decoder triggers the check.
			wait until new_char_ready = '1';
			assert decoded_index = std_logic_vector(to_unsigned(expected_idx, 8))
				report "TEST FAILED for character " & pattern & ". Expected index " & integer'image(expected_idx) &
					   " but got " & integer'image(to_integer(unsigned(decoded_index)))
				severity error;
			
			-- Wait for the pulse to go low
			wait until new_char_ready = '0';
		end procedure;

	begin
		-- Initialize signals
		btn_in <= '0';
		reset <= '1';
		wait for 100 ns;
		reset <= '0';
		wait for 100 ns;

		-- Test case 1: A (.-) -> index 0
		send_char(".-", 0);	
		wait for 1sec;

		-- Test case 2: B (-...) -> index 1
		send_char("-...", 1);
		wait for 1sec;
		
		-- Test case 3: S (...) -> index 18
		send_char("...", 18);
		wait for 1sec;

		-- Test case 4: 3 (...--) -> index 29
		send_char("...--", 29);
		wait for 1sec;
		
		-- Test case 5: SOS sequence
		send_char("...", 18); -- S -> index 18
		wait for 1sec;
		send_char("---", 14); -- O -> index 14 
		wait for 1sec;
		send_char("...", 18); -- S -> index 18	
		wait for 1sec;

		-- Test case 6: Partial character timeout (a single dot should be decoded as 'E')
		report "Testing partial timeout (E)";
		send_dot;
		wait for END_OF_CHAR_GAP;
		wait until new_char_ready = '1';
		assert decoded_index = std_logic_vector(to_unsigned(4, 8)) -- 'E' is index 4
			report "TEST FAILED for partial timeout. Expected E (4)."
			severity error;
		wait until new_char_ready = '0';
		
		-- Test case 7: Invalid short press (should be ignored, no new char ready)
		report "Testing invalid short press";
		press_button(10 ms); -- Much shorter than a dot
		-- The decoder should ignore this and new_char_ready should not pulse.
		-- We just wait a bit to ensure nothing happens.
		wait for 500 ms;
		assert new_char_ready = '0'
			report "TEST FAILED for short press. new_char_ready pulsed when it shouldn't have."
			severity warning;

		report "Simulation Finished.";
		wait;
	end process;

end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_morse_decoder of morse_decoder_tb is
	for TB_ARCHITECTURE
		for UUT : morse_decoder
			use entity work.morse_decoder(behavioral);
		end for;
	end for;
end TESTBENCH_FOR_morse_decoder;