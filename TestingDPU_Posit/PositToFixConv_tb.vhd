library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity PositToFixConv_tb is
end PositToFixConv_tb;

architecture Behavioral of PositToFixConv_tb is

    signal P : std_logic_vector(7 downto 0);
    signal FixOut : std_logic_vector(15 downto 0); 

    component Posit8ToFix
        port (
        P : in std_logic_vector(7 downto 0);      -- Posit8 input
        FixOut : out std_logic_vector(15 downto 0)          -- Q5.10 format fixed-point output
    );
    end component;

begin

    uut: Posit8ToFix
        port map ( 
            P => P,
            FixOut => FixOut 
        ); 

    stim_proc: process
        
        file input_file : text open read_mode is "C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\TestingDPU_Posit\Posit8_TestVectors.txt" ;
        
        variable text_line : line;
		variable ok : boolean;
		variable char : character;
		
        variable tmp_P : std_logic_vector(7 downto 0);
        --variable goldenRes_text : std_logic_vector(15 downto 0);

    begin
        while not endfile(input_file) loop
            
            readline(input_file, text_line);

            -- Skip comment lines
            if text_line.all'length = 0 or text_line.all(1) = '#' then
					next;
				end if;

            hread(text_line, tmp_P);
            --hread(text_line, goldenRes_text);

            P <= tmp_P;
            --goldenRes <= goldenRes_text;
            
            wait for 50 ns;
            
        end loop;

        wait;
    end process;

end Behavioral;
