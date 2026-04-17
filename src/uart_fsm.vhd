-- ============================================
-- Module: uart_fsm
-- Description: FSM controller — FIFO to RAM writer
--   Reads bytes from the RX FIFO one at a time, packs
--   4 consecutive bytes into a 32-bit word, then writes
--   the word to RAM. Asserts fsm_done when the FIFO is
--   fully drained and the last complete word is written.
--   Packing: byte 0 -> bits [7:0],  byte 1 -> bits [15:8],
--            byte 2 -> bits [23:16], byte 3 -> bits [31:24]
-- Author: Alberto Hernandez
-- Date: 2026-04-17
-- ============================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_fsm is
    port(
        clk        : in  std_logic;
        reset      : in  std_logic;
        -- FIFO interface (connects to rx_fifo)
        fifo_empty : in  std_logic;                        -- HIGH when FIFO has no data
        fifo_dout  : in  std_logic_vector(7 downto 0);     -- current byte at FIFO head (FWFT)
        fifo_rd    : out std_logic;                        -- pulse HIGH to pop byte and advance FIFO
        -- RAM interface (connects to ram_module)
        ram_we     : out std_logic;                        -- write enable, active HIGH
        ram_addr   : out std_logic_vector(4 downto 0);     -- row address (0-31)
        ram_din    : out std_logic_vector(31 downto 0);    -- 32-bit packed word to write
        -- status
        fsm_done   : out std_logic                         -- HIGH when FIFO is fully drained
    );
end uart_fsm;

architecture arch of uart_fsm is

    -- FSM states
    type state_type is (IDLE, READ_BYTE, PACK, WRITE_RAM, DONE);
    signal state, state_next : state_type;

    -- captures the byte from the FIFO in READ_BYTE so it is stable in PACK
    -- the FIFO advances its pointer one clock after fifo_rd, so fifo_dout
    -- in PACK would already show the next byte if we did not latch it here
    signal byte_buf,     byte_next     : std_logic_vector(7 downto 0);

    -- 32-bit packing register: bytes accumulate here before each RAM write
    signal word_reg,     word_next     : std_logic_vector(31 downto 0);

    -- byte lane index: which of the 4 byte positions we are currently filling (0-3)
    signal byte_idx,     byte_idx_next : unsigned(1 downto 0);

    -- RAM row counter: increments after every 32-bit word is written (0-31)
    signal addr_reg,     addr_next     : unsigned(4 downto 0);

begin

    -- register update: all state held in flip-flops
    process(clk, reset)
    begin
        if reset = '1' then
            state    <= IDLE;
            byte_buf <= (others => '0');
            word_reg <= (others => '0');
            byte_idx <= (others => '0');
            addr_reg <= (others => '0');
        elsif rising_edge(clk) then
            state    <= state_next;
            byte_buf <= byte_next;
            word_reg <= word_next;
            byte_idx <= byte_idx_next;
            addr_reg <= addr_next;
        end if;
    end process;

    -- next-state and output logic
    process(state, fifo_empty, fifo_dout, byte_buf, word_reg, byte_idx, addr_reg)
    begin
        -- defaults: hold current values, deassert all outputs
        state_next    <= state;
        byte_next     <= byte_buf;
        word_next     <= word_reg;
        byte_idx_next <= byte_idx;
        addr_next     <= addr_reg;
        fifo_rd       <= '0';
        ram_we        <= '0';
        ram_addr      <= std_logic_vector(addr_reg);
        ram_din       <= word_reg;
        fsm_done      <= '0';

        case state is

            -- IDLE: wait for data in the FIFO
            -- if FIFO is empty and no partial word is in progress, all bytes are written
            when IDLE =>
                if fifo_empty = '0' then
                    state_next <= READ_BYTE;
                elsif byte_idx = 0 then
                    state_next <= DONE;
                end if;

            -- READ_BYTE: fifo_dout already holds a valid byte (FWFT FIFO)
            -- latch the byte into byte_buf and pulse fifo_rd to advance the FIFO pointer
            when READ_BYTE =>
                fifo_rd    <= '1';
                byte_next  <= fifo_dout;
                state_next <= PACK;

            -- PACK: place the latched byte into its lane in the 32-bit word
            when PACK =>
                case byte_idx is
                    when "00"   => word_next( 7 downto  0) <= byte_buf;
                    when "01"   => word_next(15 downto  8) <= byte_buf;
                    when "10"   => word_next(23 downto 16) <= byte_buf;
                    when others => word_next(31 downto 24) <= byte_buf;
                end case;

                if byte_idx = 3 then
                    -- all 4 lanes filled: write the packed word to RAM next
                    state_next <= WRITE_RAM;
                else
                    -- still packing: fetch the next byte
                    byte_idx_next <= byte_idx + 1;
                    state_next    <= IDLE;
                end if;

            -- WRITE_RAM: assert ram_we for one cycle then advance the RAM address
            -- ram_din defaults to word_reg which already holds all 4 packed bytes
            when WRITE_RAM =>
                ram_we        <= '1';
                addr_next     <= addr_reg + 1;
                byte_idx_next <= (others => '0');
                state_next    <= IDLE;

            -- DONE: hold fsm_done HIGH until reset
            when DONE =>
                fsm_done <= '1';

        end case;
    end process;

end arch;
