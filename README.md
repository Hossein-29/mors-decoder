# Morse Code Decoder — FPGA Project

**Phase 3 Implementation** | VHDL | GHDL Simulation | HD44780 LCD Output

A fully synthesizable Morse code decoder targeting a 50 MHz FPGA. Accepts physical button presses, classifies them as dots and dashes, decodes accumulated symbols against a 36-entry lookup table (A–Z, 0–9), and drives an HD44780-compatible 16×2 LCD with the decoded ASCII characters.

---

## Table of Contents

1. [Project Structure](#project-structure)
2. [System Architecture Overview](#system-architecture-overview)
3. [Module Details](#module-details)
   - [morse_decoder.vhd](#morse_decodervhd)
   - [lcd_controller.vhd](#lcd_controllervhd)
   - [morse_top.vhd](#morse_topvhd)
4. [Simulation & Testing](#simulation--testing)
   - [Compilation Order](#compilation-order)
   - [Running the Testbench](#running-the-testbench)
   - [GTKWave Signal Guide](#gtkwave-signal-guide)
5. [Legacy Files](#legacy-files)

---

## Project Structure

```
mors-decoder/
├── src/
│   ├── morse_decoder.vhd      ← Phase 3: FSM decoder with reset + new_char_ready
│   ├── lcd_controller.vhd     ← Phase 3: extracted HD44780 LCD controller
│   ├── morse_top.vhd          ← Phase 3: structural top-level
│   ├── morse/
│   │   └── morse.vhd          ← Legacy standalone decoder (backward compat)
│   └── lcd/
│       └── lcd.vhd            ← Original third-party LCD reference driver
├── testbench/
│   ├── morse/
│   │   └── morse_tb.vhd       ← Legacy testbench (100 MHz timing)
│   └── morse_lcd/
│       └── morse_decoder_tb.vhd  ← Phase 3 testbench (50 MHz, human-scale timing)
├── docs/                      ← Project PDF documentation
└── legacy/                    ← Original Active-HDL / Xilinx ISE project files
```

---

## System Architecture Overview

The Phase 3 design uses a three-module hierarchy. Each module has a single responsibility; no logic is shared across boundaries.

```
                     ┌──────────────────────────────────────────────────┐
                     │                  morse_top.vhd                   │
                     │                                                  │
  morse_input ──┐    │  ┌─────────────────┐      ┌──────────────────┐  │
  (active-low)  │    │  │  morse_decoder  │      │  lcd_controller  │  │──► lcd_rs
                └(¬)─┼─►│                 │      │                  │  │──► lcd_rw
                     │  │  btn_in         │      │  char_data       │  │──► lcd_e
  clk ───────────────┼─►│  clk            ├─────►│  new_char        │  │──► lcd_data
  reset ─────────────┼─►│  reset          │      │  clear_display   │  │
              └──(¬)─┼─►│                 │      │  clk             │  │
                     │  │  decoded_index ─┼──┐   │  Reset (act-low) │  │
                     │  │  new_char_ready─┼──┤   └──────────────────┘  │
                     │  └─────────────────┘  │                         │
                     │                       │  p_char_detect           │
                     │                       │  (ASCII conversion +     │
                     │                       │   display management)    │
                     └───────────────────────┴──────────────────────────┘
```

**Signal interfaces between modules:**

| Signal | Direction | Width | Description |
|---|---|---|---|
| `clk` | top → decoder / LCD | 1 | 50 MHz system clock |
| `reset` | top → decoder | 1 | Active-high synchronous reset |
| `btn_in` | top → decoder | 1 | Active-high (inverted from active-low board button) |
| `decoded_index` | decoder → top | 8 | LUT index 0–35; `X"FF"` = no match |
| `new_char_ready` | decoder → top | 1 | Single-cycle pulse when `decoded_index` is valid |
| `char_data` | top → LCD | 8 | ASCII character to write |
| `new_char` | top → LCD | 1 | Single-cycle write strobe |
| `clear_display` | top → LCD | 1 | Single-cycle clear strobe |
| `Reset` | top → LCD | 1 | Active-low (inverted from system reset at boundary) |

---

## Module Details

### `morse_decoder.vhd`

**Entity interface** — matches `morse_decoder_tb.vhd` exactly:

```vhdl
entity morse_decoder is
    port (
        clk           : in  std_logic;                    -- 50 MHz system clock
        reset         : in  std_logic;                    -- Active-high synchronous reset
        btn_in        : in  std_logic;                    -- Button input (active-high)
        decoded_index : out std_logic_vector(7 downto 0); -- LUT index; X"FF" = no match
        new_char_ready: out std_logic                     -- 1-cycle pulse when index is valid
    );
end entity;
```

#### Four-State FSM

```
         btn_in='1'              btn_in='0'
  IDLE ────────────► PRESSED ────────────► RELEASED
   ▲                                           │
   │  symbol stored (symbol_count < 8)         │  classify press:
   └───────────────────────────────────────────┘  dot / dash / too-short
   │
   │  timer_done='1' AND symbol_count > 0
   └──────────────────────► PROCESSING ─────────► IDLE
                             (LUT lookup +
                              new_char_ready='1')
```

| State | Behaviour |
|---|---|
| **IDLE** | Waits for a button press or for the inter-character silence timer to expire. If the timer fires and at least one symbol is buffered, transitions to PROCESSING. |
| **PRESSED** | Counts clock cycles in `counter` while `btn_in = '1'`. Transitions to RELEASED when the button is released. |
| **RELEASED** | Classifies the press by duration: ≥ `DASH_TIME` → dash (`'1'`), ≥ `DOT_TIME` → dot (`'0'`), shorter → ignored. A valid symbol is stored into `char_pattern(char_index)` and `char_index` decrements. At 8 accumulated symbols, decodes immediately. |
| **PROCESSING** | Builds a `'-'`-padded 8-bit lookup key and linearly scans the 36-entry LUT. Writes the matching index (or `X"FF"`) to `decoded_index`, asserts `new_char_ready` for one cycle, clears the buffer, and returns to IDLE. |

#### Timing Constants (50 MHz)

| Constant | Cycles | Duration | Purpose |
|---|---|---|---|
| `DOT_TIME` | 3,000,000 | 60 ms | Minimum press duration to register as a dot |
| `DASH_TIME` | 9,000,000 | 180 ms | Minimum press duration to register as a dash |
| `IDLE_TIME` | 8,750,000 | 175 ms | Silence threshold that triggers inter-character decoding |

`IDLE_TIME` is set between the inter-symbol gap (100 ms) and the end-of-character gap (250 ms) so the decoder waits for more symbols within a character but fires when the character is complete.

#### Synchronous Reset

Both the timer process and the main FSM process check `reset = '1'` as their highest-priority branch. On assertion, the following are restored to power-on values in the same clock cycle: `state → IDLE`, `char_index → 7`, `symbol_count → 0`, `char_pattern → X"00"`, `counter → 0`, `decoded_index → X"FF"`, `done_counter → 0`, `timer_done → '0'`.

#### The `new_char_ready` Pulse

The signal defaults to `'0'` at the top of the FSM process on every rising edge. It is overridden to `'1'` only inside the PROCESSING state, on the same cycle that `decoded_index` is written. The next cycle, the FSM is in IDLE and the default `'0'` applies — exactly one clock cycle wide, no separate clear logic required.

```
clk             ___╱‾╲___╱‾╲___╱‾╲___╱‾╲___╱‾╲___
state           ──PROCESSING──╲IDLE──────────────────
decoded_index   ────────X"12"──────────────────────
new_char_ready  ____________╱‾‾‾╲____________________
                              ↑ exactly 1 clock cycle (20 ns)
```

#### Morse LUT Encoding

`'0'` = dot, `'1'` = dash, `'-'` = unused padding (left-aligned).

| Index | Character | Morse | LUT Entry |
|---|---|---|---|
| 0 | A | `.-` | `"01------"` |
| 1 | B | `-...` | `"1000----"` |
| 4 | E | `.` | `"0-------"` |
| 18 | S | `...` | `"000-----"` |
| 14 | O | `---` | `"111-----"` |
| 26 | 0 | `-----` | `"11111---"` |
| 29 | 3 | `...--` | `"00011---"` |

---

### `lcd_controller.vhd`

**Entity interface:**

```vhdl
entity lcd_controller is
    Port (
        clk           : in  std_logic;                    -- 50 MHz system clock
        Reset         : in  std_logic;                    -- Active-low reset
        char_data     : in  std_logic_vector(7 downto 0); -- ASCII character to write
        new_char      : in  std_logic;                    -- 1-cycle write strobe
        clear_display : in  std_logic;                    -- 1-cycle clear strobe
        lcd_rs        : out std_logic;
        lcd_rw        : out std_logic;
        lcd_e         : out std_logic;
        data          : out std_logic_vector(7 downto 0)
    );
end lcd_controller;
```

#### Clock Division Chain

The 50 MHz input is divided down internally to meet HD44780 command timing requirements (~100 µs per command):

```
50 MHz  →  ÷40001  →  ~1.25 kHz (tc_clkcnt)
        →  ÷2      →  ~625 Hz   (clkdiv)
        →  ÷2      →  ~312 Hz   (clk_int, period ≈ 3.2 ms)
```

`lcd_e` toggles on the **falling** edge of `clkdiv` — a half-cycle offset from `clk_int` — satisfying HD44780 data-setup and hold-time requirements.

#### Initialisation Sequence

Executed once on power-on or reset (`flag = '0'`):

```
IDLE → SETFUNCTION → SWITCHMODE → CLEAR → SETMODE → WAITCHAR
```

After completion, `init_done` is asserted and the controller waits in `WAITCHAR` indefinitely.

#### Normal Write Sequence

```
WAITCHAR → SETDDRAM → WRITERAM → WAITCHAR
```

`SETDDRAM` selects line 1 (`X"80"`) for positions 0–15 and line 2 (`X"C0"`) for positions 16–31. After position 31, the display clears and wraps to position 0.

#### Notes on Compatibility

- `lcd_e` uses `out` port mode backed by an internal `lcd_e_int` signal (replaces the deprecated `buffer` mode used in the original reference design).
- State constants use `ST_` prefix and one-hot encoding; combinational output assignments (`lcd_rs`, `lcd_rw`, `data`) decode directly from the state constant, making each LCD command byte readable as a table in the source.

---

### `morse_top.vhd`

**Entity interface:**

```vhdl
entity morse_top is
    Port (
        clk         : in  std_logic;                    -- 50 MHz system clock
        reset       : in  std_logic;                    -- Active-high system reset
        morse_input : in  std_logic;                    -- Raw button (active-low)
        lcd_rs      : out std_logic;
        lcd_rw      : out std_logic;
        lcd_e       : out std_logic;
        lcd_data    : out std_logic_vector(7 downto 0)
    );
end morse_top;
```

#### Polarity Adaptation

Two polarity inversions are performed with named intermediate signals so the boundary is explicit:

```vhdl
lcd_reset_n  <= not reset;       -- active-high system reset → active-low for LCD controller
btn_active_h <= not morse_input; -- active-low board button  → active-high for decoder
```

#### ASCII Conversion

A pure combinational function `morse_to_ascii` converts the decoder's LUT index to its ASCII code:

| Input range | Output |
|---|---|
| 0–25 | `'A'`–`'Z'` (0x41–0x5A) |
| 26–35 | `'0'`–`'9'` (0x30–0x39) |
| Any other (including `X"FF"`) | `'?'` (0x3F) |

#### Double-Character Bug — Fixed

The original Step 1 design detected new characters by comparing successive decoder output values:

```vhdl
-- BROKEN: if two consecutive characters are identical (e.g. "AA", "SS"),
-- the second produces the same value and the condition is false — it is dropped.
if morse_index /= prev_morse_index and morse_index /= X"FF" then ...
```

The Phase 3 design uses the `new_char_ready` pulse exclusively:

```vhdl
-- CORRECT: fires once per decoded character, regardless of index value.
elsif new_char_ready = '1' then
    ascii_char  <= morse_to_ascii(morse_index);
    new_char_lc <= '1';
    ...
end if;
```

Each press-and-release cycle that completes a character produces exactly one pulse. "SOS" produces three pulses (S, O, S); "AA" produces two pulses (A, A). The LCD receives one independent write per pulse, irrespective of whether consecutive indices are equal.

---

## Simulation & Testing

### Compilation Order

GHDL requires each design unit to be analysed before units that depend on it. Run all commands from the **project root directory**.

```bash
# 1. Compile the three design modules
ghdl -a src/morse_decoder.vhd
ghdl -a src/lcd_controller.vhd
ghdl -a src/morse_top.vhd

# 2. Compile the Phase 3 testbench
#    (-fsynopsys required for ieee.math_real used in the testbench)
ghdl -a -fsynopsys testbench/morse_lcd/morse_decoder_tb.vhd

# 3. Elaborate (link) the testbench top-level
ghdl -e -fsynopsys morse_decoder_tb
```

To also compile the legacy testbench (tests the original `morse.vhd`):

```bash
ghdl -a src/morse/morse.vhd
ghdl -a -fsynopsys testbench/morse/morse_tb.vhd
ghdl -e -fsynopsys morse_tb
```

### Running the Testbench

```bash
# Run Phase 3 testbench — generates a GTKWave waveform file
ghdl -r -fsynopsys morse_decoder_tb \
     --wave=wave_decoder.ghw \
     --stop-time=25000ms

# Open the waveform
gtkwave wave_decoder.ghw
```

**Why `--stop-time=25000ms`?** The testbench uses human-scale timing (100 ms dots, 300 ms dashes, 1-second waits between test cases). Each of the 7 test cases takes 1–4 seconds of simulated time; 25 seconds covers all cases.

**Checking for failures:** GHDL prints assertion failures to stderr. A clean run produces only two lines — no `ERROR` output:

```
testbench/morse_lcd/morse_decoder_tb.vhd:87:@200ns:(report note): Sending character: .-
./morse_decoder_tb:info: simulation stopped by --stop-time @25000ms
```

To also run the legacy testbench:

```bash
ghdl -r -fsynopsys morse_tb --wave=wave_legacy.ghw --stop-time=20ms
gtkwave wave_legacy.ghw
```

### Test Cases Covered

| # | Input | Expected `decoded_index` | Character |
|---|---|---|---|
| 1 | `.-` | `X"00"` | A |
| 2 | `-...` | `X"01"` | B |
| 3 | `...` | `X"12"` | S |
| 4 | `...--` | `X"1D"` | 3 |
| 5 | Short press (<60 ms) | no pulse — output unchanged | (ignored) |
| 6 | `.` + timeout | `X"04"` | E (timeout-triggered decode) |
| 7 | `...` `---` `...` | `X"12"`, `X"0E"`, `X"12"` | S, O, S (consecutive identical S) |

---

### GTKWave Signal Guide

In GTKWave, expand: `morse_decoder_tb` → `uut` to access internal decoder signals.

#### Group 1: Reset and Startup

| Signal | What to verify |
|---|---|
| `reset` | High for 100 ns at time 0, then low. All registers hold their reset values while high. |
| `decoded_index[7:0]` | Reads `X"FF"` during and immediately after reset. Changes only on a decode event. |
| `new_char_ready` | Remains `'0'` throughout reset and all inter-symbol gaps. |

#### Group 2: Button Input and Symbol Accumulation

| Signal | What to verify |
|---|---|
| `btn_in` | Goes `'1'` for 100 ms (dot) or 300 ms (dash), returns `'0'` for 100 ms between symbols. |
| `counter` | Counts from 0 while `btn_in = '1'`. After a 100 ms dot: ~5,000,000. After a 300 ms dash: ~15,000,000. |
| `char_pattern[7:0]` | Accumulates symbols MSB-first. After `.-` (A): reads `"01000000"` (bit 7 = dot, bit 6 = dash). |
| `symbol_count` | Increments by 1 per accepted symbol; resets to 0 after PROCESSING. |

#### Group 3: Decode Event (zoom to 2–3 clock cycles)

Set the timescale to **ns** when inspecting the decode event. At 50 MHz, one clock cycle = 20 ns.

| Signal | What to verify |
|---|---|
| `new_char_ready` | A single `'1'` pulse lasting **exactly one clock cycle (20 ns)**. |
| `decoded_index[7:0]` | Changes to the correct LUT index on the **same rising edge** as `new_char_ready`. |

Expected waveform for decoding 'A' (`.-`):

```
         ~675 ms mark
              ↓
clk      ___╱‾╲___╱‾╲___╱‾╲___
decoded  ──X"FF"──┤X"00"────────   (changes to 0x00 = 'A')
ready    _________╱‾‾‾╲_________   (high for exactly 20 ns)
```

#### Group 4: Consecutive-Character Proof (SOS test)

Zoom into the SOS section of the simulation. Three separate `new_char_ready` pulses appear at distinct times, even though the first and third carry the same index value (`X"12"` = S):

```
new_char_ready  __╱‾╲___________________________╱‾╲___________________________╱‾╲__
decoded_index   ──X"12"─────────────────────────X"0E"─────────────────────────X"12"
                  S (index 18)                   O (index 14)                  S (index 18)
```

This is the direct waveform proof that the double-character bug is resolved.

#### Recommended Signal Order in GTKWave

```
clk                ← reference timebase
reset              ← startup verification
btn_in             ← dot/dash input pattern
counter            ← press duration measurement
symbol_count       ← symbol accumulation progress
char_pattern[7:0]  ← accumulated bit pattern
decoded_index[7:0] ← LUT output (view in hex)
new_char_ready     ← decode event pulse
```

---

## Legacy Files

| Path | Description |
|---|---|
| `src/morse/morse.vhd` | Original standalone decoder entity (`morse`). Retained for `morse_tb.vhd` backward compatibility. Not used in the Phase 3 hierarchy. |
| `src/lcd/lcd.vhd` | Third-party HD44780 reference driver. Not used in Phase 3 (replaced by `lcd_controller.vhd`). |
| `src/morse_lcd/morse_lcd_system.vhd` | Phase 2 monolithic file containing three entities in one file. Superseded by the three-file Phase 3 split. |
| `legacy/` | Original Active-HDL and Xilinx ISE project structures with generated synthesis and implementation artifacts. |
