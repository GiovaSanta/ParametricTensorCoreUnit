library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity INT8Dpu_tb is
end INT8Dpu_tb;

architecture Behavioral of INT8Dpu_tb is

    signal aX0_s : std_logic_vector(7 downto 0);
    signal aX1_s : std_logic_vector(7 downto 0);
    signal aX2_s : std_logic_vector(7 downto 0);
    signal aX3_s : std_logic_vector(7 downto 0);
    signal bY0_s : std_logic_vector(7 downto 0);
    signal bY1_s : std_logic_vector(7 downto 0);
    signal bY2_s : std_logic_vector(7 downto 0);
    signal bY3_s : std_logic_vector(7 downto 0);
    signal cX0_s : std_logic_vector(15 downto 0);
    signal R_s : std_logic_vector(15 downto 0);
    signal R_gold_s : std_logic_vector(15 downto 0);

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

begin

    uut: dot_unit_coreINT8
        port map (
            a_X0 => aX0_s,
            a_X1 => aX1_s,
            a_X2 => aX2_s,
            a_X3 => aX3_s,
            b_X0 => bY0_s,
            b_X1 => bY1_s,
            b_X2 => bY2_s,
            b_X3 => bY3_S,
            c_X0 => cX0_s,
            w_XX3 => R_s
        ); 

    stim_proc: process
        
        file input_file : text open read_mode is "C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\TestingDPU_INT8\int8_int16out_tests.txt" ;
        file output_file: text open write_mode is  "C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\TestingDPU_INT8\output_file.txt";
        
        variable text_line : line;
		variable ok : boolean;
		variable char : character;
		
        variable tmp_aX0 : std_logic_vector(7 downto 0);
        variable tmp_aX1 : std_logic_vector(7 downto 0);
        variable tmp_aX2 : std_logic_vector(7 downto 0);
        variable tmp_aX3 : std_logic_vector(7 downto 0);
        variable tmp_bY0 : std_logic_vector(7 downto 0);
        variable tmp_bY1 : std_logic_vector(7 downto 0);
        variable tmp_bY2 : std_logic_vector(7 downto 0);
        variable tmp_bY3 : std_logic_vector(7 downto 0);
        variable tmp_cX0 : std_logic_vector(15 downto 0);
        variable tmp_gold: std_logic_vector(15 downto 0);
        
        variable L : line;

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
            hread(text_line, tmp_gold);
                                      
            aX0_s <= tmp_aX0;
            aX1_s <= tmp_aX1;
            aX2_s <= tmp_aX2;
            aX3_s <= tmp_aX3;
            bY0_s <= tmp_bY0;
            bY1_s <= tmp_bY1;
            bY2_s <= tmp_bY2;
            bY3_s <= tmp_bY3;
            cX0_s <= tmp_cX0;
            R_gold_s <= tmp_gold;
            
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
            
            wait for 50 ns;
            
        end loop;

        wait;
    end process;

end Behavioral;
