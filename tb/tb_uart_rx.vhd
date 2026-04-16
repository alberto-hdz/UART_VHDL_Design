-- ============================================
-- Testbench: tb_uart_rx
-- Description: Verifies the UART receiver by
--   driving the rx line with known byte patterns
--   and checking the dout output when rx_done fires.
--   Sends 0x41 ('A') and 0x55 ('U') at 9600 baud.
-- Author: Alberto Hernandez
-- Date: 2026-04-01
-- ============================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_uart_rx is
end tb_uart_rx;

architecture sim of tb_uart_rx is

    signal clk     : std_logic := '0';
    signal reset   : std_logic := '1';
    signal rx      : std_logic := '1';  -- idle state is high
    signal s_tick  : std_logic;
    signal rx_done : std_logic;
    signal dout    : std_logic_vector(7 downto 0);

    constant CLK_PERIOD : time := 10 ns;      -- 100 MHz
    constant BIT_PERIOD : time := 104167 ns;   -- 1 / 9600 baud in ns

begin

    -- baud rate generator instance
    baud_inst: entity work.baud_gen
        generic map(M => 651)
        port map(
            clk   => clk,
            reset => reset,
            tick  => s_tick
        );

    -- unit under test: UART receiver
    uut: entity work.uart_rx
        generic map(DBIT => 8, SB_TICK => 16)
        port map(
            clk     => clk,
            reset   => reset,
            rx      => rx,
            s_tick  => s_tick,
            rx_done => rx_done,
            dout    => dout
        );

    -- clock: toggles every 5 ns = 100 MHz
    clk <= not clk after CLK_PERIOD / 2;

    -- stimulus process
    stim: process

        -- procedure to send one byte on the rx line
        -- drives start bit, 8 data bits (LSB first), stop bit
        procedure send_byte(data : std_logic_vector(7 downto 0)) is
        begin
            -- start bit: drive rx low
            rx <= '0';
            wait for BIT_PERIOD;

            -- 8 data bits, LSB first
            for i in 0 to 7 loop
                rx <= data(i);
                wait for BIT_PERIOD;
            end loop;

            -- stop bit: drive rx high
            rx <= '1';
            wait for BIT_PERIOD;
        end procedure;

    begin
        -- hold reset
        reset <= '1';
        wait for 100 ns;
        reset <= '0';

        -- wait for baud gen to stabilize
        wait for 10 us;

        -- TEST 1: send 0x41 = 'A' = "01000001"
        send_byte("01000001");
        -- wait for rx_done, then check output
        wait until rx_done = '1';
        wait for CLK_PERIOD;
        assert dout = "01000001"
            report "TEST 1 FAILED: expected 0x41, got " & integer'image(to_integer(unsigned(dout)))
            severity error;
        report "TEST 1 PASSED: received 0x41 ('A')" severity note;

        -- gap between bytes
        wait for 50 us;

        -- TEST 2: send 0x55 = 'U' = "01010101"
        send_byte("01010101");
        wait until rx_done = '1';
        wait for CLK_PERIOD;
        assert dout = "01010101"
            report "TEST 2 FAILED: expected 0x55, got " & integer'image(to_integer(unsigned(dout)))
            severity error;
        report "TEST 2 PASSED: received 0x55 ('U')" severity note;

        wait for 50 us;

        -- TEST 3: send 0xFF = "11111111"
        send_byte("11111111");
        wait until rx_done = '1';
        wait for CLK_PERIOD;
        assert dout = "11111111"
            report "TEST 3 FAILED: expected 0xFF"
            severity error;
        report "TEST 3 PASSED: received 0xFF" severity note;

        wait for 50 us;

        -- TEST 4: send 0x00 = "00000000"
        send_byte("00000000");
        wait until rx_done = '1';
        wait for CLK_PERIOD;
        assert dout = "00000000"
            report "TEST 4 FAILED: expected 0x00"
            severity error;
        report "TEST 4 PASSED: received 0x00" severity note;

        wait for 50 us;

        report "All UART RX tests complete" severity note;
        wait;
    end process;

end sim;
