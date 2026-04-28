-- ============================================
-- Testbench: tb_uart_fsm
-- Description: Verifies the FSM reads bytes from the
--   FIFO and writes 32-bit packed words to RAM correctly.
--   Pre-loads 128 bytes into a FWFT FIFO model (32 RAM words).
--   Expected results:
--     RAM[0]  = 0xA4A3A2A1  (bytes A1,A2,A3,A4 packed little-endian)
--     RAM[1]  = 0xB4B3B2B1  (bytes B1,B2,B3,B4 packed little-endian)
--     RAM[31] = 0xE4E3E2E1  (bytes E1,E2,E3,E4 packed little-endian)
-- Author: Alberto Hernandez
-- Date: 2026-04-14
-- ============================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_uart_fsm is
end tb_uart_fsm;

architecture sim of tb_uart_fsm is

    -- signals connecting to the UUT
    signal clk        : std_logic := '0';
    signal reset      : std_logic := '1';
    signal fifo_empty : std_logic;
    signal fifo_dout  : std_logic_vector(7 downto 0);
    signal fifo_rd    : std_logic;
    signal ram_we     : std_logic;
    signal ram_addr   : std_logic_vector(4 downto 0);
    signal ram_din    : std_logic_vector(31 downto 0);
    signal fsm_done   : std_logic;

    constant CLK_PERIOD : time := 10 ns;  -- 100 MHz

    -- FIFO model: 128 pre-loaded bytes (32 words), FWFT behavior
    -- r_data (fifo_dout) is valid whenever empty is LOW
    -- asserting fifo_rd advances the read pointer on the next rising edge
    type fifo_mem_t is array (0 to 127) of std_logic_vector(7 downto 0);
    constant FIFO_DATA : fifo_mem_t := (
        -- Row 0: bytes A1..A4  -> RAM[0] = 0xA4A3A2A1
        0 => x"A1", 1 => x"A2", 2 => x"A3", 3 => x"A4",
        -- Row 1: bytes B1..B4  -> RAM[1] = 0xB4B3B2B1
        4 => x"B1", 5 => x"B2", 6 => x"B3", 7 => x"B4",
        -- Rows 2-30: all zero  -> RAM[2..30] = 0x00000000
        8 to 123 => x"00",
        -- Row 31: bytes E1..E4 -> RAM[31] = 0xE4E3E2E1
        124 => x"E1", 125 => x"E2", 126 => x"E3", 127 => x"E4"
    );
    signal rd_ptr : integer range 0 to 128 := 0;

    -- RAM model: 32 rows x 32-bit, matches ram_module interface
    type ram_mem_t is array (0 to 31) of std_logic_vector(31 downto 0);
    signal ram_mem : ram_mem_t := (others => (others => '0'));

begin

    -- unit under test
    uut: entity work.uart_fsm
        port map(
            clk        => clk,
            reset      => reset,
            fifo_empty => fifo_empty,
            fifo_dout  => fifo_dout,
            fifo_rd    => fifo_rd,
            ram_we     => ram_we,
            ram_addr   => ram_addr,
            ram_din    => ram_din,
            fsm_done   => fsm_done
        );

    -- clock: toggles every 5 ns = 100 MHz
    clk <= not clk after CLK_PERIOD / 2;

    -- FWFT FIFO model: r_data always shows the current head byte
    fifo_dout  <= FIFO_DATA(rd_ptr) when rd_ptr < 128 else (others => '0');
    fifo_empty <= '1' when rd_ptr >= 128 else '0';

    -- advance the read pointer when the FSM pops a byte
    fifo_proc: process(clk, reset)
    begin
        if reset = '1' then
            rd_ptr <= 0;
        elsif rising_edge(clk) then
            if fifo_rd = '1' and rd_ptr < 128 then
                rd_ptr <= rd_ptr + 1;
            end if;
        end if;
    end process;

    -- RAM model: synchronous write on rising edge when we is HIGH
    ram_proc: process(clk)
    begin
        if rising_edge(clk) then
            if ram_we = '1' then
                ram_mem(to_integer(unsigned(ram_addr))) <= ram_din;
            end if;
        end if;
    end process;

    -- stimulus and result checking
    stim: process
    begin
        -- hold reset for 100 ns
        reset <= '1';
        wait for 100 ns;
        reset <= '0';

        -- wait for the FSM to signal completion (single-cycle pulse)
        wait until rising_edge(clk) and fsm_done = '1';
        wait for CLK_PERIOD;

        -- TEST 1: first 4 bytes (A1,A2,A3,A4) packed little-endian into RAM[0]
        assert ram_mem(0) = x"A4A3A2A1"
            report "TEST 1 FAILED: RAM[0] expected 0xA4A3A2A1, got " &
                   integer'image(to_integer(unsigned(ram_mem(0))))
            severity error;
        report "TEST 1 PASSED: RAM[0] = 0xA4A3A2A1" severity note;

        -- TEST 2: next 4 bytes (B1,B2,B3,B4) packed little-endian into RAM[1]
        assert ram_mem(1) = x"B4B3B2B1"
            report "TEST 2 FAILED: RAM[1] expected 0xB4B3B2B1, got " &
                   integer'image(to_integer(unsigned(ram_mem(1))))
            severity error;
        report "TEST 2 PASSED: RAM[1] = 0xB4B3B2B1" severity note;

        -- TEST 3: last 4 bytes (E1,E2,E3,E4) packed little-endian into RAM[31]
        assert ram_mem(31) = x"E4E3E2E1"
            report "TEST 3 FAILED: RAM[31] expected 0xE4E3E2E1, got " &
                   integer'image(to_integer(unsigned(ram_mem(31))))
            severity error;
        report "TEST 3 PASSED: RAM[31] = 0xE4E3E2E1" severity note;

        report "All FSM tests complete" severity note;
        wait;
    end process;

end sim;
