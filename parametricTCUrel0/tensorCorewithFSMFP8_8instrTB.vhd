library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.dpuArray_package.all;

entity tensorCorewithFSMFP8_4setsOfstep01_tb is
end tensorCorewithFSMFP8_4setsOfstep01_tb; 

-- Testbench for FP8 HMMA execution on tensorCoreTop.
-- It verifies 4 chained sets of HMMA step0/step1 operations executed in parallel
-- on 2 octects (16 lanes total), with set0 using external C inputs and sets 1..3
-- reusing the previously computed results as accumulator inputs.

architecture sim of tensorCorewithFSMFP8_4setsOfstep01_tb is

    --dut generics
    constant LANES : integer := 16;
    constant REG_W  : integer := 32;
    constant ELEM_W : integer := 32;
    
    --clock/config
    constant CLK_PERIOD : time := 10 ns;
    constant WIDTH_FP8 : std_logic_vector(1 downto 0) := "00";
    constant TYPE_FP    : std_logic_vector(2 downto 0) := "000";
    
    --dut signals
    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1';
    signal start      : std_logic := '0';
    signal hmma_step  : std_logic := '0';  -- 0=HMMA step0, 1=HMMA step1
    
    signal widthSel : std_logic_vector(1 downto 0) := (others => '0');
    signal typeSel  : std_logic_vector(2 downto 0) := (others => '0');
    
    signal rf_rd_data_port_a : arraySize16_32;
    signal rf_rd_data_port_b : arraySize16_32;
    
    --octect0 signals for its outputs
    signal W0_oct0_8_X3  : arraySize4_8;
    signal W1_oct0_8_X3  : arraySize4_8;
    signal W0_oct0_16_X3 : arraySize4_16;
    signal W1_oct0_16_X3 : arraySize4_16;
    signal W0_oct0_32_X3 : arraySize4_32;
    signal W1_oct0_32_X3 : arraySize4_32;
    
    --octect1 signals for its outputs
    signal W0_oct1_8_X3  : arraySize4_8;
    signal W1_oct1_8_X3  : arraySize4_8;
    signal W0_oct1_16_X3 : arraySize4_16;
    signal W1_oct1_16_X3 : arraySize4_16;
    signal W0_oct1_32_X3 : arraySize4_32;
    signal W1_oct1_32_X3 : arraySize4_32;
    
    signal busy      : std_logic;
    signal done      : std_logic;
    signal step_done : std_logic;
    
    --tb-only types
    type matrix4x4_fp8_t is array (0 to 3, 0 to 3) of std_logic_vector(7 downto 0);
    type lane_block16_t     is array (0 to 15) of std_logic_vector(31 downto 0);
    
    --related input and output files of tb
    file tb_file : text open read_mode is
        "C:/Users/giovi/OneDrive/Desktop/Magistrale/Tesi/parametricTCUrel0/parametricTCUtestingScripts/4SetsOfHMMAstep0step1/fp8related/hmma_8instr_2octects_fp8_single_experiment_tb_input.txt";

    file tb_out_file : text open write_mode is
        "C:/Users/giovi/OneDrive/Desktop/Magistrale/Tesi/parametricTCUrel0/parametricTCUtestingScripts/4SetsOfHMMAstep0step1/fp8related/hmma_8instr_2octects_tb_output_ctrl_fp8.txt";
    
    --helper procedures

--1
    procedure clear_rf_ports(
        signal port_a : out arraySize16_32;
        signal port_b : out arraySize16_32
    ) is
    begin
        port_a <= (others => (others => '0'));
        port_b <= (others => (others => '0'));
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
    procedure drive_block_to_rf_ports(
        signal port_a : out arraySize16_32;
        signal port_b : out arraySize16_32;
        variable block_a : in lane_block16_t;
        variable block_b : in lane_block16_t
    ) is
    begin
        for i in 0 to 15 loop
            port_a(i) <= block_a(i);
            port_b(i) <= block_b(i);
        end loop;
    end procedure;

--5
    procedure write_matrix4x4_hex(
        file f : text;
        constant M : in matrix4x4_fp8_t
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
        variable M : out matrix4x4_fp8_t
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
        constant M      : in matrix4x4_fp8_t;
        constant base_lane : in integer;  -- the top threadgroup uses base_lane = 0, for bottom threadgroup use base_lane =4 inside the local 8lane block
                                          -- rapresentation because your lane block is indexed 0 to 7.
        variable block_a : inout lane_block16_t;
        variable block_b : inout lane_block16_t
    ) is
    begin
        for r in 0 to 3 loop
            --fp8 packing
            --portA = [ M(r,3) M(r,2) M(r,1) M(r,0) ]
            block_a(base_lane + r) := M(r,3) & M(r,2) & M(r,1) & M(r,0);
            block_b(base_lane + r) := x"00000000";
        end loop;
    end procedure;
    
--9
    procedure build_accumulator_blocks_from_previous_results(
    --related to octect 0 outputs
        constant prev_D00 : in matrix4x4_fp8_t ;
        constant prev_D10 : in matrix4x4_fp8_t ;
        constant prev_D01 : in matrix4x4_fp8_t ;
        constant prev_D11 : in matrix4x4_fp8_t ;
    --related to octect 1 outputs
        constant prev_D20 : in matrix4x4_fp8_t ;
        constant prev_D30 : in matrix4x4_fp8_t ;
        constant prev_D21 : in matrix4x4_fp8_t ;
        constant prev_D31 : in matrix4x4_fp8_t ;
        
        variable C0_blk_a : out lane_block16_t ;
        variable C0_blk_b : out lane_block16_t ;
        variable C1_blk_a : out lane_block16_t ;
        variable C1_blk_b : out lane_block16_t 
    ) is 
        variable tmp_C0_a : lane_block16_t;
        variable tmp_C0_b : lane_block16_t;
        variable tmp_C1_a : lane_block16_t;
        variable tmp_C1_b : lane_block16_t;
    begin 
        clear_lane_block16(tmp_C0_a, tmp_C0_b);
        clear_lane_block16(tmp_C1_a, tmp_C1_b);
        
        --step0 accumulators: 
        
        --octect 0: lanes 0..3 top, 4..7 bottom 
        matrix4x4_to_lane_block16(prev_D00, 0, tmp_C0_a, tmp_C0_b);
        matrix4x4_to_lane_block16(prev_D10, 4, tmp_C0_a, tmp_C0_b);
        
        --octect 1: lanes 8..11 top, 12..15 bottom 
        matrix4x4_to_lane_block16(prev_D20, 8, tmp_C0_a, tmp_C0_b);
        matrix4x4_to_lane_block16(prev_D30, 12, tmp_C0_a, tmp_C0_b);
        
        --step1 accumulators: 
        matrix4x4_to_lane_block16(prev_D01, 0, tmp_C1_a, tmp_C1_b);
        matrix4x4_to_lane_block16(prev_D11, 4, tmp_C1_a, tmp_C1_b);
        matrix4x4_to_lane_block16(prev_D21, 8, tmp_C1_a, tmp_C1_b);
        matrix4x4_to_lane_block16(prev_D31, 12, tmp_C1_a, tmp_C1_b);
        
        C0_blk_a := tmp_C0_a ;
        C0_blk_b := tmp_C0_b ;
        C1_blk_a := tmp_C1_a ;
        C1_blk_b := tmp_C1_b ;
        
    end procedure;
    
--10
    procedure capture_step0_outputs(
        signal W0_oct0_8_X3 : in arraySize4_8;
        signal W1_oct0_8_X3 : in arraySize4_8;
        signal W0_oct1_8_X3 : in arraySize4_8;
        signal W1_oct1_8_X3 : in arraySize4_8;
        variable D00    : out matrix4x4_fp8_t;
        variable D10    : out matrix4x4_fp8_t;
        variable D20    : out matrix4x4_fp8_t;
        variable D30    : out matrix4x4_fp8_t
    ) is
    begin
        wait until falling_edge(clk);
        for c in 0 to 3 loop
            D00(0, c) := W0_oct0_8_X3(c);
            D10(0, c) := W1_oct0_8_X3(c);
            D20(0, c) := W0_oct1_8_X3(c);
            D30(0, c) := W1_oct1_8_X3(c);
        end loop;
        
        wait until falling_edge(clk);
        for c in 0 to 3 loop
            D00(1, c) := W0_oct0_8_X3(c);
            D10(1, c) := W1_oct0_8_X3(c);
            D20(1, c) := W0_oct1_8_X3(c);
            D30(1, c) := W1_oct1_8_X3(c);
        end loop;
        
        wait until falling_edge(clk);
        for c in 0 to 3 loop
            D00(2, c) := W0_oct0_8_X3(c);
            D10(2, c) := W1_oct0_8_X3(c);
            D20(2, c) := W0_oct1_8_X3(c);
            D30(2, c) := W1_oct1_8_X3(c);
        end loop;
        
        wait until falling_edge(clk);
        for c in 0 to 3 loop
            D00(3, c) := W0_oct0_8_X3(c);
            D10(3, c) := W1_oct0_8_X3(c);
            D20(3, c) := W0_oct1_8_X3(c);
            D30(3, c) := W1_oct1_8_X3(c);
        end loop;
    end procedure;
    
--11
    procedure capture_step1_outputs(
        signal W0_oct0_8_X3 : in arraySize4_8;
        signal W1_oct0_8_X3 : in arraySize4_8;
        signal W0_oct1_8_X3 : in arraySize4_8;
        signal W1_oct1_8_X3 : in arraySize4_8;
        variable D01 : out matrix4x4_fp8_t;
        variable D11 : out matrix4x4_fp8_t;
        variable D21 : out matrix4x4_fp8_t;
        variable D31 : out matrix4x4_fp8_t
    ) is
    begin
        wait until falling_edge(clk);
        for c in 0 to 3 loop
            D01(0, c) := W0_oct0_8_X3(c);
            D11(0, c) := W1_oct0_8_X3(c);
            D21(0, c) := W0_oct1_8_X3(c);
            D31(0, c) := W1_oct1_8_X3(c);
        end loop;
        
        wait until falling_edge(clk);
        for c in 0 to 3 loop
            D01(1, c) := W0_oct0_8_X3(c);
            D11(1, c) := W1_oct0_8_X3(c);
            D21(1, c) := W0_oct1_8_X3(c);
            D31(1, c) := W1_oct1_8_X3(c);
        end loop;
        
        wait until falling_edge(clk);
        for c in 0 to 3 loop
            D01(2, c) := W0_oct0_8_X3(c);
            D11(2, c) := W1_oct0_8_X3(c);
            D21(2, c) := W0_oct1_8_X3(c);
            D31(2, c) := W1_oct1_8_X3(c);
        end loop;
        
        wait until falling_edge(clk);
        for c in 0 to 3 loop
            D01(3, c) := W0_oct0_8_X3(c);
            D11(3, c) := W1_oct0_8_X3(c);
            D21(3, c) := W0_oct1_8_X3(c);
            D31(3, c) := W1_oct1_8_X3(c);
        end loop;
    end procedure;
    
--12
     procedure write_set_result(
        file f : text;
        constant set_idx    : in integer;
        constant D00_step0  : in matrix4x4_fp8_t;
        constant D10_step0  : in matrix4x4_fp8_t;
        constant D01_step1  : in matrix4x4_fp8_t;
        constant D11_step1  : in matrix4x4_fp8_t;
        constant D20_step0  : in matrix4x4_fp8_t;
        constant D30_step0  : in matrix4x4_fp8_t;
        constant D21_step1  : in matrix4x4_fp8_t;
        constant D31_step1  : in matrix4x4_fp8_t
    ) is
        variable L : line;
    begin
        L := null;
        write(L, string'("#SET "));
        write(L, set_idx);
        write(L, string'(" results"));
        writeline(f, L);

        L := null; write(L, string'("#STEP0_D00")); writeline(f, L);
        write_matrix4x4_hex(f, D00_step0);

        L := null; write(L, string'("#STEP0_D10")); writeline(f, L);
        write_matrix4x4_hex(f, D10_step0);

        L := null; write(L, string'("#STEP1_D01")); writeline(f, L);
        write_matrix4x4_hex(f, D01_step1);

        L := null; write(L, string'("#STEP1_D11")); writeline(f, L);
        write_matrix4x4_hex(f, D11_step1);

        L := null; write(L, string'("#STEP0_D20")); writeline(f, L);
        write_matrix4x4_hex(f, D20_step0);

        L := null; write(L, string'("#STEP0_D30")); writeline(f, L);
        write_matrix4x4_hex(f, D30_step0);

        L := null; write(L, string'("#STEP1_D21")); writeline(f, L);
        write_matrix4x4_hex(f, D21_step1);

        L := null; write(L, string'("#STEP1_D31")); writeline(f, L);
        write_matrix4x4_hex(f, D31_step1);

        L := null;
        writeline(f, L);
    end procedure;
    
--13
    procedure write_final_16x8_result(
    file f : text;
    constant D00 : in matrix4x4_fp8_t;
    constant D10 : in matrix4x4_fp8_t;
    constant D01 : in matrix4x4_fp8_t;
    constant D11 : in matrix4x4_fp8_t;
    constant D20 : in matrix4x4_fp8_t;
    constant D30 : in matrix4x4_fp8_t;
    constant D21 : in matrix4x4_fp8_t;
    constant D31 : in matrix4x4_fp8_t
    ) is
    variable L : line;
    begin
        L := null;
        write(L, string'("#FINAL_16x8_RESULT"));
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
            hwrite(L, D01(r,3));
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
            hwrite(L, D11(r,3));
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
            hwrite(L, D21(r,3));
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
            hwrite(L, D31(r,3));
            writeline(f, L);
        end loop;

        L := null;
        writeline(f, L);
    end procedure;
    
begin
    
    --clock
    clk <= not clk after CLK_PERIOD/2;
    
    --dut
    dut : entity work.tensorCoreTop
        generic map(
            LANES  => LANES,
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

            rf_rd_data_port_a => rf_rd_data_port_a,
            rf_rd_data_port_b => rf_rd_data_port_b,

            W0_oct0_8_X3  => W0_oct0_8_X3,
            W1_oct0_8_X3  => W1_oct0_8_X3,
            W0_oct0_16_X3 => W0_oct0_16_X3,
            W1_oct0_16_X3 => W1_oct0_16_X3,
            W0_oct0_32_X3 => W0_oct0_32_X3,
            W1_oct0_32_X3 => W1_oct0_32_X3,
            
            W0_oct1_8_X3  => W0_oct1_8_X3,
            W1_oct1_8_X3  => W1_oct1_8_X3,
            W0_oct1_16_X3 => W0_oct1_16_X3,
            W1_oct1_16_X3 => W1_oct1_16_X3,
            W0_oct1_32_X3 => W0_oct1_32_X3,
            W1_oct1_32_X3 => W1_oct1_32_X3,

            busy      => busy,
            done      => done,
            step_done => step_done
        );
        
        --stimulus
        
        stim_process : process
            variable have_data : boolean;
            variable test_idx  : integer := 0;
            
            --set 0 blocks
            variable A0_blk_a  : lane_block16_t;
            variable A0_blk_b  : lane_block16_t;
            variable B0_blk_a  : lane_block16_t;
            variable B0_blk_b  : lane_block16_t;
            variable C0_blk_a  : lane_block16_t;
            variable C0_blk_b  : lane_block16_t;
            variable C1_blk_a  : lane_block16_t;
            variable C1_blk_b  : lane_block16_t;
            
            --set 1/2/3 filedriven A/B blocks
            variable A1_blk_a : lane_block16_t;
            variable A1_blk_b : lane_block16_t;
            variable B1_blk_a : lane_block16_t;
            variable B1_blk_b : lane_block16_t;
            
            variable A2_blk_a : lane_block16_t;
            variable A2_blk_b : lane_block16_t;
            variable B2_blk_a : lane_block16_t;
            variable B2_blk_b : lane_block16_t;
            
            variable A3_blk_a : lane_block16_t;
            variable A3_blk_b : lane_block16_t;
            variable B3_blk_a : lane_block16_t;
            variable B3_blk_b : lane_block16_t;
            
            --reconstructed accumulators for later sets
            variable C0_chain_a : lane_block16_t;
            variable C0_chain_b : lane_block16_t;
            variable C1_chain_a : lane_block16_t;
            variable C1_chain_b : lane_block16_t;
            
            --outputs set 0
            --octect0
            variable D00_set0_step0 : matrix4x4_fp8_t;
            variable D10_set0_step0 : matrix4x4_fp8_t;
            variable D01_set0_step1 : matrix4x4_fp8_t;
            variable D11_set0_step1 : matrix4x4_fp8_t;
            --octect1
            variable D20_set0_step0 : matrix4x4_fp8_t;
            variable D30_set0_step0 : matrix4x4_fp8_t;
            variable D21_set0_step1 : matrix4x4_fp8_t;
            variable D31_set0_step1 : matrix4x4_fp8_t;
            
            --outputs set 1
            --octect 0
            variable D00_set1_step0 : matrix4x4_fp8_t;
            variable D10_set1_step0 : matrix4x4_fp8_t;
            variable D01_set1_step1 : matrix4x4_fp8_t;
            variable D11_set1_step1 : matrix4x4_fp8_t;
            --octect 1
            variable D20_set1_step0 : matrix4x4_fp8_t;
            variable D30_set1_step0 : matrix4x4_fp8_t;
            variable D21_set1_step1 : matrix4x4_fp8_t;
            variable D31_set1_step1 : matrix4x4_fp8_t;
            
            --outputs set 2
            --octect 0
            variable D00_set2_step0 : matrix4x4_fp8_t;
            variable D10_set2_step0 : matrix4x4_fp8_t;
            variable D01_set2_step1 : matrix4x4_fp8_t;
            variable D11_set2_step1 : matrix4x4_fp8_t;
            --octect 1
            variable D20_set2_step0 : matrix4x4_fp8_t;
            variable D30_set2_step0 : matrix4x4_fp8_t;
            variable D21_set2_step1 : matrix4x4_fp8_t;
            variable D31_set2_step1 : matrix4x4_fp8_t;
            
            --outputs set 3
            --octect 0
            variable D00_set3_step0 : matrix4x4_fp8_t;
            variable D10_set3_step0 : matrix4x4_fp8_t;
            variable D01_set3_step1 : matrix4x4_fp8_t;
            variable D11_set3_step1 : matrix4x4_fp8_t;
            --octect 1
            variable D20_set3_step0 : matrix4x4_fp8_t;
            variable D30_set3_step0 : matrix4x4_fp8_t;
            variable D21_set3_step1 : matrix4x4_fp8_t;
            variable D31_set3_step1 : matrix4x4_fp8_t;
            
        begin
        
        --initial setup
        widthSel <= WIDTH_FP8;
        typeSel <= TYPE_FP;
        start       <= '0';
        hmma_step  <= '0';
        clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
        
        --reset
        wait for 3 * CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;
        
        while true loop
            test_idx := test_idx + 1;
            
            clear_matrix4x4(D00_set0_step0); clear_matrix4x4(D10_set0_step0);
            clear_matrix4x4(D01_set0_step1); clear_matrix4x4(D11_set0_step1);
            clear_matrix4x4(D20_set0_step0); clear_matrix4x4(D30_set0_step0);
            clear_matrix4x4(D21_set0_step1); clear_matrix4x4(D31_set0_step1);
            
            clear_matrix4x4(D00_set1_step0); clear_matrix4x4(D10_set1_step0);
            clear_matrix4x4(D01_set1_step1); clear_matrix4x4(D11_set1_step1);
            clear_matrix4x4(D20_set1_step0); clear_matrix4x4(D30_set1_step0);
            clear_matrix4x4(D21_set1_step1); clear_matrix4x4(D31_set1_step1);
            
            clear_matrix4x4(D00_set2_step0); clear_matrix4x4(D10_set2_step0);
            clear_matrix4x4(D01_set2_step1); clear_matrix4x4(D11_set2_step1);
            clear_matrix4x4(D20_set2_step0); clear_matrix4x4(D30_set2_step0);
            clear_matrix4x4(D21_set2_step1); clear_matrix4x4(D31_set2_step1);
            
            clear_matrix4x4(D00_set3_step0); clear_matrix4x4(D10_set3_step0);
            clear_matrix4x4(D01_set3_step1); clear_matrix4x4(D11_set3_step1);
            clear_matrix4x4(D20_set3_step0); clear_matrix4x4(D30_set3_step0);
            clear_matrix4x4(D21_set3_step1); clear_matrix4x4(D31_set3_step1);
            
            --READ one COMPLETE SINGLE EXPERIMENT
            
            --set 0
            read_16_lanes_into_block(tb_file, A0_blk_a, A0_blk_b, have_data);
            exit when not have_data;
            
            read_16_lanes_into_block(tb_file, B0_blk_a, B0_blk_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set0 B block" severity failure;

            read_16_lanes_into_block(tb_file, C0_blk_a, C0_blk_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set0 C0 block" severity failure;
                
            read_16_lanes_into_block(tb_file, C1_blk_a, C1_blk_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set0 C1 block" severity failure;
            
            --set 1
            read_16_lanes_into_block(tb_file, A1_blk_a, A1_blk_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set1 A block" severity failure;
            
            read_16_lanes_into_block(tb_file, B1_blk_a, B1_blk_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set1 B block" severity failure;

            --set 2
            read_16_lanes_into_block(tb_file, A2_blk_a, A2_blk_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set2 A block" severity failure;
            
            read_16_lanes_into_block(tb_file, B2_blk_a, B2_blk_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set2 B block" severity failure;
            
            --set 3
            read_16_lanes_into_block(tb_file, A3_blk_a, A3_blk_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set3 A block" severity failure;
            
            read_16_lanes_into_block(tb_file, B3_blk_a, B3_blk_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set3 B block" severity failure;
            
            --SET 0
            
            -- HMMA step0
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
          
            hmma_step <= '0';
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
          
            --feed A
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, A0_blk_a, A0_blk_b);
            wait until rising_edge(clk);
          
            --feed B
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, B0_blk_a, B0_blk_b);
            wait until rising_edge(clk);
          
            --feed C0
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C0_blk_a, C0_blk_b);
            wait until rising_edge(clk);
          
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            capture_step0_outputs(W0_oct0_8_X3, W1_oct0_8_X3,
                                  W0_oct1_8_X3, W1_oct1_8_X3,
                                  D00_set0_step0, D10_set0_step0,
                                  D20_set0_step0, D30_set0_step0);
            
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop;
            
            wait until rising_edge(clk);
            
            --HMMA step 1
          
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
          
            hmma_step <= '1';
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
          
            --feed only C1
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C1_blk_a, C1_blk_b);
            wait until rising_edge(clk);
          
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            capture_step1_outputs(W0_oct0_8_X3, W1_oct0_8_X3,
                                  W0_oct1_8_X3, W1_oct1_8_X3,
                                  D01_set0_step1, D11_set0_step1,
                                  D21_set0_step1, D31_set0_step1 );
                        
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop;
            
            wait until rising_edge(clk);
            
            --SET 1
            build_accumulator_blocks_from_previous_results(
                D00_set0_step0, D10_set0_step0, D01_set0_step1, D11_set0_step1,
                D20_set0_step0, D30_set0_step0, D21_set0_step1, D31_set0_step1,
                C0_chain_a, C0_chain_b, C1_chain_a, C1_chain_b
            );
            
            --HMMA step0
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            hmma_step <= '0';
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, A1_blk_a, A1_blk_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, B1_blk_a, B1_blk_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C0_chain_a, C0_chain_b);
            wait until rising_edge(clk);
            
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            capture_step0_outputs(W0_oct0_8_X3, W1_oct0_8_X3,
                                  W0_oct1_8_X3, W1_oct1_8_X3,
                                  D00_set1_step0, D10_set1_step0,
                                  D20_set1_step0, D30_set1_step0 );
            
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop;
            
            wait until rising_edge(clk);
            
            --HMMA step1
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            hmma_step <= '1';
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C1_chain_a, C1_chain_b);
            wait until rising_edge(clk);
            
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            capture_step1_outputs(W0_oct0_8_X3, W1_oct0_8_X3,
                                  W0_oct1_8_X3, W1_oct1_8_X3,
                                  D01_set1_step1, D11_set1_step1,
                                  D21_set1_step1, D31_set1_step1 );
            
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop;
            
            wait until rising_edge(clk);
            
            --SET 2
            build_accumulator_blocks_from_previous_results(
                D00_set1_step0, D10_set1_step0, D01_set1_step1, D11_set1_step1,
                D20_set1_step0, D30_set1_step0, D21_set1_step1, D31_set1_step1,                
                C0_chain_a, C0_chain_b, C1_chain_a, C1_chain_b
            );
            
            --HMMA step0
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            hmma_step <= '0';
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, A2_blk_a, A2_blk_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, B2_blk_a, B2_blk_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C0_chain_a, C0_chain_b);
            wait until rising_edge(clk);
            
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            capture_step0_outputs(W0_oct0_8_X3, W1_oct0_8_X3,
                                  W0_oct1_8_X3, W1_oct1_8_X3,
                                  D00_set2_step0, D10_set2_step0, 
                                  D20_set2_step0, D30_set2_step0 );
            
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop; 
            
            wait until rising_edge(clk);
            
            --HMMA step1
            
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            hmma_step <= '1';
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C1_chain_a, C1_chain_b);
            wait until rising_edge(clk);
            
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            capture_step1_outputs(W0_oct0_8_X3, W1_oct0_8_X3,
                                  W0_oct1_8_X3, W1_oct1_8_X3,
                                  D01_set2_step1, D11_set2_step1,
                                  D21_set2_step1, D31_set2_step1);
            
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop;
            
            wait until rising_edge(clk);
            
            --SET 3
            
            build_accumulator_blocks_from_previous_results(
                D00_set2_step0, D10_set2_step0, D01_set2_step1, D11_set2_step1,
                D20_set2_step0, D30_set2_step0, D21_set2_step1, D31_set2_step1,                
                C0_chain_a, C0_chain_b, C1_chain_a, C1_chain_b
            );
            
            --HMMA step0
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            hmma_step <= '0';
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, A3_blk_a, A3_blk_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, B3_blk_a, B3_blk_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C0_chain_a, C0_chain_b);
            wait until rising_edge(clk); 
            
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            capture_step0_outputs(W0_oct0_8_X3, W1_oct0_8_X3,
                                  W0_oct1_8_X3, W1_oct1_8_X3,
                                  D00_set3_step0, D10_set3_step0,
                                  D20_set3_step0, D30_set3_step0 );
            
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop;
            
            wait until rising_edge(clk);
            
            --HMMA step1
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            hmma_step <= '1';
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C1_chain_a, C1_chain_b);
            wait until rising_edge(clk);
            
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            capture_step1_outputs(W0_oct0_8_X3, W1_oct0_8_X3,
                                  W0_oct1_8_X3, W1_oct1_8_X3,
                                  D01_set3_step1, D11_set3_step1,
                                  D21_set3_step1, D31_set3_step1);
            
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop;
            
            wait until rising_edge(clk);
            
            --dump results
            
            write_set_result(tb_out_file, 0,
                             D00_set0_step0, D10_set0_step0, D01_set0_step1, D11_set0_step1, 
                             D20_set0_step0, D30_set0_step0, D21_set0_step1, D31_set0_step1 );
            
            write_set_result(tb_out_file, 1, 
                             D00_set1_step0, D10_set1_step0, D01_set1_step1, D11_set1_step1,
                             D20_set1_step0, D30_set1_step0, D21_set1_step1, D31_set1_step1 );
            
            write_set_result(tb_out_file, 2,
                             D00_set2_step0, D10_set2_step0, D01_set2_step1, D11_set2_step1,
                             D20_set2_step0, D30_set2_step0, D21_set2_step1, D31_set2_step1 );
            
            write_set_result(tb_out_file, 3,
                             D00_set3_step0, D10_set3_step0, D01_set3_step1, D11_set3_step1,
                             D20_set3_step0, D30_set3_step0, D21_set3_step1, D31_set3_step1 );
            
            write_final_16x8_result(
                tb_out_file,
                D00_set3_step0, D10_set3_step0, 
                D01_set3_step1, D11_set3_step1,
                D20_set3_step0, D30_set3_step0,
                D21_set3_step1, D31_set3_step1
            );
            
            report "Completed chained HMMA FP8 tensorCoreTop test #" & integer'image(test_idx);
          
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            wait for CLK_PERIOD;
       
        end loop;
        
        wait for 5*CLK_PERIOD;
        assert false
            report "End of file reached. End of tensorCoreTop FP8 chained testbench."
            severity failure;
    end process;
    
end sim;   