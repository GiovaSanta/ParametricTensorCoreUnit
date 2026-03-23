library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.dpuArray_package.all;

entity tensorCoreDatapath is
    generic(
        LANES  : integer := 16;
        REG_W  : integer := 32;
        ELEM_W : integer := 32
    );
    port(
        clk : in std_logic;
        rst : in std_logic;

        -- mode selection
        widthSel  : in std_logic_vector(1 downto 0);
        typeSel   : in std_logic_vector(2 downto 0);

        -- control now comes from an EXTERNAL FSM
        load_en   : in std_logic;
        load_ph   : in std_logic_vector(1 downto 0);
        load_pair : in std_logic_vector(1 downto 0);
        exec_step : in std_logic_vector(1 downto 0);
        hmma_step : in std_logic;

        -- register file read returns for 16 lanes total
        rf_rd_data_port_a : in arraySize16_32;
        rf_rd_data_port_b : in arraySize16_32;

        -- exposed results from octect 0
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

        -- local completion from the two octects combined
        step_done : out std_logic
    );
end tensorCoreDatapath;

architecture rtl of tensorCoreDatapath is

    component octectCoreTop is
        generic(
            LANES  : integer := 8;
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

    -- sliced RF inputs for octect 0 and octect 1
    signal rf_oct0_port_a_s : arraySize8_32;
    signal rf_oct0_port_b_s : arraySize8_32;
    signal rf_oct1_port_a_s : arraySize8_32;
    signal rf_oct1_port_b_s : arraySize8_32;

    -- local done signals
    signal step_done_oct0_s : std_logic;
    signal step_done_oct1_s : std_logic;

begin

    -- split the 16 RF lanes into 2 groups of 8
    gen_rf_split : for i in 0 to 7 generate
    begin
        rf_oct0_port_a_s(i) <= rf_rd_data_port_a(i);
        rf_oct0_port_b_s(i) <= rf_rd_data_port_b(i);

        rf_oct1_port_a_s(i) <= rf_rd_data_port_a(i + 8);
        rf_oct1_port_b_s(i) <= rf_rd_data_port_b(i + 8);
    end generate;

    -- octect 0
    u_octect0 : octectCoreTop
    generic map(
        LANES  => 8,
        REG_W  => REG_W,
        ELEM_W => ELEM_W
    )
    port map(
        clk => clk,
        rst => rst,

        widthSel  => widthSel,
        typeSel   => typeSel,
        load_en   => load_en,
        load_ph   => load_ph,
        load_pair => load_pair,
        hmma_step => hmma_step,
        exec_step => exec_step,

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

    -- octect 1
    u_octect1 : octectCoreTop
    generic map(
        LANES  => 8,
        REG_W  => REG_W,
        ELEM_W => ELEM_W
    )
    port map(
        clk => clk,
        rst => rst,

        widthSel  => widthSel,
        typeSel   => typeSel,
        load_en   => load_en,
        load_ph   => load_ph,
        load_pair => load_pair,
        hmma_step => hmma_step,
        exec_step => exec_step,

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

    -- combine local completion
    step_done <= step_done_oct0_s and step_done_oct1_s;

end rtl;