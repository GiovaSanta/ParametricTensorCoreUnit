library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.riscv_klessydra.all;

entity TCU_Branch is
  generic (
    THREAD_POOL_SIZE : integer
  );
  port (
    clk_i : in std_logic;
    rst_ni : in std_logic; 

    -- Request from ID_STAGE / Pipeline
    tcu_instr_req : in std_logic;

    -- Instruction context
    instr_word_IE : in std_logic_vector(31 downto 0);
    pc_IE         : in std_logic_vector(31 downto 0);
    harc_EXEC     : in integer range THREAD_POOL_SIZE-1 downto 0;

    -- Register operands from REGISTERFILE
    RS1_Data_IE : in std_logic_vector(31 downto 0);
    RS2_Data_IE : in std_logic_vector(31 downto 0);
    RD_Data_IE  : in std_logic_vector(31 downto 0);

    -- Debug outputs for waveform visibility
    tcu_valid_dbg : out std_logic;
    tcu_instr_dbg : out std_logic_vector(31 downto 0);
    tcu_pc_dbg    : out std_logic_vector(31 downto 0);
    tcu_harc_dbg  : out integer range THREAD_POOL_SIZE-1 downto 0;
    tcu_rs1_dbg   : out std_logic_vector(31 downto 0);
    tcu_rs2_dbg   : out std_logic_vector(31 downto 0);
    tcu_rd_dbg    : out std_logic_vector(31 downto 0)
  );
end entity;

architecture rtl of TCU_Branch is

  signal tcu_valid_lat : std_logic;
  signal tcu_instr_lat : std_logic_vector(31 downto 0);
  signal tcu_pc_lat    : std_logic_vector(31 downto 0);
  signal tcu_harc_lat  : integer range THREAD_POOL_SIZE-1 downto 0;
  signal tcu_rs1_lat   : std_logic_vector(31 downto 0);
  signal tcu_rs2_lat   : std_logic_vector(31 downto 0);
  signal tcu_rd_lat    : std_logic_vector(31 downto 0);

begin

  process(clk_i, rst_ni)
  begin
    if rst_ni = '0' then

      tcu_valid_lat <= '0';
      tcu_instr_lat <= (others => '0');
      tcu_pc_lat    <= (others => '0');
      tcu_harc_lat  <= 0;
      tcu_rs1_lat   <= (others => '0');
      tcu_rs2_lat   <= (others => '0');
      tcu_rd_lat    <= (others => '0');

    elsif rising_edge(clk_i) then

      if tcu_instr_req = '1' then

        tcu_valid_lat <= '1';
        tcu_instr_lat <= instr_word_IE;
        tcu_pc_lat    <= pc_IE;
        tcu_harc_lat  <= harc_EXEC;
        tcu_rs1_lat   <= RS1_Data_IE;
        tcu_rs2_lat   <= RS2_Data_IE;
        tcu_rd_lat    <= RD_Data_IE;

      else

        tcu_valid_lat <= '0';

      end if;

    end if;
  end process;

  -- Debug outputs
  tcu_valid_dbg <= tcu_valid_lat;
  tcu_instr_dbg <= tcu_instr_lat;
  tcu_pc_dbg    <= tcu_pc_lat;
  tcu_harc_dbg  <= tcu_harc_lat;
  tcu_rs1_dbg   <= tcu_rs1_lat;
  tcu_rs2_dbg   <= tcu_rs2_lat;
  tcu_rd_dbg    <= tcu_rd_lat;

end architecture;