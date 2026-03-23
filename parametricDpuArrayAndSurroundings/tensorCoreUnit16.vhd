

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity tensorCoreUnit16 is
    generic(
        LANES_PER_OCTET : integer := 8;
        REG_W           : integer := 32;
        FP16_W          : integer := 16
    );
    port(
        clk : in std_logic;
        rst : in std_logic;
        
        --control from global FSM
        load_en : in std_logic;
        load_ph : in std_logic_vector(1 downto 0); --00=A, 01=B, 10=C
        
        --registerFile read return for 16 lanes (2 octects)
        rf_rd_data_port_a_16 : in std_logic_vector(2 * LANES_PER_OCTECT*REG_W-1 downto 0);
        rf_rd_data_port_b_16 : in std_logic_vector(2 * LANES_PER_OCTECT*REG_W-1 downto 0);
        
        --outputs to DPU16 / compute stage (packed per lane, 4 fp16 each)
        A_out_16 : out std_logic_vector(2 * LANES_PER_OCTECT*4*FP16_W-1 downto 0);
        B_out_16 : out std_logic_vector(2 * LANES_PER_OCTECT*4*FP16_W-1 downto 0);
        C_out_16 : out std_logic_vector(2 * LANES_PER_OCTECT*4*FP16_W-1 downto 0)
        
        --todo later: add result/ writeback ports
    );
end tensorCoreUnit16;

architecture rtl of tensorCoreUnit16 is

    constant LANES16 : integer := 2*LANES_PER_OCTECT;
    
    --slice the buses for octect0 (lanes 0 to 7) and octect1 (lanes 8 to 15)
    signal rf_a_oct0 : std_logic_vector(LANES_PER_OCTECT*REG_W-1 downto 0);
    signal rf_b_oct0 : std_logic_vector(LANES_PER_OCTECT*REG_W-1 downto 0);
    signal rf_a_oct1 : std_logic_vector(LANES_PER_OCTECT*REG_W-1 downto 0);
    signal rf_b_oct1 : std_logic_vector(LANES_PER_OCTECT*REG_W-1 downto 0);
    
    signal A_oct0 : std_logic_vector(LANES_PER_OCTECT*4*FP16_W-1 downto 0);
    signal B_oct0 : std_logic_vector(LANES_PER_OCTECT*4*FP16_W-1 downto 0);
    signal C_oct0 : std_logic_vector(LANES_PER_OCTECT*4*FP16_W-1 downto 0);
    
    signal A_oct1 : std_logic_vector(LANES_PER_OCTECT*4*FP16_W-1 downto 0);
    signal B_oct1 : std_logic_vector(LANES_PER_OCTECT*4*FP16_W-1 downto 0);
    signal C_oct1 : std_logic_vector(LANES_PER_OCTECT*4*FP16_W-1 downto 0);
    
begin

--slice 16-lane RF read return into two 8lane chunks
--convention: 
--          lower bits --> octect0 (lanes 0 to 7)
--          upper bits --> octect1 (lanes 8 to 15)

    rf_a_oct0 <= rf_rd_data_port_a_16(LANES_PER_OCTECT*REG_W-1 downto 0);
    rf_b_oct0 <= rf_rd_data_port_b_16(LANES_PER_OCTECT*REG_W-1 downto 0);
    
    rf_a_oct1 <= rf_rd_data_port_a_16(2*LANES_PER_OCTECT*REG_W-1 downto LANES_PER_OCTECT*REG_W);
    rf_b_oct1 <= rf_rd_data_port_b_16(2*LANES_PER_OCTECT*REG_W-1 downto LANES_PER_OCTECT*REG_W);
    
--octect buffers

u_octect0: entity work.octectRelatedBuffers
    generic map(
        LANES => LANES_PER_OCTECT,
        REG_W => REG_W,
        FP16_W => FP16_W
    )
    port map(
        clk => clk,
        rst => rst,
        load_en => load_en,
        load_ph => load_ph,
        rf_rd_data_port_a => rf_a_oct0,
        rf_rd_data_port_b => rf_b_oct0,
        A_out => A_oct0, 
        B_out => B_oct0,
        C_out => C_oct0
    );

u_octect1 : entity work.octectRelatedBuffers
    generic map(
        LANES => LANES_PER_OCTECT,
        REG_W => REG_W,
        FP16_W => FP16_W
    )
    port map(
        clk => clk,
        rst => rst,
        load_en => load_en,
        load_ph => load_ph,
        rf_rd_data_port_a => rf_a_oct1,
        rf_rd_data_port_b => rf_b_oct1,
        A_out => A_oct1,
        B_out => B_oct1,
        C_out => C_oct1
    );
    
--concatenate octect outputs into a 16-lane outputs
--convention:
--      lower bits --> octect0 lanes
--      upper bits --> octect1 lanes

A_out_16 <= A_oct0 & A_oct1; 
B_out_16 <= B_oct0 & B_oct1;
C_out_16 <= C_oct0 & C_oct1;

--hook point for later:

-- DPU array consumes A_out_16/B_out_16/C_out_16
-- produces accumulator / writeback

end rtl;
