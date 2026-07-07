library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

library fp16_lib;

--------------------------------------------------------------------------------
-- FP16_fault_tb
--
-- Fault-injection simulation testbench for the FP16 DPU.
--
-- This testbench is derived from FP16_error_tb.
--
-- It supports single-bit transient faults on:
--
--   target_id = 0  -> output R
--   target_id = 1  -> input A0
--   target_id = 2  -> input A1
--   target_id = 3  -> input A2
--   target_id = 4  -> input A3
--   target_id = 5  -> input B0
--   target_id = 6  -> input B1
--   target_id = 7  -> input B2
--   target_id = 8  -> input B3
--   target_id = 9  -> input C0
--
-- Fault model:
--   single-bit flip on one selected vector and one selected bit.
--
-- Reads:
--   fp16_vectors.txt
--
-- Each input line contains:
--   A0 A1 A2 A3 B0 B1 B2 B3 C0
--
-- Writes:
--   fp16_faulty_outputs.txt
--
-- Each output line contains:
--   R
--------------------------------------------------------------------------------

entity FP16_fault_tb is
    generic (
        INPUT_FILE  : string := "fp16_vectors.txt";
        OUTPUT_FILE : string := "fp16_faulty_outputs.txt";

        FAULT_ENABLE    : boolean := false;
        FAULT_VECTOR    : integer := -1;
        FAULT_TARGET_ID : integer := -1;
        FAULT_BIT       : integer := -1
    );
end entity FP16_fault_tb;

architecture tb of FP16_fault_tb is

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

    ---------------------------------------------------------------------------
    -- Helper function: flip one bit of a 16-bit word.
    ---------------------------------------------------------------------------
    function flip_bit_16 (
        x       : std_logic_vector(15 downto 0);
        bit_idx : integer
    ) return std_logic_vector is
        variable y : std_logic_vector(15 downto 0);
    begin
        y := x;

        if bit_idx >= 0 and bit_idx <= 15 then
            y(bit_idx) := not y(bit_idx);
        end if;

        return y;
    end function;

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

        variable vR_out : std_logic_vector(15 downto 0);

        variable test_count : integer := 0;

    begin

        report "FP16 fault simulation started." severity note;

        if FAULT_ENABLE then
            report "Fault enabled. Vector = " &
                   integer'image(FAULT_VECTOR) &
                   ", Target ID = " &
                   integer'image(FAULT_TARGET_ID) &
                   ", Bit = " &
                   integer'image(FAULT_BIT)
                   severity note;
        else
            report "Fault disabled. Golden-style run." severity note;
        end if;

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

            -------------------------------------------------------------------
            -- Input-side fault injection.
            --
            -- This models a transient bit flip in an operand word before
            -- the DPU evaluates the vector.
            -------------------------------------------------------------------
            if FAULT_ENABLE and test_count = FAULT_VECTOR then
                case FAULT_TARGET_ID is

                    when 1 =>
                        vA0 := flip_bit_16(vA0, FAULT_BIT);

                    when 2 =>
                        vA1 := flip_bit_16(vA1, FAULT_BIT);

                    when 3 =>
                        vA2 := flip_bit_16(vA2, FAULT_BIT);

                    when 4 =>
                        vA3 := flip_bit_16(vA3, FAULT_BIT);

                    when 5 =>
                        vB0 := flip_bit_16(vB0, FAULT_BIT);

                    when 6 =>
                        vB1 := flip_bit_16(vB1, FAULT_BIT);

                    when 7 =>
                        vB2 := flip_bit_16(vB2, FAULT_BIT);

                    when 8 =>
                        vB3 := flip_bit_16(vB3, FAULT_BIT);

                    when 9 =>
                        vC0 := flip_bit_16(vC0, FAULT_BIT);

                    when others =>
                        null;

                end case;
            end if;

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

            vR_out := R;

            -------------------------------------------------------------------
            -- Output-side fault injection.
            --
            -- This models a transient bit flip at the DPU output word,
            -- for example before writeback or result storage.
            -------------------------------------------------------------------
            if FAULT_ENABLE and test_count = FAULT_VECTOR then
                if FAULT_TARGET_ID = 0 then
                    vR_out := flip_bit_16(R, FAULT_BIT);
                end if;
            end if;

            hwrite(output_line, vR_out);
            writeline(output_f, output_line);

            test_count := test_count + 1;
        end loop;

        file_close(input_f);
        file_close(output_f);

        report "FP16 fault simulation completed. Number of tests = " &
               integer'image(test_count)
               severity note;

        wait;
    end process;

end architecture tb;