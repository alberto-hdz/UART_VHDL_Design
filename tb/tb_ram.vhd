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

    -- clock
    process
    begin
        while true loop
            clk <= '0'; wait for 5 ns;
            clk <= '1'; wait for 5 ns;
        end loop;
    end process;

    -- test
    process
    begin
        --------------------------------------------------
        -- write to address 0
        --------------------------------------------------
        addr <= "00000";
        din  <= x"12345678";
        we   <= '1';
        wait for CLK_PERIOD;

        we <= '0';
        wait for CLK_PERIOD;

        --------------------------------------------------
        -- read address 0
        --------------------------------------------------
        wait for CLK_PERIOD;

        assert dout = x"12345678"
            report "ERROR: RAM read failed"
            severity error;

        --------------------------------------------------
        -- overwrite
        --------------------------------------------------
        we   <= '1';
        din  <= x"AAAAAAAA";
        wait for CLK_PERIOD;

        we <= '0';
        wait for CLK_PERIOD;

        assert dout = x"AAAAAAAA"
            report "ERROR: overwrite failed"
            severity error;

        report "RAM test passed" severity note;
        wait;
    end process;

end sim;
