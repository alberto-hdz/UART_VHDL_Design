-- ============================================
-- Testbench: tb_uart_top
-- Description: Full system integration test — sends 16 typed bytes
--   (ABcd1234EFgh5678) plus 112 null bytes via RX to fill all 32
--   RAM rows, waits for classification to complete, then captures
--   and verifies all 128 classification result bytes from TX.
--   BIT_PERIOD = 104167 ns (9600 baud, 100 MHz clock).
-- Author: Alberto Hernandez
-- Date: 2026-04-28
-- ============================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_uart_top is
end tb_uart_top;

architecture sim of tb_uart_top is

    -- -------------------------------------------------------
    -- Timing constants (100 MHz clock, 9600 baud)
    -- -------------------------------------------------------
    constant CLK_PERIOD   : time    := 10 ns;
    constant BIT_PERIOD   : time    := 104167 ns;  -- 1 / 9600 baud
    constant NUM_TX_BYTES : integer := 128;         -- 32 RAM rows * 4 bytes each

    -- -------------------------------------------------------
    -- DUT ports
    -- -------------------------------------------------------
    signal clk           : std_logic := '0';
    signal reset         : std_logic := '1';
    signal rx            : std_logic := '1';  -- idle HIGH
    signal tx            : std_logic;
    signal rx_done_out   : std_logic;
    signal tx_done_out   : std_logic;
    signal fifo_full     : std_logic;
    signal classify_done : std_logic;

    -- -------------------------------------------------------
    -- Expected TX results: first 16 bytes come from
    --   ABcd1234EFgh5678; remaining 112 are 0x00 (null -> special)
    -- Classification codes: 0x01=uppercase, 0x02=lowercase,
    --   0x03=digit, 0x00=other
    -- -------------------------------------------------------
    type exp_array_t is array(0 to 127) of std_logic_vector(7 downto 0);
    constant EXPECTED : exp_array_t := (
        -- Row 0: 'A'->01, 'B'->01, 'c'->02, 'd'->02
        0  => x"01", 1  => x"01", 2  => x"02", 3  => x"02",
        -- Row 1: '1'->03, '2'->03, '3'->03, '4'->03
        4  => x"03", 5  => x"03", 6  => x"03", 7  => x"03",
        -- Row 2: 'E'->01, 'F'->01, 'g'->02, 'h'->02
        8  => x"01", 9  => x"01", 10 => x"02", 11 => x"02",
        -- Row 3: '5'->03, '6'->03, '7'->03, '8'->03
        12 => x"03", 13 => x"03", 14 => x"03", 15 => x"03",
        -- Rows 4-31: null bytes -> 0x00
        others => x"00"
    );

    -- flag set by tx_verify when all bytes have been checked
    signal tx_verify_done     : std_logic := '0';
    signal classify_done_seen : std_logic := '0';

    -- -------------------------------------------------------
    -- Helper: convert byte to "0xHH" hex string for reports
    -- -------------------------------------------------------
    function to_hex_str(slv : std_logic_vector(7 downto 0)) return string is
        constant hex_chars : string(1 to 16) := "0123456789ABCDEF";
        variable hi : integer;
        variable lo : integer;
    begin
        hi := to_integer(unsigned(slv(7 downto 4)));
        lo := to_integer(unsigned(slv(3 downto 0)));
        return "0x" & hex_chars(hi + 1) & hex_chars(lo + 1);
    end function;

begin

    -- -------------------------------------------------------
    -- 100 MHz clock
    -- -------------------------------------------------------
    clk <= not clk after CLK_PERIOD / 2;

    -- -------------------------------------------------------
    -- DUT: top-level integration (BAUD_DIV defaults to 651)
    -- -------------------------------------------------------
    uut: entity work.uart_top
        port map(
            clk           => clk,
            reset         => reset,
            rx            => rx,
            tx            => tx,
            rx_done_out   => rx_done_out,
            tx_done_out   => tx_done_out,
            fifo_full     => fifo_full,
            classify_done => classify_done
        );

    -- latch classify_done so stim can assert it fired at least once
    process(clk)
    begin
        if rising_edge(clk) then
            if classify_done = '1' then
                classify_done_seen <= '1';
            end if;
        end if;
    end process;

    -- -------------------------------------------------------
    -- Stimulus: send 128 bytes via RX
    --   Bytes  0-15 : ABcd1234EFgh5678  (typed test bytes)
    --   Bytes 16-127: 0x00              (pads RAM rows 4-31)
    -- The FSM requires all 32 rows filled before asserting fsm_done.
    -- -------------------------------------------------------
    stim: process

        procedure send_byte(data : std_logic_vector(7 downto 0)) is
        begin
            rx <= '0';              -- start bit
            wait for BIT_PERIOD;
            for i in 0 to 7 loop
                rx <= data(i);      -- 8 data bits, LSB first
                wait for BIT_PERIOD;
            end loop;
            rx <= '1';              -- stop bit
            wait for BIT_PERIOD;
        end procedure;

    begin
        reset <= '1';
        rx    <= '1';
        wait for CLK_PERIOD * 20;
        reset <= '0';
        wait for 10 us;

        report "=== tb_uart_top: sending 128 RX bytes ===" severity note;

        -- 16 typed test bytes: ABcd1234EFgh5678
        send_byte(x"41");  -- 'A' -> 0x01
        send_byte(x"42");  -- 'B' -> 0x01
        send_byte(x"63");  -- 'c' -> 0x02
        send_byte(x"64");  -- 'd' -> 0x02
        send_byte(x"31");  -- '1' -> 0x03
        send_byte(x"32");  -- '2' -> 0x03
        send_byte(x"33");  -- '3' -> 0x03
        send_byte(x"34");  -- '4' -> 0x03
        send_byte(x"45");  -- 'E' -> 0x01
        send_byte(x"46");  -- 'F' -> 0x01
        send_byte(x"67");  -- 'g' -> 0x02
        send_byte(x"68");  -- 'h' -> 0x02
        send_byte(x"35");  -- '5' -> 0x03
        send_byte(x"36");  -- '6' -> 0x03
        send_byte(x"37");  -- '7' -> 0x03
        send_byte(x"38");  -- '8' -> 0x03

        -- 112 null bytes to fill RAM rows 4-31
        for i in 0 to 111 loop
            send_byte(x"00");
        end loop;

        report "=== All 128 bytes sent. Waiting for classify_done... ===" severity note;

        wait until classify_done = '1';
        report "=== classify_done asserted. ===" severity note;

        -- Wait for the TX verification process to finish sampling all bytes
        wait until tx_verify_done = '1';

        assert classify_done_seen = '1'
            report "FAIL: classify_done was never observed"
            severity error;

        report "=== tb_uart_top: simulation complete ===" severity note;

        assert false
            report "tb_uart_top finished."
            severity failure;
    end process stim;

    -- -------------------------------------------------------
    -- TX verification: sample each serial byte from the TX line
    -- and compare against the expected classification codes.
    -- Sampling strategy: align to center of each bit cell.
    --   From falling edge of start bit:
    --     +0.5 bit  -> center of start bit  (verify LOW)
    --     +1.5 bit  -> center of data bit 0
    --     ...
    --     +8.5 bit  -> center of data bit 7
    --     +9.5 bit  -> center of stop bit   (verify HIGH)
    -- -------------------------------------------------------
    tx_verify: process
        variable recv   : std_logic_vector(7 downto 0);
        variable n_pass : integer := 0;
        variable n_fail : integer := 0;
    begin
        -- wait for the very first start bit (TX falls from idle HIGH)
        wait until falling_edge(tx);

        for byte_idx in 0 to NUM_TX_BYTES - 1 loop

            -- center of start bit
            wait for BIT_PERIOD / 2;
            assert tx = '0'
                report "TX framing error: start bit not LOW on byte " &
                       integer'image(byte_idx)
                severity error;

            -- sample 8 data bits (LSB first)
            for b in 0 to 7 loop
                wait for BIT_PERIOD;
                recv(b) := tx;
            end loop;

            -- center of stop bit
            wait for BIT_PERIOD;
            assert tx = '1'
                report "TX framing error: stop bit not HIGH on byte " &
                       integer'image(byte_idx)
                severity error;

            -- check classification result
            if recv = EXPECTED(byte_idx) then
                report "TX byte " & integer'image(byte_idx) &
                       ": PASS  got=" & to_hex_str(recv) &
                       "  exp=" & to_hex_str(EXPECTED(byte_idx))
                severity note;
                n_pass := n_pass + 1;
            else
                report "TX byte " & integer'image(byte_idx) &
                       ": FAIL  got=" & to_hex_str(recv) &
                       "  exp=" & to_hex_str(EXPECTED(byte_idx))
                severity error;
                n_fail := n_fail + 1;
            end if;

            -- wait for start bit of next byte (TX controller has a few-cycle gap)
            if byte_idx < NUM_TX_BYTES - 1 then
                wait until falling_edge(tx);
            end if;

        end loop;

        -- summary report
        report "=== TX VERIFY SUMMARY ===" severity note;
        report "PASSED: " & integer'image(n_pass) & " / " &
               integer'image(NUM_TX_BYTES) severity note;
        report "FAILED: " & integer'image(n_fail) & " / " &
               integer'image(NUM_TX_BYTES) severity note;

        if n_fail = 0 then
            report "*** ALL TX BYTES CORRECT ***" severity note;
        else
            report "*** SOME TX BYTES INCORRECT ***" severity error;
        end if;

        tx_verify_done <= '1';
        wait;
    end process tx_verify;

end sim;
