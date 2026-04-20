library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo is
    generic (
        DATA_WIDTH : integer := 8;
        ADDR_WIDTH : integer := 4   -- 2^4 = 16 entries
    );
    port (
        clk    : in  std_logic;
        reset  : in  std_logic;
        wr     : in  std_logic;
        rd     : in  std_logic;
        w_data : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        r_data : out std_logic_vector(DATA_WIDTH-1 downto 0);
        empty  : out std_logic;
        full   : out std_logic
    );
end fifo;

architecture rtl of fifo is

    constant DEPTH : integer := 2**ADDR_WIDTH;

    type mem_type is array (0 to DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal mem : mem_type := (others => (others => '0'));

    signal w_ptr_reg : unsigned(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal r_ptr_reg : unsigned(ADDR_WIDTH-1 downto 0) := (others => '0');

    signal empty_reg : std_logic := '1';
    signal full_reg  : std_logic := '0';

    signal r_data_reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

    function ptr_inc(ptr : unsigned) return unsigned is
    begin
        return ptr + 1;
    end function;

begin

    process(clk, reset)
        variable w_ptr_next : unsigned(ADDR_WIDTH-1 downto 0);
        variable r_ptr_next : unsigned(ADDR_WIDTH-1 downto 0);
        variable do_write   : boolean;
        variable do_read    : boolean;
    begin
        if reset = '1' then
            w_ptr_reg <= (others => '0');
            r_ptr_reg <= (others => '0');
            empty_reg <= '1';
            full_reg  <= '0';
            r_data_reg <= (others => '0');

        elsif rising_edge(clk) then
            -- default: keep current pointers
            w_ptr_next := w_ptr_reg;
            r_ptr_next := r_ptr_reg;

            -- protected operations
            -- allow write if not full, or if a read happens in same cycle
            do_write := (wr = '1') and ((full_reg = '0') or (rd = '1'));

            -- allow read only if not empty
            do_read := (rd = '1') and (empty_reg = '0');

            -- read current FIFO location
            if do_read then
                r_data_reg <= mem(to_integer(r_ptr_reg));
                r_ptr_next := ptr_inc(r_ptr_reg);
            end if;

            -- write new FIFO location
            if do_write then
                mem(to_integer(w_ptr_reg)) <= w_data;
                w_ptr_next := ptr_inc(w_ptr_reg);
            end if;

            -- update pointers
            w_ptr_reg <= w_ptr_next;
            r_ptr_reg <= r_ptr_next;

            -- update status flags from next pointer values
            if w_ptr_next = r_ptr_next then
                empty_reg <= '1';
            else
                empty_reg <= '0';
            end if;

            if ptr_inc(w_ptr_next) = r_ptr_next then
                full_reg <= '1';
            else
                full_reg <= '0';
            end if;
        end if;
    end process;

    r_data <= r_data_reg;
    empty  <= empty_reg;
    full   <= full_reg;

end rtl;
