library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
entity tb_classification_engine is
-- Testbench has no ports
end tb_classification_engine;
 
architecture sim of tb_classification_engine is
 
    -- -------------------------------------------------------------------------
    -- Vivado-compatible hex string conversion (replaces to_hstring)
    -- Converts an 8-bit std_logic_vector to a 2-character hex string
    -- -------------------------------------------------------------------------
    function to_hex_str(slv : std_logic_vector(7 downto 0)) return string is
        constant hex_chars : string(1 to 16) := "0123456789ABCDEF";
        variable hi : integer;
        variable lo : integer;
    begin
        hi := to_integer(unsigned(slv(7 downto 4)));
        lo := to_integer(unsigned(slv(3 downto 0)));
        return hex_chars(hi + 1) & hex_chars(lo + 1);
    end function;
 
    -- -------------------------------------------------------------------------
    -- Clock period constant (100 MHz)
    -- -------------------------------------------------------------------------
    constant CLK_PERIOD : time := 10 ns;
 
    -- -------------------------------------------------------------------------
    -- DUT port signals
    -- -------------------------------------------------------------------------
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '1';
    signal start        : std_logic := '0';
    signal ram_dout     : std_logic_vector(31 downto 0) := (others => '0');
    signal ram_addr     : std_logic_vector(4 downto 0);
    signal result       : std_logic_vector(7 downto 0);
    signal result_valid : std_logic;
    signal done         : std_logic;
 
    -- -------------------------------------------------------------------------
    -- Simple 32x32 RAM model (mirrors ram_module.vhd behaviour)
    -- -------------------------------------------------------------------------
    type ram_type is array(0 to 31) of std_logic_vector(31 downto 0);
 
    -- Pre-loaded test data
    -- Byte packing: bits 7:0 = byte0 (first received), 31:24 = byte3
    signal ram_mem : ram_type := (
        --  byte3     byte2     byte1     byte0
        0  => x"00000000",   -- Test 1: NULL  (all zero)
        1  => x"0A080C06",   -- Test 2: LOW   avg = (10+8+12+6)/4 = 9
        2  => x"80807878",   -- Test 3: MID   avg = (128+128+120+120)/4 = 124
        3  => x"DCDCE0DC",   -- Test 4: HIGH  avg = (220+220+224+220)/4 = 221
        4  => x"3F3F3F3F",   -- Test 5: LOW   avg = 63 (boundary, still LOW)
        5  => x"40404040",   -- Test 6: MID   avg = 64 (boundary, first MID)
        6  => x"BFBFBFBF",   -- Test 7: MID   avg = 191 (boundary, last MID)
        7  => x"C0C0C0C0",   -- Test 8: HIGH  avg = 192 (boundary, first HIGH)
        others => x"00000000"  -- Tests 9-31: NULL
    );
 
    -- Expected results for rows 0-31
    type result_array is array(0 to 31) of std_logic_vector(7 downto 0);
    constant EXPECTED : result_array := (
        0      => x"00",   -- NULL
        1      => x"01",   -- LOW
        2      => x"02",   -- MID
        3      => x"03",   -- HIGH
        4      => x"01",   -- LOW  (avg=63)
        5      => x"02",   -- MID  (avg=64)
        6      => x"02",   -- MID  (avg=191)
        7      => x"03",   -- HIGH (avg=192)
        others => x"00"    -- NULL
    );
 
    -- -------------------------------------------------------------------------
    -- DUT component declaration
    -- -------------------------------------------------------------------------
    component classification_engine is
        port(
            clk          : in  std_logic;
            reset        : in  std_logic;
            start        : in  std_logic;
            ram_dout     : in  std_logic_vector(31 downto 0);
            ram_addr     : out std_logic_vector(4 downto 0);
            result       : out std_logic_vector(7 downto 0);
            result_valid : out std_logic;
            done         : out std_logic
        );
    end component;
 
    -- -------------------------------------------------------------------------
    -- Tracking variables
    -- -------------------------------------------------------------------------
    signal pass_count  : integer := 0;
    signal fail_count  : integer := 0;
 
begin
 
    -- =========================================================================
    -- Clock generation
    -- =========================================================================
    clk <= not clk after CLK_PERIOD / 2;
 
    -- =========================================================================
    -- RAM model -- synchronous read with 1-cycle latency (mirrors ram_module)
    -- =========================================================================
    process(clk)
    begin
        if rising_edge(clk) then
            if not is_x(ram_addr) then
                ram_dout <= ram_mem(to_integer(unsigned(ram_addr)));
            end if;
        end if;
    end process;
 
    -- =========================================================================
    -- DUT instantiation
    -- =========================================================================
    DUT : classification_engine
        port map(
            clk          => clk,
            reset        => reset,
            start        => start,
            ram_dout     => ram_dout,
            ram_addr     => ram_addr,
            result       => result,
            result_valid => result_valid,
            done         => done
        );
 
    -- =========================================================================
    -- Stimulus + checker process
    -- =========================================================================
    stimulus : process
        variable local_pass : integer := 0;
        variable local_fail : integer := 0;
    begin
        -- ---------------------------------------------------------------------
        -- 1. Hold reset for 3 cycles
        -- ---------------------------------------------------------------------
        reset <= '1';
        start <= '0';
        wait for CLK_PERIOD * 3;
        wait until rising_edge(clk);
 
        reset <= '0';
        wait for CLK_PERIOD * 2;
 
        -- ---------------------------------------------------------------------
        -- 2. Pulse start for 1 cycle (mimics fsm_done from uart_fsm)
        -- ---------------------------------------------------------------------
        report "=== Classification Engine Testbench Start ===";
        wait until rising_edge(clk);
        start <= '1';
        wait until rising_edge(clk);
        start <= '0';
 
        -- ---------------------------------------------------------------------
        -- 3. Collect 32 result bytes and check each one
        -- ---------------------------------------------------------------------
        for i in 0 to 31 loop
            -- Wait for result_valid to pulse
            wait until rising_edge(clk) and result_valid = '1';
 
            if result = EXPECTED(i) then
                report "Row " & integer'image(i) &
                       ": PASS -- result = 0x" &
                       to_hex_str(result) &
                       "  expected = 0x" & to_hex_str(EXPECTED(i));
                local_pass := local_pass + 1;
            else
                report "Row " & integer'image(i) &
                       ": FAIL -- result = 0x" &
                       to_hex_str(result) &
                       "  expected = 0x" & to_hex_str(EXPECTED(i))
                       severity error;
                local_fail := local_fail + 1;
            end if;
        end loop;
 
        -- ---------------------------------------------------------------------
        -- 4. Wait for done pulse and verify it is exactly one cycle wide
        -- ---------------------------------------------------------------------
        wait until rising_edge(clk) and done = '1';
        report "done signal asserted -- classification complete.";
        wait until rising_edge(clk);
        assert done = '0'
            report "done pulse FAILED: done did not deassert after one cycle"
            severity error;
 
        -- ---------------------------------------------------------------------
        -- 5. Final summary
        -- ---------------------------------------------------------------------
        report "=== TEST SUMMARY ===";
        report "PASSED: " & integer'image(local_pass) & " / 32";
        report "FAILED: " & integer'image(local_fail) & " / 32";
 
        if local_fail = 0 then
            report "*** ALL TESTS PASSED ***";
        else
            report "*** SOME TESTS FAILED -- see errors above ***" severity error;
        end if;
 
        -- ---------------------------------------------------------------------
        -- 6. Test reset mid-operation
        -- ---------------------------------------------------------------------
        report "--- Testing synchronous reset ---";
        wait until rising_edge(clk);
        start <= '1';
        wait until rising_edge(clk);
        start <= '0';
 
        -- Let it run for a few cycles then reset
        wait for CLK_PERIOD * 5;
        wait until rising_edge(clk);
        reset <= '1';
        wait until rising_edge(clk);
        reset <= '0';
 
        -- done and result_valid should NOT assert after reset
        wait for CLK_PERIOD * 10;
        if result_valid = '0' and done = '0' then
            report "Reset test: PASS -- no spurious outputs after reset";
        else
            report "Reset test: FAIL -- unexpected output after reset" severity error;
        end if;
 
        report "=== Testbench Complete ===";
        wait;  -- stop simulation
    end process stimulus;
 
end sim;
 