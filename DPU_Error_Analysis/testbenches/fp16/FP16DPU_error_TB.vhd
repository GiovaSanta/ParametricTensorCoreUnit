library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

library fp16_lib;

--------------------------------------------------------------------------------
-- FP16_error_tb
--
-- Error-analysis simulation testbench for the FP16 DPU.
--
-- Reads:
--   fp16_vectors.txt
--
-- Each input line contains:
--   A0 A1 A2 A3 B0 B1 B2 B3 C0
--
-- Writes:
--   fp16_hw_outputs.txt
--
-- Each output line contains:
--   R
--------------------------------------------------------------------------------

entity FP16_error_tb is
    generic (
        INPUT_FILE  : string := "fp16_vectors.txt";
        OUTPUT_FILE : string := "fp16_hw_outputs.txt"
    );
end entity FP16_error_tb;

architecture tb of FP16_error_tb is

    signal A0 : std_logic_vector(15 downto 0);
    signal A1 : std_logic_vector(15 downto 0);
    signal A2 : std_logic_vector(15 downto 0);
    signal A3 : std_logic_vector(15 downto 0);

    signal B0 : std_logic_vector(15 downto 0);
    signal B1 : std_logic_vector(15 downto 0);
    signal B2 : std_logic_vector(15 downto 0);
    signal B3 : std_logic_vector(15 downto 0);

    signal C0 : std_logic_vector(15 downto 0);

    signal R  : std_logic_vector(15 downto 0);

begin

    ---------------------------------------------------------------------------
    -- FP16 combinational DPU under test
    ---------------------------------------------------------------------------
    dpu_inst : entity fp16_lib.DotProductUnitFP16
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

    ---------------------------------------------------------------------------
    -- File-driven simulation process
    ---------------------------------------------------------------------------
    stim_proc : process
        file input_f  : text;
        file output_f : text;

        variable input_line  : line;
        variable output_line : line;

        variable vA0 : std_logic_vector(15 downto 0);
        variable vA1 : std_logic_vector(15 downto 0);
        variable vA2 : std_logic_vector(15 downto 0);
        variable vA3 : std_logic_vector(15 downto 0);

        variable vB0 : std_logic_vector(15 downto 0);
        variable vB1 : std_logic_vector(15 downto 0);
        variable vB2 : std_logic_vector(15 downto 0);
        variable vB3 : std_logic_vector(15 downto 0);

        variable vC0 : std_logic_vector(15 downto 0);

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

            -- Combinational settling time.
            wait for 20 ns;

            hwrite(output_line, R);
            writeline(output_f, output_line);

            test_count := test_count + 1;
        end loop;

        file_close(input_f);
        file_close(output_f);

        report "FP16 error-analysis simulation completed. Number of tests = " &
               integer'image(test_count)
               severity note;

        wait;
    end process;

end architecture tb;