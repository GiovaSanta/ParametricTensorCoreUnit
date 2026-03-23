library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity LNS_AddSub_4_9_tb is
end LNS_AddSub_4_9_tb;

architecture Behavioral of LNS_AddSub_4_9_tb is

    signal nA_s : std_logic_vector(15 downto 0);
    signal nB_s : std_logic_vector(15 downto 0);
    signal nR_s : std_logic_vector(15 downto 0);

    component LNSAddSub_4_9
        port ( nA : in  std_logic_vector(15 downto 0);
               nB : in  std_logic_vector(15 downto 0);
               nR : out  std_logic_vector(15 downto 0)   );
    end component;

begin

    uut: LNSAddSub_4_9
        port map (
            nA => nA_s,
            nB => nB_s,
            nR => nR_s
        ); 

    stim_proc: process
        
        file input_file : text open read_mode is "C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\TestingDPU_LNS16\LNSAddSub_4_9_TestVectors.txt.txt";
        
        variable text_line : line;
		variable ok : boolean;
		variable char : character;
		
        variable tmp_nA : std_logic_vector(15 downto 0);
        variable tmp_nB : std_logic_vector(15 downto 0);
        variable tmp_nR : std_logic_vector(15 downto 0);

    begin
        
        while not endfile(input_file) loop
            
            readline(input_file, text_line);

            -- Skip comment lines
            if text_line.all'length = 0 or text_line.all(1) = '#' then
					next;
				end if;

            hread(text_line, tmp_nA);
            hread(text_line, tmp_nB);
                                                
            nA_s <= tmp_nA;
            nB_s <= tmp_nB;
            
            wait for 50 ns;
            
        end loop;

        wait;
    end process;

end Behavioral;
