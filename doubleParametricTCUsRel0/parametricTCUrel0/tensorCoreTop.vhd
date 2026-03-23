
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_Std.all;
use work.dpuArray_package.all;


entity tensorCoreTop is
    generic(
        LANES : integer := 16;
        REG_W : integer := 32;
        ELEM_W: integer := 32
    );
    port(
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;
        hmma_step : in std_logic;
        
        --mode selection
        widthSel : in std_logic_vector(1 downto 0);
        typeSel : in std_logic_vector(2 downto 0);
        
        --register file read returns for 16 lanes total (for the 2 octects)
        rf_rd_data_port_a : in arraySize16_32;
        rf_rd_data_port_b : in arraySize16_32;
        
        --exposed results from octect 0 
        W0_oct0_8_X3  : out arraySize4_8;
        W1_oct0_8_X3  : out arraySize4_8;
        W0_oct0_16_X3 : out arraySize4_16;
        W1_oct0_16_X3 : out arraySize4_16;
        W0_oct0_32_X3 : out arraySize4_32;
        W1_oct0_32_X3 : out arraySize4_32;
        
        -- exposed results from octect 1
        W0_oct1_8_X3  : out arraySize4_8;
        W1_oct1_8_X3  : out arraySize4_8;
        W0_oct1_16_X3 : out arraySize4_16;
        W1_oct1_16_X3 : out arraySize4_16;
        W0_oct1_32_X3 : out arraySize4_32;
        W1_oct1_32_X3 : out arraySize4_32;
        
        --status 
        busy : out std_logic;
        done : out std_logic;
        step_done : out std_logic
        
    );
end tensorCoreTop;

architecture rtl of tensorCoreTop is

    component octectRelatedFSM is
        port(
            clk : in std_logic;
            rst : in std_logic;
            start : in std_logic;
            
            Fp32Op: in std_logic;
            hmma_step : in std_logic;
            
            load_en : out std_logic;
            load_ph : out std_logic_vector(1 downto 0);
            load_pair : out std_logic_vector(1 downto 0);
            
            exec_step : out std_logic_vector(1 downto 0);
            
            busy : out std_logic;
            done : out std_logic
        );
    end component;
        
    component octectCoreTop is
        generic(
            LANES : integer := 8;
            REG_W : integer := 32;
            ELEM_W: integer := 32
        );
        port(
            clk : in std_logic;
            rst : in std_logic;
            
            widthSel : in std_logic_vector(1 downto 0);
            typeSel : in std_logic_vector(2 downto 0);
            load_en : in std_logic; 
            load_ph : in std_logic_vector(1 downto 0);
            load_pair : in std_logic_vector(1 downto 0);
            
            hmma_step : in std_logic;
            exec_step : in std_logic_vector(1 downto 0);
            
            rf_rd_data_port_a : in arraySize8_32;
            rf_rd_data_port_b : in arraySize8_32;
            
            W0_8_X3   : out arraySize4_8;
            W1_8_X3   : out arraySize4_8;
            W0_16_X3  : out arraySize4_16;
            W1_16_X3  : out arraySize4_16;
            W0_32_X3  : out arraySize4_32;
            W1_32_X3  : out arraySize4_32;

            step_done : out std_logic
        );
    end component;
    
    --shared control from the single FSM
    signal load_en_s : std_logic;
    signal load_ph_s : std_logic_vector(1 downto 0);
    signal load_pair_s : std_logic_vector(1 downto 0);
    signal exec_step_s : std_logic_vector(1 downto 0);
    
    --sliced RF inputs for octect 0 and octect 1
    signal rf_oct0_port_a_s : arraySize8_32;
    signal rf_oct0_port_b_s : arraySize8_32;
    signal rf_oct1_port_a_s : arraySize8_32;
    signal rf_oct1_port_b_s : arraySize8_32;
    
    --local step_done signals from each octect
    signal step_done_oct0_s : std_logic;
    signal step_done_oct1_s : std_logic;
    
begin

    --splitting the 16 Register FIle lanes into 2 groups of 8
    
    gen_rf_split : for i in 0 to 7 generate
    begin
        rf_oct0_port_a_s(i) <= rf_rd_data_port_a(i);
        rf_oct0_port_b_s(i) <= rf_rd_data_port_b(i);
        
        rf_oct1_port_a_s(i) <= rf_rd_data_port_a(i+8);
        rf_oct1_port_b_s(i) <= rf_rd_data_port_b(i+8);
    end generate;
    
    --the single FSM controlling both octects in parallel
    
    u_fsm : octectRelatedFSM
    port map(
        clk => clk,
        rst => rst,
        start => start,
        
        Fp32Op => widthSel(1),
        hmma_step => hmma_step,
        
        load_en => load_en_s, 
        load_ph => load_ph_s,
        load_pair => load_pair_s,
        exec_step => exec_step_s,
        
        busy => busy,
        done => done
    );
    
    --hw reserved for octect0 -threadgroups 0 and 4
    
    u_octect0 : octectCoreTop
    generic map(
        LANES => 8,
        REG_W => REG_W,
        ELEM_W => ELEM_W
    )
    port map(
        clk => clk,
        rst => rst,
        
        widthSel => widthSel,
        typeSel => typeSel,
        load_en => load_en_s,
        load_ph => load_ph_s,
        load_pair => load_pair_s,
        hmma_step => hmma_step,
        exec_step => exec_step_s,
        
        rf_rd_data_port_a => rf_oct0_port_a_s,
        rf_rd_data_port_b => rf_oct0_port_b_s,
        
        W0_8_X3   => W0_oct0_8_X3,
        W1_8_X3   => W1_oct0_8_X3,
        W0_16_X3  => W0_oct0_16_X3,
        W1_16_X3  => W1_oct0_16_X3,
        W0_32_X3  => W0_oct0_32_X3,
        W1_32_X3  => W1_oct0_32_X3,

        step_done => step_done_oct0_s
    );
    
    --hw reserved for octect1 -threadgroups 1 and 5
    
    u_octect1 : octectCoreTop
    generic map(
        LANES => 8,
        REG_W => REG_W,
        ELEM_W => ELEM_W
    )
    port map(
        clk => clk,
        rst => rst,
        
        widthSel => widthSel,
        typeSel => typeSel,
        load_en => load_en_s,
        load_ph => load_ph_s,
        load_pair => load_pair_s,
        hmma_step => hmma_step,
        exec_step => exec_step_s,
        
        rf_rd_data_port_a => rf_oct1_port_a_s,
        rf_rd_data_port_b => rf_oct1_port_b_s,
        
        W0_8_X3   => W0_oct1_8_X3,
        W1_8_X3   => W1_oct1_8_X3,
        W0_16_X3  => W0_oct1_16_X3,
        W1_16_X3  => W1_oct1_16_X3,
        W0_32_X3  => W0_oct1_32_X3,
        W1_32_X3  => W1_oct1_32_X3,

        step_done => step_done_oct1_s

    );
    
    -- since both octects receive the same exec_step, these should rise together.
    -- using AND is safer than just forwarding one of them.
    step_done <= step_done_oct0_s and step_done_oct1_s;
    
end rtl;
