library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity parametricDPU_tb is
end parametricDPU_tb;

architecture Behavioral of parametricDPU_tb is

signal widthSel_s : std_logic_vector( 1 downto 0);
signal typeSel_s :  std_logic_vector ( 2 downto 0);
signal A0_8_s :  std_logic_vector(7 downto 0);
signal A1_8_s :  std_logic_vector(7 downto 0);
signal A2_8_s :  std_logic_vector(7 downto 0);
signal A3_8_s :  std_logic_vector(7 downto 0);
signal B0_8_s :  std_logic_vector(7 downto 0);
signal B1_8_s :  std_logic_vector(7 downto 0);
signal B2_8_s :  std_logic_vector(7 downto 0);
signal B3_8_s :  std_logic_vector(7 downto 0);
signal C0_8_s :  std_logic_vector(7 downto 0);
signal A0_16_s :  std_logic_vector(15 downto 0);
signal A1_16_s :  std_logic_vector(15 downto 0);
signal A2_16_s :  std_logic_vector(15 downto 0);
signal A3_16_s :  std_logic_vector(15 downto 0);
signal B0_16_s :  std_logic_vector(15 downto 0);
signal B1_16_s :  std_logic_vector(15 downto 0);
signal B2_16_s :  std_logic_vector(15 downto 0);
signal B3_16_s :  std_logic_vector(15 downto 0);
signal C0_16_s :  std_logic_vector(15 downto 0);
signal A0_32_s :  std_logic_vector(31 downto 0);
signal A1_32_s :  std_logic_vector(31 downto 0);
signal A2_32_s :  std_logic_vector(31 downto 0);
signal A3_32_s :  std_logic_vector(31 downto 0);
signal B0_32_s :  std_logic_vector(31 downto 0);
signal B1_32_s :  std_logic_vector(31 downto 0);
signal B2_32_s :  std_logic_vector(31 downto 0);
signal B3_32_s :  std_logic_vector(31 downto 0);
signal C0_32_s :  std_logic_vector(31 downto 0);
signal res_8_s:  std_logic_vector(7 downto 0);
signal res_16_s:  std_logic_vector(15 downto 0);
signal res_32_s:  std_logic_vector(31 downto 0);

component parametricDPUrel0 is
    
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
           res_32: out std_logic_vector(31 downto 0)  );
           
end component;

begin

    uut: parametricDPUrel0 
        port map (
           widthSel => widthSel_s,
           typeSel => typeSel_s,
           A0_8 => A0_8_s,
           A1_8 => A1_8_s,
           A2_8 => A2_8_s,
           A3_8 => A3_8_s,
           B0_8 => B0_8_s,
           B1_8 => B1_8_s,
           B2_8 => B2_8_s,
           B3_8 => B3_8_s,
           C0_8 => C0_8_s,
           A0_16 => A0_16_s,
           A1_16 => A1_16_s,
           A2_16 => A2_16_s,
           A3_16 => A3_16_s,
           B0_16 => B0_16_s,
           B1_16 => B1_16_s,
           B2_16 => B2_16_s,
           B3_16 => B3_16_s,
           C0_16 => C0_16_s,
           A0_32 => A0_32_s,
           A1_32 => A1_32_s,
           A2_32 => A2_32_s,
           A3_32 => A3_32_s,
           B0_32 => B0_32_s,
           B1_32 => B1_32_s,
           B2_32 => B2_32_s,
           B3_32 => B3_32_s,
           C0_32 => C0_32_s,
           res_8 => res_8_s,
           res_16 => res_16_s,
           res_32 => res_32_s
        );
        
    stim_proc : process
    
        file input_file : text open read_mode is "C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\DPU_Parametric\parametricDPU_rel0vectors.txt" ;
        --file output_file : text open write_mode is "C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\DPU_Parametric\DPU_parametric_results.txt" ;
        file output_file : text open write_mode is "\\wsl.localhost\Ubuntu-20.04\home\giooo00\tesi\ThesisGio\verificationDPU_Parametric\DPUrel0_parametric_results.txt" ;


        variable text_line : line ;
		variable ok : boolean ;
		variable char : character ;
		
		
        variable tmp_widthSel : std_logic_vector(1 downto 0);
        variable tmp_typeSel : std_logic_vector(2 downto 0);
        variable tmp_A0_8 : std_logic_vector(7 downto 0);
        variable tmp_A1_8 : std_logic_vector(7 downto 0);
        variable tmp_A2_8 : std_logic_vector(7 downto 0);
        variable tmp_A3_8 : std_logic_vector(7 downto 0);
        variable tmp_B0_8 : std_logic_vector(7 downto 0);
        variable tmp_B1_8 : std_logic_vector(7 downto 0);
        variable tmp_B2_8 : std_logic_vector(7 downto 0);
        variable tmp_B3_8 : std_logic_vector(7 downto 0);
        variable tmp_C0_8 : std_logic_vector(7 downto 0);
        variable tmp_A0_16 : std_logic_vector(15 downto 0);
        variable tmp_A1_16 : std_logic_vector(15 downto 0);
        variable tmp_A2_16 : std_logic_vector(15 downto 0);
        variable tmp_A3_16 : std_logic_vector(15 downto 0);
        variable tmp_B0_16 : std_logic_vector(15 downto 0);
        variable tmp_B1_16 : std_logic_vector(15 downto 0);
        variable tmp_B2_16 : std_logic_vector(15 downto 0);
        variable tmp_B3_16 : std_logic_vector(15 downto 0);
        variable tmp_C0_16 : std_logic_vector(15 downto 0);
        variable tmp_A0_32 : std_logic_vector(31 downto 0);
        variable tmp_A1_32 : std_logic_vector(31 downto 0);
        variable tmp_A2_32 : std_logic_vector(31 downto 0);
        variable tmp_A3_32 : std_logic_vector(31 downto 0);
        variable tmp_B0_32 : std_logic_vector(31 downto 0);
        variable tmp_B1_32 : std_logic_vector(31 downto 0);
        variable tmp_B2_32 : std_logic_vector(31 downto 0);
        variable tmp_B3_32 : std_logic_vector(31 downto 0);
        variable tmp_C0_32 : std_logic_vector(31 downto 0);
        variable tmp_res_8: std_logic_vector(7 downto 0);
        variable tmp_res_16: std_logic_vector(15 downto 0);
        variable tmp_res_32: std_logic_vector(31 downto 0); 
        
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
            hread(text_line, tmp_A0_8);
            hread(text_line, tmp_A1_8);
            hread(text_line, tmp_A2_8);
            hread(text_line, tmp_A3_8);
            hread(text_line, tmp_B0_8);
            hread(text_line, tmp_B1_8);
            hread(text_line, tmp_B2_8);
            hread(text_line, tmp_B3_8);
            hread(text_line, tmp_C0_8);
            hread(text_line, tmp_A0_16);
            hread(text_line, tmp_A1_16);
            hread(text_line, tmp_A2_16);
            hread(text_line, tmp_A3_16);
            hread(text_line, tmp_B0_16);
            hread(text_line, tmp_B1_16);
            hread(text_line, tmp_B2_16);
            hread(text_line, tmp_B3_16);
            hread(text_line, tmp_C0_16);
            hread(text_line, tmp_A0_32);
            hread(text_line, tmp_A1_32);
            hread(text_line, tmp_A2_32);
            hread(text_line, tmp_A3_32);
            hread(text_line, tmp_B0_32);
            hread(text_line, tmp_B1_32);
            hread(text_line, tmp_B2_32);
            hread(text_line, tmp_B3_32);
            hread(text_line, tmp_C0_32);
            --hread(text_line, tmp_res_8);
            --hread(text_line, tmp_res_16);
            --hread(text_line, tmp_res_32);
            
            widthSel_s <= tmp_widthSel;
            typeSel_s <= tmp_typeSel;
        
            A0_8_s <= tmp_A0_8;
            A1_8_s <= tmp_A1_8;
            A2_8_s <= tmp_A2_8;
            A3_8_s <= tmp_A3_8;
            B0_8_s <= tmp_B0_8;
            B1_8_s <= tmp_B1_8;
            B2_8_s <= tmp_B2_8;
            B3_8_s <= tmp_B3_8;
            C0_8_s <= tmp_C0_8;
            
            A0_16_s <= tmp_A0_16;
            A1_16_s <= tmp_A1_16;
            A2_16_s <= tmp_A2_16;
            A3_16_s <= tmp_A3_16;
            B0_16_s <= tmp_B0_16;
            B1_16_s <= tmp_B1_16;
            B2_16_s <= tmp_B2_16;
            B3_16_s <= tmp_B3_16;
            C0_16_s <= tmp_C0_16;
            
            A0_32_s <= tmp_A0_32;
            A1_32_s <= tmp_A1_32;
            A2_32_s <= tmp_A2_32;
            A3_32_s <= tmp_A3_32;
            B0_32_s <= tmp_B0_32;
            B1_32_s <= tmp_B1_32;
            B2_32_s <= tmp_B2_32;
            B3_32_s <= tmp_B3_32;
            C0_32_s <= tmp_C0_32;
            
            --res_8_s <= tmp_res_8;
            --res_16_s <= tmp_res_16;
            --res_32_s <= tmp_res_32;
            
            wait for 50 ns;
            
            hwrite(L, widthSel_s);
            write(L, string'(" "));
            hwrite(L, typeSel_s);
            write(L, string'(" "));
            
            hwrite(L, A0_8_s);
            write(L, string'(" "));
            hwrite(L, A1_8_s);
            write(L, string'(" "));
            hwrite(L, A2_8_s);
            write(L, string'(" "));
            hwrite(L, A3_8_s);
            write(L, string'(" "));
            hwrite(L, B0_8_s);
            write(L, string'(" "));
            hwrite(L, B1_8_s);
            write(L, string'(" "));
            hwrite(L, B2_8_s);
            write(L, string'(" "));
            hwrite(L, B3_8_s);
            write(L, string'(" "));
            hwrite(L, C0_8_s);
            write(L, string'(" "));
           
            hwrite(L, A0_16_s);
            write(L, string'(" "));
            hwrite(L, A1_16_s);
            write(L, string'(" "));
            hwrite(L, A2_16_s);
            write(L, string'(" "));
            hwrite(L, A3_16_s);
            write(L, string'(" "));
            hwrite(L, B0_16_s);
            write(L, string'(" "));
            hwrite(L, B1_16_s);
            write(L, string'(" "));
            hwrite(L, B2_16_s);
            write(L, string'(" "));
            hwrite(L, B3_16_s);
            write(L, string'(" "));
            hwrite(L, C0_16_s);
            write(L, string'(" "));
            
            hwrite(L, A0_32_s);
            write(L, string'(" "));
            hwrite(L, A1_32_s);
            write(L, string'(" "));
            hwrite(L, A2_32_s);
            write(L, string'(" "));
            hwrite(L, A3_32_s);
            write(L, string'(" "));
            hwrite(L, B0_32_s);
            write(L, string'(" "));
            hwrite(L, B1_32_s);
            write(L, string'(" "));
            hwrite(L, B2_32_s);
            write(L, string'(" "));
            hwrite(L, B3_32_s);
            write(L, string'(" "));
            hwrite(L, C0_32_s);
            write(L, string'(" "));
            
            hwrite(L, res_8_s);
            write(L, string'(" "));
            hwrite(L, res_16_s);
            write(L, string'(" "));
            hwrite(L, res_32_s);
            write(L, string'(" "));
            
            writeline(output_file, L); 
            
        end loop;

        wait;
    
    end process ;

end Behavioral;
