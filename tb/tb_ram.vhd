-- ============================================
-- Testbench: tb_ram
-- Description: Verifies synchronous RAM write,
-- read, and overwrite operations.
-- Author: econtre7
-- Date: 2026-04-07
-- ============================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_ram is
end tb_ram;

architecture sim of tb_ram is

    signal clk  : std_logic := '0';
    signal we   : std_logic := '0';
    signal addr : std_logic_vector(4 downto 0) := (others => '0');
    signal din  : std_logic_vector(31 downto 0) := (others => '0');
    signal dout : std_logic_vector(31 downto 0);

    constant CLK_PERIOD : time := 10 ns;

begin

    uut: entity work.ram_module
        port map (
            clk  => clk,
            we   => we,
            addr => addr,
            din  => din,
            dout => dout
        );

    process
    begin
        while true loop
            clk <= '0'; wait for 5 ns;
            clk <= '1'; wait for 5 ns;
        end loop;
    end process;

    process
    begin
        --------------------------------------------------
        -- Write to 5 different addresses
        --------------------------------------------------
        addr <= "00000"; din <= x"11111111"; we <= '1'; wait for CLK_PERIOD;
        addr <= "00001"; din <= x"22222222";              wait for CLK_PERIOD;
        addr <= "00010"; din <= x"33333333";              wait for CLK_PERIOD;
        addr <= "00011"; din <= x"44444444";              wait for CLK_PERIOD;
        addr <= "00100"; din <= x"55555555";              wait for CLK_PERIOD;
        we <= '0';
        wait for CLK_PERIOD;

        --------------------------------------------------
        -- Read back and verify all 5 addresses
        --------------------------------------------------
        addr <= "00000"; wait for CLK_PERIOD;
        assert dout = x"11111111"
            report "ERROR: addr 0 read failed" severity error;

        addr <= "00001"; wait for CLK_PERIOD;
        assert dout = x"22222222"
            report "ERROR: addr 1 read failed" severity error;

        addr <= "00010"; wait for CLK_PERIOD;
        assert dout = x"33333333"
            report "ERROR: addr 2 read failed" severity error;

        addr <= "00011"; wait for CLK_PERIOD;
        assert dout = x"44444444"
            report "ERROR: addr 3 read failed" severity error;

        addr <= "00100"; wait for CLK_PERIOD;
        assert dout = x"55555555"
            report "ERROR: addr 4 read failed" severity error;

        --------------------------------------------------
        -- Overwrite address 0 and verify
        --------------------------------------------------
        addr <= "00000"; din <= x"AAAAAAAA"; we <= '1';
        wait for CLK_PERIOD;
        we <= '0';
        wait for CLK_PERIOD;

        assert dout = x"AAAAAAAA"
            report "ERROR: overwrite addr 0 failed" severity error;

        report "RAM test passed" severity note;
        wait;
    end process;

end sim;
