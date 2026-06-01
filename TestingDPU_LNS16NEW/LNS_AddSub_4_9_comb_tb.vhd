library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity LNSAddSub_4_9_comb_sanity_tb is
end entity;

architecture behavioral of LNSAddSub_4_9_comb_sanity_tb is

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

    signal expected_s : std_logic_vector(15 downto 0) := (others => '0');
    signal test_id_s  : integer := 0;

    constant BASE_PATH : string :=
        "C:/Users/giovi/OneDrive/Desktop/Magistrale/Tesi/TestingDPU_LNS16/vectors/";

    constant SETTLE_TIME : time := 20 ns;
    
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

    uut : LNSAddSub_4_9_comb
        port map (
            nA => nA_s,
            nB => nB_s,
            nR => nR_s
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
            variable A_v   : std_logic_vector(15 downto 0);
            variable B_v   : std_logic_vector(15 downto 0);
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
                hread(L, A_v);
                hread(L, B_v);
                hread(L, EXP_v);
                read(L, TOL_v);

                test_id_s  <= id_v;
                nA_s       <= A_v;
                nB_s       <= B_v;
                expected_s <= EXP_v;

                -- Combinational settling time.
                -- No clock, no reset, no pipeline latency.
                wait for SETTLE_TIME;

                got_log := to_integer(signed(nR_s(12 downto 0)));
                exp_log := to_integer(signed(EXP_v(12 downto 0)));
                diff := got_log - exp_log;

                if diff < 0 then
                    diff := -diff;
                end if;

                total_tests_v := total_tests_v + 1;

                if (nR_s(15 downto 13) /= EXP_v(15 downto 13)) or (diff > TOL_v) then                    failed_tests_v := failed_tests_v + 1;

                    assert false
                    report "LNSAddSub_comb vector failed.      File = " & filename &
                           " Test ID = " & integer'image(id_v) &
                      " A=0x" & slv_to_hex(A_v) &
                           " B=0x" & slv_to_hex(B_v) &
                           " EXP=0x" & slv_to_hex(EXP_v) &
                           " GOT=0x" & slv_to_hex(nR_s) &
                           " EXP_TOP=" & slv_to_hex(EXP_v(15 downto 13)) &
                           " GOT_TOP=" & slv_to_hex(nR_s(15 downto 13)) &
                           " Diff=" & integer'image(diff) &
                           " Tol=" & integer'image(TOL_v)
                    severity warning;
                end if;
            end loop;

            file_close(vec_file);
        end procedure;

    begin

        nA_s <= x"0000";
        nB_s <= x"0000";
        expected_s <= x"0000";
        test_id_s <= 0;

        wait for 30 ns;

        report "Running same-sign LNSAddSub combinational vectors";
        run_vector_file(BASE_PATH & "LNSAddSub_same_sign_vectors.txt");

        report "Running opposite-sign basic LNSAddSub combinational vectors";
        run_vector_file(BASE_PATH & "LNSAddSub_opposite_basic_vectors.txt");

        -- Keep random stress disabled for the moment.
        -- Enable this after the structured files pass.
        -- report "Running random stress LNSAddSub combinational vectors";
        -- run_vector_file(BASE_PATH & "LNSAddSub_random_stress_vectors.txt");

        report "Total tests = " & integer'image(total_tests_v);
        report "Failed tests = " & integer'image(failed_tests_v);

        if failed_tests_v = 0 then
            assert false
                report "End of LNSAddSub combinational vector-file simulation: ALL TESTS PASSED."
                severity failure;
        else
            assert false
                report "End of LNSAddSub combinational vector-file simulation: SOME TESTS FAILED."
                severity failure;
        end if;

    end process;

end architecture;