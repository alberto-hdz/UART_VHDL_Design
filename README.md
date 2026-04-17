# UART Subsystem with Classification Engine

**ECGR 4146/5146 — Intro to VHDL (Spring 2026)**
**University of North Carolina at Charlotte**

---

## Overview

This project implements a complete Universal Asynchronous Receiver/Transmitter (UART) subsystem in VHDL, including a baud rate generator, receiver, transmitter, FIFO-based interface, RAM storage, and a classification engine. The design is simulated and verified in Xilinx Vivado 2024.2.

## Architecture

```
RX ──► UART Receiver ──► RX FIFO ──► FSM ──► RAM ──► Classification Engine
                                                              │
TX ◄── UART Transmitter ◄── TX FIFO ◄────────────────────────┘
```

### Modules

| Module | File | Description |
|--------|------|-------------|
| Baud Rate Generator | `src/baud_gen.vhd` | Generates 16× oversampling tick for 9600 baud |
| UART Receiver | `src/uart_rx.vhd` | Serial-to-parallel conversion with start/stop detection |
| UART Transmitter | `src/uart_tx.vhd` | Parallel-to-serial conversion |
| FIFO Buffer | `src/fifo.vhd` | Circular buffer for decoupling RX/TX from processing |
| RAM Module | `src/ram_module.vhd` | 32-bit wide block RAM for data storage |
| FSM Controller | `src/uart_fsm.vhd` | Packs received bytes into 32-bit words, writes to RAM |
| Classification Engine | `src/classification_engine.vhd` | Classifies stored data and sends results to TX |
| Top-Level | `src/uart_top.vhd` | Integrates all modules |

## Repository Structure

```
UART-VHDL-Design/
├── src/                    # VHDL source files
├── tb/                     # Testbench files
├── docs/                   # Report, presentation, references
├── waveforms/              # Simulation waveform screenshots
├── constraints/            # XDC constraint files (if applicable)
├── .gitignore
└── README.md
```

## Getting Started

### Prerequisites

- Xilinx Vivado 2024.2
- Git

### Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/UART-VHDL-Design.git
```

### Running Simulations in Vivado

1. Open Vivado → **Create Project** → RTL Project
2. Add all files from `src/` as design sources
3. Add all files from `tb/` as simulation sources
4. Set the desired testbench as the top-level simulation module
5. Click **Run Simulation** → **Run Behavioral Simulation**

### Simulation Run Times

| Testbench | Recommended Run Time |
|-----------|---------------------|
| `tb_baud_gen` | 200 µs |
| `tb_uart_rx` | 3 ms |
| `tb_uart_tx` | 3 ms |
| `tb_fifo` | 1 µs |
| `tb_ram` | 1 µs |
| `tb_uart_top` | 10 ms |

## Design Parameters

| Parameter | Value |
|-----------|-------|
| System Clock | 100 MHz |
| Baud Rate | 9600 |
| Data Bits | 8 |
| Stop Bits | 1 |
| Parity | None |
| Oversampling | 16× |
| FIFO Depth | 16 entries |
| RAM Width | 32 bits |
| RAM Depth | 32 rows |

---

## Interface Agreement

This section is the **source of truth** for all port names and signal widths. Every member must match these exactly so modules connect cleanly in the top-level integration. The full document is also saved at `docs/INTERFACE_AGREEMENT.md`.

### Global Conventions

| Convention | Rule |
|------------|------|
| Reset | Active HIGH (`reset = '1'` resets the module) |
| Clock | All modules use the same `clk` — 100 MHz, rising edge |
| Done flags | Active HIGH pulse for exactly one clock cycle |
| Idle line | UART RX/TX lines idle HIGH |
| Bit order | LSB first on the serial line |
| Libraries | `IEEE.STD_LOGIC_1164` and `IEEE.NUMERIC_STD` only |

### Port Specifications

#### `baud_gen` ✅ Done

| Port | Dir | Width | Description |
|------|-----|-------|-------------|
| `clk` | in | 1 | 100 MHz system clock |
| `reset` | in | 1 | Active HIGH reset |
| `tick` | out | 1 | Baud tick — HIGH 1 cycle per 651 cycles |

#### `uart_rx` ✅ Done

| Port | Dir | Width | Description |
|------|-----|-------|-------------|
| `clk` | in | 1 | 100 MHz system clock |
| `reset` | in | 1 | Active HIGH reset |
| `rx` | in | 1 | Serial input (idle HIGH) |
| `s_tick` | in | 1 | Baud tick from `baud_gen` |
| `rx_done` | out | 1 | Pulses HIGH 1 cycle when byte is received |
| `dout` | out | 8 | Received byte — valid when `rx_done` HIGH |

#### `uart_tx` (Kenneth)

| Port | Dir | Width | Description |
|------|-----|-------|-------------|
| `clk` | in | 1 | 100 MHz system clock |
| `reset` | in | 1 | Active HIGH reset |
| `tx_start` | in | 1 | Pulse HIGH to begin sending `din` |
| `s_tick` | in | 1 | Baud tick from `baud_gen` |
| `din` | in | 8 | Byte to transmit |
| `tx_done` | out | 1 | Pulses HIGH 1 cycle when transmission complete |
| `tx` | out | 1 | Serial output (idle HIGH) |

#### `fifo` (Eric)

| Port | Dir | Width | Description |
|------|-----|-------|-------------|
| `clk` | in | 1 | 100 MHz system clock |
| `reset` | in | 1 | Active HIGH reset — clears FIFO |
| `wr` | in | 1 | Write enable |
| `rd` | in | 1 | Read enable |
| `w_data` | in | 8 | Data in |
| `r_data` | out | 8 | Data out — valid when `empty` LOW |
| `empty` | out | 1 | HIGH when FIFO is empty |
| `full` | out | 1 | HIGH when FIFO is full |

> Generics: `B => 8` (data width), `W => 4` (addr width, depth = 16). Two instances: `rx_fifo` and `tx_fifo`.

#### `ram_module` (Eric)

| Port | Dir | Width | Description |
|------|-----|-------|-------------|
| `clk` | in | 1 | 100 MHz system clock |
| `we` | in | 1 | Write enable |
| `addr` | in | 5 | Row address (0–31) |
| `din` | in | 32 | Data to write |
| `dout` | out | 32 | Data read — 1 cycle latency |

#### `uart_fsm` (Alberto)

| Port | Dir | Width | Description |
|------|-----|-------|-------------|
| `clk` | in | 1 | 100 MHz system clock |
| `reset` | in | 1 | Active HIGH reset |
| `fifo_empty` | in | 1 | From `rx_fifo.empty` |
| `fifo_dout` | in | 8 | From `rx_fifo.r_data` |
| `fifo_rd` | out | 1 | Read strobe to `rx_fifo` |
| `ram_we` | out | 1 | Write enable to `ram_module` |
| `ram_addr` | out | 5 | RAM row being written |
| `ram_din` | out | 32 | 4 bytes packed: `byte3 & byte2 & byte1 & byte0` |
| `fsm_done` | out | 1 | Pulses HIGH when all 32 rows written |

#### `classification_engine` (Sebastian)

| Port | Dir | Width | Description |
|------|-----|-------|-------------|
| `clk` | in | 1 | 100 MHz system clock |
| `reset` | in | 1 | Active HIGH reset |
| `start` | in | 1 | Pulse HIGH (from `fsm_done`) to begin |
| `ram_dout` | in | 32 | From `ram_module.dout` |
| `ram_addr` | out | 5 | Address being read from RAM |
| `result` | out | 8 | One result byte — valid when `result_valid` HIGH |
| `result_valid` | out | 1 | Pulses HIGH 1 cycle per result byte |
| `done` | out | 1 | Pulses HIGH when all results produced |

### Top-Level Signal Connections

| From Module | Signal | To Module | Signal |
|-------------|--------|-----------|--------|
| `baud_gen` | `tick` | `uart_rx` | `s_tick` |
| `baud_gen` | `tick` | `uart_tx` | `s_tick` |
| `uart_rx` | `rx_done` | `rx_fifo` | `wr` |
| `uart_rx` | `dout` | `rx_fifo` | `w_data` |
| `rx_fifo` | `empty` | `uart_fsm` | `fifo_empty` |
| `rx_fifo` | `r_data` | `uart_fsm` | `fifo_dout` |
| `uart_fsm` | `fifo_rd` | `rx_fifo` | `rd` |
| `uart_fsm` | `ram_we` | `ram_module` | `we` |
| `uart_fsm` | `ram_addr` | `ram_module` | `addr` *(muxed)* |
| `uart_fsm` | `ram_din` | `ram_module` | `din` |
| `uart_fsm` | `fsm_done` | `classification_engine` | `start` |
| `ram_module` | `dout` | `classification_engine` | `ram_dout` |
| `classification_engine` | `ram_addr` | `ram_module` | `addr` *(muxed)* |
| `classification_engine` | `result` | `tx_fifo` | `w_data` |
| `classification_engine` | `result_valid` | `tx_fifo` | `wr` |
| `tx_fifo` | `r_data` | `uart_tx` | `din` |

> **RAM address mux:** `uart_fsm` drives `addr` while writing (before `fsm_done`). `classification_engine` drives `addr` while reading (after `fsm_done`). The top-level muxes these based on `fsm_done`.

---

## Branch Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Stable, tested code only — merged by integrator |
| `dev/baud-gen` | Baud rate generator development |
| `dev/uart-rx` | UART receiver development |
| `dev/uart-tx` | UART transmitter development |
| `dev/fifo` | FIFO buffer development |
| `dev/ram` | RAM module development |
| `dev/fsm` | FSM controller development |
| `dev/classification` | Classification engine development |
| `dev/top-level` | Top-level integration |
| `docs/report` | Report and presentation files |

## Team

| Member | Role | Modules |
|--------|------|---------|
| Alberto | Integrator | Baud Rate Generator, UART Receiver, FSM Controller |
| Kenneth | — | UART Transmitter, Register Interface |
| Eric | — | FIFO, RAM |
| Sebastian | — | Classification Engine, Top-Level, Report |

## Milestones

See the [Issues](../../issues) tab and [Project Board](../../projects) for current task status.
