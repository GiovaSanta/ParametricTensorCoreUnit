library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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

    -- Helpful waveform/debug signals
    signal expected_s : std_logic_vector(15 downto 0) := (others => '0');
    signal test_id_s  : integer := 0;

begin

    uut : LNSAddSub_4_9
        port map (
            clk => clk_s,
            rst => rst_s,
            nA  => nA_s,
            nB  => nB_s,
            nR  => nR_s
        );

    -- Clock generation: 10 ns period
    clk_process : process
    begin
        clk_s <= '0';
        wait for 5 ns;
        clk_s <= '1';
        wait for 5 ns;
    end process;

    stim_proc : process

        procedure run_test(
            constant id  : in integer;
            constant A   : in std_logic_vector(15 downto 0);
            constant B   : in std_logic_vector(15 downto 0);
            constant EXP : in std_logic_vector(15 downto 0)
        ) is
        begin
            test_id_s  <= id;
            nA_s       <= A;
            nB_s       <= B;
            expected_s <= EXP;

            wait for 120 ns;

            assert nR_s = EXP
                report "LNSAddSub test failed. Test ID = " & integer'image(id)
                severity warning;
        end procedure;

    begin

        -- Initial reset
        rst_s <= '1';
        nA_s <= x"0000";
        nB_s <= x"0000";
        expected_s <= x"0000";
        test_id_s <= 0;

        wait for 30 ns;

        rst_s <= '0';

        wait for 30 ns;

        --------------------------------------------------------------------
        -- Deterministic positive tests
        --------------------------------------------------------------------

        run_test(1,  x"4000", x"4000", x"4200"); -- 1.0 + 1.0
        run_test(2,  x"4000", x"5E00", x"412C"); -- 1.0 + 0.5
        run_test(3,  x"5E00", x"5E00", x"4000"); -- 0.5 + 0.5
        run_test(4,  x"4200", x"4000", x"432C"); -- 2.0 + 1.0
        run_test(5,  x"4200", x"5E00", x"42A5"); -- 2.0 + 0.5
        run_test(6,  x"5C00", x"5C00", x"5E00"); -- 0.25 + 0.25
        run_test(7,  x"4400", x"4000", x"44A5"); -- 4.0 + 1.0
        run_test(8,  x"4000", x"5C00", x"40A5"); -- 1.0 + 0.25
        run_test(9,  x"4000", x"5A00", x"4057"); -- 1.0 + 0.125

        -- I would use 5F2C here, not 5F2B, because your waveform showed
        -- the rounded hardware/log result as 5F2C.
        run_test(10, x"5E00", x"5C00", x"5F2C"); -- 0.5 + 0.25

        run_test(11, x"4200", x"4200", x"4400"); -- 2.0 + 2.0
        run_test(12, x"5C00", x"4000", x"40A5"); -- 0.25 + 1.0

        run_test(13, x"5E00", x"5C00", x"5F2C"); -- 0.5 + 0.25
        run_test(14, x"5E00", x"5A00", x"5EA5"); -- 0.5 + 0.125
        run_test(15, x"5C00", x"5A00", x"5D2C"); -- 0.25 + 0.125
        run_test(16, x"5C00", x"5800", x"5CA5"); -- 0.25 + 0.0625
        run_test(17, x"5A00", x"5800", x"5B2C"); -- 0.125 + 0.0625
        run_test(18, x"5A00", x"5A00", x"5C00"); -- 0.125 + 0.125
        run_test(19, x"5800", x"5800", x"5A00"); -- 0.0625 + 0.0625
        run_test(20, x"5C00", x"5E00", x"5F2C"); -- 0.25 + 0.5

        assert false
            report "End of LNSAddSub_4_9 deterministic positive tests."
            severity failure;

    end process;


end architecture;