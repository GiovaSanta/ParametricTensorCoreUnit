
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.dpuArray_package.all;

entity octectCorewithFSMFP32_tb is
--  Port ( );
end octectCorewithFSMFP32_tb;

architecture sim of octectCorewithFSMFP32_tb is

--DUT generics

constant LANES : integer := 8;
constant REG_W : integer := 32;
constant ELEM_W: integer := 32;

--clock/config
constant CLK_PERIOD : time := 10 ns;
constant WIDTH_FP32 : std_logic_vector(1 downto 0) := "10";
constant TYPE_FP    : std_logic_vector(2 downto 0) := "000";

--DUT signals
signal clk  : std_logic := '0';
signal rst  : std_logic := '1';
signal start: std_logic := '0';

signal widthSel : std_logic_vector(1 downto 0) := (others => '0');
signal typeSel  : std_logic_vector(2 downto 0) := (others => '0');

signal rf_rd_data_port_a : arraySize8_32;
signal rf_rd_data_port_b : arraySize8_32;

signal W0_8_X3 : arraySize4_8;
signal W1_8_X3 : arraySize4_8;
signal W0_16_X3 : arraySize4_16;
signal W1_16_X3 : arraySize4_16;
signal W0_32_X3 : arraySize4_32;
signal W1_32_X3 : arraySize4_32;

signal busy : std_logic;
signal done : std_logic;
signal step_done : std_logic;

--TB only types

type matrix4x4_fp32_t is array (0 to 3, 0 to 3) of std_logic_vector(31 downto 0);
type lane_block_t is array (0 to 7) of std_logic_vector(31 downto 0);

--Files
file tb_file : text open read_mode is 
    "C:/Users/giovi/OneDrive/Desktop/Magistrale/Tesi/octectCoreRel0/scritptsRelatedToOctectCoreTopTests/fp32related/hmma_step0_tb_input_fp32.txt";

file tb_out_file : text open write_mode is
    "C:/Users/giovi/OneDrive/Desktop/Magistrale/Tesi/octectCoreRel0/scritptsRelatedToOctectCoreTopTests/fp32related/hmma_step0_tb_output_ctrl_fp32.txt";

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
    variable ok : out boolean
) is
    variable L : line;
    variable tmp_a : std_logic_vector(31 downto 0);
    variable tmp_b : std_logic_vector(31 downto 0);
begin
    ok := false;
    
    while not endfile(f) loop
        readline(f, L);
        
        --skip blank lines
        if L = null then
            null;
        elsif L.all'length = 0 then
            null;
        --skip comments
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
    file f: text;
    variable block_a : out lane_block_t;
    variable block_b : out lane_block_t;
    variable success : out boolean
) is
    variable v_a : std_logic_vector(31 downto 0);
    variable v_b : std_logic_vector(31 downto 0);
    variable ok : boolean;

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
    file f : text ;
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

procedure write_test_result(
        file f : text;
        constant idx : in integer;
        constant D00 : in matrix4x4_fp32_t;
        constant D20 : in matrix4x4_fp32_t
    ) is
        variable L : line;
    begin
        L := null;
        write(L, string'("#Test "));
        write(L, idx);
        write(L, string'(" HMMAstep0 related D00 and D20 result submatrices (FP32, FSM wrapper)"));
        writeline(f, L);

        L := null;
        write(L, string'("#D00"));
        writeline(f, L);
        write_matrix4x4_hex(f, D00);

        L := null;
        write(L, string'("#D20"));
        writeline(f, L);
        write_matrix4x4_hex(f, D20);

        L := null;
        writeline(f, L);
end procedure;

begin

--clock

clk <= not clk after CLK_PERIOD/2;

--DUT: wrapper with FSM

 dut : entity work.octectCorewithFSM
        generic map(
            LANES => LANES,
            REG_W => REG_W,
            ELEM_W => ELEM_W
        )
        port map(
            clk => clk,
            rst => rst,
            start => start,
            instr_step => instr_step, 

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

            busy => busy,
            done => done,
            step_done => step_done
        );

--stimulus
stim_proc : process
    variable have_data : boolean;
    variable test_idx  : integer := 0;
    
    variable A0_blk_a : lane_block_t;  --the 8 A00 and A20 elements associate to portA of the register Files
    variable A0_blk_b : lane_block_t;  --the 8 A00 and A20 elements associated to portB of the Register Files
    variable B0_blk_a : lane_block_t;
    variable B0_blk_b : lane_block_t;
    variable C0_blk_a : lane_block_t;
    variable C0_blk_b : lane_block_t;
    
    variable A1_blk_a : lane_block_t;
    variable A1_blk_b : lane_block_t;  
    variable B1_blk_a : lane_block_t;
    variable B1_blk_b : lane_block_t;
    variable C1_blk_a : lane_block_t;
    variable C1_blk_b : lane_block_t;
    
    
    variable D00_capture : matrix4x4_fp32_t;
    variable D20_capture : matrix4x4_fp32_t;

begin
    --initial setup
    widthSel <= WIDTH_FP32;
    typeSel <= TYPE_FP;
    start <= '0';
    clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
    
    --reset
    wait for 3 * CLK_PERIOD;
    rst <= '0';
    wait for CLK_PERIOD;
    
    while true loop
        test_idx := test_idx + 1;
        
        --Read one full test worth of stimulus
        -- 8 lines for A 
        -- 8 lines for B
        -- 8 lines for C
        
        read_8_lanes_into_block(tb_file, A0_blk_a, A0_blk_b, have_data);
        exit when not have_data;
        
        read_8_lanes_into_block(tb_file, A1_blk_a, A1_blk_b, have_data);
        read_8_lanes_into_block(tb_file, B0_blk_a, B0_blk_b, have_data);
        read_8_lanes_into_block(tb_file, B1_blk_a, B1_blk_b, have_data);
        read_8_lanes_into_block(tb_file, C0_blk_a, C0_blk_b, have_data);
        read_8_lanes_into_block(tb_file, C1_blk_a, C1_blk_b, have_data);
            
        --launch fsm
        
        clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
        wait for CLK_PERIOD;
        
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        
        --feed operands in the order expected by the FSM
        
        --LOAD_A pair00 cycle
        drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, A0_blk_a, A0_blk_b);
        wait for CLK_PERIOD;
        
        --LOAD_A pair01 cycle
        drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, A1_blk_a, A1_blk_b);
        wait for CLK_PERIOD;
        
        --LOAD B pair00 cycle
        drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, B0_blk_a, B0_blk_b);
        wait for CLK_PERIOD;
        
        --LOAD B pair01 cycle
        drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, B1_blk_a, B1_blk_b);
        wait for CLK_PERIOD;
        
        --LOAD C pair00 cycle
        drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C0_blk_a, C0_blk_b);
        wait for CLK_PERIOD;
        
        --LOAD C pair01 cycle
        drive_block_to_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b, C1_blk_a, C1_blk_b);
        wait for CLK_PERIOD;
        
        --clear during execution
        clear_rf_ports(rf_rd_data_port_a, rf_rd_data_port_b);
        
        --capture 4 execution rows
        
        for c in 0 to 3 loop
            D00_capture(0, c) := W0_32_X3(c);
            D20_capture(0, c) := W1_32_X3(c);
        end loop;
        
        wait for CLK_PERIOD;
        for c in 0 to 3 loop
            D00_capture(1, c) := W0_32_X3(c);
            D20_capture(1, c) := W1_32_X3(c);
        end loop;
        
        wait for CLK_PERIOD;
        for c in 0 to 3 loop
            D00_capture(2, c) := W0_32_X3(c);
            D20_capture(2, c) := W1_32_X3(c);
        end loop;
        
        wait for CLK_PERIOD;
        for c in 0 to 3 loop
            D00_capture(3, c) := W0_32_X3(c);
            D20_capture(3, c) := W1_32_X3(c);
        end loop;
        
        --wait for Done and dump result
        
        if done /= '1' then
            while done /= '1' loop
                wait until rising_edge(clk);
            end loop;
        end if;
        
        write_test_result(tb_out_file, test_idx, D00_capture, D20_capture);
        
        report "completed HMMAstep0 Fp32 wrapper test #" & integer'image(test_idx);
        
        wait for CLK_PERIOD;
    end loop;
    
    wait for 5*CLK_PERIOD;
    assert false report "End of FIle reached. End of wrapper Fp32 testbench." severity failure;
    
    end process;     

end sim;
