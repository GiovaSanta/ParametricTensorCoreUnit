library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity LNSAddSub_4_9_sanity_tb is
end entity;

architecture behavioral of LNSAddSub_4_9_sanity_tb is

    component LNSAddSub_4_9 is
        port (
            clk : in  std_logic;
            rst : in  std_logic;
            nA  : in  std_logic_vector(15 downto 0);
            nB  : in  std_logic_vector(15 downto 0);
            nR  : out std_logic_vector(15 downto 0)
        );
    end component;

    signal clk_s : std_logic := '0';
    signal rst_s : std_logic := '0';

    signal nA_s : std_logic_vector(15 downto 0) := (others => '0');
    signal nB_s : std_logic_vector(15 downto 0) := (others => '0');
    signal nR_s : std_logic_vector(15 downto 0);

    signal expected_s : std_logic_vector(15 downto 0) := (others => '0');
    signal test_id_s  : integer := 0;

    constant BASE_PATH : string :=
        "C:/Users/giovi/OneDrive/Desktop/Magistrale/Tesi/TestingDPU_LNS16/vectors/";

begin

    uut : LNSAddSub_4_9
        port map (
            clk => clk_s,
            rst => rst_s,
            nA  => nA_s,
            nB  => nB_s,
            nR  => nR_s
        );

    clk_process : process
    begin
        clk_s <= '0';
        wait for 5 ns;
        clk_s <= '1';
        wait for 5 ns;
    end process;

    stim_proc : process

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

                wait for 120 ns;

                got_log := to_integer(signed(nR_s(12 downto 0)));
                exp_log := to_integer(signed(EXP_v(12 downto 0)));
                diff := got_log - exp_log;

                if diff < 0 then
                    diff := -diff;
                end if;

                assert (nR_s(15 downto 13) = EXP_v(15 downto 13)) and (diff <= TOL_v)
                   report "LNSAddSub vector failed. File = " & filename &
                        " Test ID = " & integer'image(id_v)
                    severity warning;
            end loop;

            file_close(vec_file);
        end procedure;

    begin

        rst_s <= '1';
        nA_s <= x"0000";
        nB_s <= x"0000";
        expected_s <= x"0000";
        test_id_s <= 0;

        wait for 30 ns;

        rst_s <= '0';

        wait for 30 ns;

        report "Running same-sign LNSAddSub vectors";
        run_vector_file(BASE_PATH & "LNSAddSub_same_sign_vectors.txt");

        report "Running opposite-sign basic LNSAddSub vectors";
        run_vector_file(BASE_PATH & "LNSAddSub_opposite_basic_vectors.txt");

        -- Keep random stress disabled for the moment.
        -- We will enable it after the structured files pass.
        -- report "Running random stress LNSAddSub vectors";
        -- run_vector_file(BASE_PATH & "LNSAddSub_random_stress_vectors.txt");

        assert false
            report "End of LNSAddSub vector-file simulation."
            severity failure;

    end process;

end architecture;
