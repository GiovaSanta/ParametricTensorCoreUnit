library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Multiplier_TB is
end Multiplier_TB; 

architecture Behavioral of Multiplier_TB is
    constant N : integer := 16;  -- 16-bit numbers

    signal A, B : STD_LOGIC_VECTOR(N-1 downto 0);
    signal P    : STD_LOGIC_VECTOR((2*N)-1 downto 0);

    component Multiplier
        Generic (
            N : integer := 16
        );
        Port (
            A : in  STD_LOGIC_VECTOR(N-1 downto 0);
            B : in  STD_LOGIC_VECTOR(N-1 downto 0);
            P : out STD_LOGIC_VECTOR((2*N)-1 downto 0)
        );
    end component;

begin
    -- Instantiate the Multiplier
    DUT: Multiplier
        generic map (N => 16)
        port map (A => A, B => B, P => P);
    
    -- Test process
    process
    begin
        -- Test Case 1: 5 * 10 = 50
        A <= std_logic_vector(to_signed(5, N));
        B <= std_logic_vector(to_signed(10, N));
        wait for 10 ns;

        -- Test Case 2: -3 * 7 = -21
        A <= std_logic_vector(to_signed(-3, N));
        B <= std_logic_vector(to_signed(7, N));
        wait for 10 ns;

        -- Test Case 3: -10 * -5 = 50
        A <= std_logic_vector(to_signed(-10, N));
        B <= std_logic_vector(to_signed(-5, N));
        wait for 10 ns;

        -- Test Case 4: 2^15 * 2 = 
        A <= std_logic_vector(to_signed(2**15, N));
        B <= std_logic_vector(to_signed(2, N));
        wait for 10 ns;
        
        -- Test Case 4: 32767 * 32767 = Overflow
        A <= std_logic_vector(to_signed(32767, N));
        B <= std_logic_vector(to_signed(32767, N));
        wait for 10 ns;
        -- End simulation
        wait;
    end process;
end Behavioral;
