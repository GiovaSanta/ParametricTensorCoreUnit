library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.riscv_klessydra.all;

entity TCU_Branch is
  generic (
    THREAD_POOL_SIZE : integer
  );
  port (
    clk_i  : in std_logic;
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

  ---------------------------------------------------------------------------
  -- Latched raw TCU packet
  ---------------------------------------------------------------------------

  signal tcu_valid_lat : std_logic;
  signal tcu_instr_lat : std_logic_vector(31 downto 0);
  signal tcu_pc_lat    : std_logic_vector(31 downto 0);
  signal tcu_harc_lat  : integer range THREAD_POOL_SIZE-1 downto 0;
  signal tcu_rs1_lat   : std_logic_vector(31 downto 0);
  signal tcu_rs2_lat   : std_logic_vector(31 downto 0);
  signal tcu_rd_lat    : std_logic_vector(31 downto 0);

  ---------------------------------------------------------------------------
  -- Combinational decoded wires
  -- These are decoded from the live instr_word_IE during the IE cycle.
  ---------------------------------------------------------------------------

  signal tcu_opcode_wire           : std_logic_vector(6 downto 0);
  signal tcu_rd_idx_wire           : integer range 0 to 31;
  signal tcu_funct3_wire           : std_logic_vector(2 downto 0);
  signal tcu_rs1_idx_wire          : integer range 0 to 31;
  signal tcu_rs2_idx_wire          : integer range 0 to 31;
  signal tcu_funct7_wire           : std_logic_vector(6 downto 0);
  signal tcu_regs_per_operand_wire : integer range 1 to 4;

  ---------------------------------------------------------------------------
  -- Latched decoded TCU packet
  -- These are the stable decoded fields for the future TCU controller.
  ---------------------------------------------------------------------------

  signal tcu_opcode_lat           : std_logic_vector(6 downto 0);
  signal tcu_rd_idx_lat           : integer range 0 to 31;
  signal tcu_funct3_lat           : std_logic_vector(2 downto 0);
  signal tcu_rs1_idx_lat          : integer range 0 to 31;
  signal tcu_rs2_idx_lat          : integer range 0 to 31;
  signal tcu_funct7_lat           : std_logic_vector(6 downto 0);
  signal tcu_regs_per_operand_lat : integer range 1 to 4;

begin

  ---------------------------------------------------------------------------
  -- TCU combinational decode
  --
  -- This decodes the live instruction while it is present in IE.
  -- The decoded wires are then latched by TCU_packet_sync when tcu_instr_req = 1.
  ---------------------------------------------------------------------------

  TCU_decode_comb : process(all)
  begin

    -- Safe defaults
    tcu_opcode_wire           <= (others => '0');
    tcu_rd_idx_wire           <= 0;
    tcu_funct3_wire           <= (others => '0');
    tcu_rs1_idx_wire          <= 0;
    tcu_rs2_idx_wire          <= 0;
    tcu_funct7_wire           <= (others => '0');
    tcu_regs_per_operand_wire <= 1;

    if tcu_instr_req = '1' then

      -- R-type field extraction
      tcu_opcode_wire  <= instr_word_IE(6 downto 0);
      tcu_rd_idx_wire  <= to_integer(unsigned(instr_word_IE(11 downto 7)));
      tcu_funct3_wire  <= instr_word_IE(14 downto 12);
      tcu_rs1_idx_wire <= to_integer(unsigned(instr_word_IE(19 downto 15)));
      tcu_rs2_idx_wire <= to_integer(unsigned(instr_word_IE(24 downto 20)));
      tcu_funct7_wire  <= instr_word_IE(31 downto 25);

      -- Format decode from funct7.
      -- Current convention:
      --   0000000 = FP8
      --   0000001 = FP16
      --   0000010 = FP32
      --   0000100 = POSIT8
      --   0000101 = POSIT16
      --   0000110 = POSIT32
      --   0001000 = INT8
      --   0001001 = INT16
      --   0001100 = FIXED8
      --   0001101 = FIXED16

      case instr_word_IE(31 downto 25) is

        when "0000000" =>  -- FP8
          tcu_regs_per_operand_wire <= 1;

        when "0000001" =>  -- FP16
          tcu_regs_per_operand_wire <= 2;

        when "0000010" =>  -- FP32
          tcu_regs_per_operand_wire <= 4;

        when "0000100" =>  -- POSIT8
          tcu_regs_per_operand_wire <= 1;

        when "0000101" =>  -- POSIT16
          tcu_regs_per_operand_wire <= 2;

        when "0000110" =>  -- POSIT32
          tcu_regs_per_operand_wire <= 4;

        when "0001000" =>  -- INT8
          tcu_regs_per_operand_wire <= 1;

        when "0001001" =>  -- INT16
          tcu_regs_per_operand_wire <= 2;

        when "0001100" =>  -- FIXED8
          tcu_regs_per_operand_wire <= 1;

        when "0001101" =>  -- FIXED16
          tcu_regs_per_operand_wire <= 2;

        when others =>
          tcu_regs_per_operand_wire <= 1;

      end case;

    end if;

  end process;


  ---------------------------------------------------------------------------
  -- TCU synchronous packet capture
  --
  -- When tcu_instr_req is high, the current live pipeline information is
  -- captured into a stable packet for the future TCU controller.
  ---------------------------------------------------------------------------

  TCU_packet_sync : process(clk_i, rst_ni)
  begin
    if rst_ni = '0' then

      tcu_valid_lat <= '0';
      tcu_instr_lat <= (others => '0');
      tcu_pc_lat    <= (others => '0');
      tcu_harc_lat  <= 0;
      tcu_rs1_lat   <= (others => '0');
      tcu_rs2_lat   <= (others => '0');
      tcu_rd_lat    <= (others => '0');

      tcu_opcode_lat           <= (others => '0');
      tcu_rd_idx_lat           <= 0;
      tcu_funct3_lat           <= (others => '0');
      tcu_rs1_idx_lat          <= 0;
      tcu_rs2_idx_lat          <= 0;
      tcu_funct7_lat           <= (others => '0');
      tcu_regs_per_operand_lat <= 1;

    elsif rising_edge(clk_i) then

      if tcu_instr_req = '1' then

        -- Raw instruction packet
        tcu_valid_lat <= '1';
        tcu_instr_lat <= instr_word_IE;
        tcu_pc_lat    <= pc_IE;
        tcu_harc_lat  <= harc_EXEC;
        tcu_rs1_lat   <= RS1_Data_IE;
        tcu_rs2_lat   <= RS2_Data_IE;
        tcu_rd_lat    <= RD_Data_IE;

        -- Decoded instruction packet
        tcu_opcode_lat           <= tcu_opcode_wire;
        tcu_rd_idx_lat           <= tcu_rd_idx_wire;
        tcu_funct3_lat           <= tcu_funct3_wire;
        tcu_rs1_idx_lat          <= tcu_rs1_idx_wire;
        tcu_rs2_idx_lat          <= tcu_rs2_idx_wire;
        tcu_funct7_lat           <= tcu_funct7_wire;
        tcu_regs_per_operand_lat <= tcu_regs_per_operand_wire;

      else

        -- Valid is a pulse.
        -- The packet fields remain stored from the last TCU instruction.
        tcu_valid_lat <= '0';

      end if;

    end if;
  end process;


  ---------------------------------------------------------------------------
  -- Debug outputs
  ---------------------------------------------------------------------------

  tcu_valid_dbg <= tcu_valid_lat;
  tcu_instr_dbg <= tcu_instr_lat;
  tcu_pc_dbg    <= tcu_pc_lat;
  tcu_harc_dbg  <= tcu_harc_lat;
  tcu_rs1_dbg   <= tcu_rs1_lat;
  tcu_rs2_dbg   <= tcu_rs2_lat;
  tcu_rd_dbg    <= tcu_rd_lat;

end architecture;