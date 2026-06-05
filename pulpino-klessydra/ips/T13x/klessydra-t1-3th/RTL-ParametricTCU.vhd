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

    -- Full architectural register file, read-only view for TCU operand collection
    -- Prototype assumption: 32 registers x 32 bits per hart.
    regfile_i : in array_3d(THREAD_POOL_SIZE-1 downto 0)(31 downto 0)(31 downto 0);

    -- Debug outputs for waveform visibility
    tcu_valid_dbg : out std_logic;
    tcu_instr_dbg : out std_logic_vector(31 downto 0);
    tcu_pc_dbg    : out std_logic_vector(31 downto 0);
    tcu_harc_dbg  : out integer range THREAD_POOL_SIZE-1 downto 0;
    tcu_rs1_dbg   : out std_logic_vector(31 downto 0);
    tcu_rs2_dbg   : out std_logic_vector(31 downto 0);
    tcu_rd_dbg    : out std_logic_vector(31 downto 0);

    -- TCU status toward pipeline control
    busy_TCU      : out std_logic;
    core_busy_TCU : out std_logic;

    --writeback related
    TCU_WB_EN         : out std_logic;
    TCU_WB            : out std_logic_vector(31 downto 0);
    instr_word_TCU_WB : out std_logic_vector(31 downto 0);
    harc_TCU_WB       : out integer range THREAD_POOL_SIZE-1 downto 0
  );
end entity;


architecture rtl of TCU_Branch is

  ---------------------------------------------------------------------------
  -- Latched raw TCU packet
  ---------------------------------------------------------------------------
  signal tcu_valid_lat : std_logic;
  signal tcu_instr_lat : std_logic_vector(31 downto 0); -- stored instruction used to reconstruct writeback transactions
  signal tcu_pc_lat    : std_logic_vector(31 downto 0);
  signal tcu_harc_lat  : integer range THREAD_POOL_SIZE-1 downto 0;
  signal tcu_rs1_lat   : std_logic_vector(31 downto 0);
  signal tcu_rs2_lat   : std_logic_vector(31 downto 0);  
  signal tcu_rd_lat    : std_logic_vector(31 downto 0);

  ---------------------------------------------------------------------------
  -- Combinational decoded wires
  -- These are decoded from the live instr_word_IE during the IE cycle.
  ---------------------------------------------------------------------------
  signal tcu_rd_idx_wire           : integer range 0 to 31;  -- which register of RFs will contain the result. this index is also used for the third operand of the accumulation (matrix C related value)
  signal tcu_funct3_wire           : std_logic_vector(2 downto 0); -- is it an hmma step 0 or step 1 instruction
  signal tcu_rs1_idx_wire          : integer range 0 to 31; -- which register of the RFs contain first operand (related to matrix A)
  signal tcu_rs2_idx_wire          : integer range 0 to 31; -- which register of the RFs contain second operand (related to matrix B)
  signal tcu_funct7_wire           : std_logic_vector(6 downto 0); --selection of which type of operand and bit width 

  ---------------------------------------------------------------------------
  -- Latched decoded TCU packet
  -- These are the stable decoded fields for the TCU controller.
  ---------------------------------------------------------------------------
  signal tcu_rd_idx_lat           : integer range 0 to 31; -- used for rd, rd+1, rd+2, rd+3 writeback
  signal tcu_funct3_lat           : std_logic_vector(2 downto 0); --used for hmma_step understanding.

  ---------------------------------------------------------------------------
  -- Tensor-core input staging arrays, one slot per hart/lane
  --
  -- These are not the final tensor core wrapper yet.
  -- They simply collect and preserve one format's HMMA fragment per hart.
  --
  -- src1 = A
  -- src2 = B
  -- src3 = C / accumulator
  --
  -- "pair00" type is enough for FP8,FP16,POSIT8,POSIT16, LNS16, INT8, FIXED8
  -- "pair01" type is needed for FP32, POSIT32
  ---------------------------------------------------------------------------
  signal tc0_src1_rf_port_a_pair00_s : arraySize16_32 ;
  signal tc0_src1_rf_port_b_pair00_s : arraySize16_32 ;
  signal tc0_src2_rf_port_a_pair00_s : arraySize16_32 ;
  signal tc0_src2_rf_port_b_pair00_s : arraySize16_32 ;
  signal tc0_src3_rf_port_a_pair00_s : arraySize16_32 ;
  signal tc0_src3_rf_port_b_pair00_s : arraySize16_32 ;
    
  signal tc0_src1_rf_port_a_pair01_s : arraySize16_32 ; --for the case of fp32 or posit32 for instance
  signal tc0_src1_rf_port_b_pair01_s : arraySize16_32 ;
  signal tc0_src2_rf_port_a_pair01_s : arraySize16_32 ;
  signal tc0_src2_rf_port_b_pair01_s : arraySize16_32 ;
  signal tc0_src3_rf_port_a_pair01_s : arraySize16_32 ;
  signal tc0_src3_rf_port_b_pair01_s : arraySize16_32 ;
  signal tcu_lane_valid_s      : std_logic_vector(THREAD_POOL_SIZE-1 downto 0);

  constant TCU_ALL_LANES_VALID_C : std_logic_vector(THREAD_POOL_SIZE-1 downto 0) := (others => '1');

  ---------------------------------------------------------------------------
  -- Single tensor-core wrapper interface
  ---------------------------------------------------------------------------
  signal tcu_wrapper_start_s       : std_logic;
  signal tcu_wrapper_busy_s        : std_logic;
  signal tcu_wrapper_done_s        : std_logic;
  signal tcu_wrapper_step_done_s   : std_logic;
  signal tcu_wrapper_load_pair_s   : std_logic_vector(1 downto 0);

-- Raw output interface signals from the tensor-core wrapper.
-- These are captured later into the stable tcu_res_* result buffers.  
  signal W0_tc0_oct0_8_X3_s  : arraySize16_8;
  signal W1_tc0_oct0_8_X3_s  : arraySize16_8;
  signal W0_tc0_oct0_16_X3_s : arraySize16_16;
  signal W1_tc0_oct0_16_X3_s : arraySize16_16;
  signal W0_tc0_oct0_32_X3_s : arraySize16_32;
  signal W1_tc0_oct0_32_X3_s : arraySize16_32;
  signal W0_tc0_oct1_8_X3_s  : arraySize16_8;
  signal W1_tc0_oct1_8_X3_s  : arraySize16_8;
  signal W0_tc0_oct1_16_X3_s : arraySize16_16;
  signal W1_tc0_oct1_16_X3_s : arraySize16_16;
  signal W0_tc0_oct1_32_X3_s : arraySize16_32;
  signal W1_tc0_oct1_32_X3_s : arraySize16_32;

  signal tcu_wrapper_rst_s : std_logic;

  ---------------------------------------------------------------------------
  -- TCU controller FSM, needed for better organization and for instance for stalling the upcoming instructions while tcu operates
  ---------------------------------------------------------------------------
  type tcu_state_t is ( TCU_IDLE, TCU_COLLECT, TCU_START, TCU_WAIT_DONE, TCU_WRITEBACK, TCU_RELEASE );

  signal tcu_state_s      : tcu_state_t;
  signal tcu_next_state_s : tcu_state_t;
  signal busy_TCU_s       : std_logic;
  signal core_busy_TCU_s  : std_logic;


  -- Predicts whether the already-collected lanes plus the current request
  -- complete the full TCU input packet.
  signal tcu_all_lanes_valid_next_s : std_logic; 

  signal tcu_wrapper_result_valid_s : std_logic;
  signal tcu_wrapper_result_step_s  : std_logic_vector(1 downto 0);

  -- Latched/stable result buffers used by the writeback FSM.
  signal tcu_res_W0_tc0_oct0_16_s : arraySize16_16;
  signal tcu_res_W1_tc0_oct0_16_s : arraySize16_16;
  signal tcu_res_W0_tc0_oct1_16_s : arraySize16_16;
  signal tcu_res_W1_tc0_oct1_16_s : arraySize16_16;

  signal tcu_res_W0_tc0_oct0_8_s : arraySize16_8;
  signal tcu_res_W1_tc0_oct0_8_s : arraySize16_8;
  signal tcu_res_W0_tc0_oct1_8_s : arraySize16_8;
  signal tcu_res_W1_tc0_oct1_8_s : arraySize16_8;

  signal tcu_res_W0_tc0_oct0_32_s : arraySize16_32;
  signal tcu_res_W1_tc0_oct0_32_s : arraySize16_32;
  signal tcu_res_W0_tc0_oct1_32_s : arraySize16_32;
  signal tcu_res_W1_tc0_oct1_32_s : arraySize16_32;

  signal tcu_result_is_8bit_lat  : std_logic;
  signal tcu_result_is_32bit_lat : std_logic;

  signal tcu_wb_hart_s       : integer range 0 to THREAD_POOL_SIZE-1;
  signal tcu_wb_word_s       : integer range 0 to 3;

  signal TCU_WB_EN_s         : std_logic;
  signal TCU_WB_s            : std_logic_vector(31 downto 0);
  signal instr_word_TCU_WB_s : std_logic_vector(31 downto 0);
  signal harc_TCU_WB_s       : integer range THREAD_POOL_SIZE-1 downto 0;

  signal tcu_wb_word0_s      : std_logic_vector(31 downto 0);
  signal tcu_wb_word1_s      : std_logic_vector(31 downto 0);
  signal tcu_wb_word2_s : std_logic_vector(31 downto 0);
  signal tcu_wb_word3_s : std_logic_vector(31 downto 0);

  signal tcu_wrapper_hmma_step_s : std_logic;

  signal tcu_wrapper_widthSel_lat : std_logic_vector(1 downto 0);
  signal tcu_wrapper_typeSel_lat  : std_logic_vector(2 downto 0);

begin

  --****************************A.) FRONT END / INSTRUCTION CAPTURE PROCESSES*********************************
  ---------------------------------------------------------------------------
  -- A.1) TCU combinational decode
  --  
  -- This decodes the live instruction while it is present in IE.
  -- The decoded wires are then latched by TCU_packet_sync when tcu_instr_req = 1.
  ---------------------------------------------------------------------------
  TCU_decode_comb : process(all)
  begin

    -- Safe defaults
    tcu_rd_idx_wire           <= 0;
    tcu_funct3_wire           <= (others => '0');
    tcu_rs1_idx_wire          <= 0;
    tcu_rs2_idx_wire          <= 0;
    tcu_funct7_wire           <= (others => '0');
    
    if tcu_instr_req = '1' then
      -- R-type field extraction
      tcu_rd_idx_wire  <= to_integer(unsigned(instr_word_IE(11 downto 7)));
      tcu_funct3_wire  <= instr_word_IE(14 downto 12);
      tcu_rs1_idx_wire <= to_integer(unsigned(instr_word_IE(19 downto 15)));
      tcu_rs2_idx_wire <= to_integer(unsigned(instr_word_IE(24 downto 20)));
      tcu_funct7_wire  <= instr_word_IE(31 downto 25);

    end if;

  end process;
  ---------------------------------------------------------------------------
  -- A.2) Predict whether the current HMMA request completes all TCU lanes
  ---------------------------------------------------------------------------
  TCU_valid_next_comb : process(all)
    variable lane_valid_next_v : std_logic_vector(THREAD_POOL_SIZE-1 downto 0);
    begin
      lane_valid_next_v := tcu_lane_valid_s;

      if tcu_instr_req = '1' and
        (tcu_state_s = TCU_IDLE or tcu_state_s = TCU_COLLECT) then
        lane_valid_next_v(harc_EXEC) := '1';
      end if;

      if lane_valid_next_v = TCU_ALL_LANES_VALID_C then
        tcu_all_lanes_valid_next_s <= '1';
      else
        tcu_all_lanes_valid_next_s <= '0';
      end if;
  end process;
  ---------------------------------------------------------------------------
  -- A.3) TCU synchronous packet capture
  --
  -- When tcu_instr_req is high, the current live pipeline information is
  -- captured into stable packet/registers used during wrapper execution.
  ---------------------------------------------------------------------------
  TCU_packet_sync : process(clk_i, rst_ni)
  variable tcu_lane_idx_v : integer range 0 to THREAD_POOL_SIZE-1;
  variable regs_per_operand_v : integer range 1 to 4;
  begin
    if rst_ni = '0' then

      tcu_valid_lat <= '0';
      tcu_instr_lat <= (others => '0');
      tcu_pc_lat    <= (others => '0');
      tcu_harc_lat  <= 0;
      tcu_rs1_lat   <= (others => '0');
      tcu_rs2_lat   <= (others => '0');
      tcu_rd_lat    <= (others => '0');

      tcu_rd_idx_lat           <= 0;
      tcu_funct3_lat           <= (others => '0');

      tcu_wrapper_widthSel_lat <= "01"; -- default FP16-like width
      tcu_wrapper_typeSel_lat  <= "000"; -- default floating-point type
      tcu_result_is_8bit_lat  <= '0';
      tcu_result_is_32bit_lat <= '0';

      for i in 0 to THREAD_POOL_SIZE-1 loop
        tc0_src1_rf_port_a_pair00_s(i) <= (others => '0');
        tc0_src1_rf_port_b_pair00_s(i) <= (others => '0');

        tc0_src2_rf_port_a_pair00_s(i) <= (others => '0');
        tc0_src2_rf_port_b_pair00_s(i) <= (others => '0');

        tc0_src3_rf_port_a_pair00_s(i) <= (others => '0');
        tc0_src3_rf_port_b_pair00_s(i) <= (others => '0');

        tc0_src1_rf_port_a_pair01_s(i) <= (others => '0');
        tc0_src1_rf_port_b_pair01_s(i) <= (others => '0');

        tc0_src2_rf_port_a_pair01_s(i) <= (others => '0');
        tc0_src2_rf_port_b_pair01_s(i) <= (others => '0');

        tc0_src3_rf_port_a_pair01_s(i) <= (others => '0');
        tc0_src3_rf_port_b_pair01_s(i) <= (others => '0');
      end loop;

      tcu_lane_valid_s <= (others => '0');
      
    elsif rising_edge(clk_i) then

    if tcu_instr_req = '1' and (tcu_state_s = TCU_IDLE or tcu_state_s = TCU_COLLECT) then

        -- Raw instruction packet
        tcu_valid_lat <= '1';
        tcu_instr_lat <= instr_word_IE;
        tcu_pc_lat    <= pc_IE;
        tcu_harc_lat  <= harc_EXEC;
        tcu_rs1_lat   <= RS1_Data_IE;
        tcu_rs2_lat   <= RS2_Data_IE;
        tcu_rd_lat    <= RD_Data_IE;

        -- Decoded instruction packet
        tcu_rd_idx_lat           <= tcu_rd_idx_wire;
        tcu_funct3_lat           <= tcu_funct3_wire;

        regs_per_operand_v := 1;

        -- Decode and latch wrapper format controls together with the accepted
        -- TCU instruction. These remain stable during TCU_START / TCU_WAIT_DONE.
        case tcu_funct7_wire is
          when "0000000" =>  -- FP8
            tcu_wrapper_widthSel_lat <= "00";
            tcu_wrapper_typeSel_lat  <= "000";
            tcu_result_is_8bit_lat   <= '1';
            tcu_result_is_32bit_lat  <= '0';
            regs_per_operand_v       := 1;
          when "0000001" =>  -- FP16
            tcu_wrapper_widthSel_lat <= "01";
            tcu_wrapper_typeSel_lat  <= "000";
            tcu_result_is_8bit_lat   <= '0';
            tcu_result_is_32bit_lat  <= '0';
            regs_per_operand_v       := 2;
          when "0000010" =>  -- FP32
            tcu_wrapper_widthSel_lat <= "10";
            tcu_wrapper_typeSel_lat  <= "000";
            tcu_result_is_8bit_lat   <= '0';
            tcu_result_is_32bit_lat  <= '1';
            regs_per_operand_v       := 4;
          when "0000100" =>  -- POSIT8
            tcu_wrapper_widthSel_lat <= "00";
            tcu_wrapper_typeSel_lat  <= "001";
            tcu_result_is_8bit_lat   <= '1';
            tcu_result_is_32bit_lat  <= '0';
            regs_per_operand_v       := 1;
          when "0000101" =>  -- POSIT16
            tcu_wrapper_widthSel_lat <= "01";
            tcu_wrapper_typeSel_lat  <= "001";
            tcu_result_is_8bit_lat   <= '0';
            tcu_result_is_32bit_lat  <= '0';
            regs_per_operand_v       := 2;
          when "0000110" =>  -- POSIT32
            tcu_wrapper_widthSel_lat <= "10";
            tcu_wrapper_typeSel_lat  <= "001";
            tcu_result_is_8bit_lat   <= '0';
            tcu_result_is_32bit_lat  <= '1';
            regs_per_operand_v       := 4;
          when "0001000" =>  -- INT8_16
            tcu_wrapper_widthSel_lat <= "00";
            tcu_wrapper_typeSel_lat  <= "011";
            tcu_result_is_8bit_lat   <= '0';
            tcu_result_is_32bit_lat  <= '0';
            regs_per_operand_v       := 1;
          when "0001001" =>  -- INT16_32
            tcu_wrapper_widthSel_lat <= "01";
            tcu_wrapper_typeSel_lat  <= "011";
            tcu_result_is_8bit_lat   <= '0';
            tcu_result_is_32bit_lat  <= '1';
            regs_per_operand_v       := 2;
          when "0001100" =>  -- FIXED8_16
            tcu_wrapper_widthSel_lat <= "00";
            tcu_wrapper_typeSel_lat  <= "010";
            tcu_result_is_8bit_lat   <= '0';
            tcu_result_is_32bit_lat  <= '0';
            regs_per_operand_v       := 1;
          when "0001101" =>  -- FIXED16_32
            tcu_wrapper_widthSel_lat <= "01";
            tcu_wrapper_typeSel_lat  <= "010";
            tcu_result_is_8bit_lat   <= '0';
            tcu_result_is_32bit_lat  <= '1';
            regs_per_operand_v       := 2;
          when "0010010" =>  --LNS16
            tcu_wrapper_widthSel_lat <= "01";
            tcu_wrapper_typeSel_lat  <= "100";
            tcu_result_is_8bit_lat   <= '0';
            tcu_result_is_32bit_lat  <= '0';
            regs_per_operand_v       := 2;

          when others =>
            tcu_wrapper_widthSel_lat <= "01";
            tcu_wrapper_typeSel_lat  <= "000";
            tcu_result_is_8bit_lat   <= '0';
            tcu_result_is_32bit_lat  <= '0';
            regs_per_operand_v       := 1;
        end case;

      if (regs_per_operand_v = 1) or (regs_per_operand_v = 2) then

          -----------------------------------------------------------------
          -- Store this hart's HMMA fragment into the 16-lane staging arrays.
          --
          -- For 8-bit result formats:
          --   A = src1 = rs1 only
          --   B = src2 = rs2 only
          --   C = src3 = rd  only
          --   one 32-bit register contains 4 x 8-bit values
          --
          -- For native 16-bit operand formats FP16/POSIT16/LNS16:
          --   A = src1 = rs1, rs1+1
          --   B = src2 = rs2, rs2+1
          --   C = src3 = rd,  rd+1
          --
          -- For mixed INT8_16 and FIXED8_16:
          --   A/B are 8-bit and use rs1/rs2 only
          --   C/result are 16-bit and use rd, rd+1
          -----------------------------------------------------------------

          -----------------------------------------------------------------
          -- Preserve the same hart-to-wrapper-lane mapping already used
          -- by the working FP16/POSIT16 implementation.
          -----------------------------------------------------------------

          if harc_EXEC < 4 then
            tcu_lane_idx_v := harc_EXEC;

          elsif harc_EXEC < 8 then
            tcu_lane_idx_v := harc_EXEC + 4;

          elsif harc_EXEC < 12 then
            tcu_lane_idx_v := harc_EXEC - 4;

          else
            tcu_lane_idx_v := harc_EXEC;

          end if;

          -----------------------------------------------------------------
          -- First packed 32-bit register is always used.
          -- For FP8 this register contains 4 FP8 operands.
          -- For FP16/POSIT16/LNS16 this register contains 2 16-bit operands.
          -----------------------------------------------------------------

          tc0_src1_rf_port_a_pair00_s(tcu_lane_idx_v) <= regfile_i(harc_EXEC)(tcu_rs1_idx_wire);
          tc0_src2_rf_port_a_pair00_s(tcu_lane_idx_v) <= regfile_i(harc_EXEC)(tcu_rs2_idx_wire);
          tc0_src3_rf_port_a_pair00_s(tcu_lane_idx_v) <= regfile_i(harc_EXEC)(tcu_rd_idx_wire);

          -- Clear pair01 by default.
          -- It is later filled only when extra 32-bit operand/accumulator words are required.
          tc0_src1_rf_port_a_pair01_s(tcu_lane_idx_v) <= (others => '0');
          tc0_src1_rf_port_b_pair01_s(tcu_lane_idx_v) <= (others => '0');

          tc0_src2_rf_port_a_pair01_s(tcu_lane_idx_v) <= (others => '0');
          tc0_src2_rf_port_b_pair01_s(tcu_lane_idx_v) <= (others => '0');

          tc0_src3_rf_port_a_pair01_s(tcu_lane_idx_v) <= (others => '0');
          tc0_src3_rf_port_b_pair01_s(tcu_lane_idx_v) <= (others => '0');

          -----------------------------------------------------------------
          -- Second packed register is used only for 16-bit formats.
          -- For 8-bit formats, force it to zero.
          -----------------------------------------------------------------

          -----------------------------------------------------------------
          -- Second packed register handling.
          --
          -- A/B:
          --   used only for native 16-bit formats, where each fragment
          --   needs two 32-bit registers.
          --
          -- C:
          --   used for native 16-bit formats and for mixed 8_16 formats,
          --   where A/B are 8-bit but C/result are 16-bit.
          -----------------------------------------------------------------

          -- src1 / A second register
          if regs_per_operand_v = 2 then
            if tcu_rs1_idx_wire < 31 then
              tc0_src1_rf_port_b_pair00_s(tcu_lane_idx_v) <= regfile_i(harc_EXEC)(tcu_rs1_idx_wire + 1);
            else
              tc0_src1_rf_port_b_pair00_s(tcu_lane_idx_v) <= (others => '0');
            end if;
          else
            tc0_src1_rf_port_b_pair00_s(tcu_lane_idx_v) <= (others => '0');
          end if;

          -- src2 / B second register
          if regs_per_operand_v = 2 then
            if tcu_rs2_idx_wire < 31 then
              tc0_src2_rf_port_b_pair00_s(tcu_lane_idx_v) <= regfile_i(harc_EXEC)(tcu_rs2_idx_wire + 1);
            else
              tc0_src2_rf_port_b_pair00_s(tcu_lane_idx_v) <= (others => '0');
            end if;
          else
            tc0_src2_rf_port_b_pair00_s(tcu_lane_idx_v) <= (others => '0');
          end if;

          -- src3 / C second register
          if (regs_per_operand_v = 2) or 
              (tcu_funct7_wire = "0001000") or -- INT8_16
              (tcu_funct7_wire = "0001100") then -- FIXED8_16
            if tcu_rd_idx_wire < 31 then
              tc0_src3_rf_port_b_pair00_s(tcu_lane_idx_v) <= regfile_i(harc_EXEC)(tcu_rd_idx_wire + 1);
            else
              tc0_src3_rf_port_b_pair00_s(tcu_lane_idx_v) <= (others => '0');
            end if;
          else
            tc0_src3_rf_port_b_pair00_s(tcu_lane_idx_v) <= (others => '0');
          end if;

          -----------------------------------------------------------------
          -- Extra C accumulator registers for INT16_32 and FIXED16_32 scenarios.
          --
          -- INT16_32 and FIXED16_32 has:
          --   A/B = 16-bit operands -> rs1, rs1+1 and rs2, rs2+1
          --   C   = 32-bit accumulators -> rd, rd+1, rd+2, rd+3
          --
          -- pair00 already contains:
          --   C word0 = rd
          --   C word1 = rd+1
          --
          -- pair01 must contain:
          --   C word2 = rd+2
          --   C word3 = rd+3
          -----------------------------------------------------------------

          if  (tcu_funct7_wire = "0001001") or   -- INT16_32
              (tcu_funct7_wire = "0001101") then -- FIXED16_32
            if tcu_rd_idx_wire <= 28 then
              tc0_src3_rf_port_a_pair01_s(tcu_lane_idx_v) <= regfile_i(harc_EXEC)(tcu_rd_idx_wire + 2);
              tc0_src3_rf_port_b_pair01_s(tcu_lane_idx_v) <= regfile_i(harc_EXEC)(tcu_rd_idx_wire + 3);
            else
              tc0_src3_rf_port_a_pair01_s(tcu_lane_idx_v) <= (others => '0');
              tc0_src3_rf_port_b_pair01_s(tcu_lane_idx_v) <= (others => '0');
            end if;
          end if;

          -----------------------------------------------------------------
          -- Mark this hart as having delivered its HMMA fragment.
          -----------------------------------------------------------------

          tcu_lane_valid_s(harc_EXEC) <= '1';

        else

          -----------------------------------------------------------------
          -- 32-bit operand formats.
          --
          -- For FP32 / POSIT32:
          --   A = rs1, rs1+1, rs1+2, rs1+3
          --   B = rs2, rs2+1, rs2+2, rs2+3
          --   C = rd,  rd+1,  rd+2,  rd+3
          -----------------------------------------------------------------

          if harc_EXEC < 4 then
            tcu_lane_idx_v := harc_EXEC;

          elsif harc_EXEC < 8 then
            tcu_lane_idx_v := harc_EXEC + 4;

          elsif harc_EXEC < 12 then
            tcu_lane_idx_v := harc_EXEC - 4;

          else
            tcu_lane_idx_v := harc_EXEC;

          end if;

          if (tcu_rs1_idx_wire <= 28) and
            (tcu_rs2_idx_wire <= 28) and
            (tcu_rd_idx_wire  <= 28) then

            -- A operand: rs1..rs1+3
            tc0_src1_rf_port_a_pair00_s(tcu_lane_idx_v) <= regfile_i(harc_EXEC)(tcu_rs1_idx_wire);
            tc0_src1_rf_port_b_pair00_s(tcu_lane_idx_v) <= regfile_i(harc_EXEC)(tcu_rs1_idx_wire + 1);
            tc0_src1_rf_port_a_pair01_s(tcu_lane_idx_v) <= regfile_i(harc_EXEC)(tcu_rs1_idx_wire + 2);
            tc0_src1_rf_port_b_pair01_s(tcu_lane_idx_v) <= regfile_i(harc_EXEC)(tcu_rs1_idx_wire + 3);

            -- B operand: rs2..rs2+3
            tc0_src2_rf_port_a_pair00_s(tcu_lane_idx_v) <= regfile_i(harc_EXEC)(tcu_rs2_idx_wire);
            tc0_src2_rf_port_b_pair00_s(tcu_lane_idx_v) <= regfile_i(harc_EXEC)(tcu_rs2_idx_wire + 1);
            tc0_src2_rf_port_a_pair01_s(tcu_lane_idx_v) <= regfile_i(harc_EXEC)(tcu_rs2_idx_wire + 2);
            tc0_src2_rf_port_b_pair01_s(tcu_lane_idx_v) <= regfile_i(harc_EXEC)(tcu_rs2_idx_wire + 3);

            -- C operand: rd..rd+3
            tc0_src3_rf_port_a_pair00_s(tcu_lane_idx_v) <= regfile_i(harc_EXEC)(tcu_rd_idx_wire);
            tc0_src3_rf_port_b_pair00_s(tcu_lane_idx_v) <= regfile_i(harc_EXEC)(tcu_rd_idx_wire + 1);
            tc0_src3_rf_port_a_pair01_s(tcu_lane_idx_v) <= regfile_i(harc_EXEC)(tcu_rd_idx_wire + 2);
            tc0_src3_rf_port_b_pair01_s(tcu_lane_idx_v) <= regfile_i(harc_EXEC)(tcu_rd_idx_wire + 3);

          else

            tc0_src1_rf_port_a_pair00_s(tcu_lane_idx_v) <= (others => '0');
            tc0_src1_rf_port_b_pair00_s(tcu_lane_idx_v) <= (others => '0');
            tc0_src1_rf_port_a_pair01_s(tcu_lane_idx_v) <= (others => '0');
            tc0_src1_rf_port_b_pair01_s(tcu_lane_idx_v) <= (others => '0');

            tc0_src2_rf_port_a_pair00_s(tcu_lane_idx_v) <= (others => '0');
            tc0_src2_rf_port_b_pair00_s(tcu_lane_idx_v) <= (others => '0');
            tc0_src2_rf_port_a_pair01_s(tcu_lane_idx_v) <= (others => '0');
            tc0_src2_rf_port_b_pair01_s(tcu_lane_idx_v) <= (others => '0');

            tc0_src3_rf_port_a_pair00_s(tcu_lane_idx_v) <= (others => '0');
            tc0_src3_rf_port_b_pair00_s(tcu_lane_idx_v) <= (others => '0');
            tc0_src3_rf_port_a_pair01_s(tcu_lane_idx_v) <= (others => '0');
            tc0_src3_rf_port_b_pair01_s(tcu_lane_idx_v) <= (others => '0');

          end if;

          tcu_lane_valid_s(harc_EXEC) <= '1';

        end if;

      else
        -- Valid is a pulse.
        -- The packet fields remain stored from the last TCU instruction.
        tcu_valid_lat <= '0';

      end if;

      -------------------------------------------------------------------------
      -- FSM-controlled release / re-arm
      -------------------------------------------------------------------------

      if tcu_state_s = TCU_RELEASE then
        tcu_lane_valid_s         <= (others => '0');
      end if;

    end if;
  end process;
--**************************************************************************************************

--*********************************B. TCU CONTROLLER FSM PROCESSES*********************************************
  ---------------------------------------------------------------------------
  -- B.1) TCU controller combinational part of FSM
  ---------------------------------------------------------------------------
  TCU_fsm_comb : process(all)
  begin
    tcu_next_state_s <= tcu_state_s;
    
    case tcu_state_s is

      when TCU_IDLE =>
        if tcu_instr_req = '1' then
          tcu_next_state_s <= TCU_COLLECT;
        end if;

      when TCU_COLLECT =>
        if tcu_all_lanes_valid_next_s = '1' then
          tcu_next_state_s <= TCU_START;
        end if;

      when TCU_START =>
        tcu_next_state_s <= TCU_WAIT_DONE;

      when TCU_WAIT_DONE =>
        if tcu_wrapper_done_s = '1' then
          tcu_next_state_s <= TCU_WRITEBACK;
        end if;
      
      when TCU_WRITEBACK =>
        if tcu_wb_hart_s = 0 then
          if (tcu_result_is_8bit_lat = '1'  and tcu_wb_word_s = 0) or
             (tcu_result_is_32bit_lat = '1' and tcu_wb_word_s = 3) or
             ((tcu_result_is_8bit_lat = '0') and (tcu_result_is_32bit_lat = '0') and tcu_wb_word_s = 1) then
            tcu_next_state_s <= TCU_RELEASE;
          end if;
        end if;

      when TCU_RELEASE =>
        tcu_next_state_s <= TCU_IDLE;

      when others =>
        tcu_next_state_s <= TCU_IDLE;

    end case;
  end process;
  ---------------------------------------------------------------------------
  -- B.2) TCU controller output logic
  ---------------------------------------------------------------------------
  TCU_fsm_outputs_comb : process(all)
  begin
    -- defaults
    busy_TCU_s          <= '0';
    core_busy_TCU_s     <= '0';
    tcu_wrapper_start_s <= '0';

    case tcu_state_s is

      when TCU_IDLE =>
        null;

      when TCU_COLLECT =>
        busy_TCU_s <= '1';

        if tcu_all_lanes_valid_next_s = '1' then
          core_busy_TCU_s <= '1';
        end if;

      when TCU_START =>
        busy_TCU_s          <= '1';
        core_busy_TCU_s     <= '1';
        tcu_wrapper_start_s <= '1';

      when TCU_WAIT_DONE =>
        busy_TCU_s      <= '1';
        core_busy_TCU_s <= '1';

      when TCU_WRITEBACK =>
        busy_TCU_s      <= '1';
        core_busy_TCU_s <= '1';

      when TCU_RELEASE =>
        busy_TCU_s      <= '1';
        core_busy_TCU_s <= '1';

      when others =>
        null;

    end case;
  end process;
  ---------------------------------------------------------------------------
  -- B.3) TCU controller state register
  ---------------------------------------------------------------------------
  TCU_state_reg_sync : process(clk_i, rst_ni)
  begin
    if rst_ni = '0' then
      tcu_state_s <= TCU_IDLE;
    elsif rising_edge(clk_i) then
      tcu_state_s <= tcu_next_state_s;
    end if;
  end process;
--**************************************************************************************************************

--*********************C.) TCU RESULT CAPTURE FROM TCU WRAPPER INSTANTIATION PROCESSES****************************
---------------------------------------------------------------------------
  -- C.1) Stable TCU result latch for 8/16/32-bit wrapper outputs
  --
  -- Raw W0/W1 wrapper outputs are result-step-dependent and may not remain
  -- stable after the wrapper finishes. These buffers preserve the complete
  -- TCU result for later writeback.
  TCU_result_latch_sync : process(clk_i, rst_ni)
  begin
    if rst_ni = '0' then

      for i in 0 to 15 loop
        tcu_res_W0_tc0_oct0_16_s(i) <= (others => '0');
        tcu_res_W1_tc0_oct0_16_s(i) <= (others => '0');
        tcu_res_W0_tc0_oct1_16_s(i) <= (others => '0');
        tcu_res_W1_tc0_oct1_16_s(i) <= (others => '0');

        tcu_res_W0_tc0_oct0_8_s(i) <= (others => '0');
        tcu_res_W1_tc0_oct0_8_s(i) <= (others => '0');
        tcu_res_W0_tc0_oct1_8_s(i) <= (others => '0');
        tcu_res_W1_tc0_oct1_8_s(i) <= (others => '0');

        tcu_res_W0_tc0_oct0_32_s(i) <= (others => '0');
        tcu_res_W1_tc0_oct0_32_s(i) <= (others => '0');
        tcu_res_W0_tc0_oct1_32_s(i) <= (others => '0');
        tcu_res_W1_tc0_oct1_32_s(i) <= (others => '0');
      end loop;

    elsif rising_edge(clk_i) then

      if tcu_state_s = TCU_WAIT_DONE and tcu_wrapper_result_valid_s = '1' then

        case tcu_wrapper_result_step_s is

          when "00" =>
            for i in 0 to 3 loop
              tcu_res_W0_tc0_oct0_16_s(i) <= W0_tc0_oct0_16_X3_s(i);
              tcu_res_W1_tc0_oct0_16_s(i) <= W1_tc0_oct0_16_X3_s(i);
              tcu_res_W0_tc0_oct1_16_s(i) <= W0_tc0_oct1_16_X3_s(i);
              tcu_res_W1_tc0_oct1_16_s(i) <= W1_tc0_oct1_16_X3_s(i);

              tcu_res_W0_tc0_oct0_8_s(i) <= W0_tc0_oct0_8_X3_s(i);
              tcu_res_W1_tc0_oct0_8_s(i) <= W1_tc0_oct0_8_X3_s(i);
              tcu_res_W0_tc0_oct1_8_s(i) <= W0_tc0_oct1_8_X3_s(i);
              tcu_res_W1_tc0_oct1_8_s(i) <= W1_tc0_oct1_8_X3_s(i);

              tcu_res_W0_tc0_oct0_32_s(i) <= W0_tc0_oct0_32_X3_s(i);
              tcu_res_W1_tc0_oct0_32_s(i) <= W1_tc0_oct0_32_X3_s(i);
              tcu_res_W0_tc0_oct1_32_s(i) <= W0_tc0_oct1_32_X3_s(i);
              tcu_res_W1_tc0_oct1_32_s(i) <= W1_tc0_oct1_32_X3_s(i);
            end loop;

          when "01" =>
            for i in 4 to 7 loop
              tcu_res_W0_tc0_oct0_16_s(i) <= W0_tc0_oct0_16_X3_s(i);
              tcu_res_W1_tc0_oct0_16_s(i) <= W1_tc0_oct0_16_X3_s(i);
              tcu_res_W0_tc0_oct1_16_s(i) <= W0_tc0_oct1_16_X3_s(i);
              tcu_res_W1_tc0_oct1_16_s(i) <= W1_tc0_oct1_16_X3_s(i);

              tcu_res_W0_tc0_oct0_8_s(i) <= W0_tc0_oct0_8_X3_s(i);
              tcu_res_W1_tc0_oct0_8_s(i) <= W1_tc0_oct0_8_X3_s(i);
              tcu_res_W0_tc0_oct1_8_s(i) <= W0_tc0_oct1_8_X3_s(i);
              tcu_res_W1_tc0_oct1_8_s(i) <= W1_tc0_oct1_8_X3_s(i);

              tcu_res_W0_tc0_oct0_32_s(i) <= W0_tc0_oct0_32_X3_s(i);
              tcu_res_W1_tc0_oct0_32_s(i) <= W1_tc0_oct0_32_X3_s(i);
              tcu_res_W0_tc0_oct1_32_s(i) <= W0_tc0_oct1_32_X3_s(i);
              tcu_res_W1_tc0_oct1_32_s(i) <= W1_tc0_oct1_32_X3_s(i);
            end loop;

          when "10" =>
            for i in 8 to 11 loop
              tcu_res_W0_tc0_oct0_16_s(i) <= W0_tc0_oct0_16_X3_s(i);
              tcu_res_W1_tc0_oct0_16_s(i) <= W1_tc0_oct0_16_X3_s(i);
              tcu_res_W0_tc0_oct1_16_s(i) <= W0_tc0_oct1_16_X3_s(i);
              tcu_res_W1_tc0_oct1_16_s(i) <= W1_tc0_oct1_16_X3_s(i);

              tcu_res_W0_tc0_oct0_8_s(i) <= W0_tc0_oct0_8_X3_s(i);
              tcu_res_W1_tc0_oct0_8_s(i) <= W1_tc0_oct0_8_X3_s(i);
              tcu_res_W0_tc0_oct1_8_s(i) <= W0_tc0_oct1_8_X3_s(i);
              tcu_res_W1_tc0_oct1_8_s(i) <= W1_tc0_oct1_8_X3_s(i);

              tcu_res_W0_tc0_oct0_32_s(i) <= W0_tc0_oct0_32_X3_s(i);
              tcu_res_W1_tc0_oct0_32_s(i) <= W1_tc0_oct0_32_X3_s(i);
              tcu_res_W0_tc0_oct1_32_s(i) <= W0_tc0_oct1_32_X3_s(i);
              tcu_res_W1_tc0_oct1_32_s(i) <= W1_tc0_oct1_32_X3_s(i);
              
            end loop;

          when others =>
            for i in 12 to 15 loop
              tcu_res_W0_tc0_oct0_16_s(i) <= W0_tc0_oct0_16_X3_s(i);
              tcu_res_W1_tc0_oct0_16_s(i) <= W1_tc0_oct0_16_X3_s(i);
              tcu_res_W0_tc0_oct1_16_s(i) <= W0_tc0_oct1_16_X3_s(i);
              tcu_res_W1_tc0_oct1_16_s(i) <= W1_tc0_oct1_16_X3_s(i);

              tcu_res_W0_tc0_oct0_8_s(i) <= W0_tc0_oct0_8_X3_s(i);
              tcu_res_W1_tc0_oct0_8_s(i) <= W1_tc0_oct0_8_X3_s(i);
              tcu_res_W0_tc0_oct1_8_s(i) <= W0_tc0_oct1_8_X3_s(i);
              tcu_res_W1_tc0_oct1_8_s(i) <= W1_tc0_oct1_8_X3_s(i);

              tcu_res_W0_tc0_oct0_32_s(i) <= W0_tc0_oct0_32_X3_s(i);
              tcu_res_W1_tc0_oct0_32_s(i) <= W1_tc0_oct0_32_X3_s(i);
              tcu_res_W0_tc0_oct1_32_s(i) <= W0_tc0_oct1_32_X3_s(i);
              tcu_res_W1_tc0_oct1_32_s(i) <= W1_tc0_oct1_32_X3_s(i);
            end loop;

        end case;

      end if;

    end if;
  end process;
  --*************************************************************************************************************

--******************************************D.) TCU WRITEBACK PROCESSES*******************************************
  TCU_wb_pack_comb : process(all)
  variable idx_v : integer range 0 to 15;
  begin
    tcu_wb_word0_s <= (others => '0');
    tcu_wb_word1_s <= (others => '0');
    tcu_wb_word2_s <= (others => '0');
    tcu_wb_word3_s <= (others => '0');

    -- Compute local base index for this hart.
    if tcu_wb_hart_s < 4 then
      idx_v := tcu_wb_hart_s * 4;
    elsif tcu_wb_hart_s < 8 then
      idx_v := (tcu_wb_hart_s - 4) * 4;
    elsif tcu_wb_hart_s < 12 then
      idx_v := (tcu_wb_hart_s - 8) * 4;
    else
      idx_v := (tcu_wb_hart_s - 12) * 4;
    end if;

    if tcu_result_is_32bit_lat = '1' then
      -- 32-bit result packing: word0, word1, word2, word3
      if tcu_wb_hart_s < 4 then

        tcu_wb_word0_s <= tcu_res_W0_tc0_oct0_32_s(idx_v + 0);
        tcu_wb_word1_s <= tcu_res_W0_tc0_oct0_32_s(idx_v + 1);
        tcu_wb_word2_s <= tcu_res_W0_tc0_oct0_32_s(idx_v + 2);
        tcu_wb_word3_s <= tcu_res_W0_tc0_oct0_32_s(idx_v + 3);

      elsif tcu_wb_hart_s < 8 then

        tcu_wb_word0_s <= tcu_res_W0_tc0_oct1_32_s(idx_v + 0);
        tcu_wb_word1_s <= tcu_res_W0_tc0_oct1_32_s(idx_v + 1);
        tcu_wb_word2_s <= tcu_res_W0_tc0_oct1_32_s(idx_v + 2);
        tcu_wb_word3_s <= tcu_res_W0_tc0_oct1_32_s(idx_v + 3);

      elsif tcu_wb_hart_s < 12 then

        tcu_wb_word0_s <= tcu_res_W1_tc0_oct0_32_s(idx_v + 0);
        tcu_wb_word1_s <= tcu_res_W1_tc0_oct0_32_s(idx_v + 1);
        tcu_wb_word2_s <= tcu_res_W1_tc0_oct0_32_s(idx_v + 2);
        tcu_wb_word3_s <= tcu_res_W1_tc0_oct0_32_s(idx_v + 3);

      else

        tcu_wb_word0_s <= tcu_res_W1_tc0_oct1_32_s(idx_v + 0);
        tcu_wb_word1_s <= tcu_res_W1_tc0_oct1_32_s(idx_v + 1);
        tcu_wb_word2_s <= tcu_res_W1_tc0_oct1_32_s(idx_v + 2);
        tcu_wb_word3_s <= tcu_res_W1_tc0_oct1_32_s(idx_v + 3);

      end if;

    elsif tcu_result_is_8bit_lat = '1' then
      -- 8-bit result packing: only word0 is written back

      if tcu_wb_hart_s < 4 then

        tcu_wb_word0_s <= tcu_res_W0_tc0_oct0_8_s(idx_v + 3) &
                          tcu_res_W0_tc0_oct0_8_s(idx_v + 2) &
                          tcu_res_W0_tc0_oct0_8_s(idx_v + 1) &
                          tcu_res_W0_tc0_oct0_8_s(idx_v + 0);

      elsif tcu_wb_hart_s < 8 then

        tcu_wb_word0_s <= tcu_res_W0_tc0_oct1_8_s(idx_v + 3) &
                          tcu_res_W0_tc0_oct1_8_s(idx_v + 2) &
                          tcu_res_W0_tc0_oct1_8_s(idx_v + 1) &
                          tcu_res_W0_tc0_oct1_8_s(idx_v + 0);

      elsif tcu_wb_hart_s < 12 then

        tcu_wb_word0_s <= tcu_res_W1_tc0_oct0_8_s(idx_v + 3) &
                          tcu_res_W1_tc0_oct0_8_s(idx_v + 2) &
                          tcu_res_W1_tc0_oct0_8_s(idx_v + 1) &
                          tcu_res_W1_tc0_oct0_8_s(idx_v + 0);

      else

        tcu_wb_word0_s <= tcu_res_W1_tc0_oct1_8_s(idx_v + 3) &
                          tcu_res_W1_tc0_oct1_8_s(idx_v + 2) &
                          tcu_res_W1_tc0_oct1_8_s(idx_v + 1) &
                          tcu_res_W1_tc0_oct1_8_s(idx_v + 0);

      end if;

      tcu_wb_word1_s <= (others => '0');

    else

      if tcu_wb_hart_s < 4 then

        tcu_wb_word0_s <= tcu_res_W0_tc0_oct0_16_s(idx_v + 1) &
                          tcu_res_W0_tc0_oct0_16_s(idx_v + 0);

        tcu_wb_word1_s <= tcu_res_W0_tc0_oct0_16_s(idx_v + 3) &
                          tcu_res_W0_tc0_oct0_16_s(idx_v + 2);

      elsif tcu_wb_hart_s < 8 then

        tcu_wb_word0_s <= tcu_res_W0_tc0_oct1_16_s(idx_v + 1) &
                          tcu_res_W0_tc0_oct1_16_s(idx_v + 0);

        tcu_wb_word1_s <= tcu_res_W0_tc0_oct1_16_s(idx_v + 3) &
                          tcu_res_W0_tc0_oct1_16_s(idx_v + 2);

      elsif tcu_wb_hart_s < 12 then

        tcu_wb_word0_s <= tcu_res_W1_tc0_oct0_16_s(idx_v + 1) &
                          tcu_res_W1_tc0_oct0_16_s(idx_v + 0);

        tcu_wb_word1_s <= tcu_res_W1_tc0_oct0_16_s(idx_v + 3) &
                          tcu_res_W1_tc0_oct0_16_s(idx_v + 2);

      else

        tcu_wb_word0_s <= tcu_res_W1_tc0_oct1_16_s(idx_v + 1) &
                          tcu_res_W1_tc0_oct1_16_s(idx_v + 0);

        tcu_wb_word1_s <= tcu_res_W1_tc0_oct1_16_s(idx_v + 3) &
                          tcu_res_W1_tc0_oct1_16_s(idx_v + 2);

      end if;

    end if;
  end process;

  TCU_wb_outputs_comb : process(all)
  variable instr_v  : std_logic_vector(31 downto 0);
  variable rd_v     : integer range 0 to 31;
  variable rd_sum_v : integer;
  begin
    TCU_WB_EN_s         <= '0';
    TCU_WB_s            <= (others => '0');
    instr_word_TCU_WB_s <= (others => '0');
    harc_TCU_WB_s       <= THREAD_POOL_SIZE-1;

    instr_v := tcu_instr_lat;

    ---------------------------------------------------------------------------
    -- Select architectural destination register.
    --
    -- word 0 -> rd
    -- word 1 -> rd+1
    -- word 2 -> rd+2
    -- word 3 -> rd+3
    ---------------------------------------------------------------------------

    rd_sum_v := tcu_rd_idx_lat + tcu_wb_word_s;

    if rd_sum_v <= 31 then
      rd_v := rd_sum_v;
    else
      rd_v := 31;
    end if;

    instr_v(11 downto 7) := std_logic_vector(to_unsigned(rd_v, 5));

    if tcu_state_s = TCU_WRITEBACK then

      instr_word_TCU_WB_s <= instr_v;
      harc_TCU_WB_s       <= tcu_wb_hart_s;

      -------------------------------------------------------------------------
      -- Write-enable policy.
      --
      -- 8-bit:
      --   only word0
      --
      -- 16-bit / mixed 8_16:
      --   word0 and word1
      --
      --  32bit result formats:
      --   word0, word1, word2, word3
      -------------------------------------------------------------------------

      if (tcu_result_is_8bit_lat = '1' and tcu_wb_word_s = 0) or
        (tcu_result_is_32bit_lat = '1') or
        ((tcu_result_is_8bit_lat = '0') and
          (tcu_result_is_32bit_lat = '0') and
          (tcu_wb_word_s <= 1)) then

        TCU_WB_EN_s <= '1';

      end if;

      -------------------------------------------------------------------------
      -- Select result word.
      -------------------------------------------------------------------------

      case tcu_wb_word_s is

        when 0 =>
          TCU_WB_s <= tcu_wb_word0_s;

        when 1 =>
          TCU_WB_s <= tcu_wb_word1_s;

        when 2 =>
          TCU_WB_s <= tcu_wb_word2_s;

        when others =>
          TCU_WB_s <= tcu_wb_word3_s;

      end case;

    end if;
  end process;
  
  TCU_wb_counter_sync : process(clk_i, rst_ni)
  begin
    if rst_ni = '0' then

      tcu_wb_hart_s <= THREAD_POOL_SIZE-1;
      tcu_wb_word_s <= 0;

    elsif rising_edge(clk_i) then

      if tcu_state_s = TCU_WAIT_DONE and tcu_next_state_s = TCU_WRITEBACK then

        -- First writeback cycle starts from last hart, word 0.
        tcu_wb_hart_s <= THREAD_POOL_SIZE-1;
        tcu_wb_word_s <= 0;

      elsif tcu_state_s = TCU_WRITEBACK then

        -----------------------------------------------------------------------
        -- Decide whether the current word is the final word for this hart.
        --
        -- 8-bit formats:
        --   one writeback word: rd
        --
        -- 16-bit / mixed 8_16 formats:
        --   two writeback words: rd, rd+1
        --
        -- 32bit formats:
        --   four writeback words: rd, rd+1, rd+2, rd+3
        -----------------------------------------------------------------------

        if (tcu_result_is_8bit_lat = '1' and tcu_wb_word_s = 0) or
          (tcu_result_is_32bit_lat = '1' and tcu_wb_word_s = 3) or
          ((tcu_result_is_8bit_lat = '0') and
            (tcu_result_is_32bit_lat = '0') and
            (tcu_wb_word_s = 1)) then

          -- Finished this hart. Move to next hart and restart from word 0.
          tcu_wb_word_s <= 0;

          if tcu_wb_hart_s > 0 then
            tcu_wb_hart_s <= tcu_wb_hart_s - 1;
          end if;

        else

          -- Same hart, next result word.
          tcu_wb_word_s <= tcu_wb_word_s + 1;

        end if;

      end if;

    end if;
  end process;
--****************************************************************************************************************
  
  tcu_wrapper_rst_s <= not rst_ni;

  assert THREAD_POOL_SIZE = 16
    report "singleTensorCoreWrapper assumes THREAD_POOL_SIZE = 16"
  severity failure;

  ---------------------------------------------------------------------------
  -- Single tensor-core wrapper instance
  ---------------------------------------------------------------------------
  TCU_WRAPPER_i : entity work.singleTensorCoreWrapper
    generic map (
      REG_W  => 32,
      ELEM_W => 32
    )
    port map (
      clk   => clk_i,
      rst => tcu_wrapper_rst_s,
      start => tcu_wrapper_start_s,

      hmma_step => tcu_wrapper_hmma_step_s,

      widthSel => tcu_wrapper_widthSel_lat,
      typeSel  => tcu_wrapper_typeSel_lat,

      tc0_src1_rf_port_a_pair00 => tc0_src1_rf_port_a_pair00_s,
      tc0_src1_rf_port_b_pair00 => tc0_src1_rf_port_b_pair00_s,
      tc0_src2_rf_port_a_pair00 => tc0_src2_rf_port_a_pair00_s,
      tc0_src2_rf_port_b_pair00 => tc0_src2_rf_port_b_pair00_s,
      tc0_src3_rf_port_a_pair00 => tc0_src3_rf_port_a_pair00_s,
      tc0_src3_rf_port_b_pair00 => tc0_src3_rf_port_b_pair00_s,

      tc0_src1_rf_port_a_pair01 => tc0_src1_rf_port_a_pair01_s,
      tc0_src1_rf_port_b_pair01 => tc0_src1_rf_port_b_pair01_s,
      tc0_src2_rf_port_a_pair01 => tc0_src2_rf_port_a_pair01_s,
      tc0_src2_rf_port_b_pair01 => tc0_src2_rf_port_b_pair01_s,
      tc0_src3_rf_port_a_pair01 => tc0_src3_rf_port_a_pair01_s,
      tc0_src3_rf_port_b_pair01 => tc0_src3_rf_port_b_pair01_s,

      W0_tc0_oct0_8_X3  => W0_tc0_oct0_8_X3_s,
      W1_tc0_oct0_8_X3  => W1_tc0_oct0_8_X3_s,
      W0_tc0_oct0_16_X3 => W0_tc0_oct0_16_X3_s,
      W1_tc0_oct0_16_X3 => W1_tc0_oct0_16_X3_s,
      W0_tc0_oct0_32_X3 => W0_tc0_oct0_32_X3_s,
      W1_tc0_oct0_32_X3 => W1_tc0_oct0_32_X3_s,

      W0_tc0_oct1_8_X3  => W0_tc0_oct1_8_X3_s,
      W1_tc0_oct1_8_X3  => W1_tc0_oct1_8_X3_s,
      W0_tc0_oct1_16_X3 => W0_tc0_oct1_16_X3_s,
      W1_tc0_oct1_16_X3 => W1_tc0_oct1_16_X3_s,
      W0_tc0_oct1_32_X3 => W0_tc0_oct1_32_X3_s,
      W1_tc0_oct1_32_X3 => W1_tc0_oct1_32_X3_s,

      busy      => tcu_wrapper_busy_s,
      done      => tcu_wrapper_done_s,
      step_done => tcu_wrapper_step_done_s,
      load_pair => tcu_wrapper_load_pair_s,

      result_valid => tcu_wrapper_result_valid_s,
      result_step  => tcu_wrapper_result_step_s
      
    );
    
    tcu_wrapper_hmma_step_s <= tcu_funct3_lat(0);

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

  busy_TCU      <= busy_TCU_s;
  core_busy_TCU <= core_busy_TCU_s;

  TCU_WB_EN         <= TCU_WB_EN_s;
  TCU_WB            <= TCU_WB_s;
  instr_word_TCU_WB <= instr_word_TCU_WB_s;
  harc_TCU_WB       <= harc_TCU_WB_s;

  

end architecture;