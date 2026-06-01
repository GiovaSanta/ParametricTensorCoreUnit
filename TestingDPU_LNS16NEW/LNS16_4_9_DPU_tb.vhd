--------------------------------------------------------------------------------
-- LNS16_4_9_DPU_tb
--
-- File-based sanity testbench for the combinational LNS16_4_9_DPU.
--
-- DUT equation:
--
--     R = A0*B0 + A1*B1 + A2*B2 + A3*B3 + C0
--
-- Vector file format:
--
--     ID A0 A1 A2 A3 B0 B1 B2 B3 C0 EXPECTED TOL
--
-- All LNS operands/results are 16-bit hexadecimal values.
-- TOL is an integer tolerance applied to the signed log field R(12 downto 0).
--
-- Comparison:
--   - bits 15 downto 13 must match exactly
--   - signed log field 12 downto 0 must differ by no more than TOL
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity LNS16_4_9_DPU_tb is
end entity;

architecture behavioral of LNS16_4_9_DPU_tb is

    signal A0_s : std_logic_vector(15 downto 0) := (others => '0');
    signal A1_s : std_logic_vector(15 downto 0) := (others => '0');
    signal A2_s : std_logic_vector(15 downto 0) := (others => '0');
    signal A3_s : std_logic_vector(15 downto 0) := (others => '0');

    signal B0_s : std_logic_vector(15 downto 0) := (others => '0');
    signal B1_s : std_logic_vector(15 downto 0) := (others => '0');
    signal B2_s : std_logic_vector(15 downto 0) := (others => '0');
    signal B3_s : std_logic_vector(15 downto 0) := (others => '0');

    signal C0_s : std_logic_vector(15 downto 0) := (others => '0');

    signal R_s        : std_logic_vector(15 downto 0);
    signal expected_s : std_logic_vector(15 downto 0) := (others => '0');
    signal test_id_s  : integer := 0;

    constant BASE_PATH : string :=
        "C:/Users/giovi/OneDrive/Desktop/Magistrale/Tesi/TestingDPU_LNS16NEW/vectors/";

    constant SETTLE_TIME : time := 80 ns;

    function slv_to_hex(slv : std_logic_vector) return string is
        constant hex_chars : string := "0123456789ABCDEF";
        variable result : string(1 to (slv'length + 3) / 4);
        variable padded : std_logic_vector(((slv'length + 3) / 4) * 4 - 1 downto 0);
        variable nibble : integer;
    begin
        padded := (others => '0');
        padded(slv'length - 1 downto 0) := slv;

        for i in 0 to result'length - 1 loop
            nibble := to_integer(unsigned(
                padded(padded'left - i*4 downto padded'left - i*4 - 3)
            ));
            result(i + 1) := hex_chars(nibble + 1);
        end loop;

        return result;
    end function;

begin

    uut : entity work.LNS16_4_9_DPU
        port map (
            A0 => A0_s,
            A1 => A1_s,
            A2 => A2_s,
            A3 => A3_s,

            B0 => B0_s,
            B1 => B1_s,
            B2 => B2_s,
            B3 => B3_s,

            C0 => C0_s,

            R  => R_s
        );

    stim_proc : process

        variable total_tests_v  : integer := 0;
        variable failed_tests_v : integer := 0;

        procedure run_vector_file(
            constant filename : in string
        ) is
            file vec_file : text;
            variable status : file_open_status;
            variable L : line;

            variable id_v  : integer;

            variable A0_v : std_logic_vector(15 downto 0);
            variable A1_v : std_logic_vector(15 downto 0);
            variable A2_v : std_logic_vector(15 downto 0);
            variable A3_v : std_logic_vector(15 downto 0);

            variable B0_v : std_logic_vector(15 downto 0);
            variable B1_v : std_logic_vector(15 downto 0);
            variable B2_v : std_logic_vector(15 downto 0);
            variable B3_v : std_logic_vector(15 downto 0);

            variable C0_v  : std_logic_vector(15 downto 0);
            variable EXP_v : std_logic_vector(15 downto 0);
            variable TOL_v : integer;

            variable got_log : integer;
            variable exp_log : integer;
            variable diff    : integer;
        begin
            file_open(status, vec_file, filename, read_mode);

            assert status = open_ok
                report "Could not open vector file: " & filename
                severity failure;

            while not endfile(vec_file) loop
                readline(vec_file, L);

                read(L, id_v);

                hread(L, A0_v);
                hread(L, A1_v);
                hread(L, A2_v);
                hread(L, A3_v);

                hread(L, B0_v);
                hread(L, B1_v);
                hread(L, B2_v);
                hread(L, B3_v);

                hread(L, C0_v);
                hread(L, EXP_v);
                read(L, TOL_v);

                test_id_s <= id_v;

                A0_s <= A0_v;
                A1_s <= A1_v;
                A2_s <= A2_v;
                A3_s <= A3_v;

                B0_s <= B0_v;
                B1_s <= B1_v;
                B2_s <= B2_v;
                B3_s <= B3_v;

                C0_s <= C0_v;

                expected_s <= EXP_v;

                -- Combinational settling time through:
                -- 4 multipliers + 4 LNS add/sub blocks.
                wait for SETTLE_TIME;

                got_log := to_integer(signed(R_s(12 downto 0)));
                exp_log := to_integer(signed(EXP_v(12 downto 0)));
                diff := got_log - exp_log;

                if diff < 0 then
                    diff := -diff;
                end if;

                total_tests_v := total_tests_v + 1;

                if (R_s(15 downto 13) /= EXP_v(15 downto 13)) or (diff > TOL_v) then
                    failed_tests_v := failed_tests_v + 1;

                    assert false
                        report "LNS16_4_9_DPU vector failed. File = " & filename &
                               " Test ID = " & integer'image(id_v) &
                               " A0=0x" & slv_to_hex(A0_v) &
                               " A1=0x" & slv_to_hex(A1_v) &
                               " A2=0x" & slv_to_hex(A2_v) &
                               " A3=0x" & slv_to_hex(A3_v) &
                               " B0=0x" & slv_to_hex(B0_v) &
                               " B1=0x" & slv_to_hex(B1_v) &
                               " B2=0x" & slv_to_hex(B2_v) &
                               " B3=0x" & slv_to_hex(B3_v) &
                               " C0=0x" & slv_to_hex(C0_v) &
                               " EXP=0x" & slv_to_hex(EXP_v) &
                               " GOT=0x" & slv_to_hex(R_s) &
                               " EXP_TOP=" & slv_to_hex(EXP_v(15 downto 13)) &
                               " GOT_TOP=" & slv_to_hex(R_s(15 downto 13)) &
                               " Diff=" & integer'image(diff) &
                               " Tol=" & integer'image(TOL_v)
                        severity warning;
                end if;
            end loop;

            file_close(vec_file);
        end procedure;

    begin

        A0_s <= x"0000";
        A1_s <= x"0000";
        A2_s <= x"0000";
        A3_s <= x"0000";

        B0_s <= x"0000";
        B1_s <= x"0000";
        B2_s <= x"0000";
        B3_s <= x"0000";

        C0_s <= x"0000";

        expected_s <= x"0000";
        test_id_s <= 0;

        wait for 30 ns;

        report "Running LNS16_4_9_DPU combinational vectors";
        run_vector_file(BASE_PATH & "LNS16_4_9_DPU_vectors.txt");

        report "Total tests = " & integer'image(total_tests_v);
        report "Failed tests = " & integer'image(failed_tests_v);

        if failed_tests_v = 0 then
            assert false
                report "End of LNS16_4_9_DPU combinational vector-file simulation: ALL TESTS PASSED."
                severity failure;
        else
            assert false
                report "End of LNS16_4_9_DPU combinational vector-file simulation: SOME TESTS FAILED."
                severity failure;
        end if;

    end process;

end architecture;
