-- ============================================
-- Module: ram_module
-- Description: 32-bit wide synchronous block
-- RAM with configurable depth for data storage.
-- Author: Eric Contreras
-- Date: 2026-04-07
-- ============================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_module is
    generic (
        DATA_WIDTH : integer := 32;
        ADDR_WIDTH : integer := 5   -- 32 rows
    );
    port (
        clk  : in  std_logic;
        we   : in  std_logic;
        addr : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        din  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        dout : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end ram_module;

architecture rtl of ram_module is

    type ram_type is array (0 to (2**ADDR_WIDTH)-1)
        of std_logic_vector(DATA_WIDTH-1 downto 0);

    signal ram      : ram_type := (others => (others => '0'));
    signal dout_reg : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

    process(clk)
    begin
        if rising_edge(clk) then

            -- write
            if we = '1' then
                ram(to_integer(unsigned(addr))) <= din;
            end if;

            -- synchronous read
            dout_reg <= ram(to_integer(unsigned(addr)));

        end if;
    end process;

    dout <= dout_reg;

end rtl;
