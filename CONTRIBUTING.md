# Contributing Guide

This document explains how we collaborate on this project. Read it before pushing any code.

## Git Workflow

We use a **feature-branch workflow**. Nobody pushes directly to `main`.

### Step-by-step for every task:

1. **Pull the latest main branch first:**
   ```bash
   git checkout main
   git pull origin main
   ```

2. **Create a branch for your work:**
   ```bash
   git checkout -b dev/your-module-name
   ```
   Use the branch names listed in the README (e.g., `dev/uart-rx`, `dev/fifo`).

3. **Do your work.** Write code, test it, make sure it compiles.

4. **Commit with a clear message:**
   ```bash
   git add .
   git commit -m "Add UART receiver with 4-state FSM"
   ```
   Good commit messages describe *what* you did, not *that* you did something.
   - Good: `"Add FIFO testbench with write/read/overflow tests"`
   - Bad: `"updated files"` or `"stuff"`

5. **Push your branch:**
   ```bash
   git push origin dev/your-module-name
   ```

6. **Open a Pull Request (PR) on GitHub:**
   - Go to the repo on GitHub
   - You'll see a banner saying your branch was recently pushed → click **Compare & pull request**
   - Title: what the PR does (e.g., "Add UART receiver module and testbench")
   - Description: briefly explain your design decisions and what signals to look at in simulation
   - Assign the integrator as reviewer

7. **Wait for review.** The integrator will review, comment, and merge into `main`.

## Code Standards

### File naming
- Source files: `src/module_name.vhd` (lowercase, underscores)
- Testbenches: `tb/tb_module_name.vhd`
- Waveform screenshots: `waveforms/module_name_description.png`

### VHDL style
- Use **lowercase** for all VHDL keywords and signal names
- Use **descriptive signal names** (e.g., `rx_done` not `rd`)
- Include a **file header comment** in every file:
  ```vhdl
  -- ============================================
  -- Module: uart_rx
  -- Description: UART receiver with 16x oversampling
  -- Author: Your Name
  -- Date: 2026-03-25
  -- ============================================
  ```
- Comment your FSM states and key logic, but don't comment obvious things like `clk <= not clk`
- Use `std_logic` and `unsigned` from `IEEE.NUMERIC_STD` — avoid `std_logic_arith`

### Testbench requirements
- Every module must have a testbench before it can be merged
- Testbenches must include at least one `assert` or `report` statement
- Include a note at the top of the testbench explaining what it tests

## Waveform Screenshots

When you capture waveforms:
1. Zoom to show the relevant behavior clearly
2. Add signal labels if they're not obvious
3. Save as PNG to `waveforms/` with a descriptive name
4. Reference the waveform in your report section

## If You Hit a Merge Conflict

Don't panic. This usually means two people edited the same file.

```bash
git checkout main
git pull origin main
git checkout dev/your-branch
git merge main
# Fix conflicts in your editor (look for <<<<<<< markers)
git add .
git commit -m "Resolve merge conflict with main"
git push origin dev/your-branch
```

If you're stuck, message the group chat and the integrator will help.

## Questions?

Ask in the group chat before spending hours stuck on something.
