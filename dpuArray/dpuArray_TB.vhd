library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use work.dpuArray_package.all;

library std;
use std.textio.all;

entity dpuArray_TB is
end dpuArray_TB;

architecture Behavioral of dpuArray_TB is

signal  widthSel_s: std_logic_vector( 1 downto 0);
signal  typeSel_s: std_logic_vector ( 2 downto 0);
signal	BufferA_0out8_s: arraySize4_8;
signal	BufferA_1out8_s: arraySize4_8;
signal	BufferA_2out8_s: arraySize4_8;
signal	BufferA_3out8_s: arraySize4_8;
signal	BufferB_0out8_s: arraySize16_8 ;
signal	BufferB_1out8_s: arraySize16_8 ;
signal	AccumulatorBuffer_0out8_s: arraySize4_8;
signal	AccumulatorBuffer_1out8_s: arraySize4_8;
signal	AccumulatorBuffer_2out8_s: arraySize4_8;
signal  AccumulatorBuffer_3out8_s: arraySize4_8;
signal	BufferA_0out16_s: arraySize4_16;
signal	BufferA_1out16_s: arraySize4_16;
signal	BufferA_2out16_s: arraySize4_16;
signal	BufferA_3out16_s: arraySize4_16;
signal	BufferB_0out16_s: arraySize16_16;
signal	BufferB_1out16_s: arraySize16_16;
signal	AccumulatorBuffer_0out16_s:  arraySize4_16;
signal	AccumulatorBuffer_1out16_s:  arraySize4_16;
signal	AccumulatorBuffer_2out16_s:  arraySize4_16;
signal	AccumulatorBuffer_3out16_s:  arraySize4_16;
signal	BufferA_0out32_s: arraySize4_32;
signal	BufferA_1out32_s: arraySize4_32;
signal	BufferA_2out32_s: arraySize4_32;
signal	BufferA_3out32_s: arraySize4_32;
signal	BufferB_0out32_s: arraySize16_32;
signal	BufferB_1out32_s: arraySize16_32;
signal	AccumulatorBuffer_0out32_s: arraySize4_32;
signal	AccumulatorBuffer_1out32_s: arraySize4_32;
signal	AccumulatorBuffer_2out32_s: arraySize4_32;
signal	AccumulatorBuffer_3out32_s: arraySize4_32;
signal	W0_8_X3_s:  arraySize4_8;
signal	W1_8_X3_s:  arraySize4_8;
signal	W2_8_X3_s:  arraySize4_8;
signal	W3_8_X3_s:  arraySize4_8;
signal	W0_16_X3_s:  arraySize4_16;
signal	W1_16_X3_s:  arraySize4_16;
signal	W2_16_X3_s:  arraySize4_16;
signal	W3_16_X3_s:  arraySize4_16;
signal	W0_32_X3_s:  arraySize4_32;
signal	W1_32_X3_s:  arraySize4_32;
signal	W2_32_X3_s:  arraySize4_32;
signal	W3_32_X3_s:  arraySize4_32;
				
component dpuArrayrel0 is
    
    port(      
        widthSel: in std_logic_vector( 1 downto 0);
	    typeSel: in std_logic_vector ( 2 downto 0);
		BufferA_0out8: in arraySize4_8;
	    BufferA_1out8: in arraySize4_8;
		BufferA_2out8: in arraySize4_8;
		BufferA_3out8: in arraySize4_8;
		BufferB_0out8: in arraySize16_8 ;
		BufferB_1out8: in arraySize16_8 ;
		AccumulatorBuffer_0out8: in arraySize4_8;
		AccumulatorBuffer_1out8: in arraySize4_8;
		AccumulatorBuffer_2out8: in arraySize4_8;
		AccumulatorBuffer_3out8: in arraySize4_8;
		BufferA_0out16: in arraySize4_16;
		BufferA_1out16: in arraySize4_16;
		BufferA_2out16: in arraySize4_16;
		BufferA_3out16: in arraySize4_16;
		BufferB_0out16: in arraySize16_16;
		BufferB_1out16: in arraySize16_16;
		AccumulatorBuffer_0out16:  in arraySize4_16;
		AccumulatorBuffer_1out16:  in arraySize4_16;
		AccumulatorBuffer_2out16:  in arraySize4_16;
		AccumulatorBuffer_3out16:  in arraySize4_16;
		BufferA_0out32: in arraySize4_32;
		BufferA_1out32: in arraySize4_32;
		BufferA_2out32: in arraySize4_32;
		BufferA_3out32: in arraySize4_32;
		BufferB_0out32: in arraySize16_32;
		BufferB_1out32: in arraySize16_32;
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
		W3_32_X3: out arraySize4_32 );

end component;

begin

    uut: dpuArrayrel0 
        port map (
            widthSel => widthSel_s,
	        typeSel => typeSel_s ,
		    BufferA_0out8 => BufferA_0out8_s ,
	        BufferA_1out8 => BufferA_1out8_s ,
		    BufferA_2out8 => BufferA_2out8_s , 
		    BufferA_3out8 => BufferA_3out8_s ,
		    BufferB_0out8 => BufferB_0out8_s ,
		    BufferB_1out8 => BufferB_1out8_s ,
		    AccumulatorBuffer_0out8 => AccumulatorBuffer_0out8_s ,
		    AccumulatorBuffer_1out8 => AccumulatorBuffer_1out8_s ,
		    AccumulatorBuffer_2out8 => AccumulatorBuffer_2out8_s ,
		    AccumulatorBuffer_3out8 => AccumulatorBuffer_3out8_s ,
		    BufferA_0out16 => BufferA_0out16_s ,
		    BufferA_1out16 => BufferA_1out16_s ,
		    BufferA_2out16 => BufferA_2out16_s ,
		    BufferA_3out16 => BufferA_3out16_s ,
		    BufferB_0out16 => BufferB_0out16_s ,
		    BufferB_1out16 => BufferB_1out16_s ,
		    AccumulatorBuffer_0out16 => AccumulatorBuffer_0out16_s ,
		    AccumulatorBuffer_1out16 => AccumulatorBuffer_1out16_s ,
		    AccumulatorBuffer_2out16 => AccumulatorBuffer_2out16_s ,
		    AccumulatorBuffer_3out16 => AccumulatorBuffer_3out16_s ,
		    BufferA_0out32 => BufferA_0out32_s ,
		    BufferA_1out32 => BufferA_1out32_s ,
		    BufferA_2out32 => BufferA_2out32_s ,
		    BufferA_3out32 => BufferA_3out32_s ,
		    BufferB_0out32 => BufferB_0out32_s ,
		    BufferB_1out32 => BufferB_1out32_s ,
		    AccumulatorBuffer_0out32 => AccumulatorBuffer_0out32_s ,
		    AccumulatorBuffer_1out32 => AccumulatorBuffer_1out32_s ,
		    AccumulatorBuffer_2out32 => AccumulatorBuffer_2out32_s ,
		    AccumulatorBuffer_3out32 => AccumulatorBuffer_3out32_s ,
		    W0_8_X3 => W0_8_X3_s ,
		    W1_8_X3 => W1_8_X3_s ,
		    W2_8_X3 => W2_8_X3_s ,
		    W3_8_X3 => W3_8_X3_s ,
		    W0_16_X3 => W0_16_X3_s ,
		    W1_16_X3 => W1_16_X3_s ,
		    W2_16_X3 => W2_16_X3_s ,
		    W3_16_X3 => W3_16_X3_s ,
	        W0_32_X3 => W0_32_X3_s ,
		    W1_32_X3 => W1_32_X3_s ,
		    W2_32_X3 => W2_32_X3_s,
		    W3_32_X3 => W3_32_X3_s
        );
        
    stim_proc : process
    
        file input_file : text open read_mode is "C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\dpuArray\dpuArray_initial_test.txt" ;
        --file output_file : text open write_mode is "C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\DPU_Parametric\DPU_parametric_results.txt" ;
        --file output_file : text open write_mode is "\\wsl.localhost\Ubuntu-20.04\home\giooo00\tesi\ThesisGio\verificationDPU_Parametric\DPUrel0_parametric_results.txt" ;

        variable text_line : line ;
		variable ok : boolean ;
		variable char : character ;
        
        variable tmp_widthSel: std_logic_vector( 1 downto 0);
        variable tmp_typeSel: std_logic_vector ( 2 downto 0);
        variable tmp_BufferA_0out8: arraySize4_8;
        variable tmp_BufferA_1out8: arraySize4_8;
        variable tmp_BufferA_2out8: arraySize4_8;
        variable tmp_BufferA_3out8: arraySize4_8;
        variable tmp_BufferB_0out8: arraySize16_8 ;
        variable tmp_BufferB_1out8: arraySize16_8 ;
        variable tmp_AccumulatorBuffer_0out8: arraySize4_8;
        variable tmp_AccumulatorBuffer_1out8: arraySize4_8;
        variable tmp_AccumulatorBuffer_2out8: arraySize4_8;
        variable tmp_AccumulatorBuffer_3out8: arraySize4_8;
        variable tmp_BufferA_0out16: arraySize4_16;
        variable tmp_BufferA_1out16: arraySize4_16;
        variable tmp_BufferA_2out16: arraySize4_16;
        variable tmp_BufferA_3out16: arraySize4_16;
        variable tmp_BufferB_0out16: arraySize16_16;
        variable tmp_BufferB_1out16: arraySize16_16;
        variable tmp_AccumulatorBuffer_0out16:  arraySize4_16;
        variable tmp_AccumulatorBuffer_1out16:  arraySize4_16;
        variable tmp_AccumulatorBuffer_2out16:  arraySize4_16;
        variable tmp_AccumulatorBuffer_3out16:  arraySize4_16;
        variable tmp_BufferA_0out32: arraySize4_32;
        variable tmp_BufferA_1out32: arraySize4_32;
        variable tmp_BufferA_2out32: arraySize4_32;
        variable tmp_BufferA_3out32: arraySize4_32;
        variable tmp_BufferB_0out32: arraySize16_32;
        variable tmp_BufferB_1out32: arraySize16_32;
        variable tmp_AccumulatorBuffer_0out32: arraySize4_32;
        variable tmp_AccumulatorBuffer_1out32: arraySize4_32;
        variable tmp_AccumulatorBuffer_2out32: arraySize4_32;
        variable tmp_AccumulatorBuffer_3out32: arraySize4_32;
        variable tmp_W0_8_X3:  arraySize4_8;
        variable tmp_W1_8_X3:  arraySize4_8;
        variable tmp_W2_8_X3:  arraySize4_8;
        variable tmp_W3_8_X3:  arraySize4_8;
        variable tmp_W0_16_X3:  arraySize4_16;
        variable tmp_W1_16_X3:  arraySize4_16;
        variable tmp_W2_16_X3:  arraySize4_16;
        variable tmp_W3_16_X3:  arraySize4_16;
        variable tmp_W0_32_X3:  arraySize4_32;
        variable tmp_W1_32_X3:  arraySize4_32;
        variable tmp_W2_32_X3:  arraySize4_32;
        variable tmp_W3_32_X3:  arraySize4_32;
        
        variable L : line ;
        
        begin
        
        while not endfile(input_file) loop
            
            readline(input_file, text_line);

            -- Skip comment lines
            if text_line.all'length = 0 or text_line.all(1) = '#' then
					next;
				end if;

            hread(text_line, tmp_widthSel);
            hread(text_line, tmp_typeSel);
            
            for i in 0 to 3 loop
                hread(text_line, tmp_BufferA_0out8(i) );
            end loop;
            for i in 0 to 3 loop
                hread(text_line, tmp_BufferA_1out8(i) );
            end loop;
            for i in 0 to 3 loop
                hread(text_line, tmp_BufferA_2out8(i) );
            end loop;
            for i in 0 to 3 loop
                hread(text_line, tmp_BufferA_3out8(i) );
            end loop;
            for i in 0 to 15 loop
                hread(text_line, tmp_BufferB_0out8(i) );
            end loop;
            for i in 0 to 15 loop
                hread(text_line, tmp_BufferB_1out8(i) );
            end loop;
            for i in 0 to 3 loop
                hread(text_line, tmp_AccumulatorBuffer_0out8(i) );
            end loop;
            for i in 0 to 3 loop
                hread(text_line, tmp_AccumulatorBuffer_1out8(i) );
            end loop;
            for i in 0 to 3 loop
                hread(text_line, tmp_AccumulatorBuffer_2out8(i) );
            end loop;
            for i in 0 to 3 loop
                hread(text_line, tmp_AccumulatorBuffer_3out8(i) );
            end loop;
            
            for i in 0 to 3 loop
                hread(text_line, tmp_BufferA_0out16(i) );
            end loop;
            for i in 0 to 3 loop
                hread(text_line, tmp_BufferA_1out16(i) );
            end loop;
            for i in 0 to 3 loop
                hread(text_line, tmp_BufferA_2out16(i) );
            end loop;
            for i in 0 to 3 loop
                hread(text_line, tmp_BufferA_3out16(i) );
            end loop;
            for i in 0 to 15 loop
                hread(text_line, tmp_BufferB_0out16(i) );
            end loop;
            for i in 0 to 15 loop
                hread(text_line, tmp_BufferB_1out16(i) );
            end loop;
            for i in 0 to 3 loop
                hread(text_line, tmp_AccumulatorBuffer_0out16(i) );
            end loop;
            for i in 0 to 3 loop
                hread(text_line, tmp_AccumulatorBuffer_1out16(i) );
            end loop;
            for i in 0 to 3 loop
                hread(text_line, tmp_AccumulatorBuffer_2out16(i) );
            end loop;
            for i in 0 to 3 loop
                hread(text_line, tmp_AccumulatorBuffer_3out16(i) );
            end loop;
            
            for i in 0 to 3 loop
                hread(text_line, tmp_BufferA_0out32(i) );
            end loop;
            for i in 0 to 3 loop
                hread(text_line, tmp_BufferA_1out32(i) );
            end loop;
            for i in 0 to 3 loop
                hread(text_line, tmp_BufferA_2out32(i) );
            end loop;
            for i in 0 to 3 loop
                hread(text_line, tmp_BufferA_3out32(i) );
            end loop;
            for i in 0 to 15 loop
                hread(text_line, tmp_BufferB_0out32(i) );
            end loop;
            for i in 0 to 15 loop
                hread(text_line, tmp_BufferB_1out32(i) );
            end loop;
            for i in 0 to 3 loop
                hread(text_line, tmp_AccumulatorBuffer_0out32(i) );
            end loop;
            for i in 0 to 3 loop
                hread(text_line, tmp_AccumulatorBuffer_1out32(i) );
            end loop;
            for i in 0 to 3 loop
                hread(text_line, tmp_AccumulatorBuffer_2out32(i) );
            end loop;
            for i in 0 to 3 loop
                hread(text_line, tmp_AccumulatorBuffer_3out32(i) );
            end loop;
            
            --hread(text_line, tmp_res_8);
            --hread(text_line, tmp_res_16);
            --hread(text_line, tmp_res_32);
            
            widthSel_s <= tmp_widthSel;
            typeSel_s <= tmp_typeSel;
        
            BufferA_0out8_s <= tmp_BufferA_0out8;
            BufferA_1out8_s <= tmp_BufferA_1out8;
            BufferA_2out8_s <= tmp_BufferA_2out8;
            BufferA_3out8_s <= tmp_BufferA_3out8;
            
            BufferB_0out8_s <= tmp_BufferB_0out8;
            BufferB_1out8_s <= tmp_BufferB_1out8;
            
            AccumulatorBuffer_0out8_s <= tmp_AccumulatorBuffer_0out8;
            AccumulatorBuffer_1out8_s <= tmp_AccumulatorBuffer_1out8;
            AccumulatorBuffer_2out8_s <= tmp_AccumulatorBuffer_2out8;
            AccumulatorBuffer_3out8_s <= tmp_AccumulatorBuffer_3out8;
            
            BufferA_0out16_s <= tmp_BufferA_0out16;
            BufferA_1out16_s <= tmp_BufferA_1out16;
            BufferA_2out16_s <= tmp_BufferA_2out16;
            BufferA_3out16_s <= tmp_BufferA_3out16;
            
            BufferB_0out16_s <= tmp_BufferB_0out16;
            BufferB_1out16_s <= tmp_BufferB_1out16;
            
            AccumulatorBuffer_0out16_s <= tmp_AccumulatorBuffer_0out16;
            AccumulatorBuffer_1out16_s <= tmp_AccumulatorBuffer_1out16;
            AccumulatorBuffer_2out16_s <= tmp_AccumulatorBuffer_2out16;
            AccumulatorBuffer_3out16_s <= tmp_AccumulatorBuffer_3out16;

            BufferA_0out32_s <= tmp_BufferA_0out32;
            BufferA_1out32_s <= tmp_BufferA_1out32;
            BufferA_2out32_s <= tmp_BufferA_2out32;
            BufferA_3out32_s <= tmp_BufferA_3out32;
            
            BufferB_0out32_s <= tmp_BufferB_0out32;
            BufferB_1out32_s <= tmp_BufferB_1out32;
            
            AccumulatorBuffer_0out32_s <= tmp_AccumulatorBuffer_0out32;
            AccumulatorBuffer_1out32_s <= tmp_AccumulatorBuffer_1out32;
            AccumulatorBuffer_2out32_s <= tmp_AccumulatorBuffer_2out32;
            AccumulatorBuffer_3out32_s <= tmp_AccumulatorBuffer_3out32;
              
            wait for 50 ns;
            
            --hwrite(L, widthSel_s);
            --write(L, string'(" "));
            --hwrite(L, typeSel_s);
            --write(L, string'(" "));
            
            --hwrite(L, A0_8_s);
            --write(L, string'(" "));
            --hwrite(L, A1_8_s);
            --write(L, string'(" "));
            --hwrite(L, A2_8_s);
            --write(L, string'(" "));
            --hwrite(L, A3_8_s);
            --write(L, string'(" "));
            --hwrite(L, B0_8_s);
            --write(L, string'(" "));
            --hwrite(L, B1_8_s);
            --write(L, string'(" "));
            --hwrite(L, B2_8_s);
            --write(L, string'(" "));
            --hwrite(L, B3_8_s);
            --write(L, string'(" "));
            --hwrite(L, C0_8_s);
            --write(L, string'(" "));
           
            --hwrite(L, A0_16_s);
            --write(L, string'(" "));
            --hwrite(L, A1_16_s);
            --write(L, string'(" "));
            --hwrite(L, A2_16_s);
            --write(L, string'(" "));
            --hwrite(L, A3_16_s);
            --write(L, string'(" "));
            --hwrite(L, B0_16_s);
            --write(L, string'(" "));
            --hwrite(L, B1_16_s);
            --write(L, string'(" "));
            --hwrite(L, B2_16_s);
            --write(L, string'(" "));
            --hwrite(L, B3_16_s);
            --write(L, string'(" "));
            --hwrite(L, C0_16_s);
            --write(L, string'(" "));
            
            --hwrite(L, A0_32_s);
            --write(L, string'(" "));
            --hwrite(L, A1_32_s);
            --write(L, string'(" "));
            --hwrite(L, A2_32_s);
            --write(L, string'(" "));
            --hwrite(L, A3_32_s);
            --write(L, string'(" "));
            --hwrite(L, B0_32_s);
            --write(L, string'(" "));
            --hwrite(L, B1_32_s);
            --write(L, string'(" "));
            --hwrite(L, B2_32_s);
            --write(L, string'(" "));
            --hwrite(L, B3_32_s);
            --write(L, string'(" "));
            --hwrite(L, C0_32_s);
            --write(L, string'(" "));
            
            --hwrite(L, res_8_s);
            --write(L, string'(" "));
            --hwrite(L, res_16_s);
            --write(L, string'(" "));
            --hwrite(L, res_32_s);
            --write(L, string'(" "));
            
            --writeline(output_file, L); 
            
        end loop;

        wait;
    
    end process ;

end Behavioral;
