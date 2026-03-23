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
        rf_rd_data_port_a   : in std_logic_vector(LANES*REG_W-1 downto 0);
        rf_rd_data_port_b   : in std_logic_vector(LANES*REG_W-1 downto 0);
        
        --exposed results for the active octect (TG0 and TG4)
        W0_8_X3     : out arraySize4_8;
        W1_8_X3     : out arraySize4_8;
        W0_16_X3    : out arraySize4_16;
        W1_16_X3    : out arraySize4_16;
        W0_32_X3    : out arraySize4_32;
        W1_32_X3    : out arraySize4_32
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
        
        rf_rd_data_port_a   : in std_logic_vector(LANES*REG_W-1 downto 0);
        rf_rd_data_port_b   : in std_logic_vector(LANES*REG_W-1 downto 0);
        
        A_tg0_out   : out std_logic_vector(4*ELEM_W-1 downto 0);
        A_tg4_out   : out std_logic_vector(4*ELEM_W-1 downto 0);
        B_blk_out   : out std_logic_vector(16*ELEM_W-1 downto 0);
        C_tg0_out   : out std_logic_vector(4*ELEM_W-1 downto 0);
        C_tg4_out   : out std_logic_vector(4*ELEM_W-1 downto 0)
    );
end component;

component dpuArrayrel0 is
     port(
        widthSel    : in std_logic_vector(1 downto 0);
        typeSel     : in std_logic_vector(2 downto 0);
        
        BufferA_0out8: in arraySize4_8;
        BufferA_1out8: in arraySize4_8;
        BufferA_2out8: in arraySize4_8;
        BufferA_3out8: in arraySize4_8;
        BufferB_0out8: in arraysize16_8;
        AccumulatorBuffer_0out8: in arraySize4_8;
        AccumulatorBuffer_1out8: in arraySize4_8;
        AccumulatorBuffer_2out8: in arraySize4_8;
        AccumulatorBuffer_3out8: in arraySize4_8;
        
        BufferA_0out16: in arraySize4_16;
        BufferA_1out16: in arraySize4_16;
        BufferA_2out16: in arraySize4_16;
        BufferA_3out16: in arraySize4_16;
        BufferB_0out16: in arraySize16_16;
        AccumulatorBuffer_0out16: in arraySize4_16;
        AccumulatorBuffer_1out16: in arraySize4_16;
        AccumulatorBuffer_2out16: in arraySize4_16;
        AccumulatorBuffer_3out16: in arraySize4_16;
        
        BufferA_0out32: in arraySize4_32;
        BufferA_1out32: in arraySize4_32;
        BufferA_2out32: in arraySize4_32;
        BufferA_3out32: in arraySize4_32;
        BufferB_0out32: in arraySize16_32;
        AccumulatorBuffer_0out32: in arraySize4_32;
        AccumulatorBuffer_1out32: in arraySize4_32;
        AccumulatorBuffer_2out32: in arraySize4_32;
        AccumulatorBuffer_3out32: in arraySize4_32;
        
        W0_8_X3: out arraySize4_8;
        W1_8_X3: out arraySize4_8;
        W2_8_X3: out arraySize4_8;
        W3_8_X3: out arraySize4_8;
        
        W0_16_X3: out arraySize4_16;
        W1_16_X3: out arraySize4_16;
        W2_16_X3: out arraySize4_16;
        W3_16_X3: out arraySize4_16;
        
        W0_32_X3: out arraySize4_32;
        W1_32_X3: out arraySize4_32;
        W2_32_X3: out arraySize4_32;
        W3_32_X3: out arraySize4_32
    );
end component;

--raw slot outputs from buffers

signal A_tg0_slots_out_s : std_logic_vector(4*ELEM_W-1 downto 0);
signal A_tg4_slots_out_s : std_logic_vector(4*ELEM_W-1 downto 0);
signal B_blk_slots_out_s : std_logic_vector(16*ELEM_W-1 downto 0);
signal C_tg0_slots_out_s : std_logic_vector(4*ELEM_W-1 downto 0);
signal C_tg4_slots_out_s : std_logic_vector(4*ELEM_W-1 downto 0);

--repacked signals per dpu array

signal BufferA_0out8_s  : arraySize4_8;
signal BufferA_1out8_s  : arraySize4_8;
signal BufferA_2out8_s  : arraySize4_8 := (others => (others => '0'));
signal BufferA_3out8_s  : arraySize4_8 := (others => (others => '0'));
signal BufferB_0out8_s  : arraySize16_8;
signal AccumulatorBuffer_0out8_s : arraySize4_8;
signal AccumulatorBuffer_1out8_s : arraySize4_8;
signal AccumulatorBuffer_2out8_s : arraySize4_8 := (others => (others => '0'));
signal AccumulatorBuffer_3out8_s : arraySize4_8 := (others => (others => '0'));

signal BufferA_0out16_s : arraySize4_16;
signal BufferA_1out16_s : arraySize4_16;
signal BufferA_2out16_s : arraySize4_16 := (others => (others => '0'));
signal BufferA_3out16_s : arraySize4_16 := (others => (others => '0'));
signal BufferB_0out16_s : arraySize16_16;
signal AccumulatorBuffer_0out16_s : arraySize4_16;
signal AccumulatorBuffer_1out16_s : arraySize4_16;
signal AccumulatorBuffer_2out16_s : arraySize4_16 := (others => (others => '0'));
signal AccumulatorBuffer_3out16_s : arraySize4_16 := (others => (others => '0'));

signal BufferA_0out32_s : arraySize4_32;
signal BufferA_1out32_s : arraySize4_32;
signal BufferA_2out32_s : arraySize4_32 := (others => (others => '0'));
signal BufferA_3out32_s : arraySize4_32 := (others => (others => '0'));
signal BufferB_0out32_s : arraySize16_32;
signal AccumulatorBuffer_0out32_s : arraySize4_32;
signal AccumulatorBuffer_1out32_s : arraySize4_32;
signal AccumulatorBuffer_2out32_s : arraySize4_32 := (others => (others => '0'));
signal AccumulatorBuffer_3out32_s : arraySize4_32 := (others => (others => '0'));

--unused outputs from dpuArrayrel0
signal W2_8_X3_s : arraySize4_8;
signal W3_8_X3_s : arraySize4_8;
signal W2_16_X3_s : arraySize4_16;
signal W3_16_X3_s : arraySize4_16;
signal W2_32_X3_s : arraySize4_32;
signal W3_32_X3_s : arraySize4_32;

--helpers
function get_word(
    V : std_logic_vector;
    idx : integer
) return std_logic_vector is
    variable w : std_logic_vector(31 downto 0);
    variable b : integer;
begin
    b := idx * 32;
    w := V(b+31 downto b);
    return w;
end function;

function get_half(
    W : std_logic_vector(31 downto 0);
    idx : integer
) return std_logic_vector is
    variable h : std_logic_vector(15 downto 0);
begin
    h := W(idx*16 +15 downto idx*16);
    return h;
end function;

function get_byte(
    W : std_logic_vector(31 downto 0);
    idx : integer
) return std_logic_vector is
    variable b : std_logic_vector(7 downto 0);
begin 
    b := W(idx*8 + 7 downto idx*8);
    return b;
end function;

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
        
    for i in 0 to 3 loop
        BufferA_0out32_s(i) <= get_word(A_tg0_slots_out_s, i);
        BufferA_1out32_s(i) <= get_word(A_tg4_slots_out_s, i);
        AccumulatorBuffer_0out32_s(i) <= get_word(C_tg0_slots_out_s, i);
        AccumulatorBuffer_1out32_s(i) <= get_word(C_tg4_slots_out_s, i);
    end loop;
    
    for i in 0 to 15 loop
        BufferB_0out32_s(i) <= get_word(B_blk_slots_out_s, i);
    end loop;
    
    
    --FP16
    --convention
    -- A/C use slot0 + slot1 for the particular hmma
    -- B uses first 8 slots (located in 8 entries of the bufferB, each entry containing two values) 
    BufferA_0out16_s(0) <= get_half(get_word(A_tg0_slots_out_s, 0), 0) ;
    BufferA_0out16_s(1) <= get_half(get_word(A_tg0_slots_out_s, 0), 1) ;
    BufferA_0out16_s(2) <= get_half(get_word(A_tg0_slots_out_s, 1), 0) ;
    BufferA_0out16_s(3) <= get_half(get_word(A_tg0_slots_out_s, 1), 1) ;
    
    BufferA_1out16_s(0) <= get_half(get_word(A_tg4_slots_out_s, 0), 0) ;
    BufferA_1out16_s(1) <= get_half(get_word(A_tg4_slots_out_s, 0), 1) ;
    BufferA_1out16_s(2) <= get_half(get_word(A_tg4_slots_out_s, 1), 0) ;
    BufferA_1out16_s(3) <= get_half(get_word(A_tg4_slots_out_s, 1), 1) ;
    
    AccumulatorBuffer_0out16_s(0) <= get_half(get_word(C_tg0_slots_out_s, 0), 0);
    AccumulatorBuffer_0out16_s(1) <= get_half(get_word(C_tg0_slots_out_s, 0), 1);
    AccumulatorBuffer_0out16_s(2) <= get_half(get_word(C_tg0_slots_out_s, 1), 0);
    AccumulatorBuffer_0out16_s(3) <= get_half(get_word(C_tg0_slots_out_s, 1), 1);
    
    AccumulatorBuffer_1out16_s(0) <= get_half(get_word(C_tg4_slots_out_s, 0), 0);
    AccumulatorBuffer_1out16_s(1) <= get_half(get_word(C_tg4_slots_out_s, 0) ,1);
    AccumulatorBuffer_1out16_s(2) <= get_half(get_word(C_tg4_slots_out_s, 1) ,0);
    AccumulatorBuffer_1out16_s(3) <= get_half(get_word(C_tg4_slots_out_s, 1) ,1);
    
    for i in 0 to 7 loop
        BufferB_0out16_s(i*2)   <= get_half(get_word(B_blk_slots_out_s, i), 0);
        BufferB_0out16_s(i*2+1) <= get_half(get_word(B_blk_slots_out_s, i), 1);
    end loop;
    
    --fp8 view
    --convention:
    --A/C use only slot0 (located in one Buffer Entry) of the buffer for the particular hmma
    --B uses first 4 slots (located in 4 buffer entries, each containing 4 values)
    
    BufferA_0out8_s(0) <= get_byte(get_word(A_tg0_slots_out_s, 0), 0);
    BufferA_0out8_s(1) <= get_byte(get_word(A_tg0_slots_out_s, 0), 1);
    BufferA_0out8_s(2) <= get_byte(get_word(A_tg0_slots_out_s, 0), 2);
    BufferA_0out8_s(3) <= get_byte(get_word(A_tg0_slots_out_s, 0), 3);
    
    BufferA_1out8_s(0) <= get_byte(get_word(A_tg4_slots_out_s, 0), 0);
    BufferA_1out8_s(1) <= get_byte(get_word(A_tg4_slots_out_s, 0), 1);
    BufferA_1out8_s(2) <= get_byte(get_word(A_tg4_slots_out_s, 0), 2);
    BufferA_1out8_s(3) <= get_byte(get_word(A_tg4_slots_out_s, 0), 3);
    
    AccumulatorBuffer_0out8_s(0) <= get_byte(get_word(C_tg0_slots_out_s,0),0);
    AccumulatorBuffer_0out8_s(1) <= get_byte(get_word(C_tg0_slots_out_s,0),1);
    AccumulatorBuffer_0out8_s(2) <= get_byte(get_word(C_tg0_slots_out_s,0),2);
    AccumulatorBuffer_0out8_s(3) <= get_byte(get_word(C_tg0_slots_out_s,0),3);
    
    AccumulatorBuffer_1out8_s(0) <= get_byte(get_word(C_tg4_slots_out_s,0),0);
    AccumulatorBuffer_1out8_s(1) <= get_byte(get_word(C_tg4_slots_out_s,0),1);
    AccumulatorBuffer_1out8_s(2) <= get_byte(get_word(C_tg4_slots_out_s,0),2);
    AccumulatorBuffer_1out8_s(3) <= get_byte(get_word(C_tg4_slots_out_s,0),3);
    
    for i in 0 to 3 loop
        BufferB_0out8_s(i*4)    <= get_byte(get_word(B_blk_slots_out_s, i), 0);
        BufferB_0out8_s(i*4+1)  <= get_byte(get_word(B_blk_slots_out_s, i), 1);
        BufferB_0out8_s(i*4+2)  <= get_byte(get_word(B_blk_slots_out_s, i), 2);
        BufferB_0out8_s(i*4+3)  <= get_byte(get_word(B_blk_slots_out_s, i), 3);
    end loop;

    end process;
    
    --dpu array instance
    
    u_dpu_array : dpuArrayrel0
    port map(
        widthSel => widthSel, 
        typeSel => typeSel, 
        
        BufferA_0out8 => BufferA_0out8_s,
        BufferA_1out8 => BufferA_1out8_s,
        BufferA_2out8 => BufferA_2out8_s,
        BufferA_3out8 => BufferA_3out8_s,
        BufferB_0out8 => BufferB_0out8_s,
        AccumulatorBuffer_0out8 => AccumulatorBuffer_0out8_s,
        AccumulatorBuffer_1out8 => AccumulatorBuffer_1out8_s,
        AccumulatorBuffer_2out8 => AccumulatorBuffer_2out8_s,
        AccumulatorBuffer_3out8 => AccumulatorBuffer_3out8_s,
        
        BufferA_0out16 => BufferA_0out16_s,
        BufferA_1out16 => BufferA_1out16_s,
        BufferA_2out16 => BufferA_2out16_s,
        BufferA_3out16 => BufferA_3out16_s,
        BufferB_0out16 => BufferB_0out16_s,
        AccumulatorBuffer_0out16 => AccumulatorBuffer_0out16_s,
        AccumulatorBuffer_1out16 => AccumulatorBuffer_1out16_s,
        AccumulatorBuffer_2out16 => AccumulatorBuffer_2out16_s,
        AccumulatorBuffer_3out16 => AccumulatorBuffer_3out16_s,
        
        BufferA_0out32 => BufferA_0out32_s,
        BufferA_1out32 => BufferA_1out32_s,
        BufferA_2out32 => BufferA_2out32_s,
        BufferA_3out32 => BufferA_3out32_s,
        BufferB_0out32 => BufferB_0out32_s,
        AccumulatorBuffer_0out32 => AccumulatorBuffer_0out32_s,
        AccumulatorBuffer_1out32 => AccumulatorBuffer_1out32_s,
        AccumulatorBuffer_2out32 => AccumulatorBuffer_2out32_s,
        AccumulatorBuffer_3out32 => AccumulatorBuffer_3out32_s,
        
        W0_8_X3 => W0_8_X3,
        W1_8_X3 => W1_8_X3,
        W2_8_X3 => W2_8_X3_s,
        W3_8_X3 => W3_8_X3_s,
        
        W0_16_X3 => W0_16_X3,
        W1_16_X3 => W1_16_X3,
        W2_16_X3 => W2_16_X3_s,
        W3_16_X3 => W3_16_X3_s,
        
        W0_32_X3 => W0_32_X3,
        W1_32_X3 => W1_32_X3,
        W2_32_X3 => W2_32_X3_s,
        W3_32_X3 => W3_32_X3_s
        
    );
       
end rtl;
