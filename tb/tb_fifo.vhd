-- ============================================
-- Testbench: tb_fifo
-- Description: Verifies FIFO read/write, full,
-- empty, and simultaneous access behavior.
-- Author: econtre7
-- Date: 2026-04-07
-- ============================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fifo is
end tb_fifo;

architecture sim of tb_fifo is

    constant DATA_WIDTH : integer := 8;
    constant ADDR_WIDTH : integer := 4;  -- 16 pointer locations

    signal clk    : std_logic := '0';
    signal reset  : std_logic := '0';
    signal wr     : std_logic := '0';
    signal rd     : std_logic := '0';
    signal w_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal r_data : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal empty  : std_logic;
    signal full   : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    -- DUT
    uut: entity work.fifo
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            ADDR_WIDTH => ADDR_WIDTH
        )
        port map (
            clk    => clk,
            reset  => reset,
            wr     => wr,
            rd     => rd,
            w_data => w_data,
            r_data => r_data,
            empty  => empty,
            full   => full
        );

    -- Clock generation
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- Stimulus
    stim_proc : process
    begin
        ------------------------------------------------------------
        -- 1. Reset
        ------------------------------------------------------------
        reset <= '1';
        wr    <= '0';
        rd    <= '0';
        w_data <= (others => '0');
        wait for 30 ns;
        reset <= '0';
        wait for 20 ns;

        assert (empty = '1')
            report "ERROR: FIFO should be empty after reset"
            severity error;

        assert (full = '0')
            report "ERROR: FIFO should not be full after reset"
            severity error;

        ------------------------------------------------------------
        -- 2. Write 3 bytes
        ------------------------------------------------------------
        w_data <= x"11";
        wr <= '1';
        wait for CLK_PERIOD;
        wr <= '0';
        wait for CLK_PERIOD;

        w_data <= x"22";
        wr <= '1';
        wait for CLK_PERIOD;
        wr <= '0';
        wait for CLK_PERIOD;

        w_data <= x"33";
        wr <= '1';
        wait for CLK_PERIOD;
        wr <= '0';
        wait for CLK_PERIOD;

        assert (empty = '0')
            report "ERROR: FIFO should not be empty after writes"
            severity error;

        ------------------------------------------------------------
        -- 3. Read 3 bytes back
        ------------------------------------------------------------
        rd <= '1';
        wait for CLK_PERIOD;
        rd <= '0';
        wait for 1 ns;
        assert (r_data = x"11")
            report "ERROR: First read should be 0x11"
            severity error;
        wait for CLK_PERIOD - 1 ns;

        rd <= '1';
        wait for CLK_PERIOD;
        rd <= '0';
        wait for 1 ns;
        assert (r_data = x"22")
            report "ERROR: Second read should be 0x22"
            severity error;
        wait for CLK_PERIOD - 1 ns;

        rd <= '1';
        wait for CLK_PERIOD;
        rd <= '0';
        wait for 1 ns;
        assert (r_data = x"33")
            report "ERROR: Third read should be 0x33"
            severity error;
        wait for CLK_PERIOD - 1 ns;

        assert (empty = '1')
            report "ERROR: FIFO should be empty after reading all data"
            severity error;

        ------------------------------------------------------------
        -- 4. Try reading when empty
        ------------------------------------------------------------
        rd <= '1';
        wait for CLK_PERIOD;
        rd <= '0';
        wait for CLK_PERIOD;

        assert (empty = '1')
            report "ERROR: FIFO should remain empty after invalid read"
            severity error;

        ------------------------------------------------------------
        -- 5. Fill FIFO until full
        -- With this pointer scheme, usable capacity is 15
        ------------------------------------------------------------
        for i in 0 to 14 loop
            w_data <= std_logic_vector(to_unsigned(i, DATA_WIDTH));
            wr <= '1';
            wait for CLK_PERIOD;
            wr <= '0';
            wait for CLK_PERIOD;
        end loop;

        assert (full = '1')
            report "ERROR: FIFO should be full after 15 writes"
            severity error;

        ------------------------------------------------------------
        -- 6. Try writing when full
        ------------------------------------------------------------
        w_data <= x"AA";
        wr <= '1';
        wait for CLK_PERIOD;
        wr <= '0';
        wait for CLK_PERIOD;

        assert (full = '1')
            report "ERROR: FIFO should remain full after invalid write"
            severity error;

        ------------------------------------------------------------
        -- 7. Read one item from full FIFO
        ------------------------------------------------------------
        rd <= '1';
        wait for CLK_PERIOD;
        rd <= '0';
        wait for CLK_PERIOD;

        assert (full = '0')
            report "ERROR: FIFO should not be full after one read"
            severity error;

        ------------------------------------------------------------
        -- 8. Simultaneous read/write
        ------------------------------------------------------------
        w_data <= x"55";
        wr <= '1';
        rd <= '1';
        wait for CLK_PERIOD;
        wr <= '0';
        rd <= '0';
        wait for CLK_PERIOD;

        ------------------------------------------------------------
        -- End simulation
        ------------------------------------------------------------
        report "FIFO testbench completed successfully" severity note;
        wait;
    end process;

end sim;
