library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Adder_TB is
end Adder_TB;

architecture Behavioral of Adder_TB is
    constant N : integer := 16;
    
    signal A, B : STD_LOGIC_VECTOR(N-1 downto 0);
    signal SUM : STD_LOGIC_VECTOR(N-1 downto 0);

    component Adder
        Generic (N : integer := 16);
        Port (
            A   : in  STD_LOGIC_VECTOR(N-1 downto 0);
            B   : in  STD_LOGIC_VECTOR(N-1 downto 0);
            SUM : out STD_LOGIC_VECTOR(N-1 downto 0)
        );
    end component;
    
begin
    -- Instantiate the Adder
    DUT: Adder
        generic map (N => 16)
        port map (A => A, B => B, SUM => SUM);
    
    -- Test process
    process
    begin
        -- Test Case 1: 5 + 10 = 15
        A <= std_logic_vector(to_signed(5, N));
        B <= std_logic_vector(to_signed(10, N));
        wait for 10 ns;

        -- Test Case 2: -20 + 15 = -5
        A <= std_logic_vector(to_signed(-20, N));
        B <= std_logic_vector(to_signed(15, N));
        wait for 10 ns;

        -- Test Case 3: 2^30 + 2^30 (overflow case)
        A <= std_logic_vector(to_signed(2**30, N));
        B <= std_logic_vector(to_signed(2**30, N));
        wait for 10 ns;

        -- Test Case 4: -2^31 + (-2^31) (underflow case)
        A <= std_logic_vector(to_signed(-2**31, N));
        B <= std_logic_vector(to_signed(-2**31, N));
        wait for 10 ns;

        -- End simulation
        wait;
    end process;
end Behavioral;
