-- ============================================
-- Module: uart_tx
-- Description: UART transmitter that converts
-- 8-bit parallel data into a serial frame
-- (start, data, stop) using s_tick timing.
-- Author: Kenneth Le
-- Date: 2026-04-22
-- ============================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
    generic(
        DBIT    : integer := 8;   -- number of data bits
        SB_TICK : integer := 16   -- ticks for 1 stop bit
    );
    port(
        clk      : in  std_logic;
        reset    : in  std_logic;
        tx_start : in  std_logic;                     -- pulse HIGH to begin transmission
        s_tick   : in  std_logic;                     -- baud tick from baud_gen
        din      : in  std_logic_vector(7 downto 0);  -- byte to transmit
        tx_done  : out std_logic;                     -- HIGH 1 cycle when byte sent
        tx       : out std_logic                      -- serial output, idle HIGH
    );
end uart_tx;

architecture rtl of uart_tx is
    type state_type is (idle, start, data, stop);
    signal state_reg, state_next : state_type; -- state registers
    signal s_reg, s_next : unsigned(3 downto 0);  -- counts ticks in one bit
    signal n_reg, n_next : unsigned(2 downto 0);  -- counts data bits sent
    signal b_reg, b_next : std_logic_vector(7 downto 0); -- holds data being transmitted
    signal tx_reg, tx_next : std_logic; -- output value 
    signal tx_done_reg, tx_done_next : std_logic; -- done signal 

begin
    -- State & datapath registers
    process(clk, reset)
    begin
        if reset = '1' then
            -- Reset all registers
            state_reg <= idle;
            s_reg <= (others => '0');
            n_reg <= (others => '0');
            b_reg <= (others => '0');
            tx_reg <= '1';   -- UART idle line is HIGH
            tx_done_reg <= '0';
        elsif rising_edge(clk) then
            -- Update to next registers
            state_reg <= state_next;
            s_reg <= s_next;
            n_reg <= n_next;
            b_reg <= b_next;
            tx_reg <= tx_next;
            tx_done_reg <= tx_done_next;
        end if;
    end process;

    -- Next-state logic
    process(state_reg, s_reg, n_reg, b_reg, tx_start, s_tick, din)
    begin
        -- Set next state registers to current by default
        state_next <= state_reg;
        s_next <= s_reg;
        n_next <= n_reg;
        b_next <= b_reg;
        tx_next <= tx_reg;
        tx_done_next <= '0';

        case state_reg is
            when idle =>
                tx_next <= '1';
                if tx_start = '1' then
                    b_next <= din;
                    s_next <= (others => '0');
                    n_next <= (others => '0');
                    state_next <= start;
                end if;
            when start =>
                tx_next <= '0';  -- start bit
                if s_tick = '1' then
                    if s_reg = 15 then
                        s_next <= (others => '0'); -- reset counter
                        state_next <= data;
                    else
                        s_next <= s_reg + 1; -- +1 counter
                    end if;
                end if;
            when data =>
                tx_next <= b_reg(0);  -- LSB first
                if s_tick = '1' then
                    if s_reg = 15 then
                        s_next <= (others => '0'); -- reset counter
                        b_next <= '0' & b_reg(7 downto 1);  -- shift right to get next LSB
                        if n_reg = DBIT - 1 then -- enter stop state when all bits are sent
                            state_next <= stop;
                        else
                            n_next <= n_reg + 1; -- +1 counter
                        end if;
                    else
                        s_next <= s_reg + 1; -- +1 counter
                    end if;
                end if;
            when stop =>
                tx_next <= '1';  -- stop bit
                if s_tick = '1' then
                    if s_reg = SB_TICK - 1 then
                        s_next <= (others => '0'); -- reset
                        tx_done_next <= '1';
                        state_next <= idle; -- go back to idle state
                    else
                        s_next <= s_reg + 1; -- +1 counter
                    end if;
                end if;
        end case;
    end process;
    
    -- Output logic
    tx <= tx_reg;
    tx_done <= tx_done_reg;
end rtl;