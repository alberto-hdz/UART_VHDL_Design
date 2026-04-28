-- ============================================
-- Module: uart_top
-- Description: Top-level integration — wires baud_gen, uart_rx,
--   rx_fifo, uart_fsm, ram_module, classification_engine,
--   tx_fifo, and uart_tx into a complete UART subsystem.
--   A phase signal muxes the RAM address between the FSM
--   (receive phase) and the classifier (classify phase).
--   A TX controller FSM drains the TX FIFO one byte at a time.
-- Author: Alberto Hernandez
-- Date: 2026-04-28
-- ============================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_top is
    generic(
        BAUD_DIV : integer := 651   -- divisor for baud_gen (100 MHz / (9600 * 16))
    );
    port(
        clk           : in  std_logic;
        reset         : in  std_logic;
        rx            : in  std_logic;   -- serial input, idle HIGH
        tx            : out std_logic;   -- serial output, idle HIGH
        rx_done_out   : out std_logic;   -- observation: byte received
        tx_done_out   : out std_logic;   -- observation: byte transmitted
        fifo_full     : out std_logic;   -- observation: RX FIFO full
        classify_done : out std_logic    -- observation: classification complete
    );
end uart_top;

architecture arch of uart_top is

    -- baud tick (16x oversample)
    signal s_tick : std_logic;

    -- uart_rx outputs
    signal rx_done : std_logic;
    signal rx_dout : std_logic_vector(7 downto 0);

    -- RX FIFO signals
    signal rx_fifo_rd    : std_logic;
    signal rx_fifo_rdata : std_logic_vector(7 downto 0);
    signal rx_fifo_empty : std_logic;
    signal rx_fifo_full  : std_logic;

    -- uart_fsm outputs
    signal fsm_fifo_rd  : std_logic;
    signal fsm_ram_we   : std_logic;
    signal fsm_ram_addr : std_logic_vector(4 downto 0);
    signal fsm_ram_din  : std_logic_vector(31 downto 0);
    signal fsm_done     : std_logic;

    -- classification_engine outputs
    signal ce_ram_addr     : std_logic_vector(4 downto 0);
    signal ce_result       : std_logic_vector(7 downto 0);
    signal ce_result_valid : std_logic;
    signal ce_done         : std_logic;

    -- RAM muxed inputs and output
    signal ram_we   : std_logic;
    signal ram_addr : std_logic_vector(4 downto 0);
    signal ram_din  : std_logic_vector(31 downto 0);
    signal ram_dout : std_logic_vector(31 downto 0);

    -- phase: '0' = RECEIVE (FSM drives RAM), '1' = CLASSIFY (CE drives RAM)
    signal phase : std_logic;

    -- TX FIFO signals
    signal tx_fifo_rd    : std_logic;
    signal tx_fifo_rdata : std_logic_vector(7 downto 0);
    signal tx_fifo_empty : std_logic;

    -- uart_tx signals
    signal tx_start : std_logic;
    signal tx_done  : std_logic;

    -- TX controller FSM
    type tx_ctrl_state_t is (TX_IDLE, TX_LOAD, TX_WAIT);
    signal tx_ctrl_state, tx_ctrl_next : tx_ctrl_state_t;

begin

    -- -------------------------------------------------------
    -- Baud rate generator
    -- -------------------------------------------------------
    U_BAUD_GEN : entity work.baud_gen
        generic map(M => BAUD_DIV)
        port map(
            clk   => clk,
            reset => reset,
            tick  => s_tick
        );

    -- -------------------------------------------------------
    -- UART receiver
    -- -------------------------------------------------------
    U_UART_RX : entity work.uart_rx
        port map(
            clk     => clk,
            reset   => reset,
            rx      => rx,
            s_tick  => s_tick,
            rx_done => rx_done,
            dout    => rx_dout
        );

    -- -------------------------------------------------------
    -- RX FIFO  (rx_done writes; FSM reads)
    -- -------------------------------------------------------
    U_RX_FIFO : entity work.fifo
        port map(
            clk    => clk,
            reset  => reset,
            wr     => rx_done,
            rd     => rx_fifo_rd,
            w_data => rx_dout,
            r_data => rx_fifo_rdata,
            empty  => rx_fifo_empty,
            full   => rx_fifo_full
        );

    -- -------------------------------------------------------
    -- UART FSM — packs RX bytes into 32-bit words, writes RAM
    -- -------------------------------------------------------
    U_UART_FSM : entity work.uart_fsm
        port map(
            clk        => clk,
            reset      => reset,
            fifo_empty => rx_fifo_empty,
            fifo_dout  => rx_fifo_rdata,
            fifo_rd    => rx_fifo_rd,
            ram_we     => fsm_ram_we,
            ram_addr   => fsm_ram_addr,
            ram_din    => fsm_ram_din,
            fsm_done   => fsm_done
        );

    -- -------------------------------------------------------
    -- Phase register: RECEIVE until fsm_done, CLASSIFY until ce_done
    -- -------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            phase <= '0';
        elsif rising_edge(clk) then
            if fsm_done = '1' then
                phase <= '1';
            elsif ce_done = '1' then
                phase <= '0';
            end if;
        end if;
    end process;

    -- -------------------------------------------------------
    -- RAM address mux
    -- -------------------------------------------------------
    ram_we   <= fsm_ram_we   when phase = '0' else '0';
    ram_addr <= fsm_ram_addr when phase = '0' else ce_ram_addr;
    ram_din  <= fsm_ram_din;

    -- -------------------------------------------------------
    -- RAM — 32 x 32-bit synchronous block RAM
    -- -------------------------------------------------------
    U_RAM : entity work.ram_module
        port map(
            clk  => clk,
            we   => ram_we,
            addr => ram_addr,
            din  => ram_din,
            dout => ram_dout
        );

    -- -------------------------------------------------------
    -- Classification engine — reads RAM, streams result bytes
    -- -------------------------------------------------------
    U_CLASS_ENGINE : entity work.classification_engine
        port map(
            clk          => clk,
            reset        => reset,
            start        => fsm_done,
            ram_dout     => ram_dout,
            ram_addr     => ce_ram_addr,
            result       => ce_result,
            result_valid => ce_result_valid,
            done         => ce_done
        );

    -- -------------------------------------------------------
    -- TX FIFO  (classifier writes; TX controller reads)
    -- -------------------------------------------------------
    U_TX_FIFO : entity work.fifo
        port map(
            clk    => clk,
            reset  => reset,
            wr     => ce_result_valid,
            rd     => tx_fifo_rd,
            w_data => ce_result,
            r_data => tx_fifo_rdata,
            empty  => tx_fifo_empty,
            full   => open
        );

    -- -------------------------------------------------------
    -- TX controller FSM — drains TX FIFO one byte at a time
    --   TX_IDLE : wait for data in TX FIFO, then pop it (rd pulse)
    --   TX_LOAD : r_data is now valid; assert tx_start to uart_tx
    --   TX_WAIT : wait for uart_tx to finish, then check again
    -- -------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            tx_ctrl_state <= TX_IDLE;
        elsif rising_edge(clk) then
            tx_ctrl_state <= tx_ctrl_next;
        end if;
    end process;

    process(tx_ctrl_state, tx_fifo_empty, tx_done)
    begin
        tx_ctrl_next <= tx_ctrl_state;
        tx_fifo_rd   <= '0';
        tx_start     <= '0';

        case tx_ctrl_state is
            when TX_IDLE =>
                if tx_fifo_empty = '0' then
                    tx_fifo_rd   <= '1';          -- pop head byte from FIFO
                    tx_ctrl_next <= TX_LOAD;
                end if;

            when TX_LOAD =>
                tx_start     <= '1';              -- r_data valid; start transmission
                tx_ctrl_next <= TX_WAIT;

            when TX_WAIT =>
                if tx_done = '1' then
                    tx_ctrl_next <= TX_IDLE;
                end if;
        end case;
    end process;

    -- -------------------------------------------------------
    -- UART transmitter
    -- -------------------------------------------------------
    U_UART_TX : entity work.uart_tx
        port map(
            clk      => clk,
            reset    => reset,
            tx_start => tx_start,
            s_tick   => s_tick,
            din      => tx_fifo_rdata,
            tx_done  => tx_done,
            tx       => tx
        );

    -- -------------------------------------------------------
    -- Status outputs
    -- -------------------------------------------------------
    rx_done_out   <= rx_done;
    tx_done_out   <= tx_done;
    fifo_full     <= rx_fifo_full;
    classify_done <= ce_done;

end arch;
