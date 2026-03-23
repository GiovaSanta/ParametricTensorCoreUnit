library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.dpuArray_package.all;

entity octectCorewithFSMFP16_step01_tb is
end octectCorewithFSMFP16_step01_tb; 

--testbench which tests for fp16 operands what happens in the execution phase
--of one hmma step 0 instruction and one hmma step 1 instruction related 
--only to the singular octect related hardware

architecture sim of octectCorewithFSMFP16_step01_tb is

    --dut generics
    constant LANES : integer := 8;
    constant REG_W  : integer := 32;
    constant ELEM_W : integer := 32;
    
    --clock/config
    constant CLK_PERIOD : time := 10 ns;
    constant WIDTH_FP16 : std_logic_vector(1 downto 0) := "01";
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
    type matrix4x4_fp16_t is array (0 to 3, 0 to 3) of std_logic_vector(15 downto 0);
    type lane_block_t     is array (0 to 7) of std_logic_vector(31 downto 0);
    
    --related input and output files of tb
    file tb_file : text open read_mode is
        "C:/Users/giovi/OneDrive/Desktop/Magistrale/Tesi/octectCoreRel0/scritptsRelatedToOctectCoreTopTests/HMMAstep0andstep1/fp16related/hmma_step0andstep1_tb_input.txt";

    file tb_out_file : text open write_mode is
        "C:/Users/giovi/OneDrive/Desktop/Magistrale/Tesi/octectCoreRel0/scritptsRelatedToOctectCoreTopTests/HMMAstep0andstep1/fp16related/hmma_step01_tb_output_ctrl_fp16.txt";
    
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
        constant M : in matrix4x4_fp16_t
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
    procedure write_test_result_pair(
        file f : text;
        constant idx       : in integer;
        constant D00_step0 : in matrix4x4_fp16_t;
        constant D10_step0 : in matrix4x4_fp16_t;
        constant D01_step1 : in matrix4x4_fp16_t;
        constant D11_step1 : in matrix4x4_fp16_t
    ) is
        variable L : line;
    begin
        L := null;
        write(L, string'("#Test "));
        write(L, idx);
        write(L, string'(" HMMA step0 / step1 related D00 and D10 / D01 and D11 result submatrices (FP16, FSM wrapper)"));
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
            
            variable A_blk_a  : lane_block_t;
            variable A_blk_b  : lane_block_t;
            variable B_blk_a  : lane_block_t;
            variable B_blk_b  : lane_block_t;
            variable C0_blk_a : lane_block_t;
            variable C0_blk_b : lane_block_t;
            variable C1_blk_a : lane_block_t;
            variable C1_blk_b : lane_block_t;

            variable D00_step0 : matrix4x4_fp16_t;
            variable D10_step0 : matrix4x4_fp16_t;
            variable D01_step1 : matrix4x4_fp16_t;
            variable D11_step1 : matrix4x4_fp16_t;
        begin
        
        --initial setup
        widthSel <= WIDTH_FP16;
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
            
            for r in 0 to 3 loop
                for c in 0 to 3 loop
                    D00_step0(r,c) := (others => '0');
                    D10_step0(r,c) := (others => '0');
                    D01_step1(r,c) := (others => '0');
                    D11_step1(r,c) := (others => '0');
                end loop;
            end loop;
            
            --read one compound test:
            --A, B, C0(for step0), C1(for step1) (a new C submatrix is loaded in the buffer for exedcution of hmma type step1 instruction
            read_8_lanes_into_block(tb_file, A_blk_a, A_blk_b, have_data);
            exit when not have_data;
            
            read_8_lanes_into_block(tb_file, B_blk_a, B_blk_b, have_data);
            assert have_data
                report "Stimulus file ended unexpectedly while reading B blk for test " &
                    integer'image(test_idx)
                severity failure;
                
            read_8_lanes_into_block(tb_file, C0_blk_a, C0_blk_b, have_data);
            assert have_data
                report "Stimulus file ended unexpectedly while reading C0 block for test " &
                    integer'image(test_idx)
                severity failure;
                
            read_8_lanes_into_block(tb_file, C1_blk_a, C1_blk_b, have_data);
            assert have_data
                report "Stimulus file ended unexpectedly while reading C1 block for test " &
                    integer'image(test_idx)
                severity failure;
          
            --instruction 1 : Hmma step0
          
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            --wait for CLK_PERIOD;
          
            hmma_step <= '0';
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
          
            --feed A
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, A_blk_a, A_blk_b);
            wait until rising_edge(clk);
          
            --feed B
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, B_blk_a, B_blk_b);
            wait until rising_edge(clk);
          
            --feed C0
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C0_blk_a, C0_blk_b);
            wait until rising_edge(clk);
          
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
          
            --capture 4 execution rows for step0
            wait until falling_edge(clk);
            for c in 0 to 3 loop
                D00_step0(0, c) := W0_16_X3(c);
                D10_step0(0, c) := W1_16_X3(c);
            end loop;
          
            wait until falling_edge(clk);
            for c in 0 to 3 loop
                D00_step0(1, c) := W0_16_X3(c);
                D10_step0(1, c) := W1_16_X3(c);
            end loop;
          
            wait until falling_edge(clk);
            for c in 0 to 3 loop
                D00_step0(2, c) := W0_16_X3(c);
                D10_step0(2, c) := W1_16_X3(c);
            end loop;
          
            wait until falling_edge(clk);
            for c in 0 to 3 loop
                D00_step0(3, c) := W0_16_X3(c);
                D10_step0(3, c) := W1_16_X3(c);
            end loop;
          
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop;
            
            wait until rising_edge(clk);
          
            --instruction 2 : HMMA step 1
            --reuse A/B already in buffers, reload only C1 for the step 1 instruction
          
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
          
            hmma_step <= '1';
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
          
            --feed only C1
            drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C1_blk_a, C1_blk_b);
            wait until rising_edge(clk);
          
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
          
            --capture 4 execution rows for step1
            wait until falling_edge(clk);
            for c in 0 to 3 loop
                D01_step1(0, c) := W0_16_X3(c);
                D11_step1(0, c) := W1_16_X3(c);
            end loop;
          
            wait until falling_edge(clk);
            for c in 0 to 3 loop
                D01_step1(1, c) := W0_16_X3(c);
                D11_step1(1, c) := W1_16_X3(c);
            end loop;
          
            wait until falling_edge(clk);
            for c in 0 to 3 loop
                D01_step1(2, c) := W0_16_X3(c);
                D11_step1(2, c) := W1_16_X3(c);
            end loop;
          
            wait until falling_edge(clk);
            for c in 0 to 3 loop
                D01_step1(3, c) := W0_16_X3(c);
                D11_step1(3, c) := W1_16_X3(c);
            end loop;
                        
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop;
            
            wait until rising_edge(clk);
            
            --dump results
            write_test_result_pair(
                tb_out_file,
                test_idx,
                D00_step0, D10_step0,
                D01_step1, D11_step1
            );
          
            report "Completed HMMA step0 + step1 FP16 wrapper test #" & integer'image(test_idx);
          
            clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
            wait for CLK_PERIOD;
       
        end loop;
        
        wait for 5*CLK_PERIOD;
        assert false
            report "End of file reached. End of wrapper FP16 step0/step1 testbench."
            severity failure;
    end process;
    
end sim;   