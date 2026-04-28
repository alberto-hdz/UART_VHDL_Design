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

    type state_type is (
        IDLE,
        READ_ADDR,
        WAIT_RAM,
        CLASSIFY,
        OUTPUT,
        DONE_ST
    );

    signal state : state_type := IDLE;

    signal addr_reg : unsigned(4 downto 0) := (others => '0');
    signal byte_ctr : integer range 0 to 3  := 0;

    type byte_class_t is array(0 to 3) of std_logic_vector(7 downto 0);
    signal class_regs : byte_class_t := (others => (others => '0'));

    constant MAX_ADDR : unsigned(4 downto 0) := "11111";

    function classify_byte(b : unsigned(7 downto 0)) return std_logic_vector is
    begin
        if    b >= x"41" and b <= x"5A" then return x"01";
        elsif b >= x"61" and b <= x"7A" then return x"02";
        elsif b >= x"30" and b <= x"39" then return x"03";
        else                                  return x"00";
        end if;
    end function;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state        <= IDLE;
                addr_reg     <= (others => '0');
                byte_ctr     <= 0;
                class_regs   <= (others => (others => '0'));
                ram_addr     <= (others => '0');
                result       <= (others => '0');
                result_valid <= '0';
                done         <= '0';
            else
                result_valid <= '0';
                done         <= '0';

                case state is

                    when IDLE =>
                        addr_reg <= (others => '0');
                        byte_ctr <= 0;
                        if start = '1' then
                            state <= READ_ADDR;
                        end if;

                    when READ_ADDR =>
                        ram_addr <= std_logic_vector(addr_reg);
                        state    <= WAIT_RAM;

                    when WAIT_RAM =>
                        state <= CLASSIFY;

                    when CLASSIFY =>
                        class_regs(0) <= classify_byte(unsigned(ram_dout( 7 downto  0)));
                        class_regs(1) <= classify_byte(unsigned(ram_dout(15 downto  8)));
                        class_regs(2) <= classify_byte(unsigned(ram_dout(23 downto 16)));
                        class_regs(3) <= classify_byte(unsigned(ram_dout(31 downto 24)));
                        byte_ctr <= 0;
                        state    <= OUTPUT;

                    when OUTPUT =>
                        result       <= class_regs(byte_ctr);
                        result_valid <= '1';

                        if byte_ctr = 3 then
                            byte_ctr <= 0;
                            if addr_reg = MAX_ADDR then
                                state <= DONE_ST;
                            else
                                addr_reg <= addr_reg + 1;
                                state    <= READ_ADDR;
                            end if;
                        else
                            byte_ctr <= byte_ctr + 1;
                        end if;

                    when DONE_ST =>
                        done  <= '1';
                        state <= IDLE;

                    when others =>
                        state <= IDLE;

                end case;
            end if;
        end if;
    end process;

end behavioral;
