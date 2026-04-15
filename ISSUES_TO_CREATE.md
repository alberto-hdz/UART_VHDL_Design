# GitHub Issues — Complete Task List

Create each of these as a GitHub Issue. Copy the title, labels, assignee, and description.
Use the milestone feature to group them by deadline.

---

## MILESTONES (create these first)

| Milestone Name             | Due Date   |
|---------------------------|------------|
| M1 — Baud Rate Generator  | 2026-03-25 |
| M2 — Receiving Subsystem  | 2026-04-01 |
| M3 — Interface & RAM      | 2026-04-08 |
| M4 — FSM & TX Interface   | 2026-04-15 |
| M5 — TX & Classification  | 2026-04-22 |
| M6 — Integration & Demo   | 2026-04-28 |

---

## LABELS (create these for color-coding)

| Label          | Color   | Description                        |
|----------------|---------|------------------------------------|
| module         | #1d76db | VHDL module design work            |
| testbench      | #0e8a16 | Testbench creation and simulation  |
| integration    | #d93f0b | Top-level integration task         |
| documentation  | #f9d0c4 | Report, presentation, screenshots  |
| bug            | #e11d48 | Something broken that needs fixing |
| review         | #fbca04 | Waiting for code review            |
| blocked        | #b60205 | Blocked by another task            |
| high-priority  | #ff0000 | Must be done ASAP                  |

---

## ISSUES TO CREATE

### Issue #1
**Title:** [MODULE] Baud rate generator
**Labels:** module, high-priority
**Milestone:** M1 — Baud Rate Generator
**Assignee:** Member A
**Description:**
Design the baud rate generator that produces a tick pulse at 16× the baud rate (9600 baud).

**Requirements:**
- [x] Create `src/baud_gen.vhd`
- [x] Generic parameter `M` for clock divider value (default 651 for 100 MHz / 9600 / 16)
- [x] Ports: `clk`, `reset` (in), `tick` (out)
- [x] Tick pulses high for exactly one clock cycle every M cycles

**Branch:** `dev/baud-gen`
**Due:** 2026-03-25

---

### Issue #2
**Title:** [TESTBENCH] Baud rate generator testbench
**Labels:** testbench
**Milestone:** M1 — Baud Rate Generator
**Assignee:** Member A
**Description:**
Write a testbench to verify the baud rate generator tick output.

**Requirements:**
- [ ] Create `tb/tb_baud_gen.vhd`
- [ ] Verify tick period is correct (651 × 10 ns = 6.51 µs)
- [ ] Verify tick is high for exactly one clock cycle
- [ ] Run for at least 200 µs to see multiple ticks
- [ ] Capture waveform screenshot → `waveforms/baud_gen_tick.png`

**Branch:** `dev/baud-gen`
**Due:** 2026-03-25

---

### Issue #3
**Title:** [MODULE] UART receiver
**Labels:** module, high-priority
**Milestone:** M2 — Receiving Subsystem
**Assignee:** Member A
**Description:**
Implement the UART receiver with 4-state FSM (idle, start, data, stop) and 16× oversampling.

**Requirements:**
- [ ] Create `src/uart_rx.vhd`
- [ ] Generic parameters: `DBIT` (default 8), `SB_TICK` (default 16)
- [ ] Ports: `clk`, `reset`, `rx`, `s_tick` (in), `rx_done`, `dout[7:0]` (out)
- [ ] FSM: idle → start (wait 7 ticks for mid-bit) → data (sample at tick 15) → stop
- [ ] LSB-first reception
- [ ] `rx_done` pulses for one cycle when a byte is fully received

**Branch:** `dev/uart-rx`
**Due:** 2026-04-01

---

### Issue #4
**Title:** [TESTBENCH] UART receiver testbench
**Labels:** testbench
**Milestone:** M2 — Receiving Subsystem
**Assignee:** Member A
**Description:**
Write a testbench that sends serial data on the `rx` line and verifies `dout` output.

**Requirements:**
- [ ] Create `tb/tb_uart_rx.vhd`
- [ ] Instantiate both `baud_gen` and `uart_rx`
- [ ] Write a `send_byte` procedure that drives the `rx` line with start bit, 8 data bits (LSB first), and stop bit
- [ ] Send at least 2 different bytes (e.g., 0x41 and 0x55)
- [ ] Verify `rx_done` pulses and `dout` matches expected values
- [ ] Capture waveform → `waveforms/uart_rx_receive.png`

**Branch:** `dev/uart-rx`
**Due:** 2026-04-01

---

### Issue #5
**Title:** [MODULE] UART transmitter
**Labels:** module, high-priority
**Milestone:** M2 — Receiving Subsystem
**Assignee:** Member B
**Description:**
Implement the UART transmitter with 4-state FSM.

**Requirements:**
- [ ] Create `src/uart_tx.vhd`
- [ ] Generic parameters: `DBIT` (default 8), `SB_TICK` (default 16)
- [ ] Ports: `clk`, `reset`, `tx_start`, `s_tick`, `din[7:0]` (in), `tx_done`, `tx` (out)
- [ ] On `tx_start`, latch `din` and begin transmission
- [ ] Send start bit (low), 8 data bits LSB-first, stop bit (high)
- [ ] `tx` idles high when not transmitting

**Branch:** `dev/uart-tx`
**Due:** 2026-04-01

---

### Issue #6
**Title:** [TESTBENCH] UART transmitter testbench
**Labels:** testbench
**Milestone:** M2 — Receiving Subsystem
**Assignee:** Member B
**Description:**
Write a testbench that triggers transmission and verifies the `tx` output waveform.

**Requirements:**
- [ ] Create `tb/tb_uart_tx.vhd`
- [ ] Instantiate both `baud_gen` and `uart_tx`
- [ ] Transmit at least 2 bytes
- [ ] Verify `tx` line shows correct start/data/stop pattern
- [ ] Verify `tx_done` pulses after each byte
- [ ] Capture waveform → `waveforms/uart_tx_transmit.png`

**Branch:** `dev/uart-tx`
**Due:** 2026-04-01

---

### Issue #7
**Title:** [TESTBENCH] RX-to-TX loopback verification
**Labels:** testbench, integration
**Milestone:** M2 — Receiving Subsystem
**Assignee:** Member B
**Description:**
Create a loopback testbench: send bytes into RX, connect RX output to TX input via a register, verify TX output matches the original data.

**Requirements:**
- [ ] Create `tb/tb_loopback.vhd`
- [ ] Wire: `rx` → `uart_rx` → register → `uart_tx` → `tx`
- [ ] When `rx_done` fires, load data into TX and assert `tx_start`
- [ ] Verify `tx` output matches original `rx` input
- [ ] Capture waveform → `waveforms/loopback_test.png`

**Branch:** `dev/uart-tx`
**Due:** 2026-04-01

---

### Issue #8
**Title:** [MODULE] FIFO buffer
**Labels:** module, high-priority
**Milestone:** M3 — Interface & RAM
**Assignee:** Member C
**Description:**
Design a circular FIFO buffer with configurable width and depth.

**Requirements:**
- [ ] Create `src/fifo.vhd`
- [ ] Generic parameters: `DATA_WIDTH` (default 8), `ADDR_WIDTH` (default 4, giving 16 entries)
- [ ] Ports: `clk`, `reset`, `wr`, `rd`, `w_data` (in), `r_data`, `empty`, `full` (out)
- [ ] Circular pointer logic with proper full/empty flag generation
- [ ] Handle simultaneous read/write correctly

**Branch:** `dev/fifo`
**Due:** 2026-04-08

---

### Issue #9
**Title:** [TESTBENCH] FIFO buffer testbench
**Labels:** testbench
**Milestone:** M3 — Interface & RAM
**Assignee:** Member C
**Description:**
Verify FIFO read/write, full/empty flags, and edge cases.

**Requirements:**
- [ ] Create `tb/tb_fifo.vhd`
- [ ] Test: write several values, read them back in order
- [ ] Test: fill the FIFO completely, verify `full` flag
- [ ] Test: empty the FIFO completely, verify `empty` flag
- [ ] Test: simultaneous read and write
- [ ] Capture waveform → `waveforms/fifo_operations.png`

**Branch:** `dev/fifo`
**Due:** 2026-04-08

---

### Issue #10
**Title:** [MODULE] RAM module
**Labels:** module
**Milestone:** M3 — Interface & RAM
**Assignee:** Member C
**Description:**
Design a single-port RAM module inferred as block RAM.

**Requirements:**
- [ ] Create `src/ram_module.vhd`
- [ ] Generic parameters: `DATA_WIDTH` (default 32), `ADDR_WIDTH` (default 5, giving 32 rows)
- [ ] Ports: `clk`, `we`, `addr`, `din` (in), `dout` (out)
- [ ] Synchronous read and write

**Branch:** `dev/ram`
**Due:** 2026-04-08

---

### Issue #11
**Title:** [TESTBENCH] RAM module testbench
**Labels:** testbench
**Milestone:** M3 — Interface & RAM
**Assignee:** Member C
**Description:**
Verify RAM read/write operations.

**Requirements:**
- [ ] Create `tb/tb_ram.vhd`
- [ ] Write known values to several addresses
- [ ] Read them back and verify correctness
- [ ] Capture waveform → `waveforms/ram_readwrite.png`

**Branch:** `dev/ram`
**Due:** 2026-04-08

---

### Issue #12
**Title:** [MODULE] FSM controller — FIFO to RAM writer
**Labels:** module, high-priority
**Milestone:** M4 — FSM & TX Interface
**Assignee:** Member C
**Description:**
Design the FSM that reads bytes from the RX FIFO, packs 4 bytes into a 32-bit word, and writes to RAM.

**Requirements:**
- [ ] Create `src/uart_fsm.vhd`
- [ ] States: IDLE, READ_BYTE, PACK, WRITE_RAM, DONE
- [ ] Byte packing: byte 0 → bits [7:0], byte 1 → bits [15:8], etc.
- [ ] Increment RAM address after each 32-bit write
- [ ] `write_done` output signals completion

**Branch:** `dev/fsm`
**Due:** 2026-04-15

---

### Issue #13
**Title:** [TESTBENCH] FSM controller testbench
**Labels:** testbench
**Milestone:** M4 — FSM & TX Interface
**Assignee:** Member C
**Description:**
Verify the FSM reads from FIFO and writes packed words to RAM correctly.

**Requirements:**
- [ ] Create `tb/tb_uart_fsm.vhd`
- [ ] Pre-load a FIFO with known bytes
- [ ] Run FSM and verify RAM contents match expected 32-bit packed values
- [ ] Capture waveform → `waveforms/fsm_fifo_to_ram.png`

**Branch:** `dev/fsm`
**Due:** 2026-04-15

---

### Issue #14
**Title:** [MODULE] Classification engine
**Labels:** module, high-priority
**Milestone:** M5 — TX & Classification
**Assignee:** Member D
**Description:**
Design the classification engine that reads data from RAM, classifies each byte, writes results back, and sends results to the TX FIFO.

**Requirements:**
- [ ] Create `src/classification_engine.vhd`
- [ ] Classification logic: uppercase (0x01), lowercase (0x02), digit (0x03), other (0x00)
- [ ] Read 32-bit words from RAM, classify each byte, write result word
- [ ] Push classification results to TX FIFO byte-by-byte
- [ ] `done` output signals completion
- [ ] Confirm classification criteria with instructor

**Branch:** `dev/classification`
**Due:** 2026-04-24

---

### Issue #15
**Title:** [TESTBENCH] Classification engine testbench
**Labels:** testbench
**Milestone:** M5 — TX & Classification
**Assignee:** Member D
**Description:**
Verify classification produces correct results for known inputs.

**Requirements:**
- [ ] Create `tb/tb_classification.vhd`
- [ ] Pre-load RAM with known data (mix of uppercase, lowercase, digits, special chars)
- [ ] Run classification and verify result values
- [ ] Capture waveform → `waveforms/classification_results.png`

**Branch:** `dev/classification`
**Due:** 2026-04-24

---

### Issue #16
**Title:** [INTEGRATION] Top-level module
**Labels:** integration, high-priority
**Milestone:** M6 — Integration & Demo
**Assignee:** Member A (integrator)
**Description:**
Wire all modules together in the top-level entity.

**Requirements:**
- [ ] Create `src/uart_top.vhd`
- [ ] Instantiate: baud_gen, uart_rx, rx_fifo, uart_fsm, ram_module, classification_engine, tx_fifo, uart_tx
- [ ] TX controller FSM to drain TX FIFO into transmitter
- [ ] RAM address mux between FSM (write) and classifier (read/write)
- [ ] Status outputs for observation in simulation

**Branch:** `dev/top-level`
**Due:** 2026-04-24

---

### Issue #17
**Title:** [TESTBENCH] Full system integration testbench
**Labels:** testbench, integration
**Milestone:** M6 — Integration & Demo
**Assignee:** Member A (integrator)
**Description:**
End-to-end test: send bytes via RX, verify classification results appear on TX.

**Requirements:**
- [ ] Create `tb/tb_uart_top.vhd`
- [ ] Send 16 test bytes (mix of character types)
- [ ] Wait for `classify_done`
- [ ] Verify TX output contains correct classification codes
- [ ] Run for at least 10 ms simulated time
- [ ] Capture waveform → `waveforms/full_system_test.png`

**Branch:** `dev/top-level`
**Due:** 2026-04-26

---

### Issue #18
**Title:** [DOCS] Project report
**Labels:** documentation
**Milestone:** M6 — Integration & Demo
**Assignee:** Member D (lead), all members contribute
**Description:**
Write the project report using the provided template.

**Requirements:**
- [ ] Summary section
- [ ] Module 1: UART (baud gen + RX + TX) — written by Member A and B
- [ ] Module 2: FIFO-based interface — written by Member C
- [ ] Module 3: RAM module — written by Member C
- [ ] Module 4: Classification engine — written by Member D
- [ ] Module 5: Integrated system — written by Member D
- [ ] All waveform screenshots embedded
- [ ] Challenges and solutions section
- [ ] Save to `docs/`

**Due:** 2026-04-28

---

### Issue #19
**Title:** [DOCS] Project presentation
**Labels:** documentation
**Milestone:** M6 — Integration & Demo
**Assignee:** Member D (lead)
**Description:**
Create presentation slides for the class demo.

**Requirements:**
- [ ] Architecture overview slide
- [ ] One slide per module with key design decisions
- [ ] Waveform screenshots demonstrating functionality
- [ ] Demo video or live demo plan
- [ ] Save to `docs/`

**Due:** 2026-04-28

---

### Issue #20
**Title:** [DOCS] Demo video
**Labels:** documentation
**Milestone:** M6 — Integration & Demo
**Assignee:** All members
**Description:**
Record a demo video showing project overview, completed tasks, and simulation results.

**Requirements:**
- [ ] Project overview (architecture, design flow)
- [ ] Walk through each module's simulation waveforms
- [ ] Show full system test running end-to-end
- [ ] Keep under 10 minutes
- [ ] Upload link to `docs/`

**Due:** 2026-04-28

---

### Issue #21
**Title:** [INTEGRATION] Vivado project archive for submission
**Labels:** integration
**Milestone:** M6 — Integration & Demo
**Assignee:** Member A (integrator)
**Description:**
Create the final Vivado project archive for submission.

**Requirements:**
- [ ] All source files compile without errors
- [ ] All testbenches run successfully
- [ ] File → Project → Archive (include config settings + sim results)
- [ ] Upload to Canvas

**Due:** 2026-04-28
