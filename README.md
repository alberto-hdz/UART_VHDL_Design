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
UART_VHDL_Design/
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
git clone https://github.com/alberto-hdz/uart_vhdl_design.git
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
| `tb_uart_fsm` | 5 ms |
| `tb_classification_engine` | 5 ms |
| `tb_loopback` | 10 ms |
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

All agreed-upon port names, signal widths, active levels, and top-level connections are documented in [`docs/INTERFACE_AGREEMENT.md`](docs/INTERFACE_AGREEMENT.md). Every team member must read this before writing any VHDL — it is the source for how modules connect.

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
| Erik | — | FIFO, RAM |
| Sebastian | — | Classification Engine, Top-Level, Report |

## Milestones

See the [Issues](../../issues) tab and [Project Board](../../projects) for current task status.

---

## Contributing & Community

- **[Contributing Guide](CONTRIBUTING.md)** — Workflow, code standards, and collaboration practices
- **[Security Policy](SECURITY.md)**
- **[License](LICENSE)** — Project licensing information
