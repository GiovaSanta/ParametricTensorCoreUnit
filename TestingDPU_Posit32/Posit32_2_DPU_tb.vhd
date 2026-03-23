library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity Posit32_Dpu_tb is
end Posit32_Dpu_tb;

architecture Behavioral of Posit32_Dpu_tb is

    signal aX0_s : std_logic_vector(31 downto 0);
    signal aX1_s : std_logic_vector(31 downto 0);
    signal aX2_s : std_logic_vector(31 downto 0);
    signal aX3_s : std_logic_vector(31 downto 0);
    signal bY0_s : std_logic_vector(31 downto 0);
    signal bY1_s : std_logic_vector(31 downto 0);
    signal bY2_s : std_logic_vector(31 downto 0);
    signal bY3_s : std_logic_vector(31 downto 0);
    signal cX0_s : std_logic_vector(31 downto 0);
    signal R_s :   std_logic_vector(31 downto 0); 
    signal golden_R_s : std_logic_vector(31 downto 0);

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

begin

    uut: DotProductUnitPosit32
        port map (
            aX0 => aX0_s,
            aX1 => aX1_s,
            aX2 => aX2_s,
            aX3 => aX3_s,
            bY0 => bY0_s,
            bY1 => bY1_s,
            bY2 => bY2_s,
            bY3 => bY3_s,
            cX0 => cX0_s,
            R => R_s
        ); 

    stim_proc: process
        
        file input_file : text open read_mode is "C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\TestingDPU_Posit32\Posit32_dpu_test_vectors.txt" ;
        file output_file: text open write_mode is "C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\TestingDPU_Posit32\output_file.txt" ;
        
        variable text_line : line;
		variable ok : boolean;
		variable char : character;
		
        variable tmp_aX0 : std_logic_vector(31 downto 0);
        variable tmp_aX1 : std_logic_vector(31 downto 0);
        variable tmp_aX2 : std_logic_vector(31 downto 0);
        variable tmp_aX3 : std_logic_vector(31 downto 0);
        variable tmp_bY0 : std_logic_vector(31 downto 0);
        variable tmp_bY1 : std_logic_vector(31 downto 0);
        variable tmp_bY2 : std_logic_vector(31 downto 0);
        variable tmp_bY3 : std_logic_vector(31 downto 0);
        variable tmp_cX0 : std_logic_vector(31 downto 0);
        variable tmp_goldenR : std_logic_vector(31 downto 0); 
        
        variable L : line ;
        
    begin
        
        while not endfile(input_file) loop
            
            readline(input_file, text_line);

            -- Skip comment lines
            if text_line.all'length = 0 or text_line.all(1) = '#' then
					next;
				end if;

            hread(text_line, tmp_aX0);
            hread(text_line, tmp_aX1);
            hread(text_line, tmp_aX2);
            hread(text_line, tmp_aX3);
            hread(text_line, tmp_bY0);
            hread(text_line, tmp_bY1);
            hread(text_line, tmp_bY2);
            hread(text_line, tmp_bY3);
            hread(text_line, tmp_cX0);
            hread(text_line, tmp_goldenR);

                                                
            aX0_s <= tmp_aX0;
            aX1_s <= tmp_aX1;
            aX2_s <= tmp_aX2;
            aX3_s <= tmp_aX3;
            bY0_s <= tmp_bY0;
            bY1_s <= tmp_bY1;
            bY2_s <= tmp_bY2;
            bY3_s <= tmp_bY3;
            cX0_s <= tmp_cX0;
            golden_R_s <= tmp_goldenR;
            
            wait for 50 ns;
            
            hwrite(L, aX0_s);
            write(L, string'(" "));
            hwrite(L, aX1_s);
            write(L, string'(" "));
            hwrite(L, aX2_s);
            write(L, string'(" "));
            hwrite(L, aX3_s);
            write(L, string'(" "));
            hwrite(L, bY0_s);
            write(L, string'(" "));
            hwrite(L, bY1_s);
            write(L, string'(" "));
            hwrite(L, bY2_s);
            write(L, string'(" "));
            hwrite(L, bY3_s);
            write(L, string'(" "));
            hwrite(L, cX0_s);
            write(L, string'(" "));
            hwrite(L, R_s);
            writeline(output_file, L); 
            
        end loop;

        wait;
    end process;

end Behavioral;
