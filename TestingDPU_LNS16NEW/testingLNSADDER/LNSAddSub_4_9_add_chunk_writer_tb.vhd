library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

-- ============================================================
-- LNSAddSub_4_9 ADD chunk writer testbench
-- ============================================================
-- Purpose:
--   Read a chunk produced by chunked_exhaustive_lns16_add_plot1.py
--   Apply A and B to the combinational LNSAddSub_4_9_comb module
--   Write one hardware result per input vector.
--
-- Expected input line format:
--   vector_id a_hex b_hex golden_hex delta sign_case
--
-- Example:
--   0 0000 0000 0000 -1 zero_operand
--   1 0000 5000 5000 -1 zero_operand
--
-- Output line format:
--   vector_id obtained_hex
--
-- Example:
--   vector_id obtained_hex
--   0 0000
--   1 5000
--
-- This testbench DOES NOT compare internally.
-- The Python analyzer compares the output against the golden model.
-- ============================================================

entity LNSAddSub_4_9_add_chunk_writer_tb is
end entity;

architecture behavioral of LNSAddSub_4_9_add_chunk_writer_tb is

    component LNSAddSub_4_9_comb is
        port (
            nA : in  std_logic_vector(15 downto 0);
            nB : in  std_logic_vector(15 downto 0);
            nR : out std_logic_vector(15 downto 0)
        );
    end component;

    signal nA_s : std_logic_vector(15 downto 0) := (others => '0');
    signal nB_s : std_logic_vector(15 downto 0) := (others => '0');
    signal nR_s : std_logic_vector(15 downto 0);

    constant BASE_PATH : string :=
        "C:/Users/giovi/OneDrive/Desktop/Magistrale/Tesi/TestingDPU_LNS16NEW/testingLNSADDER/";

    -- Change only these two filenames for each chunk.
    constant INPUT_FILE_NAME  : string := "add_chunk_001.txt";
    constant OUTPUT_FILE_NAME : string := "add_chunk_001_hw.txt";

    constant SETTLE_TIME : time := 20 ns;

begin

    uut : LNSAddSub_4_9_comb
        port map (
            nA => nA_s,
            nB => nB_s,
            nR => nR_s
        );

    stim_proc : process
        file vec_file    : text;
        file result_file : text;

        variable in_status  : file_open_status;
        variable out_status : file_open_status;

        variable L      : line;
        variable O      : line;

        variable id_v     : integer;
        variable A_v      : std_logic_vector(15 downto 0);
        variable B_v      : std_logic_vector(15 downto 0);
        variable GOLD_v   : std_logic_vector(15 downto 0);
        variable DELTA_v  : integer;

        variable total_v  : integer := 0;
    begin

        nA_s <= x"0000";
        nB_s <= x"0000";
        wait for 30 ns;

        file_open(
            in_status,
            vec_file,
            BASE_PATH & INPUT_FILE_NAME,
            read_mode
        );

        assert in_status = open_ok
            report "Could not open input vector file: " & BASE_PATH & INPUT_FILE_NAME
            severity failure;

        file_open(
            out_status,
            result_file,
            BASE_PATH & OUTPUT_FILE_NAME,
            write_mode
        );

        assert out_status = open_ok
            report "Could not open output result file: " & BASE_PATH & OUTPUT_FILE_NAME
            severity failure;

        -- Header for the Python analyzer.
        write(O, string'("vector_id obtained_hex"));
        writeline(result_file, O);

        while not endfile(vec_file) loop
            readline(vec_file, L);

            -- Skip empty lines and comment/header lines beginning with '#'.
            if L.all'length = 0 then
                next;
            end if;

            if L.all(L.all'left) = '#' then
                next;
            end if;

            -- Read:
            --   vector_id a_hex b_hex golden_hex delta sign_case
            -- sign_case is intentionally left unread.
            read(L, id_v);
            hread(L, A_v);
            hread(L, B_v);
            hread(L, GOLD_v);
            read(L, DELTA_v);

            nA_s <= A_v;
            nB_s <= B_v;

            wait for SETTLE_TIME;

            write(O, id_v);
            write(O, character'(' '));
            hwrite(O, nR_s);
            writeline(result_file, O);

            total_v := total_v + 1;

            if (total_v mod 10000) = 0 then
                report "Processed ADD chunk vectors: " & integer'image(total_v);
            end if;
        end loop;

        file_close(vec_file);
        file_close(result_file);

        report "Finished LNSAddSub ADD chunk writer testbench.";
        report "Total vectors processed = " & integer'image(total_v);
        report "Output file = " & BASE_PATH & OUTPUT_FILE_NAME;

        assert false
            report "End of LNSAddSub ADD chunk writer simulation."
            severity failure;

    end process;

end architecture;
