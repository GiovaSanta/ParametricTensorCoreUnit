library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
--use work.dpuArray_package.all;
--use work.gpgpu_package.all;

use work.gpgpu_package.arraySize4_8;
use work.gpgpu_package.arraySize4_16;
use work.gpgpu_package.arraySize4_32;
use work.gpgpu_package.arraySize8_32;
use work.gpgpu_package.arraySize16_8;
use work.gpgpu_package.arraySize16_16;
use work.gpgpu_package.arraySize16_32;

entity dualTensorCoreWrapper is
    generic(
        REG_W : integer := 32;
        ELEM_W : integer := 32
    );
    port(
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;
        hmma_step : in std_logic;
        
        --mode selection 
        widthSel : in std_logic_vector(1 downto 0);
        typeSel : in std_logic_vector(2 downto 0);
        
        -- tensor core datapath 0 operand groups
        tc0_src1_rf_port_a_pair00 : in arraySize16_32;
        tc0_src1_rf_port_b_pair00 : in arraySize16_32;
        tc0_src2_rf_port_a_pair00 : in arraySize16_32;
        tc0_src2_rf_port_b_pair00 : in arraySize16_32;
        tc0_src3_rf_port_a_pair00 : in arraySize16_32;
        tc0_src3_rf_port_b_pair00 : in arraySize16_32;
        tc0_src1_rf_port_a_pair01 : in arraySize16_32; --pair01 needed in case one element is of width 32 bits
        tc0_src1_rf_port_b_pair01 : in arraySize16_32;
        tc0_src2_rf_port_a_pair01 : in arraySize16_32;
        tc0_src2_rf_port_b_pair01 : in arraySize16_32;
        tc0_src3_rf_port_a_pair01 : in arraySize16_32;
        tc0_src3_rf_port_b_pair01 : in arraySize16_32;

        -- tensor core datapath 1 operand groups
        tc1_src1_rf_port_a_pair00 : in arraySize16_32;
        tc1_src1_rf_port_b_pair00 : in arraySize16_32;
        tc1_src2_rf_port_a_pair00 : in arraySize16_32;
        tc1_src2_rf_port_b_pair00 : in arraySize16_32;
        tc1_src3_rf_port_a_pair00 : in arraySize16_32;
        tc1_src3_rf_port_b_pair00 : in arraySize16_32;
        tc1_src1_rf_port_a_pair01 : in arraySize16_32;
        tc1_src1_rf_port_b_pair01 : in arraySize16_32;
        tc1_src2_rf_port_a_pair01 : in arraySize16_32;
        tc1_src2_rf_port_b_pair01 : in arraySize16_32;
        tc1_src3_rf_port_a_pair01 : in arraySize16_32;
        tc1_src3_rf_port_b_pair01 : in arraySize16_32;
        
        --outputs from tensor core datapath 0
        W0_tc0_oct0_8_X3 : out arraySize16_8;
        W1_tc0_oct0_8_X3 : out arraySize16_8;
        W0_tc0_oct0_16_X3 : out arraySize16_16;
        W1_tc0_oct0_16_X3 : out arraySize16_16;
        W0_tc0_oct0_32_X3 : out arraySize16_32;
        W1_tc0_oct0_32_X3 : out arraySize16_32;
        
        W0_tc0_oct1_8_X3 : out arraySize16_8;
        W1_tc0_oct1_8_X3 : out arraySize16_8;
        W0_tc0_oct1_16_X3 : out arraySize16_16;
        W1_tc0_oct1_16_X3 : out arraySize16_16;
        W0_tc0_oct1_32_X3 : out arraySize16_32;
        W1_tc0_oct1_32_X3 : out arraySize16_32;
        
        --outputs from tensor core datapath 1
        W0_tc1_oct0_8_X3 : out arraySize16_8;
        W1_tc1_oct0_8_X3 : out arraySize16_8;
        W0_tc1_oct0_16_X3 : out arraySize16_16;
        W1_tc1_oct0_16_X3 : out arraySize16_16;
        W0_tc1_oct0_32_X3 : out arraySize16_32;
        W1_tc1_oct0_32_X3 : out arraySize16_32;
        
        W0_tc1_oct1_8_X3 : out arraySize16_8;
        W1_tc1_oct1_8_X3 : out arraySize16_8;
        W0_tc1_oct1_16_X3 : out arraySize16_16;
        W1_tc1_oct1_16_X3 : out arraySize16_16;
        W0_tc1_oct1_32_X3 : out arraySize16_32;
        W1_tc1_oct1_32_X3 : out arraySize16_32;
        
        --status 
        busy : out std_logic;
        done : out std_logic;
        step_done : out std_logic;
        load_pair: out std_logic_vector(1 downto 0)
    );
end dualTensorCoreWrapper;


architecture rtl of dualTensorCoreWrapper is

    component octectRelatedFSM is
        port(
            clk : in std_logic;
            rst : in std_logic;
            start : in std_logic;

            Fp32Op    : in std_logic;
            w16op     : in std_logic;
            hmma_step : in std_logic;

            load_en   : out std_logic;
            load_ph   : out std_logic_vector(1 downto 0);
            load_pair : out std_logic_vector(1 downto 0);
            exec_step : out std_logic_vector(1 downto 0);

            busy : out std_logic;
            done : out std_logic;

            typeSel : in std_logic_vector(2 downto 0)
        );
    end component;
    
    component tensorCoreDatapath is
        generic(
            LANES  : integer := 16;
            REG_W  : integer := 32;
            ELEM_W : integer := 32
        );
        port(
            clk : in std_logic;
            rst : in std_logic;

            widthSel  : in std_logic_vector(1 downto 0);
            typeSel   : in std_logic_vector(2 downto 0);

            load_en   : in std_logic;
            load_ph   : in std_logic_vector(1 downto 0);
            load_pair : in std_logic_vector(1 downto 0);
            exec_step : in std_logic_vector(1 downto 0);
            hmma_step : in std_logic;

            rf_rd_data_port_a : in arraySize16_32;
            rf_rd_data_port_b : in arraySize16_32;

            W0_oct0_8_X3  : out arraySize16_8;
            W1_oct0_8_X3  : out arraySize16_8;
            W0_oct0_16_X3 : out arraySize16_16;
            W1_oct0_16_X3 : out arraySize16_16;
            W0_oct0_32_X3 : out arraySize16_32;
            W1_oct0_32_X3 : out arraySize16_32;

            W0_oct1_8_X3  : out arraySize16_8;
            W1_oct1_8_X3  : out arraySize16_8;
            W0_oct1_16_X3 : out arraySize16_16;
            W1_oct1_16_X3 : out arraySize16_16;
            W0_oct1_32_X3 : out arraySize16_32;
            W1_oct1_32_X3 : out arraySize16_32;

            step_done : out std_logic
            
        );
    end component;
    
    --shared FSM controls
    signal load_en_s : std_logic;
    signal load_ph_s : std_logic_vector(1 downto 0);
    signal load_pair_s : std_logic_vector(1 downto 0);
    signal exec_step_s : std_logic_vector(1 downto 0);
    
    --local step_done from each tensor core datapath
    signal step_done_tc0_s : std_logic;
    signal step_done_tc1_s : std_logic;
    
    signal tc0_rf_mux_a_s : arraySize16_32;
    signal tc0_rf_mux_b_s : arraySize16_32;
    signal tc1_rf_mux_a_s : arraySize16_32;
    signal tc1_rf_mux_b_s : arraySize16_32;
    
begin
    --FSM controlling both tensor cores:
    
    u_fsm : octectRelatedFSM
        port map(
        clk       => clk,
        rst       => rst,
        start     => start,
        Fp32Op    => widthSel(1),
        w16op     => widthSel(0),
        hmma_step => hmma_step,

        load_en   => load_en_s,
        load_ph   => load_ph_s,
        load_pair => load_pair_s,
        exec_step => exec_step_s,

        busy      => busy,
        done      => done,

        typeSel   => typeSel
    );
    
    --tensor core datapath 0
    
    u_tc0 : tensorCoreDatapath
    generic map(
        LANES => 16,
        REG_W => REG_W,
        ELEM_W => ELEM_W
    )
    port map(
        clk => clk,
        rst => rst,

        widthSel  => widthSel,
        typeSel   => typeSel,
        load_en   => load_en_s,
        load_ph   => load_ph_s,
        load_pair => load_pair_s,
        exec_step => exec_step_s,
        hmma_step => hmma_step,

        rf_rd_data_port_a => tc0_rf_mux_a_s,
        rf_rd_data_port_b => tc0_rf_mux_b_s,

        W0_oct0_8_X3  => W0_tc0_oct0_8_X3,
        W1_oct0_8_X3  => W1_tc0_oct0_8_X3,
        W0_oct0_16_X3 => W0_tc0_oct0_16_X3,
        W1_oct0_16_X3 => W1_tc0_oct0_16_X3,
        W0_oct0_32_X3 => W0_tc0_oct0_32_X3,
        W1_oct0_32_X3 => W1_tc0_oct0_32_X3,

        W0_oct1_8_X3  => W0_tc0_oct1_8_X3,
        W1_oct1_8_X3  => W1_tc0_oct1_8_X3,
        W0_oct1_16_X3 => W0_tc0_oct1_16_X3,
        W1_oct1_16_X3 => W1_tc0_oct1_16_X3,
        W0_oct1_32_X3 => W0_tc0_oct1_32_X3,
        W1_oct1_32_X3 => W1_tc0_oct1_32_X3,

        step_done => step_done_tc0_s
    );
    
    --Tensor core datapath 1
    
    u_tc1 : tensorCoreDatapath
    generic map(
        LANES => 16,
        REG_W => REG_W,
        ELEM_W => ELEM_W
    )
    port map(
        clk => clk,
        rst => rst,

        widthSel  => widthSel,
        typeSel   => typeSel,
        load_en   => load_en_s,
        load_ph   => load_ph_s,
        load_pair => load_pair_s,
        exec_step => exec_step_s,
        hmma_step => hmma_step,

        rf_rd_data_port_a => tc1_rf_mux_a_s,
        rf_rd_data_port_b => tc1_rf_mux_b_s,

        W0_oct0_8_X3  => W0_tc1_oct0_8_X3,
        W1_oct0_8_X3  => W1_tc1_oct0_8_X3,
        W0_oct0_16_X3 => W0_tc1_oct0_16_X3,
        W1_oct0_16_X3 => W1_tc1_oct0_16_X3,
        W0_oct0_32_X3 => W0_tc1_oct0_32_X3,
        W1_oct0_32_X3 => W1_tc1_oct0_32_X3,

        W0_oct1_8_X3  => W0_tc1_oct1_8_X3,
        W1_oct1_8_X3  => W1_tc1_oct1_8_X3,
        W0_oct1_16_X3 => W0_tc1_oct1_16_X3,
        W1_oct1_16_X3 => W1_tc1_oct1_16_X3,
        W0_oct1_32_X3 => W0_tc1_oct1_32_X3,
        W1_oct1_32_X3 => W1_tc1_oct1_32_X3,

        step_done => step_done_tc1_s
    );
    
    step_done <= step_done_tc0_s and step_done_tc1_s;

    load_pair <= load_pair_s ;
    
    process(load_ph_s, load_pair_s,
        tc0_src1_rf_port_a_pair00, tc0_src1_rf_port_b_pair00, tc0_src1_rf_port_a_pair01, tc0_src1_rf_port_b_pair01, 
        tc0_src2_rf_port_a_pair00, tc0_src2_rf_port_b_pair00, tc0_src2_rf_port_a_pair01, tc0_src2_rf_port_b_pair01,
        tc0_src3_rf_port_a_pair00, tc0_src3_rf_port_b_pair00, tc0_src3_rf_port_a_pair01, tc0_src3_rf_port_b_pair01,
        tc1_src1_rf_port_a_pair00, tc1_src1_rf_port_b_pair00, tc1_src1_rf_port_a_pair01, tc1_src1_rf_port_b_pair01,
        tc1_src2_rf_port_a_pair00, tc1_src2_rf_port_b_pair00, tc1_src2_rf_port_a_pair01, tc1_src2_rf_port_b_pair01,
        tc1_src3_rf_port_a_pair00, tc1_src3_rf_port_b_pair00, tc1_src3_rf_port_a_pair01, tc1_src3_rf_port_b_pair01 )
    
    begin
        tc0_rf_mux_a_s <= (others => (others => '0'));
        tc0_rf_mux_b_s <= (others => (others => '0'));
        tc1_rf_mux_a_s <= (others => (others => '0'));
        tc1_rf_mux_b_s <= (others => (others => '0'));

        case load_ph_s is
            when "00" =>   -- load A
                if load_pair_s = "00" then
                    tc0_rf_mux_a_s <= tc0_src1_rf_port_a_pair00;
                    tc0_rf_mux_b_s <= tc0_src1_rf_port_b_pair00;
                    tc1_rf_mux_a_s <= tc1_src1_rf_port_a_pair00;
                    tc1_rf_mux_b_s <= tc1_src1_rf_port_b_pair00;
                else
                    tc0_rf_mux_a_s <= tc0_src1_rf_port_a_pair01;
                    tc0_rf_mux_b_s <= tc0_src1_rf_port_b_pair01;
                    tc1_rf_mux_a_s <= tc1_src1_rf_port_a_pair01;
                    tc1_rf_mux_b_s <= tc1_src1_rf_port_b_pair01;
                end if;

            when "01" =>   -- load B
                if load_pair_s = "00" then
                    tc0_rf_mux_a_s <= tc0_src2_rf_port_a_pair00;
                    tc0_rf_mux_b_s <= tc0_src2_rf_port_b_pair00;
                    tc1_rf_mux_a_s <= tc1_src2_rf_port_a_pair00;
                    tc1_rf_mux_b_s <= tc1_src2_rf_port_b_pair00;
                else 
                    tc0_rf_mux_a_s <= tc0_src2_rf_port_a_pair01;
                    tc0_rf_mux_b_s <= tc0_src2_rf_port_b_pair01;
                    tc1_rf_mux_a_s <= tc1_src2_rf_port_a_pair01;
                    tc1_rf_mux_b_s <= tc1_src2_rf_port_b_pair01;
                end if;

            when "10" =>   -- load C
                if load_pair_s = "00" then
                    tc0_rf_mux_a_s <= tc0_src3_rf_port_a_pair00;
                    tc0_rf_mux_b_s <= tc0_src3_rf_port_b_pair00;
                    tc1_rf_mux_a_s <= tc1_src3_rf_port_a_pair00;
                    tc1_rf_mux_b_s <= tc1_src3_rf_port_b_pair00;
                else
                    tc0_rf_mux_a_s <= tc0_src3_rf_port_a_pair01;
                    tc0_rf_mux_b_s <= tc0_src3_rf_port_b_pair01;
                    tc1_rf_mux_a_s <= tc1_src3_rf_port_a_pair01;
                    tc1_rf_mux_b_s <= tc1_src3_rf_port_b_pair01;
                end if;

            when others =>
                null;
        end case;
    end process;
    
end rtl;