library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

library fp8_lib;

entity FP8DPU_error_TB is
    generic (
        INPUT_FILE  : string := "fp8_vectors.txt";
        OUTPUT_FILE : string := "fp8_hw_outputs.txt"
    );
end entity FP8DPU_error_TB;

architecture tb of FP8DPU_error_TB is

    signal A0 : std_logic_vector(7 downto 0);
    signal A1 : std_logic_vector(7 downto 0);
    signal A2 : std_logic_vector(7 downto 0);
    signal A3 : std_logic_vector(7 downto 0);

    signal B0 : std_logic_vector(7 downto 0);
    signal B1 : std_logic_vector(7 downto 0);
    signal B2 : std_logic_vector(7 downto 0);
    signal B3 : std_logic_vector(7 downto 0);

    signal C0 : std_logic_vector(7 downto 0);
    signal R  : std_logic_vector(7 downto 0);

begin

    dpu_inst : entity fp8_lib.DotProductUnitFP8e4m3
        port map (
            aX0 => A0,
            aX1 => A1,
            aX2 => A2,
            aX3 => A3,

            bY0 => B0,
            bY1 => B1,
            bY2 => B2,
            bY3 => B3,

            cX0 => C0,

            R   => R
        );

    stim_proc : process
        file input_f  : text;
        file output_f : text;

        variable input_line  : line;
        variable output_line : line;

        variable vA0 : std_logic_vector(7 downto 0);
        variable vA1 : std_logic_vector(7 downto 0);
        variable vA2 : std_logic_vector(7 downto 0);
        variable vA3 : std_logic_vector(7 downto 0);

        variable vB0 : std_logic_vector(7 downto 0);
        variable vB1 : std_logic_vector(7 downto 0);
        variable vB2 : std_logic_vector(7 downto 0);
        variable vB3 : std_logic_vector(7 downto 0);

        variable vC0 : std_logic_vector(7 downto 0);

        variable test_count : integer := 0;

    begin
        file_open(input_f, INPUT_FILE, read_mode);
        file_open(output_f, OUTPUT_FILE, write_mode);

        while not endfile(input_f) loop
            readline(input_f, input_line);

            hread(input_line, vA0);
            hread(input_line, vA1);
            hread(input_line, vA2);
            hread(input_line, vA3);

            hread(input_line, vB0);
            hread(input_line, vB1);
            hread(input_line, vB2);
            hread(input_line, vB3);

            hread(input_line, vC0);

            A0 <= vA0;
            A1 <= vA1;
            A2 <= vA2;
            A3 <= vA3;

            B0 <= vB0;
            B1 <= vB1;
            B2 <= vB2;
            B3 <= vB3;

            C0 <= vC0;

            wait for 20 ns;

            hwrite(output_line, R);
            writeline(output_f, output_line);

            test_count := test_count + 1;
        end loop;

        file_close(input_f);
        file_close(output_f);

        report "FP8 error-analysis simulation completed. Number of tests = " &
               integer'image(test_count)
               severity note;

        wait;
    end process;

end architecture tb;