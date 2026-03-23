Library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.dpuArray_package.all;

entity dpuArrayrel0 is --dpu array consisting of 8 dpus used by an octect

	port(       
        widthSel: in std_logic_vector( 1 downto 0);
        typeSel: in std_logic_vector ( 2 downto 0);
		BufferA_0out8: in arraySize4_8; --contains one row of the submatrix A
		BufferA_1out8: in arraySize4_8;
		BufferB_0out8: in arraySize16_8 ;
		AccumulatorBuffer_0out8: in arraySize4_8;
		AccumulatorBuffer_1out8: in arraySize4_8;
		BufferA_0out16: in arraySize4_16;
		BufferA_1out16: in arraySize4_16;
		BufferB_0out16: in arraySize16_16;
		AccumulatorBuffer_0out16:  in arraySize4_16;
		AccumulatorBuffer_1out16:  in arraySize4_16;
		BufferA_0out32: in arraySize4_32;
		BufferA_1out32: in arraySize4_32;
		BufferB_0out32: in arraySize16_32;
		AccumulatorBuffer_0out32: in arraySize4_32;
		AccumulatorBuffer_1out32: in arraySize4_32;
		W0_8_X3: out arraySize4_8; --w0 means: is the 1by4 submatrix result related to threadgroup 0 managed result
		W1_8_X3: out arraySize4_8; --w1 means: is the 1by4 submatrix result related to threadgroup 4 managed result
		W0_16_X3: out arraySize4_16;
		W1_16_X3: out arraySize4_16;
        W0_32_X3: out arraySize4_32;
		W1_32_X3: out arraySize4_32
	    );
end dpuArrayrel0;

architecture ar of dpuArrayrel0 is

	component parametricDPUrel0 is
	   Port ( 
	       widthSel : in std_logic_vector( 1 downto 0);
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
	end component;

	begin

	-- description of the 16 cores...
	
	--Reserved to Octet 0(threaGroups 0 and 4) parametric DPUs: DPPU0 - DPU7 
	
	--DPU0 to DPU3 ---> reserved to threadGroup0
	
	--at cc0, it computes 1/4th of its assigned 4x4 element subMatrix D00 elements D00 of  (to confirm by looking at article and pyOpenTCU)
	
	--at cc0 DPU0,DPU1,DPU2,DPU3 compute d00, d01, d02, d03
	--at cc1 DPU0,DPU1,DPU2,DPU3 compute d10, d11, d12, d13
	--at cc2 DPU0,DPU1,DPU2,DPU3 compute d20, d21, d22, d23
	--at cc3 DPU0,DPU1,DPU2,DPU3 compute d30, d31, d32, d33
	
	DPU0: parametricDPUrel0 
port map( 
	      widthSel => widthSel , typeSel => typeSel , 
	      A0_8 => BufferA_0out8(0) , A1_8 => BufferA_0out8(1) , 
	      A2_8 => BufferA_0out8(2) , A3_8 => BufferA_0out8(3), 
	      B0_8 => BufferB_0out8(0) , B1_8 => BufferB_0out8(1) , 
	      B2_8 => BufferB_0out8(2), B3_8 => BufferB_0out8(3) , 
	      C0_8 =>  AccumulatorBuffer_0out8(0), 
	      A0_16 => BufferA_0out16(0), A1_16 => BufferA_0out16(1), 
	      A2_16 => BufferA_0out16(2), A3_16 => BufferA_0out16(3) , 
	      B0_16 => BufferB_0out16(0) , B1_16 => BufferB_0out16(1), 
	      B2_16 => BufferB_0out16(2), B3_16 => BufferB_0out16(3) , 
	      C0_16 => AccumulatorBuffer_0out16(0), 
	      A0_32 => BufferA_0out32(0), A1_32 => BufferA_0out32(1) , 
	      A2_32 => BufferA_0out32(2) ,  A3_32 => BufferA_0out32(3) ,
	      B0_32 => BufferB_0out32(0) , B1_32 => BufferB_0out32(1) , 
	      B2_32 => BufferB_0out32(2) , B3_32 => BufferB_0out32(3) ,
	      C0_32 => AccumulatorBuffer_0out32(0),
	      res_8 => W0_8_X3(0) ,res_16 => W0_16_X3(0) ,res_32 => W0_32_X3(0) );
	
	DPU1: parametricDPUrel0 port map( 
	      widthSel => widthSel , typeSel => typeSel , 
	      A0_8 => BufferA_0out8(0) , A1_8 => BufferA_0out8(1) , 
	      A2_8 => BufferA_0out8(2) , A3_8 => BufferA_0out8(3), 
	      B0_8 => BufferB_0out8(4) , B1_8 => BufferB_0out8(5), 
	      B2_8 => BufferB_0out8(6), B3_8 => BufferB_0out8(7) , 
	      C0_8 =>  AccumulatorBuffer_0out8(1), 
	      A0_16 => BufferA_0out16(0), A1_16 => BufferA_0out16(1), 
	      A2_16 => BufferA_0out16(2), A3_16 => BufferA_0out16(3) , 
	      B0_16 => BufferB_0out16(4) , B1_16 => BufferB_0out16(5), 
	      B2_16 => BufferB_0out16(6), B3_16 => BufferB_0out16(7) , 
	      C0_16 => AccumulatorBuffer_0out16(1) , 
	      A0_32 => BufferA_0out32(0), A1_32 => BufferA_0out32(1), 
	      A2_32 => BufferA_0out32(2) ,  A3_32 => BufferA_0out32(3), 
	      B0_32 => BufferB_0out32(4) , B1_32 => BufferB_0out32(5) , 
	      B2_32 => BufferB_0out32(6)  , B3_32 => BufferB_0out32(7) ,
	      C0_32 =>  AccumulatorBuffer_0out32(1),
	      res_8 =>  W0_8_X3(1) ,res_16 => W0_16_X3(1),res_32 => W0_32_X3(1) );
	
	DPU2: parametricDPUrel0 port map( 
	      widthSel => widthSel , typeSel => typeSel , 
	      A0_8 => BufferA_0out8(0) , A1_8 => BufferA_0out8(1) , 
	      A2_8 => BufferA_0out8(2), A3_8 => BufferA_0out8(3), 
	      B0_8 => BufferB_0out8(8) , B1_8 => BufferB_0out8(9), 
	      B2_8 => BufferB_0out8(10), B3_8 => BufferB_0out8(11) , 
	      C0_8 =>  AccumulatorBuffer_0out8(2), 
	      A0_16 => BufferA_0out16(0), A1_16 => BufferA_0out16(1), 
	      A2_16 => BufferA_0out16(2), A3_16 => BufferA_0out16(3) , 
	      B0_16 => BufferB_0out16(8) , B1_16 => BufferB_0out16(9), 
	      B2_16 => BufferB_0out16(10) , B3_16 => BufferB_0out16(11) , 
	      C0_16 => AccumulatorBuffer_0out16(2), 
	      A0_32 => BufferA_0out32(0), A1_32 => BufferA_0out32(1), 
	      A2_32 => BufferA_0out32(2) ,  A3_32 => BufferA_0out32(3) ,
	      B0_32 => BufferB_0out32(8) , B1_32 => BufferB_0out32(9) , 
	      B2_32 => BufferB_0out32(10) , B3_32 => BufferB_0out32(11) ,
	      C0_32 => AccumulatorBuffer_0out32(2),
	      res_8 => W0_8_X3(2) ,res_16 => W0_16_X3(2),res_32 => W0_32_X3(2) );
	
	DPU3: parametricDPUrel0 port map( 
	      widthSel => widthSel , typeSel => typeSel , 
	      A0_8 => BufferA_0out8(0) , A1_8 => BufferA_0out8(1) , 
	      A2_8 => BufferA_0out8(2), A3_8 => BufferA_0out8(3), 
	      B0_8 => BufferB_0out8(12) , B1_8 => BufferB_0out8(13), 
	      B2_8 => BufferB_0out8(14), B3_8 => BufferB_0out8(15) , 
	      C0_8 =>  AccumulatorBuffer_0out8(3) , 
	      A0_16 => BufferA_0out16(0), A1_16 => BufferA_0out16(1), 
	      A2_16 => BufferA_0out16(2), A3_16 => BufferA_0out16(3) , 
	      B0_16 => BufferB_0out16(12) , B1_16 => BufferB_0out16(13), 
	      B2_16 => BufferB_0out16(14) , B3_16 => BufferB_0out16(15) , 
	      C0_16 => AccumulatorBuffer_0out16(3), 
	      A0_32 => BufferA_0out32(0), A1_32 => BufferA_0out32(1), 
	      A2_32 => BufferA_0out32(2) ,  A3_32 => BufferA_0out32(3) ,
	      B0_32 => BufferB_0out32(12) , B1_32 => BufferB_0out32(13) , 
	      B2_32 => BufferB_0out32(14) , B3_32 => BufferB_0out32(15) ,
	      C0_32 =>  AccumulatorBuffer_0out32(3),
	      res_8 => W0_8_X3(3) ,res_16 => W0_16_X3(3),res_32 => W0_32_X3(3) );

    --DPU4 to DPU7 ---> reserved for threadGroup4
    
    DPU4: parametricDPUrel0 port map( 
	      widthSel => widthSel , typeSel => typeSel , 
	      A0_8 => BufferA_1out8(0) , A1_8 => BufferA_1out8(1) , 
	      A2_8 => BufferA_1out8(2) , A3_8 => BufferA_1out8(3), 
	      B0_8 => BufferB_0out8(0) , B1_8 => BufferB_0out8(1) , 
	      B2_8 => BufferB_0out8(2), B3_8 => BufferB_0out8(3) , 
	      C0_8 => AccumulatorBuffer_1out8(0), 
	      A0_16 => BufferA_1out16(0), A1_16 => BufferA_1out16(1), 
	      A2_16 => BufferA_1out16(2), A3_16 => BufferA_1out16(3) , 
	      B0_16 => BufferB_0out16(0) , B1_16 => BufferB_0out16(1), 
	      B2_16 => BufferB_0out16(2), B3_16 => BufferB_0out16(3) , 
	      C0_16 => AccumulatorBuffer_1out16(0), 
	      A0_32 => BufferA_1out32(0), A1_32 => BufferA_1out32(1) , 
	      A2_32 => BufferA_1out32(2) ,  A3_32 => BufferA_1out32(3) ,
	      B0_32 => BufferB_0out32(0) , B1_32 => BufferB_0out32(1) , 
	      B2_32 => BufferB_0out32(2) , B3_32 => BufferB_0out32(3) ,
	      C0_32 =>  AccumulatorBuffer_1out32(0),
	      res_8 => W1_8_X3(0) ,res_16 => W1_16_X3(0),res_32 => W1_32_X3(0) );
	
	DPU5: parametricDPUrel0 port map( 
	      widthSel => widthSel , typeSel => typeSel , 
	      A0_8 => BufferA_1out8(0) , A1_8 => BufferA_1out8(1) , 
	      A2_8 => BufferA_1out8(2) , A3_8 => BufferA_1out8(3), 
	      B0_8 => BufferB_0out8(4) , B1_8 => BufferB_0out8(5) , 
	      B2_8 => BufferB_0out8(6), B3_8 => BufferB_0out8(7) , 
	      C0_8 =>  AccumulatorBuffer_1out8(1),  
	      A0_16 => BufferA_1out16(0), A1_16 => BufferA_1out16(1), 
	      A2_16 => BufferA_1out16(2), A3_16 => BufferA_1out16(3) , 
	      B0_16 => BufferB_0out16(4) , B1_16 => BufferB_0out16(5), 
	      B2_16 => BufferB_0out16(6), B3_16 => BufferB_0out16(7) , 
	      C0_16 => AccumulatorBuffer_1out16(1), 
	      A0_32 => BufferA_1out32(0), A1_32 => BufferA_1out32(1) , 
	      A2_32 => BufferA_1out32(2) ,  A3_32 => BufferA_1out32(3) ,
	      B0_32 => BufferB_0out32(4) , B1_32 => BufferB_0out32(5) , 
	      B2_32 => BufferB_0out32(6) , B3_32 => BufferB_0out32(7) ,
	      C0_32 => AccumulatorBuffer_1out32(1) ,
	      res_8 => W1_8_X3(1),res_16 => W1_16_X3(1),res_32 => W1_32_X3(1) );
	      
	DPU6: parametricDPUrel0 port map( 
	      widthSel => widthSel , typeSel => typeSel , 
	      A0_8 => BufferA_1out8(0) , A1_8 => BufferA_1out8(1) , 
	      A2_8 => BufferA_1out8(2) , A3_8 => BufferA_1out8(3), 
	      B0_8 => BufferB_0out8(8) , B1_8 => BufferB_0out8(9) , 
	      B2_8 => BufferB_0out8(10), B3_8 => BufferB_0out8(11) , 
	      C0_8 => AccumulatorBuffer_1out8(2), 
	      A0_16 => BufferA_1out16(0), A1_16 => BufferA_1out16(1), 
	      A2_16 => BufferA_1out16(2), A3_16 => BufferA_1out16(3) , 
	      B0_16 => BufferB_0out16(8) , B1_16 => BufferB_0out16(9), 
	      B2_16 => BufferB_0out16(10), B3_16 => BufferB_0out16(11) , 
	      C0_16 => AccumulatorBuffer_1out16(2), 
	      A0_32 => BufferA_1out32(0), A1_32 => BufferA_1out32(1) , 
	      A2_32 => BufferA_1out32(2) ,  A3_32 => BufferA_1out32(3) ,
	      B0_32 => BufferB_0out32(8) , B1_32 => BufferB_0out32(9) , 
	      B2_32 => BufferB_0out32(10) , B3_32 => BufferB_0out32(11) ,
	      C0_32 => AccumulatorBuffer_1out32(2),
	      res_8 => W1_8_X3(2) ,res_16 => W1_16_X3(2), res_32 => W1_32_X3(2) );
	      
	DPU7: parametricDPUrel0 port map( 
	      widthSel => widthSel , typeSel => typeSel , 
	      A0_8 => BufferA_1out8(0) , A1_8 => BufferA_1out8(1) , 
	      A2_8 => BufferA_1out8(2) , A3_8 => BufferA_1out8(3), 
	      B0_8 => BufferB_0out8(12) , B1_8 => BufferB_0out8(13) , 
	      B2_8 => BufferB_0out8(14), B3_8 => BufferB_0out8(15) , 
	      C0_8 => AccumulatorBuffer_1out8(3) , 
	      A0_16 => BufferA_1out16(0), A1_16 => BufferA_1out16(1), 
	      A2_16 => BufferA_1out16(2), A3_16 => BufferA_1out16(3) , 
	      B0_16 => BufferB_0out16(12) , B1_16 => BufferB_0out16(13), 
	      B2_16 => BufferB_0out16(14), B3_16 => BufferB_0out16(15) , 
	      C0_16 => AccumulatorBuffer_1out16(3)  , 
	      A0_32 => BufferA_1out32(0), A1_32 => BufferA_1out32(1) , 
	      A2_32 => BufferA_1out32(2) ,  A3_32 => BufferA_1out32(3) ,
	      B0_32 => BufferB_0out32(12) , B1_32 => BufferB_0out32(13) , 
	      B2_32 => BufferB_0out32(14) , B3_32 => BufferB_0out32(15) ,
	      C0_32 => AccumulatorBuffer_1out32(3)  ,
	      res_8 => W1_8_X3(3) ,res_16 => W1_16_X3(3),res_32 => W1_32_X3(3) );

end ar;
