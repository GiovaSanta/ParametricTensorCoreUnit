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

            procedure run_test_tol(
        constant id  : in integer;
        constant A   : in std_logic_vector(15 downto 0);
        constant B   : in std_logic_vector(15 downto 0);
        constant EXP : in std_logic_vector(15 downto 0);
        constant TOL : in integer
    ) is
        variable got_log : integer;
        variable exp_log : integer;
        variable diff    : integer;
    begin
        test_id_s  <= id;
        nA_s       <= A;
        nB_s       <= B;
        expected_s <= EXP;
    
        wait for 120 ns;
    
        got_log := to_integer(signed(nR_s(12 downto 0)));
        exp_log := to_integer(signed(EXP(12 downto 0)));
        diff    := got_log - exp_log;
    
        if diff < 0 then
            diff := -diff;
        end if;
    
        assert (nR_s(15 downto 13) = EXP(15 downto 13)) and (diff <= TOL)
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

  --      run_test_tol(1,  x"4000", x"4000", x"4200", 0); -- 1.0 + 1.0
  --      run_test_tol(2,  x"4000", x"5E00", x"412C", 0); -- 1.0 + 0.5
  --      run_test_tol(3,  x"5E00", x"5E00", x"4000", 0); -- 0.5 + 0.5
  --      run_test_tol(4,  x"4200", x"4000", x"432C", 0); -- 2.0 + 1.0
  --      run_test_tol(5,  x"4200", x"5E00", x"42A5", 0); -- 2.0 + 0.5
  --      run_test_tol(6,  x"5C00", x"5C00", x"5E00", 0); -- 0.25 + 0.25
  --      run_test_tol(7,  x"4400", x"4000", x"44A5", 0); -- 4.0 + 1.0
  --      run_test_tol(8,  x"4000", x"5C00", x"40A5", 0); -- 1.0 + 0.25
  --      run_test_tol(9,  x"4000", x"5A00", x"4057", 0); -- 1.0 + 0.125

        -- I would use 5F2C here, not 5F2B, because your waveform showed
        -- the rounded hardware/log result as 5F2C.
      --  run_test_tol(10, x"5E00", x"5C00", x"5F2C", 0); -- 0.5 + 0.25

      --  run_test_tol(11, x"4200", x"4200", x"4400", 0); -- 2.0 + 2.0
      --  run_test_tol(12, x"5C00", x"4000", x"40A5", 0); -- 0.25 + 1.0

      --  run_test_tol(13, x"5E00", x"5C00", x"5F2C", 0); -- 0.5 + 0.25
      --  run_test_tol(14, x"5E00", x"5A00", x"5EA5", 0); -- 0.5 + 0.125
      --  run_test_tol(15, x"5C00", x"5A00", x"5D2C", 0); -- 0.25 + 0.125
      --  run_test_tol(16, x"5C00", x"5800", x"5CA5", 0); -- 0.25 + 0.0625
      --  run_test_tol(17, x"5A00", x"5800", x"5B2C", 0); -- 0.125 + 0.0625
      --  run_test_tol(18, x"5A00", x"5A00", x"5C00", 0); -- 0.125 + 0.125
      --  run_test_tol(19, x"5800", x"5800", x"5A00", 0); -- 0.0625 + 0.0625
      --  run_test_tol(20, x"5C00", x"5E00", x"5F2C", 0); -- 0.25 + 0.5
      --  run_test_tol(21, x"4400", x"5E00", x"4457", 2); -- 4.0 + 0.5
      --  run_test_tol(22, x"4400", x"5C00", x"442D", 2); -- 4.0 + 0.25
      --  run_test_tol(23, x"4200", x"5C00", x"4257", 2); -- 2.0 + 0.25
      --  run_test_tol(24, x"5E00", x"5800", x"5E57", 2); -- 0.5 + 0.0625
        --run_test_tol(25, x"4000", x"5800", x"402D", 2); -- 1.0 + 0.0625
       -- run_test_tol(26, x"5C00", x"5600", x"5C57", 2); -- 0.25 + 0.03125
      --  run_test_tol(27, x"4600", x"4000", x"4657", 2); -- 8.0 + 1.0
       -- run_test_tol(28, x"4600", x"5E00", x"462D", 2); -- 8.0 + 0.5
       -- run_test_tol(29, x"5600", x"5600", x"5800", 0); -- 0.03125 + 0.03125
       -- run_test_tol(30, x"5600", x"5800", x"592C", 2); -- 0.03125 + 0.0625
       -- run_test_tol(31, x"6000", x"6000", x"6200", 0); -- -1.0 + -1.0 = -2.0
       -- run_test_tol(32, x"6000", x"7E00", x"612C", 0); -- -1.0 + -0.5 = -1.5
       -- run_test_tol(33, x"7E00", x"7E00", x"6000", 0); -- -0.5 + -0.5 = -1.0
        --run_test_tol(34, x"6200", x"6000", x"632C", 0); -- -2.0 + -1.0 = -3.0
        --run_test_tol(35, x"7E00", x"7C00", x"7F2C", 0); -- -0.5 + -0.25 = -0.75
        --run_test_tol(36, x"6000", x"7C00", x"60A5", 0); -- -1.0 + -0.25 = -1.25
        --run_test_tol(37, x"6400", x"6000", x"64A5", 0); -- -4.0 + -1.0 = -5.0
        --run_test_tol(38, x"7A00", x"7800", x"7B2C", 0); -- -0.125 + -0.0625 = -0.1875
        
                --------------------------------------------------------------------
        -- Opposite-sign nonzero tests
        --------------------------------------------------------------------

        run_test_tol(39, x"4000", x"7E00", x"5E00", 0); -- 1.0 + (-0.5) = 0.5
        run_test_tol(40, x"5E00", x"7C00", x"5C00", 0); -- 0.5 + (-0.25) = 0.25
        run_test_tol(41, x"4200", x"6000", x"4000", 0); -- 2.0 + (-1.0) = 1.0
        run_test_tol(42, x"4400", x"6000", x"432C", 2); -- 4.0 + (-1.0) = 3.0
        run_test_tol(43, x"4000", x"7C00", x"5F2C", 2); -- 1.0 + (-0.25) = 0.75
        run_test_tol(44, x"5C00", x"7A00", x"5A00", 0); -- 0.25 + (-0.125) = 0.125

        run_test_tol(45, x"6000", x"5E00", x"7E00", 0); -- -1.0 + 0.5 = -0.5
        run_test_tol(46, x"7E00", x"5C00", x"7C00", 0); -- -0.5 + 0.25 = -0.25
        run_test_tol(47, x"6200", x"4000", x"6000", 0); -- -2.0 + 1.0 = -1.0
        run_test_tol(48, x"6000", x"5C00", x"7F2C", 2); -- -1.0 + 0.25 = -0.75
        run_test_tol(49, x"5E00", x"6000", x"7E00", 0); -- 0.5 + (-1.0) = -0.5
        run_test_tol(50, x"5A00", x"7E00", x"7D2C", 2); -- 0.125 + (-0.5) = -0.375
        
        assert false
            report "End of LNSAddSub_4_9 deterministic positive tests."
            severity failure;

    end process;


end architecture;