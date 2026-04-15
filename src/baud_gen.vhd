-- ============================================
-- Module: baud_gen
-- Description: Baud rate generator for UART
--   Produces a single-cycle tick pulse at 16x
--   the target baud rate for oversampling.
--   For 9600 baud with 100 MHz clock:
--   100,000,000 / (9600 * 16) = ~651 cycles per tick
-- Author: Alberto Hernandez
-- Date: 2026-03-25
-- ============================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity baud_gen is
    generic(
        M : integer := 651  -- divisor: clk_freq / (baud * oversample)
    );
    port(
        clk   : in  std_logic;
        reset : in  std_logic;
        tick  : out std_logic
    );
end baud_gen;

architecture arch of baud_gen is
    signal count : integer range 0 to M - 1 := 0;
begin

    -- main counter process: counts from 0 to M-1, then wraps
    process(clk, reset)
    begin
        if reset = '1' then
            count <= 0;
        elsif rising_edge(clk) then
            if count = M - 1 then
                count <= 0;
            else
                count <= count + 1;
            end if;
        end if;
    end process;

    -- tick output: high for exactly one clock cycle when counter wraps
    tick <= '1' when count = M - 1 else '0';

end arch;
