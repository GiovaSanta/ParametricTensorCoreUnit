library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity Posit32_Mult_tb is
end Posit32_Mult_tb;

architecture Behavioral of Posit32_Mult_tb is

    signal X : std_logic_vector( 31 downto 0);
    signal Y : std_logic_vector( 31 downto 0);
    signal R : std_logic_vector( 31 downto 0);
    signal goldenRes: std_logic_vector( 31 downto 0 );
    
    component PositMult_32_2_F0_uid2
        port( X : in  std_logic_vector(31 downto 0);
              Y : in  std_logic_vector(31 downto 0);
              R : out std_logic_vector(31 downto 0)   
           );
    end component;

begin

    uut: PositMult_32_2_F0_uid2
        port map (
            X => X,
            Y => Y,
            R => R
        ); 

    stim_proc: process
        
        file input_file : text open read_mode is "C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\TestingDPU_Posit32\Posit32_Mult_TestVectors.txt" ;
        
        variable text_line : line;
		variable ok : boolean;
		variable char : character;
		
        variable tmp_X : std_logic_vector(31 downto 0);
        variable tmp_Y : std_logic_vector(31 downto 0);
        variable tmp_golden: std_logic_vector(31 downto 0);
        
    begin
        while not endfile(input_file) loop
            
            readline(input_file, text_line);

            -- Skip comment lines
            if text_line.all'length = 0 or text_line.all(1) = '#' then
					next;
				end if;

            hread(text_line, tmp_X);
            hread(text_line, tmp_Y);
            hread(text_line, tmp_golden);

            X <= tmp_X;
            Y <= tmp_Y;
            goldenRes <= tmp_golden;
            
            wait for 50 ns;
            
        end loop;

        wait;
    end process;

end Behavioral;
