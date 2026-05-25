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

    -- TCU writeback path, inactive for now
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

  signal tcu_opcode_wire           : std_logic_vector(6 downto 0); --distinguishes operation of the TCU to the other RISCV operations
  signal tcu_rd_idx_wire           : integer range 0 to 31;  -- which register of RFs will contain the result. this index is also used for the third operand of the accumulation (matrix C related value)
  signal tcu_funct3_wire           : std_logic_vector(2 downto 0); -- is it an hmma step 0 or step 1 instruction
  signal tcu_rs1_idx_wire          : integer range 0 to 31; -- which register of the RFs contain first operand (related to matrix A)
  signal tcu_rs2_idx_wire          : integer range 0 to 31; -- which register of the RFs contain second operand (related to matrix B)
  signal tcu_funct7_wire           : std_logic_vector(6 downto 0); --selection of which type of operand and bit width 
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

  ---------------------------------------------------------------------------
  -- FP16 operand-pair collection debug registers
  --
  -- For current FP16 HMMA convention:
  --   A pair comes from rs1 and rs1+1
  --   B pair comes from rs2 and rs2+1
  --   C pair comes from rd  and rd+1
  ---------------------------------------------------------------------------

  signal tcu_a0_lat : std_logic_vector(31 downto 0);
  signal tcu_a1_lat : std_logic_vector(31 downto 0);

  signal tcu_b0_lat : std_logic_vector(31 downto 0);
  signal tcu_b1_lat : std_logic_vector(31 downto 0);

  signal tcu_c0_lat : std_logic_vector(31 downto 0);
  signal tcu_c1_lat : std_logic_vector(31 downto 0);

  ---------------------------------------------------------------------------
  -- Tensor-core input staging arrays, one slot per hart/lane
  --
  -- These are not the final tensor core wrapper yet.
  -- They simply collect and preserve one FP16 HMMA fragment per hart.
  --
  -- src1 = A
  -- src2 = B
  -- src3 = C / accumulator
  --
  -- pair00 is enough for FP16 for now.
  ---------------------------------------------------------------------------

    signal tc0_src1_rf_port_a_pair00_s : array_2d(THREAD_POOL_SIZE-1 downto 0)(31 downto 0);
    signal tc0_src1_rf_port_b_pair00_s : array_2d(THREAD_POOL_SIZE-1 downto 0)(31 downto 0);

    signal tc0_src2_rf_port_a_pair00_s : array_2d(THREAD_POOL_SIZE-1 downto 0)(31 downto 0);
    signal tc0_src2_rf_port_b_pair00_s : array_2d(THREAD_POOL_SIZE-1 downto 0)(31 downto 0);

    signal tc0_src3_rf_port_a_pair00_s : array_2d(THREAD_POOL_SIZE-1 downto 0)(31 downto 0);
    signal tc0_src3_rf_port_b_pair00_s : array_2d(THREAD_POOL_SIZE-1 downto 0)(31 downto 0);

    signal tcu_lane_valid_s      : std_logic_vector(THREAD_POOL_SIZE-1 downto 0);
    signal tcu_all_lanes_valid_s : std_logic;

    constant TCU_ALL_LANES_VALID_C : std_logic_vector(THREAD_POOL_SIZE-1 downto 0) := (others => '1');

    ---------------------------------------------------------------------------
    -- Single tensor-core wrapper interface
    ---------------------------------------------------------------------------

    signal tcu_wrapper_start_s       : std_logic;
    signal tcu_wrapper_start_seen_s  : std_logic;

    signal tcu_wrapper_busy_s        : std_logic;
    signal tcu_wrapper_done_s        : std_logic;
    signal tcu_wrapper_step_done_s   : std_logic;
    signal tcu_wrapper_load_pair_s   : std_logic_vector(1 downto 0);

    signal tc0_src1_rf_port_a_pair00_wrap_s : arraySize16_32;
    signal tc0_src1_rf_port_b_pair00_wrap_s : arraySize16_32;
    signal tc0_src2_rf_port_a_pair00_wrap_s : arraySize16_32;
    signal tc0_src2_rf_port_b_pair00_wrap_s : arraySize16_32;
    signal tc0_src3_rf_port_a_pair00_wrap_s : arraySize16_32;
    signal tc0_src3_rf_port_b_pair00_wrap_s : arraySize16_32;

    signal tc0_src1_rf_port_a_pair01_wrap_s : arraySize16_32;
    signal tc0_src1_rf_port_b_pair01_wrap_s : arraySize16_32;
    signal tc0_src2_rf_port_a_pair01_wrap_s : arraySize16_32;
    signal tc0_src2_rf_port_b_pair01_wrap_s : arraySize16_32;
    signal tc0_src3_rf_port_a_pair01_wrap_s : arraySize16_32;
    signal tc0_src3_rf_port_b_pair01_wrap_s : arraySize16_32;

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

    signal tcu_lane_valid_next_s      : std_logic_vector(THREAD_POOL_SIZE-1 downto 0);
    signal tcu_all_lanes_valid_next_s : std_logic;

    signal tcu_wrapper_result_valid_s : std_logic;
    signal tcu_wrapper_result_step_s  : std_logic_vector(1 downto 0);

    signal tcu_res_W0_tc0_oct0_16_s : arraySize16_16;
    signal tcu_res_W1_tc0_oct0_16_s : arraySize16_16;
    signal tcu_res_W0_tc0_oct1_16_s : arraySize16_16;
    signal tcu_res_W1_tc0_oct1_16_s : arraySize16_16;

    signal tcu_wb_hart_s       : integer range 0 to THREAD_POOL_SIZE-1;
    signal tcu_wb_word_s       : integer range 0 to 1;
    signal tcu_wb_result_idx_s : integer range 0 to 15;

    signal TCU_WB_EN_s         : std_logic;
    signal TCU_WB_s            : std_logic_vector(31 downto 0);
    signal instr_word_TCU_WB_s : std_logic_vector(31 downto 0);
    signal harc_TCU_WB_s       : integer range THREAD_POOL_SIZE-1 downto 0;

    signal tcu_wb_word0_s      : std_logic_vector(31 downto 0);
    signal tcu_wb_word1_s      : std_logic_vector(31 downto 0);

begin

  ---------------------------------------------------------------------------
  -- All-lanes-valid detection
  --
  -- This becomes '1' when all harts have delivered their HMMA fragment from the register files.
  -- Later this can be used to start the tensor core wrapper.
  ---------------------------------------------------------------------------

  tcu_all_lanes_valid_s <= '1' when tcu_lane_valid_s = TCU_ALL_LANES_VALID_C else '0';

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
  -- Predict whether the current HMMA request completes all TCU lanes
  ---------------------------------------------------------------------------

  TCU_valid_next_comb : process(all)
    variable lane_valid_next_v : std_logic_vector(THREAD_POOL_SIZE-1 downto 0);
    begin
      lane_valid_next_v := tcu_lane_valid_s;

      if tcu_instr_req = '1' and
        (tcu_state_s = TCU_IDLE or tcu_state_s = TCU_COLLECT) then
        lane_valid_next_v(harc_EXEC) := '1';
      end if;

      tcu_lane_valid_next_s <= lane_valid_next_v;

      if lane_valid_next_v = TCU_ALL_LANES_VALID_C then
        tcu_all_lanes_valid_next_s <= '1';
      else
        tcu_all_lanes_valid_next_s <= '0';
      end if;
  end process;

  ---------------------------------------------------------------------------
  -- TCU controller combinational part of FSM
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
        if tcu_wb_hart_s = 0 and tcu_wb_word_s = 1 then
          tcu_next_state_s <= TCU_RELEASE;
        end if;

      when TCU_RELEASE =>
        tcu_next_state_s <= TCU_IDLE;

      when others =>
        tcu_next_state_s <= TCU_IDLE;

    end case;
  end process;

    ---------------------------------------------------------------------------
  -- TCU controller output logic
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

  TCU_wb_mapping_comb : process(all)
  begin
    tcu_wb_result_idx_s <= 0;

    if tcu_wb_hart_s < 4 then
      -- harts 0..3 use W0 octect0
      -- hart 0 -> base 0, hart 1 -> base 4, etc.
      tcu_wb_result_idx_s <= tcu_wb_hart_s * 4;

    elsif tcu_wb_hart_s < 8 then
      -- harts 4..7 use W0 octect1
      tcu_wb_result_idx_s <= (tcu_wb_hart_s - 4) * 4;

    elsif tcu_wb_hart_s < 12 then
      -- harts 8..11 use W1 octect0
      tcu_wb_result_idx_s <= (tcu_wb_hart_s - 8) * 4;

    else
      -- harts 12..15 use W1 octect1
      tcu_wb_result_idx_s <= (tcu_wb_hart_s - 12) * 4;

    end if;
  end process;

  TCU_wb_pack_comb : process(all)
  begin
    tcu_wb_word0_s <= (others => '0');
    tcu_wb_word1_s <= (others => '0');

    if tcu_wb_hart_s < 4 then

      -- harts 0..3: W0 octect0
      tcu_wb_word0_s <= tcu_res_W0_tc0_oct0_16_s(tcu_wb_result_idx_s + 1) &
                        tcu_res_W0_tc0_oct0_16_s(tcu_wb_result_idx_s + 0);

      tcu_wb_word1_s <= tcu_res_W0_tc0_oct0_16_s(tcu_wb_result_idx_s + 3) &
                        tcu_res_W0_tc0_oct0_16_s(tcu_wb_result_idx_s + 2);

    elsif tcu_wb_hart_s < 8 then

      -- harts 4..7: W0 octect1
      tcu_wb_word0_s <= tcu_res_W0_tc0_oct1_16_s(tcu_wb_result_idx_s + 1) &
                        tcu_res_W0_tc0_oct1_16_s(tcu_wb_result_idx_s + 0);

      tcu_wb_word1_s <= tcu_res_W0_tc0_oct1_16_s(tcu_wb_result_idx_s + 3) &
                        tcu_res_W0_tc0_oct1_16_s(tcu_wb_result_idx_s + 2);

    elsif tcu_wb_hart_s < 12 then

      -- harts 8..11: W1 octect0
      tcu_wb_word0_s <= tcu_res_W1_tc0_oct0_16_s(tcu_wb_result_idx_s + 1) &
                        tcu_res_W1_tc0_oct0_16_s(tcu_wb_result_idx_s + 0);

      tcu_wb_word1_s <= tcu_res_W1_tc0_oct0_16_s(tcu_wb_result_idx_s + 3) &
                        tcu_res_W1_tc0_oct0_16_s(tcu_wb_result_idx_s + 2);

    else

      -- harts 12..15: W1 octect1
      tcu_wb_word0_s <= tcu_res_W1_tc0_oct1_16_s(tcu_wb_result_idx_s + 1) &
                        tcu_res_W1_tc0_oct1_16_s(tcu_wb_result_idx_s + 0);

      tcu_wb_word1_s <= tcu_res_W1_tc0_oct1_16_s(tcu_wb_result_idx_s + 3) &
                        tcu_res_W1_tc0_oct1_16_s(tcu_wb_result_idx_s + 2);

    end if;
  end process;

  TCU_wb_counter_sync : process(clk_i, rst_ni)
  begin
    if rst_ni = '0' then

      tcu_wb_hart_s <= THREAD_POOL_SIZE-1;
      tcu_wb_word_s <= 0;

    elsif rising_edge(clk_i) then

      if tcu_state_s = TCU_WAIT_DONE and tcu_next_state_s = TCU_WRITEBACK then

        -- First writeback cycle starts from hart F, word 0.
        tcu_wb_hart_s <= THREAD_POOL_SIZE-1;
        tcu_wb_word_s <= 0;

      elsif tcu_state_s = TCU_WRITEBACK then

        if tcu_wb_word_s = 0 then

          -- Same hart, move from rd to rd+1.
          tcu_wb_word_s <= 1;

        else

          -- Finished word 1 for this hart.
          -- Move to next hart and restart from word 0.
          tcu_wb_word_s <= 0;

          if tcu_wb_hart_s > 0 then
            tcu_wb_hart_s <= tcu_wb_hart_s - 1;
          end if;

        end if;

      end if;

    end if;
  end process;
  ---------------------------------------------------------------------------
  -- TCU controller state register
  ---------------------------------------------------------------------------

  TCU_state_reg_sync : process(clk_i, rst_ni)
  begin
    if rst_ni = '0' then
      tcu_state_s <= TCU_IDLE;
    elsif rising_edge(clk_i) then
      tcu_state_s <= tcu_next_state_s;
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

      tcu_a0_lat <= (others => '0');
      tcu_a1_lat <= (others => '0');

      tcu_b0_lat <= (others => '0');
      tcu_b1_lat <= (others => '0');

      tcu_c0_lat <= (others => '0');
      tcu_c1_lat <= (others => '0');

      tcu_opcode_lat           <= (others => '0');
      tcu_rd_idx_lat           <= 0;
      tcu_funct3_lat           <= (others => '0');
      tcu_rs1_idx_lat          <= 0;
      tcu_rs2_idx_lat          <= 0;
      tcu_funct7_lat           <= (others => '0');
      tcu_regs_per_operand_lat <= 1;

      for i in 0 to THREAD_POOL_SIZE-1 loop
        tc0_src1_rf_port_a_pair00_s(i) <= (others => '0');
        tc0_src1_rf_port_b_pair00_s(i) <= (others => '0');

        tc0_src2_rf_port_a_pair00_s(i) <= (others => '0');
        tc0_src2_rf_port_b_pair00_s(i) <= (others => '0');

        tc0_src3_rf_port_a_pair00_s(i) <= (others => '0');
        tc0_src3_rf_port_b_pair00_s(i) <= (others => '0');
      end loop;

      tcu_lane_valid_s <= (others => '0');

      tcu_wrapper_start_seen_s <= '0';
      
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
        tcu_opcode_lat           <= tcu_opcode_wire;
        tcu_rd_idx_lat           <= tcu_rd_idx_wire;
        tcu_funct3_lat           <= tcu_funct3_wire;
        tcu_rs1_idx_lat          <= tcu_rs1_idx_wire;
        tcu_rs2_idx_lat          <= tcu_rs2_idx_wire;
        tcu_funct7_lat           <= tcu_funct7_wire;
        tcu_regs_per_operand_lat <= tcu_regs_per_operand_wire;


        if tcu_regs_per_operand_wire = 2 then

                    -----------------------------------------------------------------
          -- Store this hart's FP16 HMMA fragment into the 16-lane staging
          -- arrays. This prevents one hart's values from being overwritten
          -- when the next hart reaches the TCU branch.
          --
          -- FlexGrip-style convention:
          --   A = src1 = rs1, rs1+1
          --   B = src2 = rs2, rs2+1
          --   C = src3 = rd,  rd+1
          -----------------------------------------------------------------

          if(harc_EXEC < 4) then --wires dedicated to feeding octect0 related buffers in tcu
            tc0_src1_rf_port_a_pair00_s(harc_EXEC) <= regfile_i(harc_EXEC)(tcu_rs1_idx_wire);  --wire connecting buffer storing A related elements
            tc0_src1_rf_port_b_pair00_s(harc_EXEC) <= regfile_i(harc_EXEC)(tcu_rs1_idx_wire +1); -- wire connecting buffer storing A related elements

            tc0_src2_rf_port_a_pair00_s(harc_EXEC) <= regfile_i(harc_EXEC)(tcu_rs2_idx_wire);  --wire connecting buffer storing A related elements
            tc0_src2_rf_port_b_pair00_s(harc_EXEC) <= regfile_i(harc_EXEC)(tcu_rs2_idx_wire +1); -- wire connecting buffer storing A related elements

            tc0_src3_rf_port_a_pair00_s(harc_EXEC) <= regfile_i(harc_EXEC)(tcu_rd_idx_wire);  --wire connecting buffer storing C related elements
            tc0_src3_rf_port_b_pair00_s(harc_EXEC) <= regfile_i(harc_EXEC)(tcu_rd_idx_wire +1); -- wire connecting buffer storing C related elements

          elsif(harc_EXEC < 8) then --wires dedicated to feeding octect1 related buffers in tcu
            tc0_src1_rf_port_a_pair00_s(harc_EXEC+4) <= regfile_i(harc_EXEC)(tcu_rs1_idx_wire); -- wire connecting buffer storing A related elements
            tc0_src1_rf_port_b_pair00_s(harc_EXEC+4) <= regfile_i(harc_EXEC)(tcu_rs1_idx_wire +1); -- wire connecting buffer storing A related elements

            tc0_src2_rf_port_a_pair00_s(harc_EXEC+4) <= regfile_i(harc_EXEC)(tcu_rs2_idx_wire); -- wire connecting buffer storing A related elements
            tc0_src2_rf_port_b_pair00_s(harc_EXEC+4) <= regfile_i(harc_EXEC)(tcu_rs2_idx_wire +1); -- wire connecting buffer storing A related elements

            tc0_src3_rf_port_a_pair00_s(harc_EXEC+4) <= regfile_i(harc_EXEC)(tcu_rd_idx_wire); -- wire connecting buffer storing C related elements
            tc0_src3_rf_port_b_pair00_s(harc_EXEC+4) <= regfile_i(harc_EXEC)(tcu_rd_idx_wire +1); -- wire connecting buffer storing C related elements

          elsif(harc_EXEC <12) then --wires dedicated to feeding octect0 related buffers in tcu
            tc0_src1_rf_port_a_pair00_s(harc_EXEC-4) <= regfile_i(harc_EXEC)(tcu_rs1_idx_wire); -- wire connecting buffer storing A related elements
            tc0_src1_rf_port_b_pair00_s(harc_EXEC-4) <= regfile_i(harc_EXEC)(tcu_rs1_idx_wire +1); -- wire connecting buffer storing A related elements

            tc0_src2_rf_port_a_pair00_s(harc_EXEC-4) <= regfile_i(harc_EXEC)(tcu_rs2_idx_wire); -- wire connecting buffer storing A related elements
            tc0_src2_rf_port_b_pair00_s(harc_EXEC-4) <= regfile_i(harc_EXEC)(tcu_rs2_idx_wire +1); -- wire connecting buffer storing A related elements

            tc0_src3_rf_port_a_pair00_s(harc_EXEC-4) <= regfile_i(harc_EXEC)(tcu_rd_idx_wire); -- wire connecting buffer storing C related elements
            tc0_src3_rf_port_b_pair00_s(harc_EXEC-4) <= regfile_i(harc_EXEC)(tcu_rd_idx_wire +1); -- wire connecting buffer storing C related elements
            
          else --wires dedicated to feeding octect1 related buffers in tcu
            tc0_src1_rf_port_a_pair00_s(harc_EXEC) <= regfile_i(harc_EXEC)(tcu_rs1_idx_wire); -- wire connecting buffer storing A related elements
            tc0_src1_rf_port_b_pair00_s(harc_EXEC) <= regfile_i(harc_EXEC)(tcu_rs1_idx_wire + 1); -- wire connecting buffer storing A related elements

            tc0_src2_rf_port_a_pair00_s(harc_EXEC) <= regfile_i(harc_EXEC)(tcu_rs2_idx_wire); -- wire connecting buffer storing A related elements
            tc0_src2_rf_port_b_pair00_s(harc_EXEC) <= regfile_i(harc_EXEC)(tcu_rs2_idx_wire + 1); -- wire connecting buffer storing A related elements

            tc0_src3_rf_port_a_pair00_s(harc_EXEC) <= regfile_i(harc_EXEC)(tcu_rd_idx_wire); -- wire connecting buffer storing C related elements
            tc0_src3_rf_port_b_pair00_s(harc_EXEC) <= regfile_i(harc_EXEC)(tcu_rd_idx_wire +1); -- wire connecting buffer storing C related elements
            
          end if;

          tcu_lane_valid_s(harc_EXEC) <= '1';


          -- First registers of each pair
          tcu_a0_lat <= regfile_i(harc_EXEC)(tcu_rs1_idx_wire);
          tcu_b0_lat <= regfile_i(harc_EXEC)(tcu_rs2_idx_wire);
          tcu_c0_lat <= regfile_i(harc_EXEC)(tcu_rd_idx_wire);

          -- Second registers of each pair.
          -- Guard against index overflow.
          if tcu_rs1_idx_wire < 31 then
            tcu_a1_lat <= regfile_i(harc_EXEC)(tcu_rs1_idx_wire + 1);
          else
            tcu_a1_lat <= (others => '0');
          end if;

          if tcu_rs2_idx_wire < 31 then
            tcu_b1_lat <= regfile_i(harc_EXEC)(tcu_rs2_idx_wire + 1);
          else
            tcu_b1_lat <= (others => '0');
          end if;

          if tcu_rd_idx_wire < 31 then
            tcu_c1_lat <= regfile_i(harc_EXEC)(tcu_rd_idx_wire + 1);
          else
            tcu_c1_lat <= (others => '0');
          end if;

        else
          -- For now, non-FP16 formats only capture the first encoded registers. i will modify this section later when testing other programs involving operands with bitwidths != 16
          -- FP8/FP32/posit/int handling can be extended later.
          tcu_a0_lat <= regfile_i(harc_EXEC)(tcu_rs1_idx_wire);
          tcu_b0_lat <= regfile_i(harc_EXEC)(tcu_rs2_idx_wire);
          tcu_c0_lat <= regfile_i(harc_EXEC)(tcu_rd_idx_wire);

          tcu_a1_lat <= (others => '0');
          tcu_b1_lat <= (others => '0');
          tcu_c1_lat <= (others => '0');
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
        tcu_wrapper_start_seen_s <= '0';
      end if;

    end if;
  end process;

    ---------------------------------------------------------------------------
  -- Stable TCU FP16 result latch
  --
  -- Raw W0/W1 wrapper outputs are exec_step-dependent and may not remain
  -- stable after the wrapper finishes. These buffers preserve the complete
  -- FP16 result for later writeback.
  ---------------------------------------------------------------------------

  TCU_result_latch_sync : process(clk_i, rst_ni)
  begin
    if rst_ni = '0' then

      for i in 0 to 15 loop
        tcu_res_W0_tc0_oct0_16_s(i) <= (others => '0');
        tcu_res_W1_tc0_oct0_16_s(i) <= (others => '0');
        tcu_res_W0_tc0_oct1_16_s(i) <= (others => '0');
        tcu_res_W1_tc0_oct1_16_s(i) <= (others => '0');
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
            end loop;

          when "01" =>
            for i in 4 to 7 loop
              tcu_res_W0_tc0_oct0_16_s(i) <= W0_tc0_oct0_16_X3_s(i);
              tcu_res_W1_tc0_oct0_16_s(i) <= W1_tc0_oct0_16_X3_s(i);
              tcu_res_W0_tc0_oct1_16_s(i) <= W0_tc0_oct1_16_X3_s(i);
              tcu_res_W1_tc0_oct1_16_s(i) <= W1_tc0_oct1_16_X3_s(i);
            end loop;

          when "10" =>
            for i in 8 to 11 loop
              tcu_res_W0_tc0_oct0_16_s(i) <= W0_tc0_oct0_16_X3_s(i);
              tcu_res_W1_tc0_oct0_16_s(i) <= W1_tc0_oct0_16_X3_s(i);
              tcu_res_W0_tc0_oct1_16_s(i) <= W0_tc0_oct1_16_X3_s(i);
              tcu_res_W1_tc0_oct1_16_s(i) <= W1_tc0_oct1_16_X3_s(i);
            end loop;

          when others =>
            for i in 12 to 15 loop
              tcu_res_W0_tc0_oct0_16_s(i) <= W0_tc0_oct0_16_X3_s(i);
              tcu_res_W1_tc0_oct0_16_s(i) <= W1_tc0_oct0_16_X3_s(i);
              tcu_res_W0_tc0_oct1_16_s(i) <= W0_tc0_oct1_16_X3_s(i);
              tcu_res_W1_tc0_oct1_16_s(i) <= W1_tc0_oct1_16_X3_s(i);
            end loop;

        end case;

      end if;

    end if;
  end process;

  TCU_wb_outputs_comb : process(all)
  variable instr_v : std_logic_vector(31 downto 0);
  variable rd_v    : integer range 0 to 31;
  begin
    TCU_WB_EN_s         <= '0';
    TCU_WB_s            <= (others => '0');
    instr_word_TCU_WB_s <= (others => '0');
    harc_TCU_WB_s       <= THREAD_POOL_SIZE-1;

    instr_v := tcu_instr_lat;

    if tcu_wb_word_s = 0 then
      rd_v := tcu_rd_idx_lat;
    else
      if tcu_rd_idx_lat < 31 then
        rd_v := tcu_rd_idx_lat + 1;
      else
        rd_v := 31;
      end if;
    end if;

    instr_v(11 downto 7) := std_logic_vector(to_unsigned(rd_v, 5));

    if tcu_state_s = TCU_WRITEBACK then
      TCU_WB_EN_s         <= '1';
      instr_word_TCU_WB_s <= instr_v;
      harc_TCU_WB_s       <= tcu_wb_hart_s;

      if tcu_wb_word_s = 0 then
        TCU_WB_s <= tcu_wb_word0_s;
      else
        TCU_WB_s <= tcu_wb_word1_s;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Convert Klessydra per-hart staging arrays to wrapper input arrays.
  -- The wrapper is fixed to 16 lanes, so this assumes THREAD_POOL_SIZE = 16.  -- right now implemented assuming the study of fp16 operands.
  ---------------------------------------------------------------------------

  gen_tcu_wrapper_inputs : for i in 0 to 15 generate
  begin

    tc0_src1_rf_port_a_pair00_wrap_s(i) <= tc0_src1_rf_port_a_pair00_s(i);
    tc0_src1_rf_port_b_pair00_wrap_s(i) <= tc0_src1_rf_port_b_pair00_s(i);

    tc0_src2_rf_port_a_pair00_wrap_s(i) <= tc0_src2_rf_port_a_pair00_s(i);
    tc0_src2_rf_port_b_pair00_wrap_s(i) <= tc0_src2_rf_port_b_pair00_s(i);

    tc0_src3_rf_port_a_pair00_wrap_s(i) <= tc0_src3_rf_port_a_pair00_s(i);
    tc0_src3_rf_port_b_pair00_wrap_s(i) <= tc0_src3_rf_port_b_pair00_s(i);

    -- pair01 is unused for the FP16 first test
    tc0_src1_rf_port_a_pair01_wrap_s(i) <= (others => '0');
    tc0_src1_rf_port_b_pair01_wrap_s(i) <= (others => '0');

    tc0_src2_rf_port_a_pair01_wrap_s(i) <= (others => '0');
    tc0_src2_rf_port_b_pair01_wrap_s(i) <= (others => '0');

    tc0_src3_rf_port_a_pair01_wrap_s(i) <= (others => '0');
    tc0_src3_rf_port_b_pair01_wrap_s(i) <= (others => '0');

  end generate;

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

      hmma_step => '0',

      widthSel => "01",
      typeSel  => "000",

      tc0_src1_rf_port_a_pair00 => tc0_src1_rf_port_a_pair00_wrap_s,
      tc0_src1_rf_port_b_pair00 => tc0_src1_rf_port_b_pair00_wrap_s,
      tc0_src2_rf_port_a_pair00 => tc0_src2_rf_port_a_pair00_wrap_s,
      tc0_src2_rf_port_b_pair00 => tc0_src2_rf_port_b_pair00_wrap_s,
      tc0_src3_rf_port_a_pair00 => tc0_src3_rf_port_a_pair00_wrap_s,
      tc0_src3_rf_port_b_pair00 => tc0_src3_rf_port_b_pair00_wrap_s,

      tc0_src1_rf_port_a_pair01 => tc0_src1_rf_port_a_pair01_wrap_s,
      tc0_src1_rf_port_b_pair01 => tc0_src1_rf_port_b_pair01_wrap_s,
      tc0_src2_rf_port_a_pair01 => tc0_src2_rf_port_a_pair01_wrap_s,
      tc0_src2_rf_port_b_pair01 => tc0_src2_rf_port_b_pair01_wrap_s,
      tc0_src3_rf_port_a_pair01 => tc0_src3_rf_port_a_pair01_wrap_s,
      tc0_src3_rf_port_b_pair01 => tc0_src3_rf_port_b_pair01_wrap_s,

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