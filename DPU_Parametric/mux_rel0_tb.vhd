library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity mux_rel0_tb is
end mux_rel0_tb;

architecture Behavioral of mux_rel0_tb is

 signal widthSel_s : std_logic_vector( 1 downto 0 ) ;
 signal typeSel_s : std_logic_vector (2 downto 0 );
 signal float8e4m3out_s : std_logic_vector ( 7 downto 0) ;
 signal float16out_s : std_logic_vector ( 15 downto 0 ) ;
 signal float32out_s : std_logic_vector ( 31 downto 0 ) ;
 signal posit8out_s : std_logic_vector ( 7 downto 0 ) ;
 signal posit16out_s : std_logic_vector (15 downto 0 ) ;
 signal posit32out_s : std_logic_vector ( 31 downto 0 ) ;
 signal out8bit_s : std_logic_vector  ( 7 downto 0 ) ;
 signal out16bit_s : std_logic_vector ( 15 downto 0 ) ;
 signal out32bit_s : std_logic_vector ( 31 downto 0 ) ;

component mux_rel0 is
    
    Port ( widthSel: in std_logic_vector(1 downto 0); 
           typeSel: in std_logic_vector(2 downto 0);  
           float8e4m3out: in std_logic_vector( 7 downto 0);
           float16out: in std_logic_vector( 15 downto 0);
           float32out: in std_logic_vector( 31 downto 0);
           posit8out: in std_logic_vector( 7 downto 0);
           posit16out: in std_logic_vector( 15 downto 0);
           posit32out: in std_logic_vector( 31 downto 0);
           out8bit : out std_logic_vector( 7 downto 0 );
           out16bit: out std_logic_vector( 15 downto 0);
           out32bit: out std_logic_vector( 31 downto 0) );
end component;

begin

    uut: mux_rel0 
        port map (
            widthSel => widthSel_s,
            typeSel => typeSel_s,
            float8e4m3out => float8e4m3out_s,
            float16out => float16out_s,
            float32out => float32out_s,
            posit8out => posit8out_s,
            posit16out => posit16out_s,
            posit32out => posit32out_s,
            out8bit => out8bit_s,
            out16bit => out16bit_s,
            out32bit => out32bit_s
        );
        
    stim_proc : process
    
        file input_file : text open read_mode is "C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\DPU_Parametric\mux_rel0vectors.txt" ;
        file output_file : text open write_mode is "C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\DPU_Parametric\output_file.txt" ;

        variable text_line : line ;
		variable ok : boolean ;
		variable char : character ;
		
        variable tmp_widthSel : std_logic_vector(1 downto 0);
        variable tmp_typeSel : std_logic_vector(2 downto 0);
        variable tmp_float8e4m3out : std_logic_vector(7 downto 0);
        variable tmp_float16out : std_logic_vector(15 downto 0);
        variable tmp_float32out : std_logic_vector(31 downto 0);
        variable tmp_posit8out : std_logic_vector(7 downto 0);
        variable tmp_posit16out : std_logic_vector(15 downto 0);
        variable tmp_posit32out : std_logic_vector(31 downto 0);
        
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
            hread(text_line, tmp_float8e4m3out);
            hread(text_line, tmp_float16out);
            hread(text_line, tmp_float32out);
            hread(text_line, tmp_posit8out);
            hread(text_line, tmp_posit16out);
            hread(text_line, tmp_posit32out);
                                      
            widthSel_s <= tmp_widthSel;
            typeSel_s <= tmp_typeSel;
            float8e4m3out_s <= tmp_float8e4m3out;
            float16out_s <= tmp_float16out;
            float32out_s <= tmp_float32out;
            posit8out_s <= tmp_posit8out;
            posit16out_s <= tmp_posit16out;
            posit32out_s <= tmp_posit32out;
            
            wait for 50 ns;
            
            hwrite(L, widthSel_s);
            write(L, string'(" "));
            hwrite(L, typeSel_s);
            write(L, string'(" "));
            hwrite(L, float8e4m3out_s);
            write(L, string'(" "));
            hwrite(L, float16out_s);
            write(L, string'(" "));
            hwrite(L, float32out_s);
            write(L, string'(" "));
            hwrite(L, posit8out_s);
            write(L, string'(" "));
            hwrite(L, posit16out_s);
            write(L, string'(" "));
            hwrite(L, posit32out_s);
            writeline(output_file, L); 
            
        end loop;

        wait;
    
    end process ;

end Behavioral;
