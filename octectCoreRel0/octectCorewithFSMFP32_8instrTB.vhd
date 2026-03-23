library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.dpuArray_package.all;

entity octectCorewithFSMFP32_4setsOfstep01_tb is
end octectCorewithFSMFP32_4setsOfstep01_tb; 

-- testbench for FP32 operands:
-- executes 4 chained sets of HMMA step0 + HMMA step1 instructions
-- on the singular octect-related hardware
--
-- FP32 loading convention:
-- each 4x4 submatrix is loaded in 2 cycles:
--   pair00 -> columns 0,1
--   pair01 -> columns 2,3
--
-- step0 loads: A(pair00,pair01), B(pair00,pair01), C0(pair00,pair01)
-- step1 loads: only C1(pair00,pair01)
--
-- sets 1..3 use accumulator inputs reconstructed from previous results.

architecture sim of octectCorewithFSMFP32_4setsOfstep01_tb is

    --dut generics
    constant LANES : integer := 8;
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
    
    signal rf_rd_data_port_a : arraySize8_32;
    signal rf_rd_data_port_b : arraySize8_32;
    
    signal W0_8_X3  : arraySize4_8;
    signal W1_8_X3  : arraySize4_8;
    signal W0_16_X3 : arraySize4_16;
    signal W1_16_X3 : arraySize4_16;
    signal W0_32_X3 : arraySize4_32;
    signal W1_32_X3 : arraySize4_32;
    
    signal busy      : std_logic;
    signal done      : std_logic;
    signal step_done : std_logic;
    
    --tb-only types
    type matrix4x4_fp32_t is array (0 to 3, 0 to 3) of std_logic_vector(31 downto 0);
    type lane_block_t     is array (0 to 7) of std_logic_vector(31 downto 0);
    
    --related input and output files of tb
    file tb_file : text open read_mode is
        "C:/Users/giovi/OneDrive/Desktop/Magistrale/Tesi/octectCoreRel0/scritptsRelatedToOctectCoreTopTests/4SetsOfHMMAstep0step1/fp32related/hmma_8instr_fp32_single_experiment_tb_input.txt";

    file tb_out_file : text open write_mode is
        "C:/Users/giovi/OneDrive/Desktop/Magistrale/Tesi/octectCoreRel0/scritptsRelatedToOctectCoreTopTests/4SetsOfHMMAstep0step1/fp32related/hmma_8instr_tb_output_ctrl_fp32.txt";
    
    --helper procedures

--1
    procedure clear_rf_ports(
        signal port_a : out arraySize8_32;
        signal port_b : out arraySize8_32
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
    procedure read_8_lanes_into_block(
        file f : text;
        variable block_a : out lane_block_t;
        variable block_b : out lane_block_t;
        variable success : out boolean
    ) is
        variable v_a : std_logic_vector(31 downto 0);
        variable v_b : std_logic_vector(31 downto 0);
        variable ok  : boolean;
    begin
        success := false;

        for i in 0 to 7 loop
            read_next_port_pair(f, v_a, v_b, ok);

            if not ok then
                if i = 0 then
                    return;
                else
                    assert false
                        report "Unexpected EOF while reading 8-lane block from stimulus file"
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
        signal port_a : out arraySize8_32;
        signal port_b : out arraySize8_32;
        variable block_a : in lane_block_t;
        variable block_b : in lane_block_t
    ) is
    begin
        for i in 0 to 7 loop
            port_a(i) <= block_a(i);
            port_b(i) <= block_b(i);
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
    procedure write_set_result(
        file f:text;
        constant set_idx : in integer;
        constant D00_step0 : in matrix4x4_fp32_t;
        constant D10_step0 : in matrix4x4_fp32_t;
        constant D01_step1 : in matrix4x4_fp32_t;
        constant D11_step1 : in matrix4x4_fp32_t
    ) is
        variable L : line;
    begin
        L := null;
        write(L, string'("#SET "));
        write(L, set_idx);
        write(L, string'(" results"));
        writeline(f, L);
        
        L := null;
        write(L, string'("#STEP0_D00"));
        writeline(f, L);
        write_matrix4x4_hex(f, D00_step0);
        
        L := null;
        write(L, string'("#STEP0_D10"));
        writeline(f, L);
        write_matrix4x4_hex(f, D10_step0);
        
        L := null;
        write(L, string'("#STEP1_D01"));
        writeline(f, L);
        write_matrix4x4_hex(f, D01_step1);
        
        L := null;
        write(L, string'("#STEP1_D11"));
        writeline(f, L);
        write_matrix4x4_hex(f, D11_step1);
        
        L := null;
        writeline(f, L);
    end procedure;
    
--7
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
    
--8
    procedure clear_lane_block(
        variable block_a : out lane_block_t ;
        variable block_b : out lane_block_t 
    ) is
    begin
        for i in 0 to 7 loop
            block_a(i) := (others => '0');
            block_b(i) := (others => '0');
        end loop;
    end procedure;
    
--9
    procedure matrix4x4_to_lane_block(
        constant M      : in matrix4x4_fp32_t;
        constant base_lane : in integer;  -- the top threadgroup uses base_lane = 0, for bottom threadgroup use base_lane =4 inside the local 8lane block
                                          -- rapresentation because the lane block is indexed 0 to 7.
        variable pair00_a   : inout lane_block_t ;
        variable pair00_b   : inout lane_block_t ;
        variable pair01_a   : inout lane_block_t ;
        variable pair01_b   : inout lane_block_t 
    ) is
    begin
        for r in 0 to 3 loop
            pair00_a(base_lane + r) := M(r,0) ;
            pair00_b(base_lane + r) := M(r,1) ;
            
            pair01_a(base_lane + r) := M(r,2) ;
            pair01_b(base_lane + r) := M(r,3) ;
        end loop;
    end procedure;
    
--10
    procedure build_accumulator_blocks_from_previous_results(
        constant prev_D00 : in matrix4x4_fp32_t ;
        constant prev_D10 : in matrix4x4_fp32_t ;
        constant prev_D01 : in matrix4x4_fp32_t ;
        constant prev_D11 : in matrix4x4_fp32_t ;
        
        variable C0_pair00_a : out lane_block_t ;
        variable C0_pair00_b : out lane_block_t ;
        variable C0_pair01_a : out lane_block_t ;
        variable C0_pair01_b : out lane_block_t ;
        
        variable C1_pair00_a : out lane_block_t ;
        variable C1_pair00_b : out lane_block_t ;
        variable C1_pair01_a : out lane_block_t ;
        variable C1_pair01_b : out lane_block_t 
    ) is 
        variable tmp_C0_pair00_a : lane_block_t ;
        variable tmp_C0_pair00_b : lane_block_t ;
        variable tmp_C0_pair01_a : lane_block_t ;
        variable tmp_C0_pair01_b : lane_block_t ;
        
        variable tmp_C1_pair00_a : lane_block_t ;
        variable tmp_C1_pair00_b : lane_block_t ;
        variable tmp_C1_pair01_a : lane_block_t ;
        variable tmp_C1_pair01_b : lane_block_t ;
        
    begin 
        clear_lane_block(tmp_C0_pair00_a, tmp_C0_pair00_b);
        clear_lane_block(tmp_C0_pair01_a, tmp_C0_pair01_b);
        clear_lane_block(tmp_C1_pair00_a, tmp_C1_pair00_b);
        clear_lane_block(tmp_C1_pair01_a, tmp_C1_pair01_b);
        
        --step0 accumulators: D00 goes to top group, D10 to bottom group
        matrix4x4_to_lane_block(prev_D00, 0, tmp_C0_pair00_a, tmp_C0_pair00_b, tmp_C0_pair01_a, tmp_C0_pair01_b);
        matrix4x4_to_lane_block(prev_D10, 4, tmp_C0_pair00_a, tmp_C0_pair00_b, tmp_C0_pair01_a, tmp_C0_pair01_b);
        
        --step1 accumulators: D01 goes to top group, D11 to bottom group
        matrix4x4_to_lane_block(prev_D01, 0, tmp_C1_pair00_a, tmp_C1_pair00_b, tmp_C1_pair01_a, tmp_C1_pair01_b );
        matrix4x4_to_lane_block(prev_D11, 4, tmp_C1_pair00_a, tmp_C1_pair00_b, tmp_C1_pair01_a, tmp_C1_pair01_b );
        
        C0_pair00_a := tmp_C0_pair00_a ;
        C0_pair00_b := tmp_C0_pair00_b ;
        C0_pair01_a := tmp_C0_pair01_a ;
        C0_pair01_b := tmp_C0_pair01_b ;
        
        C1_pair00_a := tmp_C1_pair00_a ;
        C1_pair00_b := tmp_C1_pair00_b ;
        C1_pair01_a := tmp_C1_pair01_a ;
        C1_pair01_b := tmp_C1_pair01_b ;
        
    end procedure;
    
--11
    procedure capture_step0_outputs(
        signal W0_32_X3 : in arraySize4_32;
        signal W1_32_X3 : in arraySize4_32;
        variable D00    : out matrix4x4_fp32_t;
        variable D10    : out matrix4x4_fp32_t
    ) is
    begin
        wait until falling_edge(clk);
        for c in 0 to 3 loop
            D00(0, c) := W0_32_X3(c);
            D10(0, c) := W1_32_X3(c);
        end loop;
        
        wait until falling_edge(clk);
        for c in 0 to 3 loop
            D00(1, c) := W0_32_X3(c);
            D10(1, c) := W1_32_X3(c);
        end loop;
        
        wait until falling_edge(clk);
        for c in 0 to 3 loop
            D00(2, c) := W0_32_X3(c);
            D10(2, c) := W1_32_X3(c);
        end loop;
        
        wait until falling_edge(clk);
        for c in 0 to 3 loop
            D00(3, c) := W0_32_X3(c);
            D10(3, c) := W1_32_X3(c);
        end loop;
    end procedure;
    
--12
    procedure capture_step1_outputs(
        signal W0_32_X3 : in arraySize4_32;
        signal W1_32_X3 : in arraySize4_32;
        variable D01 : out matrix4x4_fp32_t;
        variable D11 : out matrix4x4_fp32_t
    ) is
    begin
        wait until falling_edge(clk);
        for c in 0 to 3 loop
            D01(0, c) := W0_32_X3(c);
            D11(0, c) := W1_32_X3(c);
        end loop;
        
        wait until falling_edge(clk);
        for c in 0 to 3 loop
            D01(1, c) := W0_32_X3(c);
            D11(1, c) := W1_32_X3(c);
        end loop;
        
        wait until falling_edge(clk);
        for c in 0 to 3 loop
            D01(2, c) := W0_32_X3(c);
            D11(2, c) := W1_32_X3(c);
        end loop;
        
        wait until falling_edge(clk);
        for c in 0 to 3 loop
            D01(3, c) := W0_32_X3(c);
            D11(3, c) := W1_32_X3(c);
        end loop;
    end procedure;
    
--13
    procedure write_final_8x8_quadrant(
        file f : text ;
        constant D00 : in matrix4x4_fp32_t ;
        constant D10 : in matrix4x4_fp32_t ;
        constant D01 : in matrix4x4_fp32_t ;
        constant D11 : in matrix4x4_fp32_t 
    ) is
        variable L : line ;
    begin
        L := null ;
        write(L, string'("#FINAL_8x8_QUADRANT"));
        writeline(f, L);
        
        --rows 0..3 = D00 | D01
        for r in 0 to 3 loop
            L := null;
            hwrite(L, D00(r,0)) ; write(L, string'(" "));
            hwrite(L, D00(r,1)) ; write(L, string'(" "));
            hwrite(L, D00(r,2)) ; write(L, string'(" "));
            hwrite(L, D00(r,3)) ; write(L, string'(" "));
            hwrite(L, D01(r,0)) ; write(L, string'(" "));
            hwrite(L, D01(r,1)) ; write(L, string'(" "));
            hwrite(L, D01(r,2)) ; write(L, string'(" "));
            hwrite(L, D01(r,3)) ; 
            writeline(f,L);
        end loop;
        
        --rows 4..7 = D10 | D11
        for r in 0 to 3 loop
            L := null;
            hwrite(L, D10(r,0)) ; write(L, string'(" "));
            hwrite(L, D10(r,1)) ; write(L, string'(" "));
            hwrite(L, D10(r,2)) ; write(L, string'(" "));
            hwrite(L, D10(r,3)) ; write(L, string'(" "));
            hwrite(L, D11(r,0)) ; write(L, string'(" "));
            hwrite(L, D11(r,1)) ; write(L, string'(" "));
            hwrite(L, D11(r,2)) ; write(L, string'(" "));
            hwrite(L, D11(r,3)) ; 
            writeline(f,L);
        end loop;
        
        L := null;
        writeline(f, L);
    end procedure;
    
begin
    
    --clock
    clk <= not clk after CLK_PERIOD/2;
    
    --dut
    dut : entity work.octectCorewithFSM
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

            W0_8_X3  => W0_8_X3,
            W1_8_X3  => W1_8_X3,
            W0_16_X3 => W0_16_X3,
            W1_16_X3 => W1_16_X3,
            W0_32_X3 => W0_32_X3,
            W1_32_X3 => W1_32_X3,

            busy      => busy,
            done      => done,
            step_done => step_done
        );
        
        --stimulus
        
        stim_process : process
            variable have_data : boolean;
            variable test_idx  : integer := 0;
            
            --set 0 filedriven blocks
            variable A0_pair00_a : lane_block_t ;
            variable A0_pair00_b : lane_block_t ;
            variable A0_pair01_a : lane_block_t ;
            variable A0_pair01_b : lane_block_t ;
            
            variable B0_pair00_a : lane_block_t ;
            variable B0_pair00_b : lane_block_t ;
            variable B0_pair01_a : lane_block_t ;
            variable B0_pair01_b : lane_block_t ;
            
            variable C0_pair00_a : lane_block_t ;
            variable C0_pair00_b : lane_block_t ;
            variable C0_pair01_a : lane_block_t ;
            variable C0_pair01_b : lane_block_t ;
            
            variable C1_pair00_a : lane_block_t ;
            variable C1_pair00_b : lane_block_t ;
            variable C1_pair01_a : lane_block_t ;
            variable C1_pair01_b : lane_block_t ;
            
            --set 1 filedriven A/B 
            variable A1_pair00_a : lane_block_t ;
            variable A1_pair00_b : lane_block_t ;
            variable A1_pair01_a : lane_block_t ;
            variable A1_pair01_b : lane_block_t ;
            
            variable B1_pair00_a : lane_block_t ;
            variable B1_pair00_b : lane_block_t ;
            variable B1_pair01_a : lane_block_t ;
            variable B1_pair01_b : lane_block_t ;
            
            --set 2 filedriven A/B 
            variable A2_pair00_a : lane_block_t;
            variable A2_pair00_b : lane_block_t;
            variable A2_pair01_a : lane_block_t;
            variable A2_pair01_b : lane_block_t;
            
            variable B2_pair00_a : lane_block_t;
            variable B2_pair00_b : lane_block_t;
            variable B2_pair01_a : lane_block_t;
            variable B2_pair01_b : lane_block_t;
            
            --set 3 filedriven A/B 
            variable A3_pair00_a : lane_block_t;
            variable A3_pair00_b : lane_block_t;
            variable A3_pair01_a : lane_block_t;
            variable A3_pair01_b : lane_block_t;
            
            variable B3_pair00_a : lane_block_t;
            variable B3_pair00_b : lane_block_t;
            variable B3_pair01_a : lane_block_t;
            variable B3_pair01_b : lane_block_t;
            
            --reconstructed accumulators for later sets
            variable C0_chain_pair00_a : lane_block_t;
            variable C0_chain_pair00_b : lane_block_t;
            variable C0_chain_pair01_a : lane_block_t;
            variable C0_chain_pair01_b : lane_block_t;
            
            variable C1_chain_pair00_a : lane_block_t;
            variable C1_chain_pair00_b : lane_block_t;
            variable C1_chain_pair01_a : lane_block_t;
            variable C1_chain_pair01_b : lane_block_t;
            
            --outputs set 0
            variable D00_set0_step0 : matrix4x4_fp32_t;
            variable D10_set0_step0 : matrix4x4_fp32_t;
            variable D01_set0_step1 : matrix4x4_fp32_t;
            variable D11_set0_step1 : matrix4x4_fp32_t;
            
            --outputs set 1
            variable D00_set1_step0 : matrix4x4_fp32_t;
            variable D10_set1_step0 : matrix4x4_fp32_t;
            variable D01_set1_step1 : matrix4x4_fp32_t;
            variable D11_set1_step1 : matrix4x4_fp32_t;
            
            --outputs set 2
            variable D00_set2_step0 : matrix4x4_fp32_t;
            variable D10_set2_step0 : matrix4x4_fp32_t;
            variable D01_set2_step1 : matrix4x4_fp32_t;
            variable D11_set2_step1 : matrix4x4_fp32_t;
            
            --outputs set 3
            variable D00_set3_step0 : matrix4x4_fp32_t;
            variable D10_set3_step0 : matrix4x4_fp32_t;
            variable D01_set3_step1 : matrix4x4_fp32_t;
            variable D11_set3_step1 : matrix4x4_fp32_t;
        begin
        
        --initial setup
        widthSel <= WIDTH_FP32;
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
            
            clear_matrix4x4(D00_set0_step0); 
            clear_matrix4x4(D10_set0_step0);
            clear_matrix4x4(D01_set0_step1);
            clear_matrix4x4(D11_set0_step1);
            
            clear_matrix4x4(D00_set1_step0);
            clear_matrix4x4(D10_set1_step0);
            clear_matrix4x4(D01_set1_step1);
            clear_matrix4x4(D11_set1_step1);
            
            clear_matrix4x4(D00_set2_step0);
            clear_matrix4x4(D10_set2_step0);
            clear_matrix4x4(D01_set2_step1);
            clear_matrix4x4(D11_set2_step1);
            
            clear_matrix4x4(D00_set3_step0);
            clear_matrix4x4(D10_set3_step0);
            clear_matrix4x4(D01_set3_step1);
            clear_matrix4x4(D11_set3_step1);
            
            --READ COMPLETE SINGLE EXPERIMENT
            
            --set 0
            read_8_lanes_into_block(tb_file, A0_pair00_a, A0_pair00_b, have_data);
            exit when not have_data;
            
            read_8_lanes_into_block(tb_file, A0_pair01_a, A0_pair01_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set0 A pair01 block" severity failure;
            
            read_8_lanes_into_block(tb_file, B0_pair00_a, B0_pair00_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set0 B pair00 block" severity failure;

            read_8_lanes_into_block(tb_file, B0_pair01_a, B0_pair01_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set0 B pair01 block" severity failure;

            read_8_lanes_into_block(tb_file, C0_pair00_a, C0_pair00_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set0 C0 pair00 block" severity failure;
            
            read_8_lanes_into_block(tb_file, C0_pair01_a, C0_pair01_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set0 C0 pair01 block" severity failure;
                
            read_8_lanes_into_block(tb_file, C1_pair00_a, C1_pair00_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set0 C1 pair00 block" severity failure;
            
            read_8_lanes_into_block(tb_file, C1_pair01_a, C1_pair01_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set0 C1 pair01 block" severity failure;
            
            --set 1
            read_8_lanes_into_block(tb_file, A1_pair00_a, A1_pair00_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set1 A pair00 block" severity failure;
            
            read_8_lanes_into_block(tb_file, A1_pair01_a, A1_pair01_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set1 A pair01 block" severity failure;
            
            read_8_lanes_into_block(tb_file, B1_pair00_a, B1_pair00_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set1 B pair00 block" severity failure;

            read_8_lanes_into_block(tb_file, B1_pair01_a, B1_pair01_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set1 B pair01 block" severity failure;

            --set 2
            read_8_lanes_into_block(tb_file, A2_pair00_a, A2_pair00_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set2 A pair00 block" severity failure;
            
            read_8_lanes_into_block(tb_file, A2_pair01_a, A2_pair01_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set2 A pair01 block" severity failure;
            
            read_8_lanes_into_block(tb_file, B2_pair00_a, B2_pair00_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set2 B pair00 block" severity failure;
            
            read_8_lanes_into_block(tb_file, B2_pair01_a, B2_pair01_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set2 B pair01 block" severity failure;
            
            --set 3
            read_8_lanes_into_block(tb_file, A3_pair00_a, A3_pair00_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set3 A pair00 block" severity failure;
            
            read_8_lanes_into_block(tb_file, A3_pair01_a, A3_pair01_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set3 A pair01 block" severity failure;
            
            read_8_lanes_into_block(tb_file, B3_pair00_a, B3_pair00_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set3 B pair00 block" severity failure;
            
            read_8_lanes_into_block(tb_file, B3_pair01_a, B3_pair01_b, have_data);
            assert have_data report "Stimulus file ended unexpectedly while reading set3 B pair01 block" severity failure;
            
            --SET 0
            
            -- HMMA step0
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
          
            hmma_step <= '0';
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
          
            --feed A pair00
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, A0_pair00_a, A0_pair00_b);
            wait until rising_edge(clk);
            
            --feed A pair01
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, A0_pair01_a, A0_pair01_b);
            wait until rising_edge(clk);
            
            --feed B pair00
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, B0_pair00_a, B0_pair00_b);
            wait until rising_edge(clk);
            
            --feed B pair01
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, B0_pair01_a, B0_pair01_b);
            wait until rising_edge(clk);
            
            --feed C0 pair00
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C0_pair00_a, C0_pair00_b);
            wait until rising_edge(clk);
            
            --feed C0 pair01
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C0_pair01_a, C0_pair01_b);
            wait until rising_edge(clk);
          
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            capture_step0_outputs(W0_32_X3, W1_32_X3, D00_set0_step0, D10_set0_step0);
            
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
          
            --feed only C1 pair00
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C1_pair00_a, C1_pair00_b);
            wait until rising_edge(clk);
            
            --feed only C1 pair01
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C1_pair01_a, C1_pair01_b);
            wait until rising_edge(clk);
          
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            capture_step1_outputs(W0_32_X3, W1_32_X3, D01_set0_step1, D11_set0_step1);
                        
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop;
            
            wait until rising_edge(clk);
            
            --SET 1
            build_accumulator_blocks_from_previous_results(
                D00_set0_step0, D10_set0_step0, D01_set0_step1, D11_set0_step1,
                C0_chain_pair00_a, C0_chain_pair00_b, 
                C0_chain_pair01_a, C0_chain_pair01_b,
                C1_chain_pair00_a, C1_chain_pair00_b,
                C1_chain_pair01_a, C1_chain_pair01_b
            );
            
            --HMMA step0
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            hmma_step <= '0';
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, A1_pair00_a, A1_pair00_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, A1_pair01_a, A1_pair01_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, B1_pair00_a, B1_pair00_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, B1_pair01_a, B1_pair01_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C0_chain_pair00_a, C0_chain_pair00_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C0_chain_pair01_a, C0_chain_pair01_b);
            wait until rising_edge(clk);
            
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            capture_step0_outputs(W0_32_X3, W1_32_X3, D00_set1_step0, D10_set1_step0);
            
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
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C1_chain_pair00_a, C1_chain_pair00_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C1_chain_pair01_a, C1_chain_pair01_b);
            wait until rising_edge(clk);
            
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            capture_step1_outputs(W0_32_X3, W1_32_X3, D01_set1_step1, D11_set1_step1);
            
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop;
            
            wait until rising_edge(clk);
            
            --SET 2
            build_accumulator_blocks_from_previous_results(
                D00_set1_step0, D10_set1_step0, D01_set1_step1, D11_set1_step1,
                C0_chain_pair00_a, C0_chain_pair00_b,
                C0_chain_pair01_a, C0_chain_pair01_b,
                C1_chain_pair00_a, C1_chain_pair00_b,
                C1_chain_pair01_a, C1_chain_pair01_b
            );
            
            --HMMA step0
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            hmma_step <= '0';
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, A2_pair00_a, A2_pair00_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, A2_pair01_a, A2_pair01_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, B2_pair00_a, B2_pair00_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, B2_pair01_a, B2_pair01_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C0_chain_pair00_a, C0_chain_pair00_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C0_chain_pair01_a, C0_chain_pair01_b);
            wait until rising_edge(clk);
            
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            capture_step0_outputs(W0_32_X3, W1_32_X3, D00_set2_step0, D10_set2_step0);
            
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
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C1_chain_pair00_a, C1_chain_pair00_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C1_chain_pair01_a, C1_chain_pair01_b);
            wait until rising_edge(clk);
            
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            capture_step1_outputs(W0_32_X3, W1_32_X3, D01_set2_step1, D11_set2_step1);
            
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop;
            
            wait until rising_edge(clk);
            
            --SET 3
            
            build_accumulator_blocks_from_previous_results(
                D00_set2_step0, D10_set2_step0, D01_set2_step1, D11_set2_step1,
                C0_chain_pair00_a, C0_chain_pair00_b, 
                C0_chain_pair01_a, C0_chain_pair01_b,
                C1_chain_pair00_a, C1_chain_pair00_b, 
                C1_chain_pair01_a, C1_chain_pair01_b
            );
            
            --HMMA step0
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            hmma_step <= '0';
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, A3_pair00_a, A3_pair00_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, A3_pair01_a, A3_pair01_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, B3_pair00_a, B3_pair00_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, B3_pair01_a, B3_pair01_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C0_chain_pair00_a, C0_chain_pair00_b);
            wait until rising_edge(clk); 
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C0_chain_pair01_a, C0_chain_pair01_b);
            wait until rising_edge(clk);
            
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            capture_step0_outputs(W0_32_X3, W1_32_X3, D00_set3_step0, D10_set3_step0);
            
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
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C1_chain_pair00_a, C1_chain_pair00_b);
            wait until rising_edge(clk);
            
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C1_chain_pair01_a, C1_chain_pair01_b);
            wait until rising_edge(clk);
            
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            
            capture_step1_outputs(W0_32_X3, W1_32_X3, D01_set3_step1, D11_set3_step1);
            
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop;
            
            wait until rising_edge(clk);
            
            --dump results
            
            write_set_result(tb_out_file, 0, D00_set0_step0, D10_set0_step0, D01_set0_step1, D11_set0_step1);
            write_set_result(tb_out_file, 1, D00_set1_step0, D10_set1_step0, D01_set1_step1, D11_set1_step1);
            write_set_result(tb_out_file, 2, D00_set2_step0, D10_set2_step0, D01_set2_step1, D11_set2_step1);
            write_set_result(tb_out_file, 3, D00_set3_step0, D10_set3_step0, D01_set3_step1, D11_set3_step1);
            
            write_final_8x8_quadrant(
                tb_out_file,
                D00_set3_step0,
                D10_set3_step0,
                D01_set3_step1,
                D11_set3_step1
            );
            
            report "Completed chained HMMA FP32 wrapper test #" & integer'image(test_idx);
          
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            wait for CLK_PERIOD;
       
        end loop;
        
        wait for 5*CLK_PERIOD;
        assert false
            report "End of file reached. End of wrapper FP32 chained testbench."
            severity failure;
    end process;
    
end sim;   