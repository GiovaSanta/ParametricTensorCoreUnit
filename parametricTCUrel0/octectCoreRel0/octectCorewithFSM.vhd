
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.dpuArray_package.all;

entity octectCorewithFSM is
    generic(
        LANES    : integer := 8;
        REG_W    : integer := 32;
        ELEM_W   : integer := 32
    );
    port(
        clk      : in std_logic;
        rst      : in std_logic;
        start    : in std_logic;
        hmma_step : in std_logic;
    
        --mode selection
        widthSel : in std_logic_vector(1 downto 0);
        typeSel  : in std_logic_vector(2 downto 0);
        
        --register file read returns
        rf_rd_data_port_a : in arraySize8_32;
        rf_rd_data_port_b : in arraySize8_32;
        
        --exposed results
        W0_8_X3 : out arraySize4_8;
        W1_8_X3 : out arraySize4_8;
        W0_16_X3: out arraySize4_16;
        W1_16_X3: out arraySize4_16;
        W0_32_X3: out arraySize4_32;
        W1_32_X3: out arraySize4_32;
        
        --status
        busy     : out std_logic;
        done     : out std_logic;
        step_done: out std_logic
    
    );
end octectCorewithFSM;

architecture rtl of octectCorewithFSM is

--components instantiations

component octectRelatedFSM is
    port(
        clk     : in std_logic;
        rst     : in std_logic;
        start   : in std_logic;
        
        Fp32Op      : in std_logic;
        
        hmma_step : in std_logic;
        
        load_en : out std_logic;
        load_ph : out std_logic_vector(1 downto 0);
        load_pair: out std_logic_vector(1 downto 0);
        
        exec_Step : out std_logic_vector(1 downto 0);
        
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
        typeSel  : in std_logic_vector(2 downto 0);
        load_en  : in std_logic;
        load_ph : in std_logic_vector(1 downto 0);
        load_pair : in std_logic_vector(1 downto 0);
        hmma_step : in std_logic;
        exec_step : in std_logic_vector(1 downto 0);
        
        rf_rd_data_port_a : in arraySize8_32;
        rf_rd_data_port_b : in arraySize8_32;
        
        W0_8_X3 : out arraySize4_8;
        W1_8_X3 : out arraySize4_8;
        W0_16_X3: out arraySize4_16;
        W1_16_X3: out arraySize4_16;
        W0_32_X3: out arraySize4_32;
        W1_32_X3: out arraySize4_32;
        
        step_done : out std_logic
    );
    end component;
    
    --internal control signals from FSM to octectCoreTop
    
    signal load_en_s : std_logic;
    signal load_ph_s : std_logic_vector(1 downto 0);
    signal load_pair_s : std_logic_vector(1 downto 0);
    signal exec_step_s : std_logic_vector(1 downto 0);
    
begin
    
    --fsm instance
    u_fsm : octectRelatedFSM
    port map(
        clk         => clk,
        rst         => rst,
        start       => start,
        
        Fp32Op      => widthSel(1),
        
        hmma_step   => hmma_step,

        load_en     => load_en_s,
        load_ph     => load_ph_s,
        load_pair   => load_pair_s,
        
        exec_step   => exec_step_s,

        busy        => busy,
        done        => done
    );
    
    --exisisting and verified octect datapath
    u_octect_core : octectCoreTop
    generic map(
        LANES   => LANES,
        REG_W   => REG_W,
        ELEM_W  => ELEM_W
    )
    port map(
        clk     => clk,
        rst     => rst,

        widthSel    => widthSel,
        typeSel     => typeSel,
        load_en     => load_en_s,
        load_ph     => load_ph_s,
        load_pair   => load_pair_s,
        hmma_step   => hmma_step,
        exec_step   => exec_step_s,

        rf_rd_data_port_a   => rf_rd_data_port_a,
        rf_rd_data_port_b   => rf_rd_data_port_b,

        W0_8_X3     => W0_8_X3,
        W1_8_X3     => W1_8_X3,
        W0_16_X3    => W0_16_X3,
        W1_16_X3    => W1_16_X3,
        W0_32_X3    => W0_32_X3,
        W1_32_X3    => W1_32_X3,

        step_done   => step_done
    );

end rtl;
