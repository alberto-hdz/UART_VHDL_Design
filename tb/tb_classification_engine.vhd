library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_classification_engine is
end tb_classification_engine;

architecture sim of tb_classification_engine is

    function to_hex_str(slv : std_logic_vector(7 downto 0)) return string is
        constant hex_chars : string(1 to 16) := "0123456789ABCDEF";
        variable hi : integer;
        variable lo : integer;
    begin
        hi := to_integer(unsigned(slv(7 downto 4)));
        lo := to_integer(unsigned(slv(3 downto 0)));
        return hex_chars(hi + 1) & hex_chars(lo + 1);
    end function;

    constant CLK_PERIOD : time := 10 ns;

    signal clk          : std_logic := '0';
    signal reset        : std_logic := '1';
    signal start        : std_logic := '0';
    signal ram_dout     : std_logic_vector(31 downto 0) := (others => '0');
    signal ram_addr     : std_logic_vector(4 downto 0);
    signal result       : std_logic_vector(7 downto 0);
    signal result_valid : std_logic;
    signal done         : std_logic;

    -- 32-entry RAM model (mirrors ram_module.vhd, synchronous read, 1-cycle latency)
    type ram_type is array(0 to 31) of std_logic_vector(31 downto 0);

    -- Byte packing: bits 7:0 = byte0 (first received / LSB), 31:24 = byte3
    -- Word 0: 0x64634241 -> byte0='A'(0x41), byte1='B'(0x42), byte2='c'(0x63), byte3='d'(0x64)
    -- Word 1: 0x34333231 -> byte0='1'(0x31), byte1='2'(0x32), byte2='3'(0x33), byte3='4'(0x34)
    -- Word 2: boundary uppercase: byte0='A'(0x41), byte1='Z'(0x5A), byte2='a'(0x61), byte3='z'(0x7A)
    -- Word 3: boundary digits:    byte0='0'(0x30), byte1='9'(0x39), byte2=' '(0x20), byte3='!'(0x21)
    signal ram_mem : ram_type := (
        0      => x"64634241",
        1      => x"34333231",
        2      => x"7A615A41",
        3      => x"21203930",
        others => x"00000000"
    );

    -- Expected results: 32 words x 4 bytes = 128 entries
    -- Index = word * 4 + byte_within_word (byte0 first)
    type result_array is array(0 to 127) of std_logic_vector(7 downto 0);
    constant EXPECTED : result_array := (
        -- Word 0: 'A'->01, 'B'->01, 'c'->02, 'd'->02
        0  => x"01", 1  => x"01", 2  => x"02", 3  => x"02",
        -- Word 1: '1'->03, '2'->03, '3'->03, '4'->03
        4  => x"03", 5  => x"03", 6  => x"03", 7  => x"03",
        -- Word 2: 'A'->01, 'Z'->01, 'a'->02, 'z'->02
        8  => x"01", 9  => x"01", 10 => x"02", 11 => x"02",
        -- Word 3: '0'->03, '9'->03, ' '->00, '!'->00
        12 => x"03", 13 => x"03", 14 => x"00", 15 => x"00",
        -- Words 4-31 are all zeros -> 0x00
        others => x"00"
    );

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

begin

    clk <= not clk after CLK_PERIOD / 2;

    -- Synchronous RAM model with 1-cycle read latency
    process(clk)
    begin
        if rising_edge(clk) then
            if not is_x(ram_addr) then
                ram_dout <= ram_mem(to_integer(unsigned(ram_addr)));
            end if;
        end if;
    end process;

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

    stimulus : process
        variable local_pass : integer := 0;
        variable local_fail : integer := 0;
    begin
        -- Hold reset for 3 cycles
        reset <= '1';
        start <= '0';
        wait for CLK_PERIOD * 3;
        wait until rising_edge(clk);
        reset <= '0';
        wait for CLK_PERIOD * 2;

        report "=== Classification Engine Testbench Start ===";

        -- Pulse start for 1 cycle
        wait until rising_edge(clk);
        start <= '1';
        wait until rising_edge(clk);
        start <= '0';

        -- Collect 128 result bytes (32 words * 4 bytes each) and verify
        for i in 0 to 127 loop
            wait until rising_edge(clk) and result_valid = '1';

            if result = EXPECTED(i) then
                report "Result " & integer'image(i) &
                       " (word " & integer'image(i/4) &
                       " byte " & integer'image(i mod 4) &
                       "): PASS  got=0x" & to_hex_str(result) &
                       "  exp=0x" & to_hex_str(EXPECTED(i));
                local_pass := local_pass + 1;
            else
                report "Result " & integer'image(i) &
                       " (word " & integer'image(i/4) &
                       " byte " & integer'image(i mod 4) &
                       "): FAIL  got=0x" & to_hex_str(result) &
                       "  exp=0x" & to_hex_str(EXPECTED(i))
                       severity error;
                local_fail := local_fail + 1;
            end if;
        end loop;

        -- Verify done pulses exactly once
        wait until rising_edge(clk) and done = '1';
        report "done asserted.";
        wait until rising_edge(clk);
        assert done = '0'
            report "done FAILED: did not deassert after one cycle"
            severity error;

        -- Summary
        report "=== TEST SUMMARY ===";
        report "PASSED: " & integer'image(local_pass) & " / 128";
        report "FAILED: " & integer'image(local_fail) & " / 128";

        if local_fail = 0 then
            report "*** ALL TESTS PASSED ***";
        else
            report "*** SOME TESTS FAILED -- see errors above ***" severity error;
        end if;

        -- Test synchronous reset mid-operation
        report "--- Testing synchronous reset ---";
        wait until rising_edge(clk);
        start <= '1';
        wait until rising_edge(clk);
        start <= '0';
        wait for CLK_PERIOD * 5;
        wait until rising_edge(clk);
        reset <= '1';
        wait until rising_edge(clk);
        reset <= '0';

        wait for CLK_PERIOD * 10;
        if result_valid = '0' and done = '0' then
            report "Reset test: PASS -- no spurious outputs after reset";
        else
            report "Reset test: FAIL -- unexpected output after reset" severity error;
        end if;

        report "=== Testbench Complete ===";
        wait;
    end process stimulus;

end sim;
