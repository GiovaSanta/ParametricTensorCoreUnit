-- tb_dp_regfile.vhd  (Vivado/XSim-friendly, file preload + safe hex print)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

use ieee.std_logic_textio.all;  -- hread

entity tb_dp_regfile is
end entity;

architecture tb of tb_dp_regfile is

  constant RAM_SIZE    : integer := 1024;
  constant RAM_A_WIDTH : integer := 10;
  constant RAM_D_WIDTH : integer := 32;

  signal clk   : std_logic := '0';
  signal rst   : std_logic := '0';

  signal addr_a : std_logic_vector(RAM_A_WIDTH-1 downto 0) := (others => '0');
  signal din_a  : std_logic_vector(RAM_D_WIDTH-1 downto 0) := (others => '0');
  signal we_a   : std_logic := '0';

  signal addr_b : std_logic_vector(RAM_A_WIDTH-1 downto 0) := (others => '0');
  signal din_b  : std_logic_vector(RAM_D_WIDTH-1 downto 0) := (others => '0');
  signal we_b   : std_logic := '0';

  signal dout_a : std_logic_vector(RAM_D_WIDTH-1 downto 0);
  signal dout_b : std_logic_vector(RAM_D_WIDTH-1 downto 0);

  constant CLK_PERIOD : time := 10 ns;

  -- Helper: convert integer to address vector
  function to_addr(i : integer) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(i, RAM_A_WIDTH));
  end function;

  -- Vivado/XSim-safe std_logic_vector -> hex string (no to_hstring/to_string)
  function slv_to_hex(slv : std_logic_vector) return string is
    constant NIBBLES : integer := (slv'length + 3) / 4;
    variable padded  : std_logic_vector(NIBBLES*4 - 1 downto 0) := (others => '0');
    variable s       : string(1 to NIBBLES);
    variable nibble  : std_logic_vector(3 downto 0);
    variable v       : integer;
  begin
    padded(slv'length-1 downto 0) := slv;

    for i in 0 to NIBBLES-1 loop
      nibble := padded((NIBBLES-1-i)*4 + 3 downto (NIBBLES-1-i)*4);

      -- treat anything not '1' as 0 for printing
      v := 0;
      if nibble(3) = '1' then v := v + 8; end if;
      if nibble(2) = '1' then v := v + 4; end if;
      if nibble(1) = '1' then v := v + 2; end if;
      if nibble(0) = '1' then v := v + 1; end if;

      case v is
        when 0  => s(i+1) := '0';
        when 1  => s(i+1) := '1';
        when 2  => s(i+1) := '2';
        when 3  => s(i+1) := '3';
        when 4  => s(i+1) := '4';
        when 5  => s(i+1) := '5';
        when 6  => s(i+1) := '6';
        when 7  => s(i+1) := '7';
        when 8  => s(i+1) := '8';
        when 9  => s(i+1) := '9';
        when 10 => s(i+1) := 'A';
        when 11 => s(i+1) := 'B';
        when 12 => s(i+1) := 'C';
        when 13 => s(i+1) := 'D';
        when 14 => s(i+1) := 'E';
        when others => s(i+1) := 'F';
      end case;
    end loop;

    return s;
  end function;

begin
  -- DUT
  dut: entity work.dp_regfile
    generic map(
      RAM_SIZE    => RAM_SIZE,
      RAM_A_WIDTH => RAM_A_WIDTH,
      RAM_D_WIDTH => RAM_D_WIDTH
    )
    port map(
      clk    => clk,
      rst    => rst,
      addr_a => addr_a,
      din_a  => din_a,
      we_a   => we_a,
      addr_b => addr_b,
      din_b  => din_b,
      we_b   => we_b,
      dout_a => dout_a,
      dout_b => dout_b
    );

  -- clock
  clk <= not clk after CLK_PERIOD/2;

  --------------------------------------------------------------
  -- File-driven preload + (optional) checks after preload
  --------------------------------------------------------------
  stim: process

    -- writes one entry through port A
    procedure wr_a(addr_i: integer; data_v: std_logic_vector(RAM_D_WIDTH-1 downto 0)) is
    begin
      addr_a <= to_addr(addr_i);
      din_a  <= data_v;
      we_a   <= '1';
      wait until rising_edge(clk);
      wait for 1 ns;
      we_a   <= '0';
    end procedure;

    -- writes one entry through port B
    procedure wr_b(addr_i : integer; data_v : std_logic_vector(RAM_D_WIDTH-1 downto 0)) is
    begin
      addr_b <= to_addr(addr_i);
      din_b  <= data_v;
      we_b   <= '1';
      wait until rising_edge(clk);
      wait for 1 ns;
      we_b   <= '0';
    end procedure;

    -- preloading from text file.
    -- format per non-comment line: "<hex_addr> <hex_data>"
    -- example: "0A FF"
    procedure preload_from_file(constant fname : in string) is
      file     f          : text open read_mode is fname;
      variable l          : line;
      variable ok         : boolean;
      variable c          : character;
      variable use_port_a : boolean := true;
      variable line_no    : integer := 0;
      variable addr_i     : integer;

      -- IMPORTANT: hread wants vectors whose length is a multiple of 4.
      constant ADDR_PAD_BITS : integer := ((RAM_A_WIDTH + 3) / 4) * 4; -- e.g. 12 for 10-bit addr
      variable addr_tmp   : std_logic_vector(ADDR_PAD_BITS-1 downto 0);

      variable data_slv   : std_logic_vector(RAM_D_WIDTH-1 downto 0);
    begin
      -- put ports in a known state
      we_a   <= '0'; we_b <= '0';
      din_a  <= (others => '0'); din_b <= (others => '0');
      addr_a <= (others => '0'); addr_b <= (others => '0');

      -- optional reset pulse (your RTL doesn't clear RAM anyway)
      rst <= '1';
      wait for 2*CLK_PERIOD;
      rst <= '0';
      wait until rising_edge(clk);

      while not endfile(f) loop
        readline(f, l);
        line_no := line_no + 1;

        -- skip blank lines
        if l'length = 0 then
          next;
        end if;

        -- skip leading whitespace
        ok := true;
        while ok loop
          if l'length = 0 then
            ok := false;
          else
            c := l.all(l.all'left);
            if c = ' ' or c = HT then
              read(l, c, ok);
              ok := true;
            else
              exit;
            end if;
          end if;
        end loop;

        if l'length = 0 then
          next;
        end if;

        -- comment line
        c := l.all(l.all'left);
        if c = '#' then
          next;
        end if;

        -- read hex address into padded vector
        hread(l, addr_tmp, ok);
        if not ok then
          report "Preload parse error (addr) on line " & integer'image(line_no)
            severity failure;
        end if;

        -- read hex data
        hread(l, data_slv, ok);
        if not ok then
          report "Preload parse error (data) on line " & integer'image(line_no)
            severity failure;
        end if;

        -- take low RAM_A_WIDTH bits as the actual address
        addr_i := to_integer(unsigned(addr_tmp(RAM_A_WIDTH-1 downto 0)));

        if addr_i < 0 or addr_i >= RAM_SIZE then
          report "Preload warning: address out of range on line " &
                 integer'image(line_no) & " addr=" & integer'image(addr_i)
            severity warning;
          next;
        end if;

        -- alternate ports to preload faster (optional)
        if use_port_a then
          wr_a(addr_i, data_slv);
        else
          wr_b(addr_i, data_slv);
        end if;
        use_port_a := not use_port_a;

      end loop;

      report "Preload complete from file: " & fname severity note;
    end procedure;

  begin
    -- *** PRELOADING HERE ***
    -- Use either:
    -- 1) forward slashes (recommended on Windows), OR
    -- 2) double backslashes
    preload_from_file("C:/Users/giovi/OneDrive/Desktop/Magistrale/Tesi/parametricDpuArrayAndSurroundings/RF_initial_values.txt");
    -- preload_from_file("C:\\Users\\giovi\\OneDrive\\Desktop\\Magistrale\\Tesi\\parametricDpuArrayAndSurroundings\\RF_initial_values.txt");

    -- quick sanity read
    addr_a <= to_addr(0); we_a <= '0';
    addr_b <= to_addr(1); we_b <= '0';
    wait for 1 ns;

    report "Post-preload sample: dout_a=0x" & slv_to_hex(dout_a) &
           " dout_b=0x" & slv_to_hex(dout_b)
      severity note;

    -- continue with your HMMA sequencing...
    wait;
  end process;

end architecture;