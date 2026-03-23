library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.dpuArray_package.all;


entity octectCoreTop is
    generic(
        LANES   : integer := 8;
        REG_W   : integer := 32;
        ELEM_W  : integer := 32
    );
    port(
        clk     : in std_logic; 
        rst     : in std_logic;
        
        --control
        widthSel    : in std_logic_vector(1 downto 0);
        typeSel     : in std_logic_vector(2 downto 0);
        load_en     : in std_logic;
        load_ph     : in std_logic_vector(1 downto 0); -- 00=A, 01=B, 10=C
        load_pair   : in std_logic_vector(1 downto 0); -- 00-->slots0,1 01--> slots2,3
        
        hmma_step   : in std_logic; -- '0' = step0 inst, '1' = step1
        exec_step   : in std_logic_vector(1 downto 0); -- 00, 01, 10, 11
        
        --register file read returns
        rf_rd_data_port_a   : in arraySize8_32;
        rf_rd_data_port_b   : in arraySize8_32;
        
        --exposed results for the active octect (TG0 and TG4)
        W0_8_X3     : out arraySize4_8;
        W1_8_X3     : out arraySize4_8;
        W0_16_X3    : out arraySize4_16;
        W1_16_X3    : out arraySize4_16;
        W0_32_X3    : out arraySize4_32;
        W1_32_X3    : out arraySize4_32;
        
        step_done   : out std_logic
    );
        
end octectCoreTop;

architecture rtl of octectCoreTop is

component octectRelatedBuffers is
    generic (
        LANES   : integer := 8;
        REG_W   : integer := 32;
        ELEM_W  : integer := 32
    );
    port (
        clk     : in std_logic;
        rst     : in std_logic;
        
        load_en     : in std_logic;
        load_ph     : in std_logic_vector(1 downto 0);
        load_pair   : in std_logic_vector(1 downto 0);
        hmma_step   : in std_logic; --'0' = step0, '1'= step1

        exec_step   : in std_logic_vector(1 downto 0);
        
        rf_rd_data_port_a   : in arraySize8_32;
        rf_rd_data_port_b   : in arraySize8_32;
        
        A_tg0_out   : out arraySize4_32;
        A_tg4_out   : out arraySize4_32;
        B_blk_out   : out arraySize16_32;
        C_tg0_out   : out arraySize4_32;
        C_tg4_out   : out arraySize4_32
    );
end component;

component dpuArrayrel0 is --dpu Array consisting of 8 dpus.
     port(
        widthSel    : in std_logic_vector(1 downto 0);
        typeSel     : in std_logic_vector(2 downto 0);
        
        BufferA_0out8: in arraySize4_8; -- contains one row of 4 values of submatrixA0 related to threadgroup0
        BufferA_1out8: in arraySize4_8; -- contains one row of 4 values of submatrixA1 related to threadgroup4
        BufferB_0out8: in arraysize16_8; --contains all the columns of subamtrix B which is used contemporarely to all the DPUs of the two threadgroups
        AccumulatorBuffer_0out8: in arraySize4_8; --contains one row of 4 values of submatrixC section related to threadgroup0
        AccumulatorBuffer_1out8: in arraySize4_8; -- contains one row of 4 values of submatrixC related to threadgroup4 of the octect.
        
        BufferA_0out16: in arraySize4_16;
        BufferA_1out16: in arraySize4_16;
        BufferB_0out16: in arraySize16_16;
        AccumulatorBuffer_0out16: in arraySize4_16;
        AccumulatorBuffer_1out16: in arraySize4_16;
        
        BufferA_0out32: in arraySize4_32;
        BufferA_1out32: in arraySize4_32;
        BufferB_0out32: in arraySize16_32;
        AccumulatorBuffer_0out32: in arraySize4_32;
        AccumulatorBuffer_1out32: in arraySize4_32;
        
        W0_8_X3: out arraySize4_8;
        W1_8_X3: out arraySize4_8;
        
        W0_16_X3: out arraySize4_16;
        W1_16_X3: out arraySize4_16;
        
        W0_32_X3: out arraySize4_32;
        W1_32_X3: out arraySize4_32
    );
end component;

--raw slot outputs from buffers

signal A_tg0_slots_out_s : arraySize4_32; --signal which contains 4 values of either 
signal A_tg4_slots_out_s : arraySize4_32; 
signal B_blk_slots_out_s : arraySize16_32;
signal C_tg0_slots_out_s : arraySize4_32;
signal C_tg4_slots_out_s : arraySize4_32;

--repacked signals per dpu array

signal BufferA_0out8_s  : arraySize4_8;
signal BufferA_1out8_s  : arraySize4_8;
signal BufferB_0out8_s  : arraySize16_8; 
signal AccumulatorBuffer_0out8_s : arraySize4_8;
signal AccumulatorBuffer_1out8_s : arraySize4_8;

signal BufferA_0out16_s : arraySize4_16;
signal BufferA_1out16_s : arraySize4_16;
signal BufferB_0out16_s : arraySize16_16;
signal AccumulatorBuffer_0out16_s : arraySize4_16;
signal AccumulatorBuffer_1out16_s : arraySize4_16;

signal BufferA_0out32_s : arraySize4_32;
signal BufferA_1out32_s : arraySize4_32;
signal BufferB_0out32_s : arraySize16_32;
signal AccumulatorBuffer_0out32_s : arraySize4_32;
signal AccumulatorBuffer_1out32_s : arraySize4_32;

begin

    --buffer instance
    
    u_buffers : octectRelatedBuffers
    generic map(
        LANES => LANES,
        REG_W => REG_W,
        ELEM_W => ELEM_W
    )
    port map(
        clk => clk,
        rst => rst,
        load_en => load_en,
        load_ph => load_ph,
        load_pair => load_pair,
        hmma_step => hmma_step,
        exec_step => exec_step,
        rf_rd_data_port_a => rf_rd_data_port_a,
        rf_rd_data_port_b => rf_rd_data_port_b,
        
        A_tg0_out => A_tg0_slots_out_s,
        A_tg4_out => A_tg4_slots_out_s,
        B_blk_out => B_blk_slots_out_s,
        C_tg0_out => C_tg0_slots_out_s,
        C_tg4_out => C_tg4_slots_out_s
    );
    
    --repack / unpack raw 32 bit slots into the shapes expected by dpuArrayRel0
    
    process(A_tg0_slots_out_s, A_tg4_slots_out_s, B_blk_slots_out_s,
            C_tg0_slots_out_s, C_tg4_slots_out_s)

    begin
        --fp32 view
        
    BufferA_0out32_s <= A_tg0_slots_out_s;
    BufferA_1out32_s <= A_tg4_slots_out_s;
    BufferB_0out32_s <= B_blk_slots_out_s;
    AccumulatorBuffer_0out32_s <= C_tg0_slots_out_s;
    AccumulatorBuffer_1out32_s <= C_tg4_slots_out_s;
    
    --FP16
    --convention
    -- A/C use slot0 + slot1 for the particular hmma
    -- B uses first 8 slots (located in 8 entries of the bufferB, each entry containing two values) 
    BufferA_0out16_s(0) <= A_tg0_slots_out_s(0)(15 downto 0);
    BufferA_0out16_s(1) <= A_tg0_slots_out_s(0)(31 downto 16) ;
    BufferA_0out16_s(2) <= A_tg0_slots_out_s(1)(15 downto 0) ;
    BufferA_0out16_s(3) <= A_tg0_slots_out_s(1)(31 downto 16) ;
    
    BufferA_1out16_s(0) <= A_tg4_slots_out_s(0)(15 downto 0) ;
    BufferA_1out16_s(1) <= A_tg4_slots_out_s(0)(31 downto 16) ;
    BufferA_1out16_s(2) <= A_tg4_slots_out_s(1)(15 downto 0) ;
    BufferA_1out16_s(3) <= A_tg4_slots_out_s(1)(31 downto 16) ;
    
    AccumulatorBuffer_0out16_s(0) <= C_tg0_slots_out_s(0)(15 downto 0);
    AccumulatorBuffer_0out16_s(1) <= C_tg0_slots_out_s(0)(31 downto 16);
    AccumulatorBuffer_0out16_s(2) <= C_tg0_slots_out_s(1)(15 downto 0);
    AccumulatorBuffer_0out16_s(3) <= C_tg0_slots_out_s(1)(31 downto 16);
    
    AccumulatorBuffer_1out16_s(0) <= C_tg4_slots_out_s(0)(15 downto 0);
    AccumulatorBuffer_1out16_s(1) <= C_tg4_slots_out_s(0)(31 downto 16);
    AccumulatorBuffer_1out16_s(2) <= C_tg4_slots_out_s(1)(15 downto 0);
    AccumulatorBuffer_1out16_s(3) <= C_tg4_slots_out_s(1)(31 downto 16);
    
    BufferB_0out16_s(0) <= B_blk_slots_out_s(0)(15 downto 0);
    BufferB_0out16_s(1) <= B_blk_slots_out_s(0)(31 downto 16);
    BufferB_0out16_s(2) <= B_blk_slots_out_s(1)(15 downto 0);
    BufferB_0out16_s(3) <= B_blk_slots_out_s(1)(31 downto 16);
    BufferB_0out16_s(4) <= B_blk_slots_out_s(4)(15 downto 0);
    BufferB_0out16_s(5) <= B_blk_slots_out_s(4)(31 downto 16);
    BufferB_0out16_s(6) <= B_blk_slots_out_s(5)(15 downto 0);
    BufferB_0out16_s(7) <= B_blk_slots_out_s(5)(31 downto 16);
    BufferB_0out16_s(8) <= B_blk_slots_out_s(8)(15 downto 0);
    BufferB_0out16_s(9) <= B_blk_slots_out_s(8)(31 downto 16);
    BufferB_0out16_s(10) <= B_blk_slots_out_s(9)(15 downto 0);
    BufferB_0out16_s(11) <= B_blk_slots_out_s(9)(31 downto 16);
    BufferB_0out16_s(12) <= B_blk_slots_out_s(12)(15 downto 0);
    BufferB_0out16_s(13) <= B_blk_slots_out_s(12)(31 downto 16);
    BufferB_0out16_s(14) <= B_blk_slots_out_s(13)(15 downto 0);
    BufferB_0out16_s(15) <= B_blk_slots_out_s(13)(31 downto 16); 
    
    --fp8 view
    --convention:
    --A/C use only slot0 (located in one Buffer Entry) of the buffer for the particular hmma
    --B uses first 4 slots (located in 4 buffer entries, each containing 4 values)
    
    BufferA_0out8_s(0) <= A_tg0_slots_out_s(0)(7 downto 0);
    BufferA_0out8_s(1) <= A_tg0_slots_out_s(0)(15 downto 8);
    BufferA_0out8_s(2) <= A_tg0_slots_out_s(0)(23 downto 16);
    BufferA_0out8_s(3) <= A_tg0_slots_out_s(0)(31 downto 24);
    
    BufferA_1out8_s(0) <= A_tg4_slots_out_s(0)(7 downto 0);
    BufferA_1out8_s(1) <= A_tg4_slots_out_s(0)(15 downto 8);
    BufferA_1out8_s(2) <= A_tg4_slots_out_s(0)(23 downto 16);
    BufferA_1out8_s(3) <= A_tg4_slots_out_s(0)(31 downto 24);
    
    AccumulatorBuffer_0out8_s(0) <= C_tg0_slots_out_s(0)(7 downto 0);
    AccumulatorBuffer_0out8_s(1) <= C_tg0_slots_out_s(0)(15 downto 8);
    AccumulatorBuffer_0out8_s(2) <= C_tg0_slots_out_s(0)(23 downto 16);
    AccumulatorBuffer_0out8_s(3) <= C_tg0_slots_out_s(0)(31 downto 24);
    
    AccumulatorBuffer_1out8_s(0) <= C_tg4_slots_out_s(0)(7 downto 0);
    AccumulatorBuffer_1out8_s(1) <= C_tg4_slots_out_s(0)(15 downto 8);
    AccumulatorBuffer_1out8_s(2) <= C_tg4_slots_out_s(0)(23 downto 16);
    AccumulatorBuffer_1out8_s(3) <= C_tg4_slots_out_s(0)(31 downto 24);
    
    BufferB_0out8_s(0) <= B_blk_slots_out_s(0)(7 downto 0);
    BufferB_0out8_s(1) <= B_blk_slots_out_s(0)(15 downto 8);
    BufferB_0out8_s(2) <= B_blk_slots_out_s(0)(23 downto 16);
    BufferB_0out8_s(3) <= B_blk_slots_out_s(0)(31 downto 24);
    BufferB_0out8_s(4) <= B_blk_slots_out_s(4)(7 downto 0);
    BufferB_0out8_s(5) <= B_blk_slots_out_s(4)(15 downto 8);
    BufferB_0out8_s(6) <= B_blk_slots_out_s(4)(23 downto 16);
    BufferB_0out8_s(7) <= B_blk_slots_out_s(4)(31 downto 24);
    BufferB_0out8_s(8) <= B_blk_slots_out_s(8)(7 downto 0);
    BufferB_0out8_s(9) <= B_blk_slots_out_s(8)(15 downto 8);
    BufferB_0out8_s(10) <= B_blk_slots_out_s(8)(23 downto 16);
    BufferB_0out8_s(11) <= B_blk_slots_out_s(8)(31 downto 24);
    BufferB_0out8_s(12) <= B_blk_slots_out_s(12)(7 downto 0);
    BufferB_0out8_s(13) <= B_blk_slots_out_s(12)(15 downto 8);
    BufferB_0out8_s(14) <= B_blk_slots_out_s(12)(23 downto 16);
    BufferB_0out8_s(15) <= B_blk_slots_out_s(12)(31 downto 24);

    end process;
    
    --dpu array instance
    
    u_dpu_array : dpuArrayrel0
    port map(
        widthSel => widthSel, 
        typeSel => typeSel, 
        
        BufferA_0out8 => BufferA_0out8_s,
        BufferA_1out8 => BufferA_1out8_s,
        BufferB_0out8 => BufferB_0out8_s,
        AccumulatorBuffer_0out8 => AccumulatorBuffer_0out8_s,
        AccumulatorBuffer_1out8 => AccumulatorBuffer_1out8_s,
        
        BufferA_0out16 => BufferA_0out16_s,
        BufferA_1out16 => BufferA_1out16_s,
        BufferB_0out16 => BufferB_0out16_s,
        AccumulatorBuffer_0out16 => AccumulatorBuffer_0out16_s,
        AccumulatorBuffer_1out16 => AccumulatorBuffer_1out16_s,
        
        BufferA_0out32 => BufferA_0out32_s,
        BufferA_1out32 => BufferA_1out32_s,
        BufferB_0out32 => BufferB_0out32_s,
        AccumulatorBuffer_0out32 => AccumulatorBuffer_0out32_s,
        AccumulatorBuffer_1out32 => AccumulatorBuffer_1out32_s,
        
        W0_8_X3 => W0_8_X3,
        W1_8_X3 => W1_8_X3,
        
        W0_16_X3 => W0_16_X3,
        W1_16_X3 => W1_16_X3,
        
        W0_32_X3 => W0_32_X3,
        W1_32_X3 => W1_32_X3
    );
    
    step_done <= '1' when exec_step = "11" else '0' ;
       
end rtl;
