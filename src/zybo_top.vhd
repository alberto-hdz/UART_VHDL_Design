-- ============================================
-- Module: zybo_top
-- Description: Board wrapper for the Zybo Z7-10.
--   - Zybo PL clock is 125 MHz (K17), so BAUD_DIV is
--     125,000,000 / (9600 * 16) = 813.8 -> 814
--     (actual baud 9597.6, about 0.03% error)
--   - BTN0 is the reset. It goes through a reset synchronizer
--     (asserts right away, releases on a clock edge) so every
--     flip-flop leaves reset on the same cycle.
--   - UART rx/tx are on Pmod JE pins 1 and 2.
--   - rx_done / tx_done / classify_done are 1-cycle pulses,
--     too short to see on an LED, so I latch them until reset.
-- Author: Alberto Hernandez
-- Date: 2026-11-02
-- ============================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity zybo_top is
    generic(
        BAUD_DIV : integer := 814   -- 125 MHz / (9600 * 16)
    );
    port(
        sysclk  : in  std_logic;                     -- 125 MHz board clock
        btn0    : in  std_logic;                     -- reset, active HIGH
        uart_rx : in  std_logic;                     -- Pmod JE1
        uart_tx : out std_logic;                     -- Pmod JE2
        led     : out std_logic_vector(3 downto 0)   -- status LEDs
    );
end zybo_top;

architecture arch of zybo_top is

    -- reset synchronizer flops
    signal rst_meta : std_logic := '1';
    signal rst_sync : std_logic := '1';
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of rst_meta : signal is "TRUE";
    attribute ASYNC_REG of rst_sync : signal is "TRUE";

    -- status pulses from uart_top
    signal rx_done_p, tx_done_p, fifo_full_s, class_done_p : std_logic;

    -- latched versions for the LEDs
    signal rx_seen, tx_seen, class_seen : std_logic := '0';

begin

    -- reset synchronizer: async assert, sync release
    process(sysclk, btn0)
    begin
        if btn0 = '1' then
            rst_meta <= '1';
            rst_sync <= '1';
        elsif rising_edge(sysclk) then
            rst_meta <= '0';
            rst_sync <= rst_meta;
        end if;
    end process;

    U_UART_TOP : entity work.uart_top
        generic map(BAUD_DIV => BAUD_DIV)
        port map(
            clk           => sysclk,
            reset         => rst_sync,
            rx            => uart_rx,
            tx            => uart_tx,
            rx_done_out   => rx_done_p,
            tx_done_out   => tx_done_p,
            fifo_full     => fifo_full_s,
            classify_done => class_done_p
        );

    -- latch the done pulses so they stay visible on the LEDs
    process(sysclk, rst_sync)
    begin
        if rst_sync = '1' then
            rx_seen    <= '0';
            tx_seen    <= '0';
            class_seen <= '0';
        elsif rising_edge(sysclk) then
            if rx_done_p = '1' then
                rx_seen <= '1';
            end if;
            if tx_done_p = '1' then
                tx_seen <= '1';
            end if;
            if class_done_p = '1' then
                class_seen <= '1';
            end if;
        end if;
    end process;

    led(0) <= rx_seen;       -- at least one byte received
    led(1) <= tx_seen;       -- at least one byte sent
    led(2) <= fifo_full_s;   -- RX FIFO full right now
    led(3) <= class_seen;    -- classification finished

end arch;
