-- ============================================
-- Module: uart_rx
-- Description: UART receiver with 16x oversampling
--   Uses a 4-state FSM: idle, start, data, stop
--   Samples incoming rx line at the middle of each
--   bit using the baud rate tick. Receives LSB first.
-- Author: Alberto Hernandez
-- Date: 2026-04-01
-- ============================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_rx is
    generic(
        DBIT    : integer := 8;   -- number of data bits
        SB_TICK : integer := 16   -- ticks for 1 stop bit (16 ticks = 1 bit)
    );
    port(
        clk       : in  std_logic;
        reset     : in  std_logic;
        rx        : in  std_logic;         -- serial input line
        s_tick    : in  std_logic;         -- baud rate tick (16x oversample)
        rx_done   : out std_logic;         -- pulses high when byte is received
        dout      : out std_logic_vector(7 downto 0)  -- received byte
    );
end uart_rx;

architecture arch of uart_rx is

    -- FSM states
    type state_type is (idle, start, data, stop);
    signal state, state_next : state_type;

    -- tick counter: counts 0-15 within each bit period
    signal s_count, s_count_next : unsigned(3 downto 0);

    -- bit counter: counts which data bit we're receiving (0-7)
    signal n_count, n_count_next : unsigned(2 downto 0);

    -- shift register: holds incoming bits
    signal shift, shift_next : std_logic_vector(7 downto 0);

begin

    -- register update: all state held in flip-flops
    process(clk, reset)
    begin
        if reset = '1' then
            state   <= idle;
            s_count <= (others => '0');
            n_count <= (others => '0');
            shift   <= (others => '0');
        elsif rising_edge(clk) then
            state   <= state_next;
            s_count <= s_count_next;
            n_count <= n_count_next;
            shift   <= shift_next;
        end if;
    end process;

    -- next-state and output logic
    process(state, rx, s_tick, s_count, n_count, shift)
    begin
        -- defaults: hold current values
        state_next   <= state;
        s_count_next <= s_count;
        n_count_next <= n_count;
        shift_next   <= shift;
        rx_done      <= '0';

        case state is

            -- IDLE: wait for start bit (rx goes low)
            when idle =>
                if rx = '0' then
                    state_next   <= start;
                    s_count_next <= (others => '0');
                end if;

            -- START: wait 7 ticks to reach middle of start bit
            when start =>
                if s_tick = '1' then
                    if s_count = 7 then
                        -- we're at the middle of the start bit
                        state_next   <= data;
                        s_count_next <= (others => '0');
                        n_count_next <= (others => '0');
                    else
                        s_count_next <= s_count + 1;
                    end if;
                end if;

            -- DATA: sample each data bit at the middle (tick 15)
            when data =>
                if s_tick = '1' then
                    if s_count = 15 then
                        -- middle of this data bit: sample rx
                        s_count_next <= (others => '0');
                        -- shift rx into MSB (LSB arrives first, shifts right)
                        shift_next <= rx & shift(7 downto 1);

                        if n_count = DBIT - 1 then
                            -- all bits received, move to stop
                            state_next <= stop;
                        else
                            n_count_next <= n_count + 1;
                        end if;
                    else
                        s_count_next <= s_count + 1;
                    end if;
                end if;

            -- STOP: wait for stop bit duration
            when stop =>
                if s_tick = '1' then
                    if s_count = SB_TICK - 1 then
                        -- stop bit complete, signal done
                        state_next <= idle;
                        rx_done    <= '1';
                    else
                        s_count_next <= s_count + 1;
                    end if;
                end if;

        end case;
    end process;

    -- output the received byte
    dout <= shift;

end arch;
