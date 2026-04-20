-- ============================================
-- Testbench: tb_loopback
-- Description: Integration test for UART RX-to-TX
-- loopback using a register between receiver and
-- transmitter. Received bytes are stored and then
-- retransmitted when rx_done is asserted.
-- Author: Kenneth Le
-- Date: 2026-03-30
-- ============================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_loopback is
end tb_loopback;

architecture sim of tb_loopback is
    constant CLK_PERIOD : time := 10 ns;
    constant TICK_PERIOD : time := 160 ns;  -- s_tick every 16 clocks
    constant BIT_PERIOD : time := 2560 ns;  -- 16 s_ticks per UART BIT
    
    signal clk  : std_logic := '0';
    signal reset : std_logic := '1';
    signal s_tick : std_logic := '0';
    
    -- RX serial input/outputs
    signal rx : std_logic := '1';
    signal rx_done : std_logic;
    signal rx_dout : std_logic_vector(7 downto 0);
    
    -- Register between RX & TX
    signal loop_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal loop_flag : std_logic := '0';
    
    -- TX inputs/outputs
    signal tx_start : std_logic := '0';
    signal tx_done : std_logic;
    signal tx: std_logic;
    
begin
    -- UART Receiver
    uut_rx: entity work.uart_rx
        generic map(
            DBIT => 8,
            SB_TICK => 16
        )
        port map(
            clk => clk,
            reset => reset,
            rx => rx,
            s_tick => s_tick,
            rx_done => rx_done,
            dout => rx_dout
        );
        
    -- UART Transmitter
    uut_tx: entity work.uart_tx
        generic map(
            DBIT => 8,
            SB_TICK => 16
        )
        port map(
            clk => clk,
            reset => reset,
            tx_start => tx_start,
            s_tick => s_tick,
            din => loop_reg,
            tx_done => tx_done,
            tx => tx
        );

    -- CLK generator
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
    
    -- Loopback process - when rx_done is finished, tx_start will pulse to begin retransmission
    loopback_process: process(clk, reset)
    begin
        if reset = '1' then
            loop_reg  <= (others => '0');
            loop_flag <= '0';
            tx_start  <= '0';
        elsif rising_edge(clk) then
            tx_start <= '0';  -- default
            if rx_done = '1' then
                loop_reg  <= rx_dout;
                loop_flag <= '1'; -- set flag
            elsif loop_flag = '1' then
                tx_start  <= '1';
                loop_flag <= '0'; -- reset flag
            end if;
        end if;
    end process;
    
    stim_process: process
        procedure send_uart_byte(
            signal rx_line : out std_logic;
            constant data  : in  std_logic_vector(7 downto 0)
        ) is
        begin
            -- Idle before frame
            rx_line <= '1';
            wait for BIT_PERIOD;
    
            -- Start bit
            rx_line <= '0';
            wait for BIT_PERIOD;
    
            -- Data bits, LSB first
            for i in 0 to 7 loop
                rx_line <= data(i);
                wait for BIT_PERIOD;
            end loop;
    
            -- Stop bit
            rx_line <= '1';
            wait for BIT_PERIOD;
        end procedure;
    begin
        -- Reset
        wait for 50 ns;
        reset <= '0';
        wait for 100 ns;
    
        ----------------------------------------------------------------------
        -- Test Case 1
        ----------------------------------------------------------------------
        report "Starting Test Case 1" severity warning;
        send_uart_byte(rx, x"55");
    
        -- Give receiver a little time after frame completion
        wait for 1 us;
    
        assert rx_dout = x"55"
            report "Loopback RX failed for Test Case 1: expected x55"
            severity failure;
    
        report "Loopback RX Test Case 1 passed." severity warning;
    
        -- Give transmitter enough time to retransmit looped-back byte
        wait for 35 us;
    
        ----------------------------------------------------------------------
        -- Test Case 2
        ----------------------------------------------------------------------
        report "Starting Test Case 2" severity warning;
        send_uart_byte(rx, x"A3");
    
        wait for 1 us;
    
        assert rx_dout = x"A3"
            report "Loopback RX failed for Test Case 2: expected xA3"
            severity failure;
    
        report "Loopback RX Test Case 2 passed." severity warning;
    
        wait for 35 us;
    
        ----------------------------------------------------------------------
        -- Test Case 3
        ----------------------------------------------------------------------
        report "Starting Test Case 3" severity warning;
        send_uart_byte(rx, x"3C");
    
        wait for 1 us;
    
        assert rx_dout = x"3C"
            report "Loopback RX failed for Test Case 3: expected x3C"
            severity failure;
    
        report "Loopback RX Test Case 3 passed." severity warning;
    
        wait for 35 us;
    
        ----------------------------------------------------------------------
        -- End simulation
        ----------------------------------------------------------------------
        assert false
            report "tb_loopback completed successfully."
            severity failure;
    end process;
end sim;