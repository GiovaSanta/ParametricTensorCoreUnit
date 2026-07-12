library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;
use std.env.all;

library posit32_lib;

entity Posit32_fault_campaign_100vectors_TB is
    generic (
        GOLDEN_INPUT_FILE  : string := "posit32_vectors.txt";
        FAULT_INPUT_FILE   : string := "fault_vectors.txt";
        GOLDEN_OUTPUT_FILE : string := "golden_results.txt";
        FAULT_OUTPUT_FILE  : string := "faulty_results.txt";
        SETTLE_TIME        : time   := 20 ns
    );
end entity;

architecture tb of Posit32_fault_campaign_100vectors_TB is
    signal A0, A1, A2, A3 : std_logic_vector(31 downto 0);
    signal B0, B1, B2, B3 : std_logic_vector(31 downto 0);
    signal C0, R           : std_logic_vector(31 downto 0);
begin

    dpu_inst : entity posit32_lib.DotProductUnitPosit32
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
        file golden_in  : text;
        file fault_in   : text;
        file golden_out : text;
        file fault_out  : text;

        variable input_line  : line;
        variable output_line : line;

        variable vA0, vA1, vA2, vA3 :
            std_logic_vector(31 downto 0);
        variable vB0, vB1, vB2, vB3 :
            std_logic_vector(31 downto 0);
        variable vC0 :
            std_logic_vector(31 downto 0);

        variable golden_count : natural := 0;
        variable fault_count  : natural := 0;
    begin
        file_open(golden_in, GOLDEN_INPUT_FILE, read_mode);
        file_open(golden_out, GOLDEN_OUTPUT_FILE, write_mode);

        while not endfile(golden_in) loop
            readline(golden_in, input_line);

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

            wait for SETTLE_TIME;

            hwrite(output_line, R);
            writeline(golden_out, output_line);
            golden_count := golden_count + 1;
        end loop;

        file_close(golden_in);
        file_close(golden_out);

        file_open(fault_in, FAULT_INPUT_FILE, read_mode);
        file_open(fault_out, FAULT_OUTPUT_FILE, write_mode);

        while not endfile(fault_in) loop
            readline(fault_in, input_line);

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

            wait for SETTLE_TIME;

            hwrite(output_line, R);
            writeline(fault_out, output_line);
            fault_count := fault_count + 1;
        end loop;

        file_close(fault_in);
        file_close(fault_out);

        report
            "Golden vectors written: "
            & integer'image(golden_count)
            & "; faulty cases written: "
            & integer'image(fault_count)
            severity note;

        stop;
        wait;
    end process;

end architecture;
