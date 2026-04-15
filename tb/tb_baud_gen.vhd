-- ============================================
-- Testbench: tb_baud_gen
-- Description: Verifies the baud rate generator
--   produces tick pulses at the correct interval.
--   Expected: tick every 651 clock cycles (6.51 us at 100 MHz)
-- Author: Alberto Hernandez
-- Date: 2026-03-25
-- ============================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_baud_gen is
end tb_baud_gen;

architecture sim of tb_baud_gen is

    -- signals connecting to the unit under test
    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';
    signal tick  : std_logic;

    constant CLK_PERIOD : time := 10 ns;  -- 100 MHz clock

begin

    -- instantiate the baud rate generator
    uut: entity work.baud_gen
        generic map(M => 651)
        port map(
            clk   => clk,
            reset => reset,
            tick  => tick
        );

    -- clock generation: toggles every half period
    clk <= not clk after CLK_PERIOD / 2;

    -- stimulus process
    stim: process
    begin
        -- hold reset for 100 ns
        reset <= '1';
        wait for 100 ns;

        -- release reset and let it run
        reset <= '0';

        -- run long enough to see ~30 ticks (30 * 6.51 us = ~195 us)
        wait for 200 us;

        -- end simulation
        assert false report "Baud gen simulation complete -- check tick spacing is ~6.51 us" severity note;
        wait;
    end process;

end sim;
