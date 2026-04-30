# Interface Agreement — UART Subsystem
**ECGR 4146/5146 — Spring 2026**
**Last Updated: 2026-04-16**

This document defines the agreed-upon port names, signal widths, and active levels for every module in the design. All team members must follow these exactly so modules connect cleanly in the top-level integration.

---

## Global Conventions

| Convention | Rule |
|------------|------|
| Reset | Active HIGH (`reset = '1'` resets the module) |
| Clock | All modules use the same `clk` — 100 MHz, rising edge |
| Tick | `s_tick` / `tick` — active HIGH for exactly one clock cycle |
| Done flags | Active HIGH pulse for exactly one clock cycle |
| Idle line | UART RX/TX lines idle HIGH |
| Bit order | LSB first on the serial line |
| Libraries | `IEEE.STD_LOGIC_1164` and `IEEE.NUMERIC_STD` only — no `std_logic_arith` |

---

## Module Port Specifications

### 1. Baud Rate Generator — `baud_gen.vhd` ✅ Done (Alberto)

```vhdl
entity baud_gen is
    generic(
        M : integer := 651        -- divisor: clk_freq / (baud * oversample)
    );
    port(
        clk   : in  std_logic;
        reset : in  std_logic;
        tick  : out std_logic     -- HIGH for 1 cycle every 651 cycles
    );
end baud_gen;
```

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| `clk` | in | 1-bit | 100 MHz system clock |
| `reset` | in | 1-bit | Active HIGH synchronous reset |
| `tick` | out | 1-bit | Baud tick — HIGH 1 cycle per 651 cycles (16× 9600 baud) |

---

### 2. UART Receiver — `uart_rx.vhd` ✅ Done (Alberto)

```vhdl
entity uart_rx is
    generic(
        DBIT    : integer := 8;   -- number of data bits
        SB_TICK : integer := 16   -- ticks for 1 stop bit
    );
    port(
        clk     : in  std_logic;
        reset   : in  std_logic;
        rx      : in  std_logic;                      -- serial input, idle HIGH
        s_tick  : in  std_logic;                      -- baud tick from baud_gen
        rx_done : out std_logic;                      -- HIGH 1 cycle when byte received
        dout    : out std_logic_vector(7 downto 0)    -- received byte, valid when rx_done HIGH
    );
end uart_rx;
```

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| `clk` | in | 1-bit | 100 MHz system clock |
| `reset` | in | 1-bit | Active HIGH synchronous reset |
| `rx` | in | 1-bit | Serial input line (idle HIGH) |
| `s_tick` | in | 1-bit | Connected to `tick` from `baud_gen` |
| `rx_done` | out | 1-bit | Pulses HIGH for 1 cycle when full byte is received |
| `dout` | out | 8-bit | Received byte — hold value, valid when `rx_done` is HIGH |

---

### 3. UART Transmitter — `uart_tx.vhd` (Kenneth)

```vhdl
entity uart_tx is
    generic(
        DBIT    : integer := 8;   -- number of data bits
        SB_TICK : integer := 16   -- ticks for 1 stop bit
    );
    port(
        clk     : in  std_logic;
        reset   : in  std_logic;
        tx_start : in  std_logic;                     -- pulse HIGH to begin transmission
        s_tick  : in  std_logic;                      -- baud tick from baud_gen
        din     : in  std_logic_vector(7 downto 0);   -- byte to transmit
        tx_done : out std_logic;                      -- HIGH 1 cycle when byte sent
        tx      : out std_logic                       -- serial output, idle HIGH
    );
end uart_tx;
```

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| `clk` | in | 1-bit | 100 MHz system clock |
| `reset` | in | 1-bit | Active HIGH synchronous reset |
| `tx_start` | in | 1-bit | Pulse HIGH for 1 cycle to begin sending `din` |
| `s_tick` | in | 1-bit | Connected to `tick` from `baud_gen` |
| `din` | in | 8-bit | Byte to transmit — must be stable when `tx_start` pulses |
| `tx_done` | out | 1-bit | Pulses HIGH for 1 cycle when transmission is complete |
| `tx` | out | 1-bit | Serial output line (idle HIGH) |

---

### 4. FIFO Buffer — `fifo.vhd` (Erik)

```vhdl
entity fifo is
    generic(
        B : integer := 8;    -- data width in bits
        W : integer := 4     -- address width (depth = 2^W = 16 entries)
    );
    port(
        clk   : in  std_logic;
        reset : in  std_logic;
        wr    : in  std_logic;                        -- write enable, active HIGH
        rd    : in  std_logic;                        -- read enable, active HIGH
        w_data : in  std_logic_vector(B-1 downto 0); -- data in
        r_data : out std_logic_vector(B-1 downto 0); -- data out
        empty : out std_logic;                        -- HIGH when FIFO is empty
        full  : out std_logic                         -- HIGH when FIFO is full
    );
end fifo;
```

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| `clk` | in | 1-bit | 100 MHz system clock |
| `reset` | in | 1-bit | Active HIGH synchronous reset — clears FIFO |
| `wr` | in | 1-bit | Write enable — write `w_data` on rising edge when HIGH |
| `rd` | in | 1-bit | Read enable — advance read pointer on rising edge when HIGH |
| `w_data` | in | 8-bit | Data to write into FIFO |
| `r_data` | out | 8-bit | Data read from FIFO — valid when `empty` is LOW |
| `empty` | out | 1-bit | HIGH when FIFO has no data — do not read |
| `full` | out | 1-bit | HIGH when FIFO is full — do not write |

> **Note:** Two FIFO instances will be used — one on the RX path (`rx_fifo`) and one on the TX path (`tx_fifo`). Both use the same entity with `B=8, W=4`.

---

### 5. RAM Module — `ram_module.vhd` (Erik)

```vhdl
entity ram_module is
    generic(
        ADDR_WIDTH : integer := 5;   -- 2^5 = 32 rows
        DATA_WIDTH : integer := 32   -- 32-bit wide rows
    );
    port(
        clk   : in  std_logic;
        we    : in  std_logic;                              -- write enable, active HIGH
        addr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0); -- address (0 to 31)
        din   : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- data in (32-bit)
        dout  : out std_logic_vector(DATA_WIDTH-1 downto 0)  -- data out (32-bit)
    );
end ram_module;
```

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| `clk` | in | 1-bit | 100 MHz system clock |
| `we` | in | 1-bit | Write enable — write `din` to `addr` on rising edge when HIGH |
| `addr` | in | 5-bit | Row address (0–31) |
| `din` | in | 32-bit | Data to write |
| `dout` | out | 32-bit | Data read from `addr` — registered (1 cycle latency) |

---

### 6. FSM Controller — `uart_fsm.vhd` (Alberto)

```vhdl
entity uart_fsm is
    port(
        clk      : in  std_logic;
        reset    : in  std_logic;
        fifo_empty : in  std_logic;                         -- from rx_fifo
        fifo_dout  : in  std_logic_vector(7 downto 0);      -- byte from rx_fifo
        fifo_rd    : out std_logic;                         -- read strobe to rx_fifo
        ram_we     : out std_logic;                         -- write enable to ram_module
        ram_addr   : out std_logic_vector(4 downto 0);      -- address to ram_module (0-31)
        ram_din    : out std_logic_vector(31 downto 0);     -- 32-bit word to ram_module
        fsm_done   : out std_logic                          -- HIGH when RAM is fully written
    );
end uart_fsm;
```

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| `clk` | in | 1-bit | 100 MHz system clock |
| `reset` | in | 1-bit | Active HIGH synchronous reset |
| `fifo_empty` | in | 1-bit | Connected to `empty` from `rx_fifo` |
| `fifo_dout` | in | 8-bit | Connected to `r_data` from `rx_fifo` |
| `fifo_rd` | out | 1-bit | Pulses HIGH to pop a byte from `rx_fifo` |
| `ram_we` | out | 1-bit | Write enable to `ram_module` |
| `ram_addr` | out | 5-bit | Current RAM row being written (0–31) |
| `ram_din` | out | 32-bit | 4 bytes packed into one 32-bit word for RAM |
| `fsm_done` | out | 1-bit | Pulses HIGH when all 32 rows have been written |

> **Packing rule:** Bytes arrive LSB-first. The FSM packs 4 consecutive bytes into one 32-bit word: `ram_din <= byte3 & byte2 & byte1 & byte0` (byte0 = first received, stored in bits 7:0).

---

### 7. Classification Engine — `classification_engine.vhd` (Sebastian)

```vhdl
entity classification_engine is
    port(
        clk          : in  std_logic;
        reset        : in  std_logic;
        start        : in  std_logic;                        -- pulse HIGH to begin classification
        ram_dout     : in  std_logic_vector(31 downto 0);    -- data from ram_module
        ram_addr     : out std_logic_vector(4 downto 0);     -- address to read from ram_module
        result       : out std_logic_vector(7 downto 0);     -- classification result byte
        result_valid : out std_logic;                        -- HIGH 1 cycle when result is ready
        done         : out std_logic                         -- HIGH when all classification complete
    );
end classification_engine;
```

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| `clk` | in | 1-bit | 100 MHz system clock |
| `reset` | in | 1-bit | Active HIGH synchronous reset |
| `start` | in | 1-bit | Pulse HIGH (connected to `fsm_done`) to begin classification |
| `ram_dout` | in | 32-bit | Connected to `dout` from `ram_module` |
| `ram_addr` | out | 5-bit | Address the engine is reading from RAM |
| `result` | out | 8-bit | One classification result byte — valid when `result_valid` HIGH |
| `result_valid` | out | 1-bit | Pulses HIGH for 1 cycle each time a result byte is ready |
| `done` | out | 1-bit | Pulses HIGH when all results have been produced |

---

## Signal Connections at Top Level

This table shows exactly how signals connect between modules in `uart_top.vhd`:

| From | Signal | To | Signal |
|------|--------|----|--------|
| `baud_gen` | `tick` | `uart_rx` | `s_tick` |
| `baud_gen` | `tick` | `uart_tx` | `s_tick` |
| `uart_rx` | `rx_done` | `rx_fifo` | `wr` |
| `uart_rx` | `dout` | `rx_fifo` | `w_data` |
| `rx_fifo` | `empty` | `uart_fsm` | `fifo_empty` |
| `rx_fifo` | `r_data` | `uart_fsm` | `fifo_dout` |
| `uart_fsm` | `fifo_rd` | `rx_fifo` | `rd` |
| `uart_fsm` | `ram_we` | `ram_module` | `we` |
| `uart_fsm` | `ram_addr` | `ram_module` | `addr` (muxed with classifier) |
| `uart_fsm` | `ram_din` | `ram_module` | `din` |
| `uart_fsm` | `fsm_done` | `classification_engine` | `start` |
| `ram_module` | `dout` | `classification_engine` | `ram_dout` |
| `classification_engine` | `ram_addr` | `ram_module` | `addr` (muxed with FSM) |
| `classification_engine` | `result` | `tx_fifo` | `w_data` |
| `classification_engine` | `result_valid` | `tx_fifo` | `wr` |
| `tx_fifo` | `r_data` | `uart_tx` | `din` |
| `tx_fifo` | `empty` | TX controller | — |

> **RAM address mux:** The `ram_module` `addr` input is shared between `uart_fsm` (writes) and `classification_engine` (reads). The top-level will mux these based on `fsm_done`: before `fsm_done`, FSM drives the address; after `fsm_done`, the classifier drives it.

---

## Notes for Each Member

**Kenneth (uart_tx):** Match the `tx_start` / `tx_done` / `din` naming exactly. The TX FIFO drains into your transmitter — when the FIFO is not empty and your module is idle, a controller pulses `tx_start`.

**Eric (fifo, ram_module):** Two FIFO instances will be created in the top level — name them `rx_fifo` and `tx_fifo` as labels, but they are the same entity. RAM `dout` has 1-cycle read latency — the classifier must account for this.

**Sebastian (classification_engine):** Your `ram_addr` and the FSM's `ram_addr` share the same RAM port. Design your module to start reading from address 0 when `start` pulses. Results stream out one byte at a time via `result` / `result_valid`.
