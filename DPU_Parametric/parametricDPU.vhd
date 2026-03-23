
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

begin

dpu_fp8 : DotProductUnitFP8e4m3 
    port map ( aX0 => A0_8, aX1 => A1_8, aX2 => A2_8, aX3 => A3_8, bY0 => B0_8, bY1 => B1_8, bY2 => B2_8 , bY3 => B3_8 , cX0 => C0_8 , R => out_DPU_FP8  ) ;

dpu_fp16: DotProductUnitFP16
    port map ( aX0 => A0_16, aX1 => A1_16, aX2 => A2_16, aX3 => A3_16, bY0 => B0_16, bY1 => B1_16, bY2 => B2_16 , bY3 => B3_16 , cX0 => C0_16 , R => out_DPU_FP16  ) ;

dpu_fp32: DotProductUnitFP32
    port map ( aX0 => A0_32, aX1 => A1_32, aX2 => A2_32, aX3 => A3_32, bY0 => B0_32, bY1 => B1_32, bY2 => B2_32 , bY3 => B3_32 , cX0 => C0_32 , R => out_DPU_FP32  ) ;

dpu_posit8: DotProductUnitPosit
    port map ( aX0 => A0_8 , aX1 => A1_8 , aX2 => A2_8 , aX3 => A3_8 , bY0 => B0_8 , bY1 => B1_8 , bY2 => B2_8, bY3 => B3_8 , cX0 => C0_8 , R => out_DPU_posit8  ) ;

dpu_posit16: DotProductUnitPosit16
    port map ( aX0 => A0_16 , aX1 => A1_16 , aX2 => A2_16 , aX3 => A3_16 , bY0 => B0_16 , bY1 => B1_16 , bY2 => B2_16, bY3 => B3_16 , cX0 => C0_16 , R => out_DPU_posit16 ) ;

dpu_posit32: DotProductUnitPosit32
    port map ( aX0 => A0_32 , aX1 => A1_32 , aX2 => A2_32 , aX3 => A3_32 , bY0 => B0_32 , bY1 => B1_32 , bY2 => B2_32, bY3 => B3_32 , cX0 => C0_32 , R => out_DPU_posit32 ) ;

dpu_FixP8_16: DotProductUnit_FixedPoint8_16 
    port map ( aX0 => A0_8 , aX1 => A1_8 , aX2 => A2_8 , aX3 => A3_8 , bY0 => B0_8 , bY1 => B1_8 , bY2 => B2_8, bY3 => B3_8 , cX0 => C0_16 , R => out_DPU_FixP8_16 ) ;

dpu_FixP16_32: DotProductUnit
    port map (  aX0 => A0_16 , aX1 => A1_16 , aX2 => A2_16 , aX3 => A3_16 , bY0 => B0_16 , bY1 => B1_16 , bY2 => B2_16, bY3 => B3_16 , cX0 => C0_32 , R => out_DPU_FixP16_32 ) ;

dpu_int8_16: dot_unit_coreINT8
    port map ( a_X0 => A0_8, a_X1 => A1_8, a_X2 => A2_8, a_X3 => A3_8, b_X0 => B0_8, b_X1 => B1_8, b_X2 => B2_8, b_X3 => B3_8, c_X0 => C0_16, w_XX3 => out_DPU_int8_16 ) ;
    
dpu_int16_32: dot_unit_coreINT
    port map ( a_X0 => A0_16, a_X1 => A1_16, a_X2 => A2_16, a_X3 => A3_16, b_X0 => B0_16, b_X1 => B1_16, b_X2 => B2_16, b_X3 =>	B3_16, c_X0 => C0_32, w_XX3 => out_DPU_int16_32 ) ;

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
               out8bit => res_8, 
               out16bit => res_16, 
               out32bit => res_32 ) ;

end Behavioral;
