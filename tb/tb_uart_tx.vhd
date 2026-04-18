-- ============================================
-- Testbench: tb_uart_tx
-- Description: Verifies the UART transmitter
-- by applying input data and tx_start, and
-- observing correct serial output and tx_done.
-- Author: Kenneth Le
-- Date: 2026-04-22
-- ============================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_uart_tx is
end tb_uart_tx;

architecture sim of tb_uart_tx is
    constant CLK_PERIOD : time := 10 ns;

    signal clk      : std_logic := '0';
    signal reset    : std_logic := '1';
    signal tx_start : std_logic := '0';
    signal s_tick   : std_logic := '0';
    signal din      : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_done  : std_logic;
    signal tx       : std_logic;

begin
    -- DUT
    uut: entity work.uart_tx
        generic map(
            DBIT    => 8,
            SB_TICK => 16
        )
        port map(
            clk      => clk,
            reset    => reset,
            tx_start => tx_start,
            s_tick   => s_tick,
            din      => din,
            tx_done  => tx_done,
            tx       => tx
        );
    
    -- Clock
    clk_process: process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- s_tick generator
    tick_process: process
        variable count : integer := 0;
    begin
        while true loop
            wait until rising_edge(clk);
            if count = 15 then
                s_tick <= '1';
                count := 0; -- reset
            else
                s_tick <= '0';
                count := count + 1; -- +1 counter
            end if;
        end loop;
    end process;

    -- Stimulus
    stim_process: process
    begin
        -- reset
        wait for 50 ns;
        reset <= '0';
        wait for 50 ns;

        -- Test Case 1: Send x"55" = 01010101
        -- UART transmits LSB first => 1 0 1 0 1 0 1 0
        din <= x"55";
        tx_start <= '1';
        wait for 20 ns;
        tx_start <= '0';

        wait until tx_done = '1';
        wait for 2 us;

        -- Test Case 2: Send x"A3" = 10100011
        -- UART transmits LSB first => 1 1 0 0 0 1 0 1
        wait for 100 ns;
        din <= x"A3";
        tx_start <= '1';
        wait for 20 ns;
        tx_start <= '0';

        wait until tx_done = '1';
        wait for 2 us;

        assert false report "tb_uart_tx completed successfully." severity failure;
    end process;
end sim;