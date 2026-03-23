library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity FixPointDpu_tb is
end FixPointDpu_tb;

architecture Behavioral of FixPointDpu_tb is

    signal X0 : std_logic_vector(15 downto 0);
    signal X1 : std_logic_vector(15 downto 0);
    signal X2 : std_logic_vector(15 downto 0);
    signal X3 : std_logic_vector(15 downto 0);
    signal Y0 : std_logic_vector(15 downto 0);
    signal Y1 : std_logic_vector(15 downto 0);
    signal Y2 : std_logic_vector(15 downto 0);
    signal Y3 : std_logic_vector(15 downto 0);
    signal cX0: std_logic_vector(31 downto 0);
    signal R : std_logic_vector(31 downto 0);

    component DotProductUnit
        port (
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

begin

    uut: DotProductUnit
        port map (
            aX0 => X0,
            aX1 => X1,
            aX2 => X2,
            aX3 => X3,
            bY0 => Y0,
            bY1 => Y1,
            bY2 => Y2,
            bY3 => Y3,
            cX0 => cX0,
            R => R
        ); 

    stim_proc: process
        
        --file input_file : text open read_mode is "C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\TestingDPU_FixedPoint\fixed_point_dpu_test_vectors.txt" ;
        file input_file : text open read_mode is "C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\TestingDPU_FixedPoint16_32\dotproduct_fixedPoint16_32_tests.txt" ;
        --file output_file: text open write_mode is "C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\TestingDPU_FixedPoint16_32\FixedPoint16_32_dpu_output_from_HDL_circuit_.txt" ; 
        file output_file : text open write_mode is "\\wsl.localhost\Ubuntu-20.04\home\giooo00\tesi\ThesisGio\verificationDPUFIxedPoint16_32\FixedPoint16_32_dpu_output_from_HDL_circuit_.txt";

        variable text_line : line;
		variable ok : boolean;
		variable char : character;
		
        variable tmp_aX0 : std_logic_vector(15 downto 0);
        variable tmp_aX1 : std_logic_vector(15 downto 0);
        variable tmp_aX2 : std_logic_vector(15 downto 0);
        variable tmp_aX3 : std_logic_vector(15 downto 0);
        variable tmp_bY0 : std_logic_vector(15 downto 0);
        variable tmp_bY1 : std_logic_vector(15 downto 0);
        variable tmp_bY2 : std_logic_vector(15 downto 0);
        variable tmp_bY3 : std_logic_vector(15 downto 0);
        variable tmp_cX0 : std_logic_vector(31 downto 0);
        
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
                                                
            X0 <= tmp_aX0;
            X1 <= tmp_aX1;
            X2 <= tmp_aX2;
            X3 <= tmp_aX3;
            Y0 <= tmp_bY0;
            Y1 <= tmp_bY1;
            Y2 <= tmp_bY2;
            Y3 <= tmp_bY3;
            cX0 <= tmp_cx0;
            
            wait for 50 ns;
            
            hwrite(L, X0);
            write(L, string'(" "));
            hwrite(L, X1);
            write(L, string'(" "));
            hwrite(L, X2);
            write(L, string'(" "));
            hwrite(L, X3);
            write(L, string'(" "));
            hwrite(L, Y0);
            write(L, string'(" "));
            hwrite(L, Y1);
            write(L, string'(" "));
            hwrite(L, Y2);
            write(L, string'(" "));
            hwrite(L, Y3);
            write(L, string'(" "));
            hwrite(L, cX0);
            write(L, string'(" "));
            hwrite(L, R);
            writeline(output_file, L);
            
        end loop;

        wait;
    end process;

end Behavioral;
