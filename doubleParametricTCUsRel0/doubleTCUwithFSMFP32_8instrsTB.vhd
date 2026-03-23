library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.dpuArray_package.all;

entity doubleTensorCorewithFSMFP32_4setsOfstep01_tb is
end doubleTensorCorewithFSMFP32_4setsOfstep01_tb; 

-- Testbench for FP32 HMMA execution on dualTensorCoreWrapper.
-- It verifies 4 chained sets of HMMA step0/step1 operations executed in parallel
-- across 2 tensor cores = 4 octects total (32 lanes total).
--
-- Set 0 uses external C inputs.
-- Sets 1..3 reuse previously computed results as chained accumulators.
--
-- FP32 loading convention:
-- each 4x4 submatrix is loaded in 2 cycles:
--   pair00 -> columns 0,1
--   pair01 -> columns 2,3
--
-- step0 loads:
--   A(pair00,pair01), B(pair00,pair01), C0(pair00,pair01)
--
-- step1 loads:
--   only C1(pair00,pair01)

architecture sim of doubleTensorCorewithFSMFP32_4setsOfstep01_tb is

    --dut generics
    constant REG_W  : integer := 32;
    constant ELEM_W : integer := 32;
    
    --clock/config
    constant CLK_PERIOD : time := 10 ns;
    constant WIDTH_FP32 : std_logic_vector(1 downto 0) := "10";
    constant TYPE_FP    : std_logic_vector(2 downto 0) := "000";
    
    --dut signals
    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1';
    signal start      : std_logic := '0';
    signal hmma_step  : std_logic := '0';  -- 0=HMMA step0, 1=HMMA step1
    
    signal widthSel : std_logic_vector(1 downto 0) := (others => '0');
    signal typeSel  : std_logic_vector(2 downto 0) := (others => '0');
    
    --RFs inputs to tc0
    signal rf0_rd_data_port_a : arraySize16_32;
    signal rf0_rd_data_port_b : arraySize16_32;
    
    --RFs inputs to tc1
    signal rf1_rd_data_port_a : arraySize16_32;
    signal rf1_rd_data_port_b : arraySize16_32;
    
    --outputs tc0
    --octect0 signals for its outputs
    signal W0_tc0_oct0_8_X3  : arraySize4_8;
    signal W1_tc0_oct0_8_X3  : arraySize4_8;
    signal W0_tc0_oct0_16_X3 : arraySize4_16;
    signal W1_tc0_oct0_16_X3 : arraySize4_16;
    signal W0_tc0_oct0_32_X3 : arraySize4_32;
    signal W1_tc0_oct0_32_X3 : arraySize4_32;
    --octect1 signals for its outputs
    signal W0_tc0_oct1_8_X3  : arraySize4_8;
    signal W1_tc0_oct1_8_X3  : arraySize4_8;
    signal W0_tc0_oct1_16_X3 : arraySize4_16;
    signal W1_tc0_oct1_16_X3 : arraySize4_16;
    signal W0_tc0_oct1_32_X3 : arraySize4_32;
    signal W1_tc0_oct1_32_X3 : arraySize4_32;
    
    --outputs tc1
    --octect0 signals for its outputs (octect 0 of tc1 corresponds to octect 2 from global perspective)
    signal W0_tc1_oct0_8_X3  : arraySize4_8;
    signal W1_tc1_oct0_8_X3  : arraySize4_8;
    signal W0_tc1_oct0_16_X3 : arraySize4_16;
    signal W1_tc1_oct0_16_X3 : arraySize4_16;
    signal W0_tc1_oct0_32_X3 : arraySize4_32;
    signal W1_tc1_oct0_32_X3 : arraySize4_32;
    --octect1 signals for its outputs (octect 1 of tc1 corresponds to octect 3 in a global perspective)
    signal W0_tc1_oct1_8_X3  : arraySize4_8;
    signal W1_tc1_oct1_8_X3  : arraySize4_8;
    signal W0_tc1_oct1_16_X3 : arraySize4_16;
    signal W1_tc1_oct1_16_X3 : arraySize4_16;
    signal W0_tc1_oct1_32_X3 : arraySize4_32;
    signal W1_tc1_oct1_32_X3 : arraySize4_32;
    
    signal busy      : std_logic;
    signal done      : std_logic;
    signal step_done : std_logic;
    
    --tb-only types
    type matrix4x4_fp32_t is array (0 to 3, 0 to 3) of std_logic_vector(31 downto 0);
    type lane_block16_t     is array (0 to 15) of std_logic_vector(31 downto 0);
    
    --related input and output files of tb
    file tb_file : text open read_mode is
        "C:/Users/giovi/OneDrive/Desktop/Magistrale/Tesi/doubleParametricTCUsRel0/doubleParametricTCUsRelatedScripts/4SetsOfHMMAstep0step1/fp32related/hmma_8instr_dualTC_4octects_fp32_single_experiment_tb_input.txt";

    file tb_out_file : text open write_mode is
        "C:/Users/giovi/OneDrive/Desktop/Magistrale/Tesi/doubleParametricTCUsRel0/doubleParametricTCUsRelatedScripts/4SetsOfHMMAstep0step1/fp32related/hmma_8instr_dualTC_4octects_tb_output_ctrl_fp32.txt";
    
    --helper procedures

--1
    procedure clear_wrapper_rf_ports(
        signal tc0_port_a : out arraySize16_32;
        signal tc0_port_b : out arraySize16_32;
        signal tc1_port_a : out arraySize16_32;
        signal tc1_port_b : out arraySize16_32
    ) is
    begin
        tc0_port_a <= (others => (others => '0'));
        tc0_port_b <= (others => (others => '0'));
        tc1_port_a <= (others => (others => '0'));
        tc1_port_b <= (others => (others => '0'));
    end procedure;
    
--2
    procedure read_next_port_pair(
        file f : text;
        variable val_a : out std_logic_vector(31 downto 0);
        variable val_b : out std_logic_vector(31 downto 0);
        variable ok    : out boolean
    ) is
        variable L     : line;
        variable tmp_a : std_logic_vector(31 downto 0);
        variable tmp_b : std_logic_vector(31 downto 0);
    begin
        ok := false;

        while not endfile(f) loop
            readline(f, L);

            if L = null then
                null;
            elsif L.all'length = 0 then
                null;
            elsif L.all(1) = '#' then
                null;
            else
                hread(L, tmp_a);
                hread(L, tmp_b);
                val_a := tmp_a;
                val_b := tmp_b;
                ok := true;
                return;
            end if;
        end loop;
    end procedure;
    
--3
    procedure read_16_lanes_into_block(
        file f : text;
        variable block_a : out lane_block16_t;
        variable block_b : out lane_block16_t;
        variable success : out boolean
    ) is
        variable v_a : std_logic_vector(31 downto 0);
        variable v_b : std_logic_vector(31 downto 0);
        variable ok  : boolean;
    begin
        success := false;

        for i in 0 to 15 loop
            read_next_port_pair(f, v_a, v_b, ok);

            if not ok then
                if i = 0 then
                    return;
                else
                    assert false
                        report "Unexpected EOF while reading 16-lane block from stimulus file"
                        severity failure;
                end if;
            end if;

            block_a(i) := v_a;
            block_b(i) := v_b;
        end loop;

        success := true;
    end procedure;

--4
    procedure drive_wrapper_blocks_to_rf_ports(
        signal tc0_port_a : out arraySize16_32;
        signal tc0_port_b : out arraySize16_32;
        signal tc1_port_a : out arraySize16_32;
        signal tc1_port_b : out arraySize16_32;
        variable tc0_block_a : in lane_block16_t;
        variable tc0_block_b : in lane_block16_t;
        variable tc1_block_a : in lane_block16_t;
        variable tc1_block_b : in lane_block16_t
    ) is
    begin
        for i in 0 to 15 loop
            tc0_port_a(i) <= tc0_block_a(i);
            tc0_port_b(i) <= tc0_block_b(i);
            tc1_port_a(i) <= tc1_block_a(i);
            tc1_port_b(i) <= tc1_block_b(i);
        end loop;
    end procedure;

--5
    procedure write_matrix4x4_hex(
        file f : text;
        constant M : in matrix4x4_fp32_t
    ) is
        variable L : line;
    begin
        for r in 0 to 3 loop
            L := null;
            for c in 0 to 3 loop
                hwrite(L, M(r, c));
                if c < 3 then
                    write(L, string'(" "));
                end if;
            end loop;
            writeline(f, L);
        end loop;
    end procedure;
    
--6
    procedure clear_matrix4x4(
        variable M : out matrix4x4_fp32_t
    ) is
    begin
        for r in 0 to 3 loop
            for c in 0 to 3 loop
                M(r,c) := (others => '0');
            end loop;
        end loop;
    end procedure; 
    
--7
    procedure clear_lane_block16(
        variable block_a : out lane_block16_t ;
        variable block_b : out lane_block16_t 
    ) is
    begin
        for i in 0 to 15 loop
            block_a(i) := (others => '0');
            block_b(i) := (others => '0');
        end loop;
    end procedure;
    
--8
    procedure matrix4x4_to_lane_block16(
        constant M      : in matrix4x4_fp32_t;
        constant base_lane : in integer;  -- the top threadgroup uses base_lane = 0, for bottom threadgroup use base_lane =4 inside the local 8lane block
                                          -- rapresentation because your lane block is indexed 0 to 7.
        variable pair00_a : inout lane_block16_t;
        variable pair00_b : inout lane_block16_t;
        variable pair01_a : inout lane_block16_t;
        variable pair01_b : inout lane_block16_t
    ) is
    begin
        for r in 0 to 3 loop
            pair00_a(base_lane + r) := M(r,0) ;
            pair00_b(base_lane + r) := M(r,1) ;
            
            pair01_a(base_lane + r) := M(r,2) ;
            pair01_b(base_lane + r) := M(r,3) ;
        end loop;
    end procedure;
    
--9
    procedure build_accumulator_blocks_from_previous_results(
    --related to octect 0 outputs
        constant prev_D00 : in matrix4x4_fp32_t ;
        constant prev_D10 : in matrix4x4_fp32_t ;
        constant prev_D01 : in matrix4x4_fp32_t ;
        constant prev_D11 : in matrix4x4_fp32_t ;
    --related to octect 1 outputs
        constant prev_D20 : in matrix4x4_fp32_t ;
        constant prev_D30 : in matrix4x4_fp32_t ;
        constant prev_D21 : in matrix4x4_fp32_t ;
        constant prev_D31 : in matrix4x4_fp32_t ;
        
        variable C0_pair00_a : out lane_block16_t ;
        variable C0_pair00_b : out lane_block16_t ;
        variable C0_pair01_a : out lane_block16_t ;
        variable C0_pair01_b : out lane_block16_t ;
        
        variable C1_pair00_a : out lane_block16_t ;
        variable C1_pair00_b : out lane_block16_t ;
        variable C1_pair01_a : out lane_block16_t ;
        variable C1_pair01_b : out lane_block16_t 
    ) is 
        variable tmp_C0_pair00_a : lane_block16_t;
        variable tmp_C0_pair00_b : lane_block16_t;
        variable tmp_C0_pair01_a : lane_block16_t;
        variable tmp_C0_pair01_b : lane_block16_t;
        
        variable tmp_C1_pair00_a : lane_block16_t;
        variable tmp_C1_pair00_b : lane_block16_t;
        variable tmp_C1_pair01_a : lane_block16_t;
        variable tmp_C1_pair01_b : lane_block16_t;
    begin 
        clear_lane_block16(tmp_C0_pair00_a, tmp_C0_pair00_b);
        clear_lane_block16(tmp_C0_pair01_a, tmp_C0_pair01_b);
        clear_lane_block16(tmp_C1_pair00_a, tmp_C1_pair00_b);
        clear_lane_block16(tmp_C1_pair01_a, tmp_C1_pair01_b);
        
        --step0 accumulators: 
        
        --octect 0: lanes 0..3 top, 4..7 bottom 
        matrix4x4_to_lane_block16(prev_D00, 0, tmp_C0_pair00_a, tmp_C0_pair00_b, tmp_C0_pair01_a, tmp_C0_pair01_b);
        matrix4x4_to_lane_block16(prev_D10, 4, tmp_C0_pair00_a, tmp_C0_pair00_b, tmp_C0_pair01_a, tmp_C0_pair01_b);
        
        --octect 1: lanes 8..11 top, 12..15 bottom 
        matrix4x4_to_lane_block16(prev_D20, 8,  tmp_C0_pair00_a, tmp_C0_pair00_b, tmp_C0_pair01_a, tmp_C0_pair01_b);
        matrix4x4_to_lane_block16(prev_D30, 12, tmp_C0_pair00_a, tmp_C0_pair00_b, tmp_C0_pair01_a, tmp_C0_pair01_b);
        
        --step1 accumulators: 
        matrix4x4_to_lane_block16(prev_D01, 0, tmp_C1_pair00_a, tmp_C1_pair00_b, tmp_C1_pair01_a, tmp_C1_pair01_b);
        matrix4x4_to_lane_block16(prev_D11, 4, tmp_C1_pair00_a, tmp_C1_pair00_b, tmp_C1_pair01_a, tmp_C1_pair01_b);
        
        matrix4x4_to_lane_block16(prev_D21, 8, tmp_C1_pair00_a, tmp_C1_pair00_b, tmp_C1_pair01_a, tmp_C1_pair01_b);
        matrix4x4_to_lane_block16(prev_D31, 12, tmp_C1_pair00_a, tmp_C1_pair00_b, tmp_C1_pair01_a, tmp_C1_pair01_b);
        
        C0_pair00_a := tmp_C0_pair00_a ;
        C0_pair00_b := tmp_C0_pair00_b ;
        C0_pair01_a := tmp_C0_pair01_a ;
        C0_pair01_b := tmp_C0_pair01_b ;
        
        C1_pair00_a := tmp_C1_pair00_a ;
        C1_pair00_b := tmp_C1_pair00_b ;
        C1_pair01_a := tmp_C1_pair01_a ;
        C1_pair01_b := tmp_C1_pair01_b ;
        
    end procedure;
    
--10
    procedure capture_step0_outputs(
        --TC0
        signal W0_tc0_oct0_32_X3 : in arraySize4_32;
        signal W1_tc0_oct0_32_X3 : in arraySize4_32;
        signal W0_tc0_oct1_32_X3 : in arraySize4_32;
        signal W1_tc0_oct1_32_X3 : in arraySize4_32;
        --TC1
        signal W0_tc1_oct0_32_X3 : in arraySize4_32;
        signal W1_tc1_oct0_32_X3 : in arraySize4_32;
        signal W0_tc1_oct1_32_X3 : in arraySize4_32;
        signal W1_tc1_oct1_32_X3 : in arraySize4_32;
        
        variable D00    : out matrix4x4_fp32_t;
        variable D10    : out matrix4x4_fp32_t;
        variable D20    : out matrix4x4_fp32_t;
        variable D30    : out matrix4x4_fp32_t;
        
        variable D02    : out matrix4x4_fp32_t;
        variable D12    : out matrix4x4_fp32_t;
        variable D22    : out matrix4x4_fp32_t;
        variable D32    : out matrix4x4_fp32_t
    ) is
    begin
        for r in 0 to 3 loop
            wait until falling_edge(clk);
            for c in 0 to 3 loop
                D00(r, c) := W0_tc0_oct0_32_X3(c);
                D10(r, c) := W1_tc0_oct0_32_X3(c);
                D20(r, c) := W0_tc0_oct1_32_X3(c);
                D30(r, c) := W1_tc0_oct1_32_X3(c);
                
                D02(r, c) := W0_tc1_oct0_32_X3(c);
                D12(r, c) := W1_tc1_oct0_32_X3(c);
                D22(r, c) := W0_tc1_oct1_32_X3(c);
                D32(r, c) := W1_tc1_oct1_32_X3(c);
            end loop;
        end loop;
    end procedure;
    
--11
    procedure capture_step1_outputs(
    --TC0
        signal W0_tc0_oct0_32_X3 : in arraySize4_32;
        signal W1_tc0_oct0_32_X3 : in arraySize4_32;
        signal W0_tc0_oct1_32_X3 : in arraySize4_32;
        signal W1_tc0_oct1_32_X3 : in arraySize4_32;
    --TC1
        signal W0_tc1_oct0_32_X3 : in arraySize4_32;
        signal W1_tc1_oct0_32_X3 : in arraySize4_32;
        signal W0_tc1_oct1_32_X3 : in arraySize4_32;
        signal W1_tc1_oct1_32_X3 : in arraySize4_32;
        
        variable D01 : out matrix4x4_fp32_t;
        variable D11 : out matrix4x4_fp32_t;
        variable D21 : out matrix4x4_fp32_t;
        variable D31 : out matrix4x4_fp32_t;
        
        variable D03 : out matrix4x4_fp32_t;
        variable D13 : out matrix4x4_fp32_t;
        variable D23 : out matrix4x4_fp32_t;
        variable D33 : out matrix4x4_fp32_t
    ) is
    begin
        for r in 0 to 3 loop
            wait until falling_edge(clk);
            for c in 0 to 3 loop
                D01(r, c) := W0_tc0_oct0_32_X3(c);
                D11(r, c) := W1_tc0_oct0_32_X3(c);
                D21(r, c) := W0_tc0_oct1_32_X3(c);
                D31(r, c) := W1_tc0_oct1_32_X3(c);
                
                D03(r, c) := W0_tc1_oct0_32_X3(c);
                D13(r, c) := W1_tc1_oct0_32_X3(c);
                D23(r, c) := W0_tc1_oct1_32_X3(c);
                D33(r, c) := W1_tc1_oct1_32_X3(c);
            end loop;
        end loop;
    end procedure;
    
--12
     procedure write_set_result(
        file f : text;
        constant set_idx    : in integer;
        
        --TC0  
        constant D00_step0  : in matrix4x4_fp32_t;
        constant D10_step0  : in matrix4x4_fp32_t;
        constant D01_step1  : in matrix4x4_fp32_t;
        constant D11_step1  : in matrix4x4_fp32_t;
        constant D20_step0  : in matrix4x4_fp32_t;
        constant D30_step0  : in matrix4x4_fp32_t;
        constant D21_step1  : in matrix4x4_fp32_t;
        constant D31_step1  : in matrix4x4_fp32_t;
        
        --TC1
        constant D02_step0  : in matrix4x4_fp32_t;
        constant D12_step0  : in matrix4x4_fp32_t;
        constant D03_step1  : in matrix4x4_fp32_t;
        constant D13_step1  : in matrix4x4_fp32_t;
        constant D22_step0  : in matrix4x4_fp32_t;
        constant D32_step0  : in matrix4x4_fp32_t;
        constant D23_step1  : in matrix4x4_fp32_t;
        constant D33_step1  : in matrix4x4_fp32_t
    ) is
        variable L : line;
    begin
        L := null;
        write(L, string'("#SET "));
        write(L, set_idx);
        write(L, string'(" results"));
        writeline(f, L);

        L := null; write(L, string'("#STEP0_D00")); writeline(f, L); write_matrix4x4_hex(f, D00_step0);
        L := null; write(L, string'("#STEP0_D10")); writeline(f, L); write_matrix4x4_hex(f, D10_step0);
        L := null; write(L, string'("#STEP1_D01")); writeline(f, L); write_matrix4x4_hex(f, D01_step1);
        L := null; write(L, string'("#STEP1_D11")); writeline(f, L); write_matrix4x4_hex(f, D11_step1);
        L := null; write(L, string'("#STEP0_D20")); writeline(f, L); write_matrix4x4_hex(f, D20_step0);
        L := null; write(L, string'("#STEP0_D30")); writeline(f, L); write_matrix4x4_hex(f, D30_step0);
        L := null; write(L, string'("#STEP1_D21")); writeline(f, L); write_matrix4x4_hex(f, D21_step1);
        L := null; write(L, string'("#STEP1_D31")); writeline(f, L); write_matrix4x4_hex(f, D31_step1);
        
        L := null; write(L, string'("#STEP0_D02")); writeline(f, L); write_matrix4x4_hex(f, D02_step0);
        L := null; write(L, string'("#STEP0_D12")); writeline(f, L); write_matrix4x4_hex(f, D12_step0);
        L := null; write(L, string'("#STEP1_D03")); writeline(f, L); write_matrix4x4_hex(f, D03_step1);
        L := null; write(L, string'("#STEP1_D13")); writeline(f, L); write_matrix4x4_hex(f, D13_step1);
        L := null; write(L, string'("#STEP0_D22")); writeline(f, L); write_matrix4x4_hex(f, D22_step0);
        L := null; write(L, string'("#STEP0_D32")); writeline(f, L); write_matrix4x4_hex(f, D32_step0);
        L := null; write(L, string'("#STEP1_D23")); writeline(f, L); write_matrix4x4_hex(f, D23_step1);
        L := null; write(L, string'("#STEP1_D33")); writeline(f, L); write_matrix4x4_hex(f, D33_step1);

        L := null;
        writeline(f, L);
    end procedure;
    
--13
    procedure write_final_16x16_result(
    file f : text;
    constant D00 : in matrix4x4_fp32_t;
    constant D10 : in matrix4x4_fp32_t;
    constant D20 : in matrix4x4_fp32_t;
    constant D30 : in matrix4x4_fp32_t;
    
    constant D01 : in matrix4x4_fp32_t;
    constant D11 : in matrix4x4_fp32_t;
    constant D21 : in matrix4x4_fp32_t;
    constant D31 : in matrix4x4_fp32_t;
    
    constant D02 : in matrix4x4_fp32_t;
    constant D12 : in matrix4x4_fp32_t;
    constant D22 : in matrix4x4_fp32_t;
    constant D32 : in matrix4x4_fp32_t;
    
    constant D03 : in matrix4x4_fp32_t;
    constant D13 : in matrix4x4_fp32_t;
    constant D23 : in matrix4x4_fp32_t;
    constant D33 : in matrix4x4_fp32_t
    ) is
    variable L : line;
    begin
        L := null;
        write(L, string'("#FINAL_16x16_RESULT"));
        writeline(f, L);

        -- rows 0..3 = D00 | D01
        for r in 0 to 3 loop
            L := null;
            hwrite(L, D00(r,0)); write(L, string'(" "));
            hwrite(L, D00(r,1)); write(L, string'(" "));
            hwrite(L, D00(r,2)); write(L, string'(" "));
            hwrite(L, D00(r,3)); write(L, string'(" "));
            hwrite(L, D01(r,0)); write(L, string'(" "));
            hwrite(L, D01(r,1)); write(L, string'(" "));
            hwrite(L, D01(r,2)); write(L, string'(" "));
            hwrite(L, D01(r,3)); write(L, string'(" "));
            hwrite(L, D02(r,0)); write(L, string'(" "));
            hwrite(L, D02(r,1)); write(L, string'(" "));
            hwrite(L, D02(r,2)); write(L, string'(" "));
            hwrite(L, D02(r,3)); write(L, string'(" "));
            hwrite(L, D03(r,0)); write(L, string'(" "));
            hwrite(L, D03(r,1)); write(L, string'(" "));
            hwrite(L, D03(r,2)); write(L, string'(" "));
            hwrite(L, D03(r,3));
            writeline(f, L);
        end loop;

        -- rows 4..7 = D10 | D11
        for r in 0 to 3 loop
            L := null;
            hwrite(L, D10(r,0)); write(L, string'(" "));
            hwrite(L, D10(r,1)); write(L, string'(" "));
            hwrite(L, D10(r,2)); write(L, string'(" "));
            hwrite(L, D10(r,3)); write(L, string'(" "));
            hwrite(L, D11(r,0)); write(L, string'(" "));
            hwrite(L, D11(r,1)); write(L, string'(" "));
            hwrite(L, D11(r,2)); write(L, string'(" "));
            hwrite(L, D11(r,3)); write(L, string'(" "));
            hwrite(L, D12(r,0)); write(L, string'(" "));
            hwrite(L, D12(r,1)); write(L, string'(" "));
            hwrite(L, D12(r,2)); write(L, string'(" "));
            hwrite(L, D12(r,3)); write(L, string'(" "));
            hwrite(L, D13(r,0)); write(L, string'(" "));
            hwrite(L, D13(r,1)); write(L, string'(" "));
            hwrite(L, D13(r,2)); write(L, string'(" "));
            hwrite(L, D13(r,3));
            writeline(f, L);
        end loop;
    
        -- rows 8..11 = D20 | D21
        for r in 0 to 3 loop
            L := null;
            hwrite(L, D20(r,0)); write(L, string'(" "));
            hwrite(L, D20(r,1)); write(L, string'(" "));
            hwrite(L, D20(r,2)); write(L, string'(" "));
            hwrite(L, D20(r,3)); write(L, string'(" "));
            hwrite(L, D21(r,0)); write(L, string'(" "));
            hwrite(L, D21(r,1)); write(L, string'(" "));
            hwrite(L, D21(r,2)); write(L, string'(" "));
            hwrite(L, D21(r,3)); write(L, string'(" "));
            hwrite(L, D22(r,0)); write(L, string'(" "));
            hwrite(L, D22(r,1)); write(L, string'(" "));
            hwrite(L, D22(r,2)); write(L, string'(" "));
            hwrite(L, D22(r,3)); write(L, string'(" "));
            hwrite(L, D23(r,0)); write(L, string'(" "));
            hwrite(L, D23(r,1)); write(L, string'(" "));
            hwrite(L, D23(r,2)); write(L, string'(" "));
            hwrite(L, D23(r,3));
            writeline(f, L);
        end loop;

        -- rows 12..15 = D30 | D31
        for r in 0 to 3 loop
            L := null;
            hwrite(L, D30(r,0)); write(L, string'(" "));
            hwrite(L, D30(r,1)); write(L, string'(" "));
            hwrite(L, D30(r,2)); write(L, string'(" "));
            hwrite(L, D30(r,3)); write(L, string'(" "));
            hwrite(L, D31(r,0)); write(L, string'(" "));
            hwrite(L, D31(r,1)); write(L, string'(" "));
            hwrite(L, D31(r,2)); write(L, string'(" "));
            hwrite(L, D31(r,3)); write(L, string'(" "));
            hwrite(L, D32(r,0)); write(L, string'(" "));
            hwrite(L, D32(r,1)); write(L, string'(" "));
            hwrite(L, D32(r,2)); write(L, string'(" "));
            hwrite(L, D32(r,3)); write(L, string'(" "));
            hwrite(L, D33(r,0)); write(L, string'(" "));
            hwrite(L, D33(r,1)); write(L, string'(" "));
            hwrite(L, D33(r,2)); write(L, string'(" "));
            hwrite(L, D33(r,3));
            writeline(f, L);
        end loop;

        L := null;
        writeline(f, L);
    end procedure;
    
begin
    
    --clock
    clk <= not clk after CLK_PERIOD/2;
    
    --dut
    dut : entity work.dualTensorCoreWrapper
        generic map(
            REG_W  => REG_W,
            ELEM_W => ELEM_W
        )
        port map(
            clk        => clk,
            rst        => rst,
            start      => start,
            hmma_step => hmma_step,   

            widthSel => widthSel,
            typeSel  => typeSel,

            rf0_rd_data_port_a => rf0_rd_data_port_a,
            rf0_rd_data_port_b => rf0_rd_data_port_b,
            rf1_rd_data_port_a => rf1_rd_data_port_a,
            rf1_rd_data_port_b => rf1_rd_data_port_b,

            W0_tc0_oct0_8_X3  => W0_tc0_oct0_8_X3,
            W1_tc0_oct0_8_X3  => W1_tc0_oct0_8_X3,
            W0_tc0_oct0_16_X3 => W0_tc0_oct0_16_X3,
            W1_tc0_oct0_16_X3 => W1_tc0_oct0_16_X3,
            W0_tc0_oct0_32_X3 => W0_tc0_oct0_32_X3,
            W1_tc0_oct0_32_X3 => W1_tc0_oct0_32_X3,
            
            W0_tc0_oct1_8_X3  => W0_tc0_oct1_8_X3,
            W1_tc0_oct1_8_X3  => W1_tc0_oct1_8_X3,
            W0_tc0_oct1_16_X3 => W0_tc0_oct1_16_X3,
            W1_tc0_oct1_16_X3 => W1_tc0_oct1_16_X3,
            W0_tc0_oct1_32_X3 => W0_tc0_oct1_32_X3,
            W1_tc0_oct1_32_X3 => W1_tc0_oct1_32_X3,
            
            W0_tc1_oct0_8_X3  => W0_tc1_oct0_8_X3,
            W1_tc1_oct0_8_X3  => W1_tc1_oct0_8_X3,
            W0_tc1_oct0_16_X3 => W0_tc1_oct0_16_X3,
            W1_tc1_oct0_16_X3 => W1_tc1_oct0_16_X3,
            W0_tc1_oct0_32_X3 => W0_tc1_oct0_32_X3,
            W1_tc1_oct0_32_X3 => W1_tc1_oct0_32_X3,

            W0_tc1_oct1_8_X3  => W0_tc1_oct1_8_X3,
            W1_tc1_oct1_8_X3  => W1_tc1_oct1_8_X3,
            W0_tc1_oct1_16_X3 => W0_tc1_oct1_16_X3,
            W1_tc1_oct1_16_X3 => W1_tc1_oct1_16_X3,
            W0_tc1_oct1_32_X3 => W0_tc1_oct1_32_X3,
            W1_tc1_oct1_32_X3 => W1_tc1_oct1_32_X3,

            busy      => busy,
            done      => done,
            step_done => step_done
        );
        
        --stimulus
        
        stim_process : process
            variable have_data : boolean;
            variable test_idx  : integer := 0;
            
            --set 0 blocks
            variable tc0_A0_pair00_a, tc0_A0_pair00_b  : lane_block16_t;
            variable tc0_A0_pair01_a, tc0_A0_pair01_b  : lane_block16_t;
            variable tc1_A0_pair00_a, tc1_A0_pair00_b  : lane_block16_t;
            variable tc1_A0_pair01_a, tc1_A0_pair01_b  : lane_block16_t;
            
            variable tc0_B0_pair00_a, tc0_B0_pair00_b  : lane_block16_t;
            variable tc0_B0_pair01_a, tc0_B0_pair01_b  : lane_block16_t;
            variable tc1_B0_pair00_a, tc1_B0_pair00_b  : lane_block16_t;
            variable tc1_B0_pair01_a, tc1_B0_pair01_b  : lane_block16_t;
            
            variable tc0_C0_pair00_a, tc0_C0_pair00_b : lane_block16_t;
            variable tc0_C0_pair01_a, tc0_C0_pair01_b : lane_block16_t;
            variable tc1_C0_pair00_a, tc1_C0_pair00_b : lane_block16_t;
            variable tc1_C0_pair01_a, tc1_C0_pair01_b : lane_block16_t;
            
            variable tc0_C1_pair00_a, tc0_C1_pair00_b : lane_block16_t;
            variable tc0_C1_pair01_a, tc0_C1_pair01_b : lane_block16_t;
            variable tc1_C1_pair00_a, tc1_C1_pair00_b : lane_block16_t;
            variable tc1_C1_pair01_a, tc1_C1_pair01_b : lane_block16_t;
            
            --set 1 filedriven A/B blocks
            variable tc0_A1_pair00_a, tc0_A1_pair00_b : lane_block16_t;
            variable tc0_A1_pair01_a, tc0_A1_pair01_b : lane_block16_t;
            variable tc1_A1_pair00_a, tc1_A1_pair00_b : lane_block16_t;
            variable tc1_A1_pair01_a, tc1_A1_pair01_b : lane_block16_t;
            
            variable tc0_B1_pair00_a, tc0_B1_pair00_b : lane_block16_t;
            variable tc0_B1_pair01_a, tc0_B1_pair01_b : lane_block16_t;
            variable tc1_B1_pair00_a, tc1_B1_pair00_b : lane_block16_t;
            variable tc1_B1_pair01_a, tc1_B1_pair01_b : lane_block16_t;
            
            --set 2 filedriven A/B blocks
            variable tc0_A2_pair00_a, tc0_A2_pair00_b : lane_block16_t;
            variable tc0_A2_pair01_a, tc0_A2_pair01_b : lane_block16_t;
            variable tc1_A2_pair00_a, tc1_A2_pair00_b : lane_block16_t;
            variable tc1_A2_pair01_a, tc1_A2_pair01_b : lane_block16_t;
            
            variable tc0_B2_pair00_a, tc0_B2_pair00_b : lane_block16_t;
            variable tc0_B2_pair01_a, tc0_B2_pair01_b : lane_block16_t;
            variable tc1_B2_pair00_a, tc1_B2_pair00_b : lane_block16_t;
            variable tc1_B2_pair01_a, tc1_B2_pair01_b : lane_block16_t;
            
            --set 3 filedriven A/B blocks
            variable tc0_A3_pair00_a, tc0_A3_pair00_b : lane_block16_t;
            variable tc0_A3_pair01_a, tc0_A3_pair01_b : lane_block16_t;
            variable tc1_A3_pair00_a, tc1_A3_pair00_b : lane_block16_t;
            variable tc1_A3_pair01_a, tc1_A3_pair01_b : lane_block16_t;
            
            variable tc0_B3_pair00_a, tc0_B3_pair00_b : lane_block16_t;
            variable tc0_B3_pair01_a, tc0_B3_pair01_b : lane_block16_t;
            variable tc1_B3_pair00_a, tc1_B3_pair00_b : lane_block16_t;
            variable tc1_B3_pair01_a, tc1_B3_pair01_b : lane_block16_t;
            
            --reconstructed accumulators for later sets
            variable tc0_C0_chain_pair00_a, tc0_C0_chain_pair00_b : lane_block16_t;
            variable tc0_C0_chain_pair01_a, tc0_C0_chain_pair01_b : lane_block16_t;
            variable tc1_C0_chain_pair00_a, tc1_C0_chain_pair00_b : lane_block16_t;
            variable tc1_C0_chain_pair01_a, tc1_C0_chain_pair01_b : lane_block16_t;
            
            variable tc0_C1_chain_pair00_a, tc0_C1_chain_pair00_b : lane_block16_t;
            variable tc0_C1_chain_pair01_a, tc0_C1_chain_pair01_b : lane_block16_t;
            variable tc1_C1_chain_pair00_a, tc1_C1_chain_pair00_b : lane_block16_t;
            variable tc1_C1_chain_pair01_a, tc1_C1_chain_pair01_b : lane_block16_t;
            
            --outputs set 0
            --octect0 (living in tc0)
            variable D00_set0_step0 : matrix4x4_fp32_t;
            variable D10_set0_step0 : matrix4x4_fp32_t;
            variable D01_set0_step1 : matrix4x4_fp32_t;
            variable D11_set0_step1 : matrix4x4_fp32_t;
            --octect1 (living in tc0)
            variable D20_set0_step0 : matrix4x4_fp32_t;
            variable D30_set0_step0 : matrix4x4_fp32_t;
            variable D21_set0_step1 : matrix4x4_fp32_t;
            variable D31_set0_step1 : matrix4x4_fp32_t;
            --octect2 (living in tc1)
            variable D02_set0_step0 : matrix4x4_fp32_t;
            variable D12_set0_step0 : matrix4x4_fp32_t;
            variable D03_set0_step1 : matrix4x4_fp32_t;
            variable D13_set0_step1 : matrix4x4_fp32_t;
            --octect3 (living in tc1)
            variable D22_set0_step0 : matrix4x4_fp32_t;
            variable D32_set0_step0 : matrix4x4_fp32_t;
            variable D23_set0_step1 : matrix4x4_fp32_t;
            variable D33_set0_step1 : matrix4x4_fp32_t;
            
            --outputs set 1
            --octect 0
            variable D00_set1_step0 : matrix4x4_fp32_t;
            variable D10_set1_step0 : matrix4x4_fp32_t;
            variable D01_set1_step1 : matrix4x4_fp32_t;
            variable D11_set1_step1 : matrix4x4_fp32_t;
            --octect 1
            variable D20_set1_step0 : matrix4x4_fp32_t;
            variable D30_set1_step0 : matrix4x4_fp32_t;
            variable D21_set1_step1 : matrix4x4_fp32_t;
            variable D31_set1_step1 : matrix4x4_fp32_t;
            --octect2 (living in tc1)
            variable D02_set1_step0 : matrix4x4_fp32_t;
            variable D12_set1_step0 : matrix4x4_fp32_t;
            variable D03_set1_step1 : matrix4x4_fp32_t;
            variable D13_set1_step1 : matrix4x4_fp32_t;
            --octect3 (living in tc1)
            variable D22_set1_step0 : matrix4x4_fp32_t;
            variable D32_set1_step0 : matrix4x4_fp32_t;
            variable D23_set1_step1 : matrix4x4_fp32_t;
            variable D33_set1_step1 : matrix4x4_fp32_t;
            
            --outputs set 2
            --octect 0
            variable D00_set2_step0 : matrix4x4_fp32_t;
            variable D10_set2_step0 : matrix4x4_fp32_t;
            variable D01_set2_step1 : matrix4x4_fp32_t;
            variable D11_set2_step1 : matrix4x4_fp32_t;
            --octect 1
            variable D20_set2_step0 : matrix4x4_fp32_t;
            variable D30_set2_step0 : matrix4x4_fp32_t;
            variable D21_set2_step1 : matrix4x4_fp32_t;
            variable D31_set2_step1 : matrix4x4_fp32_t;
            --octect2 (living in tc1)
            variable D02_set2_step0 : matrix4x4_fp32_t;
            variable D12_set2_step0 : matrix4x4_fp32_t;
            variable D03_set2_step1 : matrix4x4_fp32_t;
            variable D13_set2_step1 : matrix4x4_fp32_t;
            --octect3 (living in tc1)
            variable D22_set2_step0 : matrix4x4_fp32_t;
            variable D32_set2_step0 : matrix4x4_fp32_t;
            variable D23_set2_step1 : matrix4x4_fp32_t;
            variable D33_set2_step1 : matrix4x4_fp32_t;
            
            --outputs set 3
            --octect 0
            variable D00_set3_step0 : matrix4x4_fp32_t;
            variable D10_set3_step0 : matrix4x4_fp32_t;
            variable D01_set3_step1 : matrix4x4_fp32_t;
            variable D11_set3_step1 : matrix4x4_fp32_t;
            --octect 1
            variable D20_set3_step0 : matrix4x4_fp32_t;
            variable D30_set3_step0 : matrix4x4_fp32_t;
            variable D21_set3_step1 : matrix4x4_fp32_t;
            variable D31_set3_step1 : matrix4x4_fp32_t;
            --octect2 (living in tc1)
            variable D02_set3_step0 : matrix4x4_fp32_t;
            variable D12_set3_step0 : matrix4x4_fp32_t;
            variable D03_set3_step1 : matrix4x4_fp32_t;
            variable D13_set3_step1 : matrix4x4_fp32_t;
            --octect3 (living in tc1)
            variable D22_set3_step0 : matrix4x4_fp32_t;
            variable D32_set3_step0 : matrix4x4_fp32_t;
            variable D23_set3_step1 : matrix4x4_fp32_t;
            variable D33_set3_step1 : matrix4x4_fp32_t;
            
        begin
        
        --initial setup
        widthSel <= WIDTH_FP32;
        typeSel <= TYPE_FP;
        start       <= '0';
        hmma_step  <= '0';
        clear_wrapper_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                               rf1_rd_data_port_a, rf1_rd_data_port_b);
        
        --reset
        wait for 3 * CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;
        
        while true loop
            test_idx := test_idx + 1;
            
            --clear all result matrices
            clear_matrix4x4(D00_set0_step0); clear_matrix4x4(D10_set0_step0); clear_matrix4x4(D20_set0_step0); clear_matrix4x4(D30_set0_step0);
            clear_matrix4x4(D01_set0_step1); clear_matrix4x4(D11_set0_step1); clear_matrix4x4(D21_set0_step1); clear_matrix4x4(D31_set0_step1);
            clear_matrix4x4(D02_set0_step0); clear_matrix4x4(D12_set0_step0); clear_matrix4x4(D22_set0_step0); clear_matrix4x4(D32_set0_step0);
            clear_matrix4x4(D03_set0_step1); clear_matrix4x4(D13_set0_step1); clear_matrix4x4(D23_set0_step1); clear_matrix4x4(D33_set0_step1);
            
            clear_matrix4x4(D00_set1_step0); clear_matrix4x4(D10_set1_step0); clear_matrix4x4(D20_set1_step0); clear_matrix4x4(D30_set1_step0);
            clear_matrix4x4(D01_set1_step1); clear_matrix4x4(D11_set1_step1); clear_matrix4x4(D21_set1_step1); clear_matrix4x4(D31_set1_step1);
            clear_matrix4x4(D02_set1_step0); clear_matrix4x4(D12_set1_step0); clear_matrix4x4(D22_set1_step0); clear_matrix4x4(D32_set1_step0);
            clear_matrix4x4(D03_set1_step1); clear_matrix4x4(D13_set1_step1); clear_matrix4x4(D23_set1_step1); clear_matrix4x4(D33_set1_step1);
            
            clear_matrix4x4(D00_set2_step0); clear_matrix4x4(D10_set2_step0); clear_matrix4x4(D20_set2_step0); clear_matrix4x4(D30_set2_step0);
            clear_matrix4x4(D01_set2_step1); clear_matrix4x4(D11_set2_step1); clear_matrix4x4(D21_set2_step1); clear_matrix4x4(D31_set2_step1);
            clear_matrix4x4(D02_set2_step0); clear_matrix4x4(D12_set2_step0); clear_matrix4x4(D22_set2_step0); clear_matrix4x4(D32_set2_step0);
            clear_matrix4x4(D03_set2_step1); clear_matrix4x4(D13_set2_step1); clear_matrix4x4(D23_set2_step1); clear_matrix4x4(D33_set2_step1);
            
            clear_matrix4x4(D00_set3_step0); clear_matrix4x4(D10_set3_step0); clear_matrix4x4(D20_set3_step0); clear_matrix4x4(D30_set3_step0);
            clear_matrix4x4(D01_set3_step1); clear_matrix4x4(D11_set3_step1); clear_matrix4x4(D21_set3_step1); clear_matrix4x4(D31_set3_step1);
            clear_matrix4x4(D02_set3_step0); clear_matrix4x4(D12_set3_step0); clear_matrix4x4(D22_set3_step0); clear_matrix4x4(D32_set3_step0);
            clear_matrix4x4(D03_set3_step1); clear_matrix4x4(D13_set3_step1); clear_matrix4x4(D23_set3_step1); clear_matrix4x4(D33_set3_step1);
            
            --READ one COMPLETE SINGLE EXPERIMENT from file
            
            --set 0: A for TC0 and TC1
            read_16_lanes_into_block(tb_file, tc0_A0_pair00_a, tc0_A0_pair00_b, have_data);
            exit when not have_data;
            read_16_lanes_into_block(tb_file, tc1_A0_pair00_a, tc1_A0_pair00_b, have_data);
            assert have_data report "EOF while reading set0 tc1 A pair00 block" severity failure;
            
            read_16_lanes_into_block(tb_file, tc0_A0_pair01_a, tc0_A0_pair01_b, have_data);
            assert have_data report "EOF while reading set0 tc0 A pair01 block" severity failure;
            read_16_lanes_into_block(tb_file, tc1_A0_pair01_a, tc1_A0_pair01_b, have_data);
            assert have_data report "EOF while reading set0 tc1 A pair01 block" severity failure;

            --set 0: B for TC0 and TC1
            read_16_lanes_into_block(tb_file, tc0_B0_pair00_a, tc0_B0_pair00_b, have_data);
            assert have_data report "EOF while reading set0 tc0 B pair00 block" severity failure;
            read_16_lanes_into_block(tb_file, tc1_B0_pair00_a, tc1_B0_pair00_b, have_data);
            assert have_data report "EOF while reading set0 tc1 B pair00 block" severity failure;
            
            read_16_lanes_into_block(tb_file, tc0_B0_pair01_a, tc0_B0_pair01_b, have_data);
            assert have_data report "EOF while reading set0 tc0 B pair01 block" severity failure;
            read_16_lanes_into_block(tb_file, tc1_B0_pair01_a, tc1_B0_pair01_b, have_data);
            assert have_data report "EOF while reading set0 tc1 B pair01 block" severity failure;
            
            --set 0: C step0 for tc0 and tc1
            read_16_lanes_into_block(tb_file, tc0_C0_pair00_a, tc0_C0_pair00_b, have_data);
            assert have_data report "EOF while reading set0 TC0 C0 pair00 block" severity failure;
            read_16_lanes_into_block(tb_file, tc1_C0_pair00_a, tc1_C0_pair00_b, have_data);
            assert have_data report "EOF while reading set0 TC1 C0 pair00 block" severity failure;
            
            read_16_lanes_into_block(tb_file, tc0_C0_pair01_a, tc0_C0_pair01_b, have_data);
            assert have_data report "EOF while reading set0 TC0 C0 pair01 block" severity failure;
            read_16_lanes_into_block(tb_file, tc1_C0_pair01_a, tc1_C0_pair01_b, have_data);
            assert have_data report "EOF while reading set0 TC1 C0 pair01 block" severity failure;
            
            --set 0: C step1 for tc0 and tc1    
            read_16_lanes_into_block(tb_file, tc0_C1_pair00_a, tc0_C1_pair00_b, have_data);
            assert have_data report "EOF while reading set0 TC0 C1 pair00 block" severity failure;
            read_16_lanes_into_block(tb_file, tc1_C1_pair00_a, tc1_C1_pair00_b, have_data);
            assert have_data report "EOF while reading set0 TC1 C1 pair00 block" severity failure;
            
            read_16_lanes_into_block(tb_file, tc0_C1_pair01_a, tc0_C1_pair01_b, have_data);
            assert have_data report "EOF while reading set0 TC0 C1 pair01 block" severity failure;
            read_16_lanes_into_block(tb_file, tc1_C1_pair01_a, tc1_C1_pair01_b, have_data);
            assert have_data report "EOF while reading set0 TC1 C1 pair01 block" severity failure;
            
            --set 1 A/B
            read_16_lanes_into_block(tb_file, tc0_A1_pair00_a, tc0_A1_pair00_b, have_data);
            assert have_data report "EOF while reading set1 TC0 A pair00 block" severity failure;
            read_16_lanes_into_block(tb_file, tc1_A1_pair00_a, tc1_A1_pair00_b, have_data);
            assert have_data report "EOF while reading set1 TC1 A pair00 block" severity failure;
            
            read_16_lanes_into_block(tb_file, tc0_A1_pair01_a, tc0_A1_pair01_b, have_data);
            assert have_data report "EOF while reading set1 TC0 A pair01 block" severity failure;
            read_16_lanes_into_block(tb_file, tc1_A1_pair01_a, tc1_A1_pair01_b, have_data);
            assert have_data report "EOF while reading set1 TC1 A pair01 block" severity failure;
            
            read_16_lanes_into_block(tb_file, tc0_B1_pair00_a, tc0_B1_pair00_b, have_data);
            assert have_data report "EOF while reading set1 TC0 B pair00 block" severity failure;
            read_16_lanes_into_block(tb_file, tc1_B1_pair00_a, tc1_B1_pair00_b, have_data);
            assert have_data report "EOF while reading set1 TC1 B pair00 block" severity failure;

            read_16_lanes_into_block(tb_file, tc0_B1_pair01_a, tc0_B1_pair01_b, have_data);
            assert have_data report "EOF while reading set1 TC0 B pair01 block" severity failure;
            read_16_lanes_into_block(tb_file, tc1_B1_pair01_a, tc1_B1_pair01_b, have_data);
            assert have_data report "EOF while reading set1 TC1 B pair01 block" severity failure;
            
            --set 2
            read_16_lanes_into_block(tb_file, tc0_A2_pair00_a, tc0_A2_pair00_b, have_data);
            assert have_data report "EOF while reading  set2 TC0 A pair00 block" severity failure;
            read_16_lanes_into_block(tb_file, tc1_A2_pair00_a, tc1_A2_pair00_b, have_data);
            assert have_data report "EOF while reading  set2 TC1 A pair00 block" severity failure;
            
            read_16_lanes_into_block(tb_file, tc0_A2_pair01_a, tc0_A2_pair01_b, have_data);
            assert have_data report "EOF while reading  set2 TC0 A pair01 block" severity failure;
            read_16_lanes_into_block(tb_file, tc1_A2_pair01_a, tc1_A2_pair01_b, have_data);
            assert have_data report "EOF while reading  set2 TC1 A pair01 block" severity failure;
            
            read_16_lanes_into_block(tb_file, tc0_B2_pair00_a, tc0_B2_pair00_b, have_data);
            assert have_data report "EOF while reading set2 TC0 B pair00 block" severity failure;
            read_16_lanes_into_block(tb_file, tc1_B2_pair00_a, tc1_B2_pair00_b, have_data);
            assert have_data report "EOF while reading set2 TC1 B pair00 block" severity failure;
            
            read_16_lanes_into_block(tb_file, tc0_B2_pair01_a, tc0_B2_pair01_b, have_data);
            assert have_data report "EOF while reading set2 TC0 B pair01 block" severity failure;
            read_16_lanes_into_block(tb_file, tc1_B2_pair01_a, tc1_B2_pair01_b, have_data);
            assert have_data report "EOF while reading set2 TC1 B pair01 block" severity failure;
            
            --set 3
            read_16_lanes_into_block(tb_file, tc0_A3_pair00_a, tc0_A3_pair00_b, have_data);
            assert have_data report "EOF while reading set3 TC0 A pair00 block" severity failure;
            read_16_lanes_into_block(tb_file, tc1_A3_pair00_a, tc1_A3_pair00_b, have_data);
            assert have_data report "EOF while reading set3 TC1 A pair00 block" severity failure;
            
            read_16_lanes_into_block(tb_file, tc0_A3_pair01_a, tc0_A3_pair01_b, have_data);
            assert have_data report "EOF while reading set3 TC0 A pair01 block" severity failure;
            read_16_lanes_into_block(tb_file, tc1_A3_pair01_a, tc1_A3_pair01_b, have_data);
            assert have_data report "EOF while reading set3 TC1 A pair01 block" severity failure;
            
            read_16_lanes_into_block(tb_file, tc0_B3_pair00_a, tc0_B3_pair00_b, have_data);
            assert have_data report "EOF while reading set3 TC0 B pair00 block" severity failure;
            read_16_lanes_into_block(tb_file, tc1_B3_pair00_a, tc1_B3_pair00_b, have_data);
            assert have_data report "EOF while reading set3 TC1 B pair00 block" severity failure;
            
            read_16_lanes_into_block(tb_file, tc0_B3_pair01_a, tc0_B3_pair01_b, have_data);
            assert have_data report "EOF while reading set3 TC0 B pair01 block" severity failure;
            read_16_lanes_into_block(tb_file, tc1_B3_pair01_a, tc1_B3_pair01_b, have_data);
            assert have_data report "EOF while reading set3 TC1 B pair01 block" severity failure;
            
            --SET 0 
            
            -- HMMA step0
            clear_wrapper_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b,
                                   rf1_rd_data_port_a, rf1_rd_data_port_b );
          
            hmma_step <= '0';
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
          
            --feed A pair00
            drive_wrapper_blocks_to_rf_ports(
                                    rf0_rd_data_port_a, rf0_rd_data_port_b,
                                    rf1_rd_data_port_a, rf1_rd_data_port_b,
                                    tc0_A0_pair00_a, tc0_A0_pair00_b,
                                    tc1_A0_pair00_a, tc1_A0_pair00_b );
            wait until rising_edge(clk);
            
            --feed A pair01
            drive_wrapper_blocks_to_rf_ports(
                                    rf0_rd_data_port_a, rf0_rd_data_port_b,
                                    rf1_rd_data_port_a, rf1_rd_data_port_b,
                                    tc0_A0_pair01_a, tc0_A0_pair01_b,
                                    tc1_A0_pair01_a, tc1_A0_pair01_b );
            wait until rising_edge(clk);
          
            --feed B pair00
            drive_wrapper_blocks_to_rf_ports(
                                    rf0_rd_data_port_a, rf0_rd_data_port_b,
                                    rf1_rd_data_port_a, rf1_rd_data_port_b,
                                    tc0_B0_pair00_a, tc0_B0_pair00_b,
                                    tc1_B0_pair00_a, tc1_B0_pair00_b );
            wait until rising_edge(clk);
            
            --feed B pair01
            drive_wrapper_blocks_to_rf_ports(
                                    rf0_rd_data_port_a, rf0_rd_data_port_b,
                                    rf1_rd_data_port_a, rf1_rd_data_port_b,
                                    tc0_B0_pair01_a, tc0_B0_pair01_b,
                                    tc1_B0_pair01_a, tc1_B0_pair01_b );
            wait until rising_edge(clk);
          
            --feed C0 pair00
            drive_wrapper_blocks_to_rf_ports(
                                    rf0_rd_data_port_a, rf0_rd_data_port_b,
                                    rf1_rd_data_port_a, rf1_rd_data_port_b,
                                    tc0_C0_pair00_a, tc0_C0_pair00_b,
                                    tc1_C0_pair00_a, tc1_C0_pair00_b );
            wait until rising_edge(clk);
            
            --feed C0 pair01
            drive_wrapper_blocks_to_rf_ports(
                                    rf0_rd_data_port_a, rf0_rd_data_port_b,
                                    rf1_rd_data_port_a, rf1_rd_data_port_b,
                                    tc0_C0_pair01_a, tc0_C0_pair01_b,
                                    tc1_C0_pair01_a, tc1_C0_pair01_b );
            wait until rising_edge(clk);
          
            clear_wrapper_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                   rf1_rd_data_port_a, rf1_rd_data_port_b);
            
            capture_step0_outputs(W0_tc0_oct0_32_X3, W1_tc0_oct0_32_X3, W0_tc0_oct1_32_X3, W1_tc0_oct1_32_X3,
                                  W0_tc1_oct0_32_X3, W1_tc1_oct0_32_X3, W0_tc1_oct1_32_X3, W1_tc1_oct1_32_X3,
                                  D00_set0_step0, D10_set0_step0, D20_set0_step0, D30_set0_step0,
                                  D02_set0_step0, D12_set0_step0, D22_set0_step0, D32_set0_step0
                                  );
            
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop;
            
            wait until rising_edge(clk);
            
            --HMMA step 1
          
            clear_wrapper_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b,
                                   rf1_rd_data_port_a, rf1_rd_data_port_b );
          
            hmma_step <= '1';
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
          
            --feed only C1 pair 00
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                             rf1_rd_data_port_a, rf1_rd_data_port_b,
                                             tc0_C1_pair00_a, tc0_C1_pair00_b, 
                                             tc1_C1_pair00_a, tc1_C1_pair00_b );
            wait until rising_edge(clk);
            
            --feed only C1 pair 01
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                             rf1_rd_data_port_a, rf1_rd_data_port_b,
                                             tc0_C1_pair01_a, tc0_C1_pair01_b, 
                                             tc1_C1_pair01_a, tc1_C1_pair01_b );
            wait until rising_edge(clk);
          
            clear_wrapper_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b,
                                   rf1_rd_data_port_a, rf1_rd_data_port_b);
            
            capture_step1_outputs(W0_tc0_oct0_32_X3, W1_tc0_oct0_32_X3, W0_tc0_oct1_32_X3, W1_tc0_oct1_32_X3,
                                  W0_tc1_oct0_32_X3, W1_tc1_oct0_32_X3, W0_tc1_oct1_32_X3, W1_tc1_oct1_32_X3,
                                  D01_set0_step1, D11_set0_step1, D21_set0_step1, D31_set0_step1,
                                  D03_set0_step1, D13_set0_step1, D23_set0_step1, D33_set0_step1 );
                        
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop;
            
            wait until rising_edge(clk);
            
            --SET 1
            build_accumulator_blocks_from_previous_results(
                D00_set0_step0, D10_set0_step0, D01_set0_step1, D11_set0_step1,
                D20_set0_step0, D30_set0_step0, D21_set0_step1, D31_set0_step1,
                tc0_C0_chain_pair00_a, tc0_C0_chain_pair00_b, tc0_C0_chain_pair01_a, tc0_C0_chain_pair01_b,
                tc0_C1_chain_pair00_a, tc0_C1_chain_pair00_b, tc0_C1_chain_pair01_a, tc0_C1_chain_pair01_b               
            );
            
            build_accumulator_blocks_from_previous_results(
                D02_set0_step0, D12_set0_step0, D03_set0_step1, D13_set0_step1,
                D22_set0_step0, D32_set0_step0, D23_set0_step1, D33_set0_step1,
                tc1_C0_chain_pair00_a, tc1_C0_chain_pair00_b, tc1_C0_chain_pair01_a, tc1_C0_chain_pair01_b,
                tc1_C1_chain_pair00_a, tc1_C1_chain_pair00_b, tc1_C1_chain_pair01_a, tc1_C1_chain_pair01_b
            );
            
            --HMMA step0
            clear_wrapper_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b,
                           rf1_rd_data_port_a, rf1_rd_data_port_b);
            
            hmma_step <= '0';
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                             rf1_rd_data_port_a, rf1_rd_data_port_b,
                                             tc0_A1_pair00_a, tc0_A1_pair00_b,
                                             tc1_A1_pair00_a, tc1_A1_pair00_b );
            wait until rising_edge(clk);
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                             rf1_rd_data_port_a, rf1_rd_data_port_b,
                                             tc0_A1_pair01_a, tc0_A1_pair01_b,
                                             tc1_A1_pair01_a, tc1_A1_pair01_b );
            wait until rising_edge(clk);
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                             rf1_rd_data_port_a, rf1_rd_data_port_b, 
                                             tc0_B1_pair00_a, tc0_B1_pair00_b,
                                             tc1_B1_pair00_a, tc1_B1_pair00_b);
            wait until rising_edge(clk);
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                             rf1_rd_data_port_a, rf1_rd_data_port_b, 
                                             tc0_B1_pair01_a, tc0_B1_pair01_b,
                                             tc1_B1_pair01_a, tc1_B1_pair01_b);
            wait until rising_edge(clk);
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                             rf1_rd_data_port_a, rf1_rd_data_port_b,
                                             tc0_C0_chain_pair00_a, tc0_C0_chain_pair00_b,
                                             tc1_C0_chain_pair00_a, tc1_C0_chain_pair00_b );
            wait until rising_edge(clk);
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                             rf1_rd_data_port_a, rf1_rd_data_port_b,
                                             tc0_C0_chain_pair01_a, tc0_C0_chain_pair01_b,
                                             tc1_C0_chain_pair01_a, tc1_C0_chain_pair01_b );
            wait until rising_edge(clk);
            
            clear_wrapper_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b,
                                   rf1_rd_data_port_a, rf1_rd_data_port_b );
            
            capture_step0_outputs(W0_tc0_oct0_32_X3, W1_tc0_oct0_32_X3, W0_tc0_oct1_32_X3, W1_tc0_oct1_32_X3,
                                  W0_tc1_oct0_32_X3, W1_tc1_oct0_32_X3, W0_tc1_oct1_32_X3, W1_tc1_oct1_32_X3,
                                  D00_set1_step0, D10_set1_step0, D20_set1_step0, D30_set1_step0,
                                  D02_set1_step0, D12_set1_step0, D22_set1_step0, D32_set1_step0 );
            
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop;
            
            wait until rising_edge(clk);
            
            --HMMA step1
            clear_wrapper_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b,
                                   rf1_rd_data_port_a, rf1_rd_data_port_b );
            
            hmma_step <= '1';
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b,
                                             rf1_rd_data_port_a, rf1_rd_data_port_b,
                                             tc0_C1_chain_pair00_a, tc0_C1_chain_pair00_b, 
                                             tc1_C1_chain_pair00_a, tc1_C1_chain_pair00_b );
            wait until rising_edge(clk);
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b,
                                             rf1_rd_data_port_a, rf1_rd_data_port_b,
                                             tc0_C1_chain_pair01_a, tc0_C1_chain_pair01_b, 
                                             tc1_C1_chain_pair01_a, tc1_C1_chain_pair01_b );
            wait until rising_edge(clk);
            
            clear_wrapper_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b,
                                   rf1_rd_data_port_a, rf1_rd_data_port_b);
            
            capture_step1_outputs(W0_tc0_oct0_32_X3, W1_tc0_oct0_32_X3, W0_tc0_oct1_32_X3, W1_tc0_oct1_32_X3,
                                  W0_tc1_oct0_32_X3, W1_tc1_oct0_32_X3, W0_tc1_oct1_32_X3, W1_tc1_oct1_32_X3,
                                  D01_set1_step1, D11_set1_step1, D21_set1_step1, D31_set1_step1,
                                  D03_set1_step1, D13_set1_step1, D23_set1_step1, D33_set1_step1 );
            
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop;
            
            wait until rising_edge(clk);
            
            --SET 2
            build_accumulator_blocks_from_previous_results(
                D00_set1_step0, D10_set1_step0, D01_set1_step1, D11_set1_step1,
                D20_set1_step0, D30_set1_step0, D21_set1_step1, D31_set1_step1,                
                tc0_C0_chain_pair00_a, tc0_C0_chain_pair00_b, tc0_C0_chain_pair01_a, tc0_C0_chain_pair01_b,
                tc0_C1_chain_pair00_a, tc0_C1_chain_pair00_b, tc0_C1_chain_pair01_a, tc0_C1_chain_pair01_b
            );
            
            build_accumulator_blocks_from_previous_results(
                D02_set1_step0, D12_set1_step0, D03_set1_step1, D13_set1_step1,
                D22_set1_step0, D32_set1_step0, D23_set1_step1, D33_set1_step1,                
                tc1_C0_chain_pair00_a, tc1_C0_chain_pair00_b, tc1_C0_chain_pair01_a, tc1_C0_chain_pair01_b,
                tc1_C1_chain_pair00_a, tc1_C1_chain_pair00_b, tc1_C1_chain_pair01_a, tc1_C1_chain_pair01_b
            );
            
            --HMMA step0
            clear_wrapper_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b,
                                   rf1_rd_data_port_a, rf1_rd_data_port_b );
            
            hmma_step <= '0';
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                             rf1_rd_data_port_a, rf1_rd_data_port_b, 
                                             tc0_A2_pair00_a, tc0_A2_pair00_b, 
                                             tc1_A2_pair00_a, tc1_A2_pair00_b);
            wait until rising_edge(clk);
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                             rf1_rd_data_port_a, rf1_rd_data_port_b, 
                                             tc0_A2_pair01_a, tc0_A2_pair01_b, 
                                             tc1_A2_pair01_a, tc1_A2_pair01_b);
            wait until rising_edge(clk);
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                             rf1_rd_data_port_a, rf1_rd_data_port_b, 
                                             tc0_B2_pair00_a, tc0_B2_pair00_b, 
                                             tc1_B2_pair00_a, tc1_B2_pair00_b);
            wait until rising_edge(clk);
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                             rf1_rd_data_port_a, rf1_rd_data_port_b, 
                                             tc0_B2_pair01_a, tc0_B2_pair01_b, 
                                             tc1_B2_pair01_a, tc1_B2_pair01_b);
            wait until rising_edge(clk);
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                    rf1_rd_data_port_a, rf1_rd_data_port_b, 
                                    tc0_C0_chain_pair00_a, tc0_C0_chain_pair00_b, 
                                    tc1_C0_chain_pair00_a, tc1_C0_chain_pair00_b);
            wait until rising_edge(clk);
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                    rf1_rd_data_port_a, rf1_rd_data_port_b, 
                                    tc0_C0_chain_pair01_a, tc0_C0_chain_pair01_b, 
                                    tc1_C0_chain_pair01_a, tc1_C0_chain_pair01_b);
            wait until rising_edge(clk);
            
            clear_wrapper_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                   rf1_rd_data_port_a, rf1_rd_data_port_b);
            
            capture_step0_outputs(W0_tc0_oct0_32_X3, W1_tc0_oct0_32_X3, W0_tc0_oct1_32_X3, W1_tc0_oct1_32_X3,
                                  W0_tc1_oct0_32_X3, W1_tc1_oct0_32_X3, W0_tc1_oct1_32_X3, W1_tc1_oct1_32_X3,
                                  D00_set2_step0, D10_set2_step0, D20_set2_step0, D30_set2_step0, 
                                  D02_set2_step0, D12_set2_step0, D22_set2_step0, D32_set2_step0 );
            
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop; 
            
            wait until rising_edge(clk);
            
            --HMMA step1
            
            clear_wrapper_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b,
                                   rf1_rd_data_port_a, rf1_rd_data_port_b );
            
            hmma_step <= '1';
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                             rf1_rd_data_port_a, rf1_rd_data_port_b,
                                             tc0_C1_chain_pair00_a, tc0_C1_chain_pair00_b,
                                             tc1_C1_chain_pair00_a, tc1_C1_chain_pair00_b );
            wait until rising_edge(clk);
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                             rf1_rd_data_port_a, rf1_rd_data_port_b,
                                             tc0_C1_chain_pair01_a, tc0_C1_chain_pair01_b,
                                             tc1_C1_chain_pair01_a, tc1_C1_chain_pair01_b );
            wait until rising_edge(clk);
            
            clear_wrapper_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                   rf1_rd_data_port_a, rf1_rd_data_port_b );
            
            capture_step1_outputs(W0_tc0_oct0_32_X3, W1_tc0_oct0_32_X3, W0_tc0_oct1_32_X3, W1_tc0_oct1_32_X3,
                                  W0_tc1_oct0_32_X3, W1_tc1_oct0_32_X3, W0_tc1_oct1_32_X3, W1_tc1_oct1_32_X3,
                                  D01_set2_step1, D11_set2_step1, D21_set2_step1, D31_set2_step1,
                                  D03_set2_step1, D13_set2_step1, D23_set2_step1, D33_set2_step1 );
            
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop;
            
            wait until rising_edge(clk);
            
            --SET 3
            
            build_accumulator_blocks_from_previous_results(
                D00_set2_step0, D10_set2_step0, D01_set2_step1, D11_set2_step1,
                D20_set2_step0, D30_set2_step0, D21_set2_step1, D31_set2_step1,                
                tc0_C0_chain_pair00_a, tc0_C0_chain_pair00_b, tc0_C0_chain_pair01_a, tc0_C0_chain_pair01_b,
                tc0_C1_chain_pair00_a, tc0_C1_chain_pair00_b, tc0_C1_chain_pair01_a, tc0_C1_chain_pair01_b            
            );
            
             build_accumulator_blocks_from_previous_results(
                D02_set2_step0, D12_set2_step0, D03_set2_step1, D13_set2_step1,
                D22_set2_step0, D32_set2_step0, D23_set2_step1, D33_set2_step1,                
                tc1_C0_chain_pair00_a, tc1_C0_chain_pair00_b, tc1_C0_chain_pair01_a, tc1_C0_chain_pair01_b,
                tc1_C1_chain_pair00_a, tc1_C1_chain_pair00_b, tc1_C1_chain_pair01_a, tc1_C1_chain_pair01_b           
            );
            
            --HMMA step0
            clear_wrapper_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b,
                                   rf1_rd_data_port_a, rf1_rd_data_port_b );
            
            hmma_step <= '0';
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                             rf1_rd_data_port_a, rf1_rd_data_port_b,
                                             tc0_A3_pair00_a, tc0_A3_pair00_b,
                                             tc1_A3_pair00_a, tc1_A3_pair00_b);
            wait until rising_edge(clk);
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                             rf1_rd_data_port_a, rf1_rd_data_port_b,
                                             tc0_A3_pair01_a, tc0_A3_pair01_b,
                                             tc1_A3_pair01_a, tc1_A3_pair01_b);
            wait until rising_edge(clk);
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                             rf1_rd_data_port_a, rf1_rd_data_port_b, 
                                             tc0_B3_pair00_a, tc0_B3_pair00_b,
                                             tc1_B3_pair00_a, tc1_B3_pair00_b);
            wait until rising_edge(clk);
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                             rf1_rd_data_port_a, rf1_rd_data_port_b, 
                                             tc0_B3_pair01_a, tc0_B3_pair01_b,
                                             tc1_B3_pair01_a, tc1_B3_pair01_b);
            wait until rising_edge(clk);
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                    rf1_rd_data_port_a, rf1_rd_data_port_b,
                                    tc0_C0_chain_pair00_a, tc0_C0_chain_pair00_b,
                                    tc1_C0_chain_pair00_a, tc1_C0_chain_pair00_b);
            wait until rising_edge(clk); 
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                                    rf1_rd_data_port_a, rf1_rd_data_port_b,
                                    tc0_C0_chain_pair01_a, tc0_C0_chain_pair01_b,
                                    tc1_C0_chain_pair01_a, tc1_C0_chain_pair01_b);
            wait until rising_edge(clk); 
            
            clear_wrapper_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b, 
                           rf1_rd_data_port_a, rf1_rd_data_port_b );
            
            capture_step0_outputs(W0_tc0_oct0_32_X3, W1_tc0_oct0_32_X3, W0_tc0_oct1_32_X3, W1_tc0_oct1_32_X3,
                                  W0_tc1_oct0_32_X3, W1_tc1_oct0_32_X3, W0_tc1_oct1_32_X3, W1_tc1_oct1_32_X3,
                                  D00_set3_step0, D10_set3_step0, D20_set3_step0, D30_set3_step0,
                                  D02_set3_step0, D12_set3_step0, D22_set3_step0, D32_set3_step0 );
            
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop;
            
            wait until rising_edge(clk);
            
            --HMMA step1
            clear_wrapper_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b,
                           rf1_rd_data_port_a, rf1_rd_data_port_b );
            
            hmma_step <= '1';
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b,
                                    rf1_rd_data_port_a, rf1_rd_data_port_b, 
                                    tc0_C1_chain_pair00_a, tc0_C1_chain_pair00_b,
                                    tc1_C1_chain_pair00_a, tc1_C1_chain_pair00_b );
            wait until rising_edge(clk);
            
            drive_wrapper_blocks_to_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b,
                                    rf1_rd_data_port_a, rf1_rd_data_port_b, 
                                    tc0_C1_chain_pair01_a, tc0_C1_chain_pair01_b,
                                    tc1_C1_chain_pair01_a, tc1_C1_chain_pair01_b );
            wait until rising_edge(clk);
            
            clear_wrapper_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b,
                           rf1_rd_data_port_a, rf1_rd_data_port_b );
            
            capture_step1_outputs(W0_tc0_oct0_32_X3, W1_tc0_oct0_32_X3, W0_tc0_oct1_32_X3, W1_tc0_oct1_32_X3,
                                  W0_tc1_oct0_32_X3, W1_tc1_oct0_32_X3, W0_tc1_oct1_32_X3, W1_tc1_oct1_32_X3,
                                  D01_set3_step1, D11_set3_step1, D21_set3_step1, D31_set3_step1,
                                  D03_set3_step1, D13_set3_step1, D23_set3_step1, D33_set3_step1 );
            
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop;
            
            wait until rising_edge(clk);
            
            --dump results
            
            write_set_result(tb_out_file, 0,
                             D00_set0_step0, D10_set0_step0, D01_set0_step1, D11_set0_step1, 
                             D20_set0_step0, D30_set0_step0, D21_set0_step1, D31_set0_step1,
                             D02_set0_step0, D12_set0_step0, D03_set0_step1, D13_set0_step1,
                             D22_set0_step0, D32_set0_step0, D23_set0_step1, D33_set0_step1 );
            
            write_set_result(tb_out_file, 1, 
                             D00_set1_step0, D10_set1_step0, D01_set1_step1, D11_set1_step1,
                             D20_set1_step0, D30_set1_step0, D21_set1_step1, D31_set1_step1,
                             D02_set1_step0, D12_set1_step0, D03_set1_step1, D13_set1_step1,
                             D22_set1_step0, D32_set1_step0, D23_set1_step1, D33_set1_step1 );
            
            write_set_result(tb_out_file, 2,
                             D00_set2_step0, D10_set2_step0, D01_set2_step1, D11_set2_step1,
                             D20_set2_step0, D30_set2_step0, D21_set2_step1, D31_set2_step1,
                             D02_set2_step0, D12_set2_step0, D03_set2_step1, D13_set2_step1,
                             D22_set2_step0, D32_set2_step0, D23_set2_step1, D33_set2_step1 );
            
            write_set_result(tb_out_file, 3,
                             D00_set3_step0, D10_set3_step0, D01_set3_step1, D11_set3_step1,
                             D20_set3_step0, D30_set3_step0, D21_set3_step1, D31_set3_step1,
                             D02_set3_step0, D12_set3_step0, D03_set3_step1, D13_set3_step1,
                             D22_set3_step0, D32_set3_step0, D23_set3_step1, D33_set3_step1 );
            
            write_final_16x16_result(
                tb_out_file,
                D00_set3_step0, D10_set3_step0, D20_set3_step0, D30_set3_step0,
                D01_set3_step1, D11_set3_step1, D21_set3_step1, D31_set3_step1,
                D02_set3_step0, D12_set3_step0, D22_set3_step0, D32_set3_step0,
                D03_set3_step1, D13_set3_step1, D23_set3_step1, D33_set3_step1 );
            
            report "Completed chained HMMA FP32 dualtensorCoreTop test #" & integer'image(test_idx);
          
            clear_wrapper_rf_ports(rf0_rd_data_port_a, rf0_rd_data_port_b,
                                   rf1_rd_data_port_a, rf1_rd_data_port_b);
            wait for CLK_PERIOD;
       
        end loop;
        
        wait for 5*CLK_PERIOD;
        assert false
            report "End of file reached. End of dualtensorCoreTop FP32 chained testbench."
            severity failure;
    end process;
    
end sim;   