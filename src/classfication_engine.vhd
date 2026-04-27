library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
entity classification_engine is
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
end classification_engine;
 
architecture behavioral of classification_engine is
 
    -- -------------------------------------------------------------------------
    -- FSM state type
    -- -------------------------------------------------------------------------
    type state_type is (
        IDLE,       -- waiting for start pulse
        READ_ADDR,  -- present address to RAM
        WAIT_RAM,   -- absorb 1-cycle RAM read latency
        CLASSIFY,   -- compute sum and determine class
        OUTPUT,     -- assert result / result_valid for 1 cycle
        DONE_ST     -- assert done for 1 cycle then return to IDLE
    );
 
    signal state     : state_type := IDLE;
 
    -- -------------------------------------------------------------------------
    -- Internal signals
    -- -------------------------------------------------------------------------
    signal addr_reg  : unsigned(4 downto 0) := (others => '0');  -- current row (0-31)
    signal sum_reg   : unsigned(9 downto 0) := (others => '0');  -- max = 4*255 = 1020 < 1024
    signal avg_reg   : unsigned(7 downto 0) := (others => '0');  -- sum >> 2
    signal class_reg : std_logic_vector(7 downto 0) := (others => '0');
 
    -- Number of RAM rows to classify (matches ram_module generic: 2^5 = 32)
    constant MAX_ADDR : unsigned(4 downto 0) := "11111";  -- 31
 
begin
 
    -- =========================================================================
    -- FSM + datapath (single clocked process)
    -- =========================================================================
    process(clk)
        variable b0, b1, b2, b3 : unsigned(7 downto 0);
        variable v_sum           : unsigned(9 downto 0);
        variable v_avg           : unsigned(7 downto 0);
        variable v_class         : std_logic_vector(7 downto 0);
    begin
        if rising_edge(clk) then
            if reset = '1' then
                -- Synchronous reset -- all outputs and registers cleared
                state        <= IDLE;
                addr_reg     <= (others => '0');
                sum_reg      <= (others => '0');
                avg_reg      <= (others => '0');
                class_reg    <= (others => '0');
                ram_addr     <= (others => '0');
                result       <= (others => '0');
                result_valid <= '0';
                done         <= '0';
 
            else
                -- Default: de-assert single-cycle outputs every cycle
                result_valid <= '0';
                done         <= '0';
 
                case state is
 
                    -- ---------------------------------------------------------
                    when IDLE =>
                        addr_reg <= (others => '0');
                        if start = '1' then
                            state <= READ_ADDR;
                        end if;
 
                    -- ---------------------------------------------------------
                    -- Present the current address to RAM this cycle.
                    -- Data will be valid on ram_dout next cycle.
                    -- ---------------------------------------------------------
                    when READ_ADDR =>
                        ram_addr <= std_logic_vector(addr_reg);
                        state    <= WAIT_RAM;
 
                    -- ---------------------------------------------------------
                    -- One idle cycle to satisfy RAM read latency.
                    -- ram_dout is now valid (registered output of ram_module).
                    -- ---------------------------------------------------------
                    when WAIT_RAM =>
                        state <= CLASSIFY;
 
                    -- ---------------------------------------------------------
                    -- Split ram_dout into 4 bytes, compute average, classify.
                    -- Byte packing from FSM: byte0 in bits 7:0 (first received)
                    -- ---------------------------------------------------------
                    when CLASSIFY =>
                        b0 := unsigned(ram_dout( 7 downto  0));
                        b1 := unsigned(ram_dout(15 downto  8));
                        b2 := unsigned(ram_dout(23 downto 16));
                        b3 := unsigned(ram_dout(31 downto 24));
 
                        v_sum := ('0' & '0' & b0) +
                                 ('0' & '0' & b1) +
                                 ('0' & '0' & b2) +
                                 ('0' & '0' & b3);
 
                        -- Divide by 4 via right-shift
                        v_avg := v_sum(9 downto 2);
 
                        -- Classify
                        if (b0 = 0) and (b1 = 0) and (b2 = 0) and (b3 = 0) then
                            v_class := x"00";   -- NULL
                        elsif v_avg < 64 then
                            v_class := x"01";   -- LOW
                        elsif v_avg < 192 then
                            v_class := x"02";   -- MID
                        else
                            v_class := x"03";   -- HIGH
                        end if;
 
                        sum_reg   <= v_sum;
                        avg_reg   <= v_avg;
                        class_reg <= v_class;
                        state     <= OUTPUT;
 
                    -- ---------------------------------------------------------
                    -- Assert result and result_valid for exactly 1 cycle.
                    -- Then decide: more rows or done.
                    -- ---------------------------------------------------------
                    when OUTPUT =>
                        result       <= class_reg;
                        result_valid <= '1';
 
                        if addr_reg = MAX_ADDR then
                            -- All 32 rows processed
                            state <= DONE_ST;
                        else
                            addr_reg <= addr_reg + 1;
                            state    <= READ_ADDR;
                        end if;
 
                    -- ---------------------------------------------------------
                    -- Pulse done for 1 cycle then return to IDLE.
                    -- ---------------------------------------------------------
                    when DONE_ST =>
                        done  <= '1';
                        state <= IDLE;
 
                    -- ---------------------------------------------------------
                    when others =>
                        state <= IDLE;
 
                end case;
            end if;
        end if;
    end process;
 
end behavioral;