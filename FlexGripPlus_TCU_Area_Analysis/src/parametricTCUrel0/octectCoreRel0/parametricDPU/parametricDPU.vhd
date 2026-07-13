
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library FixedP8_16_dpu;
use FixedP8_16_dpu.all;

library FixedP16_32_DPU;
use FixedP16_32_DPU.all;

library INT8_16_DPU;
use INT8_16_DPU.all;

library INT16_32_DPU;
use INT16_32_DPU.all;

library FP8_DPU;
use FP8_DPU.all;

library FP16_DPU;
use FP16_DPU.all;

library FP32_DPU;
use FP32_DPU.all;

library POSIT8_DPU;
use POSIT8_DPU.all;

library POSIT16_DPU;
use POSIT16_DPU.all;

library POSIT32_DPU;
use POSIT32_DPU.all;

library LNS16_DPU;
use LNS16_DPU.all;

-- rel 0 parametric DPU supported formats:
-- posit8, posit16, posit32
-- float8e4m3, float16, float32
-- fixPoint8_16, fixPoint16_32
-- int 8_16, int 16_32

--rel 1 will support 
-- LNS 8, LNS16, LNS32 

entity parametricDPUrel0 is
    Port ( widthSel : in std_logic_vector( 1 downto 0);
           typeSel : in std_logic_vector ( 2 downto 0);
           A0_8 : in std_logic_vector(7 downto 0);
           A1_8 : in std_logic_vector(7 downto 0);
           A2_8 : in std_logic_vector(7 downto 0);
           A3_8 : in std_logic_vector(7 downto 0);
           B0_8 : in std_logic_vector(7 downto 0);
           B1_8 : in std_logic_vector(7 downto 0);
           B2_8 : in std_logic_vector(7 downto 0);
           B3_8 : in std_logic_vector(7 downto 0);
           C0_8 : in std_logic_vector(7 downto 0);
           A0_16 : in std_logic_vector(15 downto 0);
           A1_16 : in std_logic_vector(15 downto 0);
           A2_16 : in std_logic_vector(15 downto 0);
           A3_16 : in std_logic_vector(15 downto 0);
           B0_16 : in std_logic_vector(15 downto 0);
           B1_16 : in std_logic_vector(15 downto 0);
           B2_16 : in std_logic_vector(15 downto 0);
           B3_16 : in std_logic_vector(15 downto 0);
           C0_16 : in std_logic_vector(15 downto 0);
           A0_32 : in std_logic_vector(31 downto 0);
           A1_32 : in std_logic_vector(31 downto 0);
           A2_32 : in std_logic_vector(31 downto 0);
           A3_32 : in std_logic_vector(31 downto 0);
           B0_32 : in std_logic_vector(31 downto 0);
           B1_32 : in std_logic_vector(31 downto 0);
           B2_32 : in std_logic_vector(31 downto 0);
           B3_32 : in std_logic_vector(31 downto 0);
           C0_32 : in std_logic_vector(31 downto 0);
           res_8: out std_logic_vector(7 downto 0);
           res_16: out std_logic_vector(15 downto 0);
           res_32: out std_logic_vector(31 downto 0) );
end parametricDPUrel0;

architecture Behavioral of parametricDPUrel0 is

signal out_DPU_FP8 : std_logic_vector( 7 downto 0 ) ;
signal out_DPU_FP16: std_logic_vector(15 downto 0 ) ;
signal out_DPU_FP32: std_logic_vector(31 downto 0 ) ;
signal out_DPU_posit8: std_logic_vector(7 downto 0) ;
signal out_DPU_posit16: std_logic_vector(15 downto 0) ;
signal out_DPU_posit32: std_logic_vector(31 downto 0) ;
signal out_DPU_FixP8_16: std_logic_vector(15 downto 0);
signal out_DPU_FixP16_32: std_logic_vector(31 downto 0);
signal out_DPU_int8_16: std_logic_vector(15 downto 0);
signal out_DPU_int16_32: std_logic_vector(31 downto 0);

signal out_DPU_LNS16 : std_logic_vector(15 downto 0);

--the multiplexer
component mux_rel0 is
    Port ( widthSel: in std_logic_vector( 1 downto 0); --selects the width
           typeSel: in std_logic_vector( 2 downto 0);  --selects the type
           float8e4m3out: in std_logic_vector( 7 downto 0);
           float16out: in std_logic_vector( 15 downto 0);
           float32out: in std_logic_vector( 31 downto 0);
           posit8out: in std_logic_vector( 7 downto 0);
           posit16out: in std_logic_vector( 15 downto 0);
           posit32out: in std_logic_vector( 31 downto 0);
           fixP8_16out: in std_logic_vector( 15 downto 0);
           fixP16_32out: in std_logic_vector ( 31 downto 0 );
           int8_16out: in std_logic_vector( 15 downto 0 );
           int16_32out: in std_logic_vector(31 downto 0 );
           LNS16out: in std_logic_vector(15 downto 0);
           out8bit : out std_logic_vector( 7 downto 0 );
           out16bit: out std_logic_vector( 15 downto 0);
           out32bit: out std_logic_vector( 31 downto 0) );
end component;

--float8e4m3 DPU:
component DotProductUnitFP8e4m3 is
    Port (
        aX0 : in  std_logic_vector(7 downto 0);
        aX1 : in  std_logic_vector(7 downto 0);
        aX2 : in  std_logic_vector(7 downto 0);
        aX3 : in  std_logic_vector(7 downto 0);
        bY0 : in  std_logic_vector(7 downto 0);
        bY1 : in  std_logic_vector(7 downto 0);
        bY2 : in  std_logic_vector(7 downto 0);
        bY3 : in  std_logic_vector(7 downto 0);
        cX0 : in std_logic_vector(7 downto 0);
        R  : out std_logic_vector(7 downto 0)
    );
end component;

--float16 DPU:
component DotProductUnitFP16 is
    Port (
        aX0 : in  std_logic_vector(15 downto 0);
        aX1 : in  std_logic_vector(15 downto 0);
        aX2 : in  std_logic_vector(15 downto 0);
        aX3 : in  std_logic_vector(15 downto 0);
        bY0 : in  std_logic_vector(15 downto 0);
        bY1 : in  std_logic_vector(15 downto 0);
        bY2 : in  std_logic_vector(15 downto 0);
        bY3 : in  std_logic_vector(15 downto 0);
        cX0 : in std_logic_vector(15 downto 0);
        R  : out std_logic_vector(15 downto 0)
    );
end component;

--float32 DPU:
component DotProductUnitFP32 is
    Port (
        aX0 : in  std_logic_vector(31 downto 0);
        aX1 : in  std_logic_vector(31 downto 0);
        aX2 : in  std_logic_vector(31 downto 0);
        aX3 : in  std_logic_vector(31 downto 0);
        bY0 : in  std_logic_vector(31 downto 0);
        bY1 : in  std_logic_vector(31 downto 0);
        bY2 : in  std_logic_vector(31 downto 0);
        bY3 : in  std_logic_vector(31 downto 0);
        cX0 : in std_logic_vector(31 downto 0);
        R  : out std_logic_vector(31 downto 0)
    );
end component;

--posit8 DPU:
component DotProductUnitPosit is
    Port (
        aX0 : in  std_logic_vector(7 downto 0);
        aX1 : in  std_logic_vector(7 downto 0);
        aX2 : in  std_logic_vector(7 downto 0);
        aX3 : in  std_logic_vector(7 downto 0);
        bY0 : in  std_logic_vector(7 downto 0);
        bY1 : in  std_logic_vector(7 downto 0);
        bY2 : in  std_logic_vector(7 downto 0);
        bY3 : in  std_logic_vector(7 downto 0);
        cX0 : in  std_logic_vector(7 downto 0);
        R  : out std_logic_vector(7 downto 0)
    );
end component;

--posit16 DPU:
component DotProductUnitPosit16 is
    Port (
        aX0 : in  std_logic_vector(15 downto 0);
        aX1 : in  std_logic_vector(15 downto 0);
        aX2 : in  std_logic_vector(15 downto 0);
        aX3 : in  std_logic_vector(15 downto 0);
        bY0 : in  std_logic_vector(15 downto 0);
        bY1 : in  std_logic_vector(15 downto 0);
        bY2 : in  std_logic_vector(15 downto 0);
        bY3 : in  std_logic_vector(15 downto 0);
        cX0 : in  std_logic_vector(15 downto 0);
        R  : out std_logic_vector(15 downto 0)
    );
end component;

--posit32 DPU:
component DotProductUnitPosit32 is
    Port (
        aX0 : in  std_logic_vector(31 downto 0);
        aX1 : in  std_logic_vector(31 downto 0);
        aX2 : in  std_logic_vector(31 downto 0);
        aX3 : in  std_logic_vector(31 downto 0);
        bY0 : in  std_logic_vector(31 downto 0);
        bY1 : in  std_logic_vector(31 downto 0);
        bY2 : in  std_logic_vector(31 downto 0);
        bY3 : in  std_logic_vector(31 downto 0);
        cX0 : in  std_logic_vector(31 downto 0);
        R  : out std_logic_vector(31 downto 0)
    );
end component; 

--fixPoint8_16 DPU:
component DotProductUnit_FixedPoint8_16 is
    Port (
        aX0 : in  std_logic_vector(7 downto 0);
        aX1 : in  std_logic_vector(7 downto 0);
        aX2 : in  std_logic_vector(7 downto 0);
        aX3 : in  std_logic_vector(7 downto 0);
        bY0 : in  std_logic_vector(7 downto 0);
        bY1 : in  std_logic_vector(7 downto 0);
        bY2 : in  std_logic_vector(7 downto 0);
        bY3 : in  std_logic_vector(7 downto 0);
        cX0 : in std_logic_vector(15 downto 0);
        R  : out std_logic_vector(15 downto 0)
    );
end component; 

--fixPoint16_32 DPU:
component DotProductUnit is
    Port (
        aX0 : in  std_logic_vector(15 downto 0);
        aX1 : in  std_logic_vector(15 downto 0);
        aX2 : in  std_logic_vector(15 downto 0);
        aX3 : in  std_logic_vector(15 downto 0);
        bY0 : in  std_logic_vector(15 downto 0);
        bY1 : in  std_logic_vector(15 downto 0);
        bY2 : in  std_logic_vector(15 downto 0);
        bY3 : in  std_logic_vector(15 downto 0);
       cX0 : in std_logic_vector(31 downto 0);
        R  : out std_logic_vector(31 downto 0)
    );
end component;

-- int8_16 DPU
component dot_unit_coreINT8 is
	port(		a_X0 : in std_logic_vector(7 downto 0);
				a_X1 : in std_logic_vector(7 downto 0);
				a_X2 : in std_logic_vector(7 downto 0);
				a_X3 : in std_logic_vector(7 downto 0);
				b_X0 : in std_logic_vector(7 downto 0);
				b_X1 : in std_logic_vector(7 downto 0);
				b_X2 : in std_logic_vector(7 downto 0);
				b_X3 : in std_logic_vector(7 downto 0);		
				c_X0: in std_logic_vector(15 downto 0);
				w_XX3: out std_logic_vector(15 downto 0)
	);
end component;

--int16_32 DPU
component dot_unit_coreINT is
	generic( long : natural := 16 );
	port(
			a_X0 : in std_logic_vector(long-1 downto 0);
			a_X1 : in std_logic_vector(long-1 downto 0);
			a_X2 : in std_logic_vector(long-1 downto 0);
			a_X3 : in std_logic_vector(long-1 downto 0);
			b_X0 : in std_logic_vector(long-1 downto 0);
			b_X1 : in std_logic_vector(long-1 downto 0);
			b_X2 : in std_logic_vector(long-1 downto 0);
			b_X3 : in std_logic_vector(long-1 downto 0);		
			c_X0: in std_logic_vector((2*long)-1 downto 0);
			w_XX3: out std_logic_vector((2*long)-1 downto 0)
	);
end component;

--LNS16 DPU

component LNS16_4_9_DPU is
    port (
        A0 : in  std_logic_vector(15 downto 0);
        A1 : in  std_logic_vector(15 downto 0);
        A2 : in  std_logic_vector(15 downto 0);
        A3 : in  std_logic_vector(15 downto 0);
        B0 : in  std_logic_vector(15 downto 0);
        B1 : in  std_logic_vector(15 downto 0);
        B2 : in  std_logic_vector(15 downto 0);
        B3 : in  std_logic_vector(15 downto 0);
        C0 : in  std_logic_vector(15 downto 0);
        R  : out std_logic_vector(15 downto 0)
    );
end component;

constant ZERO8  : std_logic_vector(7 downto 0)  := (others => '0');
constant ZERO16 : std_logic_vector(15 downto 0) := (others => '0');
constant ZERO32 : std_logic_vector(31 downto 0) := (others => '0');

signal is_fp8       : std_logic;
signal is_fp16      : std_logic;
signal is_fp32      : std_logic;
signal is_posit8    : std_logic;
signal is_posit16   : std_logic;
signal is_posit32   : std_logic;
signal is_fixP8_16  : std_logic;
signal is_fixP16_32 : std_logic;
signal is_int8_16   : std_logic;
signal is_int16_32  : std_logic;

signal is_lns16     : std_logic;

-- FP8 gated inputs
signal A0_8_fp8_g, A1_8_fp8_g, A2_8_fp8_g, A3_8_fp8_g : std_logic_vector(7 downto 0);
signal B0_8_fp8_g, B1_8_fp8_g, B2_8_fp8_g, B3_8_fp8_g : std_logic_vector(7 downto 0);
signal C0_8_fp8_g : std_logic_vector(7 downto 0);

-- FP16 gated inputs
signal A0_16_fp16_g, A1_16_fp16_g, A2_16_fp16_g, A3_16_fp16_g : std_logic_vector(15 downto 0);
signal B0_16_fp16_g, B1_16_fp16_g, B2_16_fp16_g, B3_16_fp16_g : std_logic_vector(15 downto 0);
signal C0_16_fp16_g : std_logic_vector(15 downto 0);

-- FP32 gated inputs
signal A0_32_fp32_g, A1_32_fp32_g, A2_32_fp32_g, A3_32_fp32_g : std_logic_vector(31 downto 0);
signal B0_32_fp32_g, B1_32_fp32_g, B2_32_fp32_g, B3_32_fp32_g : std_logic_vector(31 downto 0);
signal C0_32_fp32_g : std_logic_vector(31 downto 0);

-- POSIT8 gated inputs
signal A0_8_posit8_g, A1_8_posit8_g, A2_8_posit8_g, A3_8_posit8_g : std_logic_vector(7 downto 0);
signal B0_8_posit8_g, B1_8_posit8_g, B2_8_posit8_g, B3_8_posit8_g : std_logic_vector(7 downto 0);
signal C0_8_posit8_g : std_logic_vector(7 downto 0);

-- POSIT16 gated inputs
signal A0_16_posit16_g, A1_16_posit16_g, A2_16_posit16_g, A3_16_posit16_g : std_logic_vector(15 downto 0);
signal B0_16_posit16_g, B1_16_posit16_g, B2_16_posit16_g, B3_16_posit16_g : std_logic_vector(15 downto 0);
signal C0_16_posit16_g : std_logic_vector(15 downto 0);

-- POSIT32 gated inputs
signal A0_32_posit32_g, A1_32_posit32_g, A2_32_posit32_g, A3_32_posit32_g : std_logic_vector(31 downto 0);
signal B0_32_posit32_g, B1_32_posit32_g, B2_32_posit32_g, B3_32_posit32_g : std_logic_vector(31 downto 0);
signal C0_32_posit32_g : std_logic_vector(31 downto 0);

-- FixedP8_16 gated inputs
signal A0_8_fixP8_16_g, A1_8_fixP8_16_g, A2_8_fixP8_16_g, A3_8_fixP8_16_g : std_logic_vector(7 downto 0);
signal B0_8_fixP8_16_g, B1_8_fixP8_16_g, B2_8_fixP8_16_g, B3_8_fixP8_16_g : std_logic_vector(7 downto 0);
signal C0_16_fixP8_16_g : std_logic_vector(15 downto 0);

-- FixedP16_32 gated inputs
signal A0_16_fixP16_32_g, A1_16_fixP16_32_g, A2_16_fixP16_32_g, A3_16_fixP16_32_g : std_logic_vector(15 downto 0);
signal B0_16_fixP16_32_g, B1_16_fixP16_32_g, B2_16_fixP16_32_g, B3_16_fixP16_32_g : std_logic_vector(15 downto 0);
signal C0_32_fixP16_32_g : std_logic_vector(31 downto 0);

-- INT8_16 gated inputs
signal A0_8_int8_16_g, A1_8_int8_16_g, A2_8_int8_16_g, A3_8_int8_16_g : std_logic_vector(7 downto 0);
signal B0_8_int8_16_g, B1_8_int8_16_g, B2_8_int8_16_g, B3_8_int8_16_g : std_logic_vector(7 downto 0);
signal C0_16_int8_16_g : std_logic_vector(15 downto 0);

-- INT16_32 gated inputs
signal A0_16_int16_32_g, A1_16_int16_32_g, A2_16_int16_32_g, A3_16_int16_32_g : std_logic_vector(15 downto 0);
signal B0_16_int16_32_g, B1_16_int16_32_g, B2_16_int16_32_g, B3_16_int16_32_g : std_logic_vector(15 downto 0);
signal C0_32_int16_32_g : std_logic_vector(31 downto 0);

--LNS16 gated inputs
signal A0_16_LNS16_g, A1_16_LNS16_g, A2_16_LNS16_g, A3_16_LNS16_g : std_logic_vector(15 downto 0);
signal B0_16_LNS16_g, B1_16_LNS16_g, B2_16_LNS16_g, B3_16_LNS16_g : std_logic_vector(15 downto 0);
signal C0_16_LNS16_g : std_logic_vector(15 downto 0);

begin

-- Format selection decoding
is_fp8       <= '1' when widthSel = "00" and typeSel = "000" else '0';
is_fp16      <= '1' when widthSel = "01" and typeSel = "000" else '0';
is_fp32      <= '1' when widthSel = "10" and typeSel = "000" else '0';

is_posit8    <= '1' when widthSel = "00" and typeSel = "001" else '0';
is_posit16   <= '1' when widthSel = "01" and typeSel = "001" else '0';
is_posit32   <= '1' when widthSel = "10" and typeSel = "001" else '0';

is_fixP8_16  <= '1' when widthSel = "00" and typeSel = "010" else '0';
is_fixP16_32 <= '1' when widthSel = "01" and typeSel = "010" else '0';

is_int8_16   <= '1' when widthSel = "00" and typeSel = "011" else '0';
is_int16_32  <= '1' when widthSel = "01" and typeSel = "011" else '0';

is_LNS16     <= '1' when widthSel = "01" and typeSel = "100" else '0';

-- FP8 gating
A0_8_fp8_g <= A0_8 when is_fp8 = '1' else ZERO8;
A1_8_fp8_g <= A1_8 when is_fp8 = '1' else ZERO8;
A2_8_fp8_g <= A2_8 when is_fp8 = '1' else ZERO8;
A3_8_fp8_g <= A3_8 when is_fp8 = '1' else ZERO8;
B0_8_fp8_g <= B0_8 when is_fp8 = '1' else ZERO8;
B1_8_fp8_g <= B1_8 when is_fp8 = '1' else ZERO8;
B2_8_fp8_g <= B2_8 when is_fp8 = '1' else ZERO8;
B3_8_fp8_g <= B3_8 when is_fp8 = '1' else ZERO8;
C0_8_fp8_g <= C0_8 when is_fp8 = '1' else ZERO8;

-- FP16 gating
A0_16_fp16_g <= A0_16 when is_fp16 = '1' else ZERO16;
A1_16_fp16_g <= A1_16 when is_fp16 = '1' else ZERO16;
A2_16_fp16_g <= A2_16 when is_fp16 = '1' else ZERO16;
A3_16_fp16_g <= A3_16 when is_fp16 = '1' else ZERO16;
B0_16_fp16_g <= B0_16 when is_fp16 = '1' else ZERO16;
B1_16_fp16_g <= B1_16 when is_fp16 = '1' else ZERO16;
B2_16_fp16_g <= B2_16 when is_fp16 = '1' else ZERO16;
B3_16_fp16_g <= B3_16 when is_fp16 = '1' else ZERO16;
C0_16_fp16_g <= C0_16 when is_fp16 = '1' else ZERO16;

-- FP32 gating
A0_32_fp32_g <= A0_32 when is_fp32 = '1' else ZERO32;
A1_32_fp32_g <= A1_32 when is_fp32 = '1' else ZERO32;
A2_32_fp32_g <= A2_32 when is_fp32 = '1' else ZERO32;
A3_32_fp32_g <= A3_32 when is_fp32 = '1' else ZERO32;
B0_32_fp32_g <= B0_32 when is_fp32 = '1' else ZERO32;
B1_32_fp32_g <= B1_32 when is_fp32 = '1' else ZERO32;
B2_32_fp32_g <= B2_32 when is_fp32 = '1' else ZERO32;
B3_32_fp32_g <= B3_32 when is_fp32 = '1' else ZERO32;
C0_32_fp32_g <= C0_32 when is_fp32 = '1' else ZERO32;

-- POSIT8 gating
A0_8_posit8_g <= A0_8 when is_posit8 = '1' else ZERO8;
A1_8_posit8_g <= A1_8 when is_posit8 = '1' else ZERO8;
A2_8_posit8_g <= A2_8 when is_posit8 = '1' else ZERO8;
A3_8_posit8_g <= A3_8 when is_posit8 = '1' else ZERO8;
B0_8_posit8_g <= B0_8 when is_posit8 = '1' else ZERO8;
B1_8_posit8_g <= B1_8 when is_posit8 = '1' else ZERO8;
B2_8_posit8_g <= B2_8 when is_posit8 = '1' else ZERO8;
B3_8_posit8_g <= B3_8 when is_posit8 = '1' else ZERO8;
C0_8_posit8_g <= C0_8 when is_posit8 = '1' else ZERO8;

-- POSIT16 gating
A0_16_posit16_g <= A0_16 when is_posit16 = '1' else ZERO16;
A1_16_posit16_g <= A1_16 when is_posit16 = '1' else ZERO16;
A2_16_posit16_g <= A2_16 when is_posit16 = '1' else ZERO16;
A3_16_posit16_g <= A3_16 when is_posit16 = '1' else ZERO16;
B0_16_posit16_g <= B0_16 when is_posit16 = '1' else ZERO16;
B1_16_posit16_g <= B1_16 when is_posit16 = '1' else ZERO16;
B2_16_posit16_g <= B2_16 when is_posit16 = '1' else ZERO16;
B3_16_posit16_g <= B3_16 when is_posit16 = '1' else ZERO16;
C0_16_posit16_g <= C0_16 when is_posit16 = '1' else ZERO16;

-- POSIT32 gating
A0_32_posit32_g <= A0_32 when is_posit32 = '1' else ZERO32;
A1_32_posit32_g <= A1_32 when is_posit32 = '1' else ZERO32;
A2_32_posit32_g <= A2_32 when is_posit32 = '1' else ZERO32;
A3_32_posit32_g <= A3_32 when is_posit32 = '1' else ZERO32;
B0_32_posit32_g <= B0_32 when is_posit32 = '1' else ZERO32;
B1_32_posit32_g <= B1_32 when is_posit32 = '1' else ZERO32;
B2_32_posit32_g <= B2_32 when is_posit32 = '1' else ZERO32;
B3_32_posit32_g <= B3_32 when is_posit32 = '1' else ZERO32;
C0_32_posit32_g <= C0_32 when is_posit32 = '1' else ZERO32;

-- FixedP8_16 gating
A0_8_fixP8_16_g <= A0_8 when is_fixP8_16 = '1' else ZERO8;
A1_8_fixP8_16_g <= A1_8 when is_fixP8_16 = '1' else ZERO8;
A2_8_fixP8_16_g <= A2_8 when is_fixP8_16 = '1' else ZERO8;
A3_8_fixP8_16_g <= A3_8 when is_fixP8_16 = '1' else ZERO8;
B0_8_fixP8_16_g <= B0_8 when is_fixP8_16 = '1' else ZERO8;
B1_8_fixP8_16_g <= B1_8 when is_fixP8_16 = '1' else ZERO8;
B2_8_fixP8_16_g <= B2_8 when is_fixP8_16 = '1' else ZERO8;
B3_8_fixP8_16_g <= B3_8 when is_fixP8_16 = '1' else ZERO8;
C0_16_fixP8_16_g <= C0_16 when is_fixP8_16 = '1' else ZERO16;

-- FixedP16_32 gating
A0_16_fixP16_32_g <= A0_16 when is_fixP16_32 = '1' else ZERO16;
A1_16_fixP16_32_g <= A1_16 when is_fixP16_32 = '1' else ZERO16;
A2_16_fixP16_32_g <= A2_16 when is_fixP16_32 = '1' else ZERO16;
A3_16_fixP16_32_g <= A3_16 when is_fixP16_32 = '1' else ZERO16;
B0_16_fixP16_32_g <= B0_16 when is_fixP16_32 = '1' else ZERO16;
B1_16_fixP16_32_g <= B1_16 when is_fixP16_32 = '1' else ZERO16;
B2_16_fixP16_32_g <= B2_16 when is_fixP16_32 = '1' else ZERO16;
B3_16_fixP16_32_g <= B3_16 when is_fixP16_32 = '1' else ZERO16;
C0_32_fixP16_32_g <= C0_32 when is_fixP16_32 = '1' else ZERO32;

-- INT8_16 gating
A0_8_int8_16_g <= A0_8 when is_int8_16 = '1' else ZERO8;
A1_8_int8_16_g <= A1_8 when is_int8_16 = '1' else ZERO8;
A2_8_int8_16_g <= A2_8 when is_int8_16 = '1' else ZERO8;
A3_8_int8_16_g <= A3_8 when is_int8_16 = '1' else ZERO8;
B0_8_int8_16_g <= B0_8 when is_int8_16 = '1' else ZERO8;
B1_8_int8_16_g <= B1_8 when is_int8_16 = '1' else ZERO8;
B2_8_int8_16_g <= B2_8 when is_int8_16 = '1' else ZERO8;
B3_8_int8_16_g <= B3_8 when is_int8_16 = '1' else ZERO8;
C0_16_int8_16_g <= C0_16 when is_int8_16 = '1' else ZERO16;

-- INT16_32 gating
A0_16_int16_32_g <= A0_16 when is_int16_32 = '1' else ZERO16;
A1_16_int16_32_g <= A1_16 when is_int16_32 = '1' else ZERO16;
A2_16_int16_32_g <= A2_16 when is_int16_32 = '1' else ZERO16;
A3_16_int16_32_g <= A3_16 when is_int16_32 = '1' else ZERO16;
B0_16_int16_32_g <= B0_16 when is_int16_32 = '1' else ZERO16;
B1_16_int16_32_g <= B1_16 when is_int16_32 = '1' else ZERO16;
B2_16_int16_32_g <= B2_16 when is_int16_32 = '1' else ZERO16;
B3_16_int16_32_g <= B3_16 when is_int16_32 = '1' else ZERO16;
C0_32_int16_32_g <= C0_32 when is_int16_32 = '1' else ZERO32;

--LNS16 gating
A0_16_LNS16_g <= A0_16 when is_LNS16 = '1' else ZERO16;
A1_16_LNS16_g <= A1_16 when is_LNS16 = '1' else ZERO16;
A2_16_LNS16_g <= A2_16 when is_LNS16 = '1' else ZERO16;
A3_16_LNS16_g <= A3_16 when is_LNS16 = '1' else ZERO16;
B0_16_LNS16_g <= B0_16 when is_LNS16 = '1' else ZERO16;
B1_16_LNS16_g <= B1_16 when is_LNS16 = '1' else ZERO16;
B2_16_LNS16_g <= B2_16 when is_LNS16 = '1' else ZERO16;
B3_16_LNS16_g <= B3_16 when is_LNS16 = '1' else ZERO16;
C0_16_LNS16_g <= C0_16 when is_LNS16 = '1' else ZERO16;

dpu_fp8 : DotProductUnitFP8e4m3 
    port map (
        aX0 => A0_8_fp8_g,
        aX1 => A1_8_fp8_g,
        aX2 => A2_8_fp8_g,
        aX3 => A3_8_fp8_g,
        bY0 => B0_8_fp8_g,
        bY1 => B1_8_fp8_g,
        bY2 => B2_8_fp8_g,
        bY3 => B3_8_fp8_g,
        cX0 => C0_8_fp8_g,
        R   => out_DPU_FP8
    );

dpu_fp16: DotProductUnitFP16
    port map (
        aX0 => A0_16_fp16_g,
        aX1 => A1_16_fp16_g,
        aX2 => A2_16_fp16_g,
        aX3 => A3_16_fp16_g,
        bY0 => B0_16_fp16_g,
        bY1 => B1_16_fp16_g,
        bY2 => B2_16_fp16_g,
        bY3 => B3_16_fp16_g,
        cX0 => C0_16_fp16_g,
        R   => out_DPU_FP16
    );

dpu_fp32: DotProductUnitFP32
    port map (
        aX0 => A0_32_fp32_g,
        aX1 => A1_32_fp32_g,
        aX2 => A2_32_fp32_g,
        aX3 => A3_32_fp32_g,
        bY0 => B0_32_fp32_g,
        bY1 => B1_32_fp32_g,
        bY2 => B2_32_fp32_g,
        bY3 => B3_32_fp32_g,
        cX0 => C0_32_fp32_g,
        R   => out_DPU_FP32
    );

dpu_posit8: DotProductUnitPosit
    port map (
        aX0 => A0_8_posit8_g,
        aX1 => A1_8_posit8_g,
        aX2 => A2_8_posit8_g,
        aX3 => A3_8_posit8_g,
        bY0 => B0_8_posit8_g,
        bY1 => B1_8_posit8_g,
        bY2 => B2_8_posit8_g,
        bY3 => B3_8_posit8_g,
        cX0 => C0_8_posit8_g,
        R   => out_DPU_posit8
    );

dpu_posit16: DotProductUnitPosit16
    port map (
        aX0 => A0_16_posit16_g,
        aX1 => A1_16_posit16_g,
        aX2 => A2_16_posit16_g,
        aX3 => A3_16_posit16_g,
        bY0 => B0_16_posit16_g,
        bY1 => B1_16_posit16_g,
        bY2 => B2_16_posit16_g,
        bY3 => B3_16_posit16_g,
        cX0 => C0_16_posit16_g,
        R   => out_DPU_posit16
    );

dpu_posit32: DotProductUnitPosit32
    port map (
        aX0 => A0_32_posit32_g,
        aX1 => A1_32_posit32_g,
        aX2 => A2_32_posit32_g,
        aX3 => A3_32_posit32_g,
        bY0 => B0_32_posit32_g,
        bY1 => B1_32_posit32_g,
        bY2 => B2_32_posit32_g,
        bY3 => B3_32_posit32_g,
        cX0 => C0_32_posit32_g,
        R   => out_DPU_posit32
    );

dpu_FixP8_16: DotProductUnit_FixedPoint8_16 
    port map (
        aX0 => A0_8_fixP8_16_g,
        aX1 => A1_8_fixP8_16_g,
        aX2 => A2_8_fixP8_16_g,
        aX3 => A3_8_fixP8_16_g,
        bY0 => B0_8_fixP8_16_g,
        bY1 => B1_8_fixP8_16_g,
        bY2 => B2_8_fixP8_16_g,
        bY3 => B3_8_fixP8_16_g,
        cX0 => C0_16_fixP8_16_g,
        R   => out_DPU_FixP8_16
    );

dpu_FixP16_32: DotProductUnit
    port map (
        aX0 => A0_16_fixP16_32_g,
        aX1 => A1_16_fixP16_32_g,
        aX2 => A2_16_fixP16_32_g,
        aX3 => A3_16_fixP16_32_g,
        bY0 => B0_16_fixP16_32_g,
        bY1 => B1_16_fixP16_32_g,
        bY2 => B2_16_fixP16_32_g,
        bY3 => B3_16_fixP16_32_g,
        cX0 => C0_32_fixP16_32_g,
        R   => out_DPU_FixP16_32
    );

dpu_int8_16: dot_unit_coreINT8
    port map (
        a_X0 => A0_8_int8_16_g,
        a_X1 => A1_8_int8_16_g,
        a_X2 => A2_8_int8_16_g,
        a_X3 => A3_8_int8_16_g,
        b_X0 => B0_8_int8_16_g,
        b_X1 => B1_8_int8_16_g,
        b_X2 => B2_8_int8_16_g,
        b_X3 => B3_8_int8_16_g,
        c_X0 => C0_16_int8_16_g,
        w_XX3 => out_DPU_int8_16
    );

dpu_int16_32: dot_unit_coreINT
    port map (
        a_X0 => A0_16_int16_32_g,
        a_X1 => A1_16_int16_32_g,
        a_X2 => A2_16_int16_32_g,
        a_X3 => A3_16_int16_32_g,
        b_X0 => B0_16_int16_32_g,
        b_X1 => B1_16_int16_32_g,
        b_X2 => B2_16_int16_32_g,
        b_X3 => B3_16_int16_32_g,
        c_X0 => C0_32_int16_32_g,
        w_XX3 => out_DPU_int16_32
    );

dpu_LNS16: LNS16_4_9_DPU
    port map (
        A0 => A0_16_LNS16_g,
        A1 => A1_16_LNS16_g,
        A2 => A2_16_LNS16_g,
        A3 => A3_16_LNS16_g,
        B0 => B0_16_LNS16_g,
        B1 => B1_16_LNS16_g,
        B2 => B2_16_LNS16_g,
        B3 => B3_16_LNS16_g,
        C0 => C0_16_LNS16_g,
        R   => out_DPU_LNS16
    );

mux : mux_rel0 
    port map ( widthSel => widthSel,
               typeSel => typeSel ,
               float8e4m3out => out_DPU_FP8 ,
               float16out => out_DPU_FP16 ,
               float32out => out_DPU_FP32 ,
               posit8out => out_DPU_posit8 ,
               posit16out => out_DPU_posit16,
               posit32out => out_DPU_posit32,
               fixP8_16out => out_DPU_FixP8_16,
               fixP16_32out => out_DPU_FixP16_32 ,
               int8_16out => out_DPU_int8_16,
               int16_32out => out_DPU_int16_32,
               LNS16out => out_DPU_LNS16,
               out8bit => res_8, 
               out16bit => res_16, 
               out32bit => res_32 ) ;

end Behavioral;
