library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Multiplier is
    Generic (
        N : integer := 16  -- Bit-width of input integers
    );
    Port (
        A     : in  STD_LOGIC_VECTOR(N-1 downto 0);  -- Multiplier
        B     : in  STD_LOGIC_VECTOR(N-1 downto 0);  -- Multiplicand
        P     : out STD_LOGIC_VECTOR( (2*N)-1 downto 0)  -- Product (2N-bit result)
    );
end Multiplier;

architecture Behavioral of Multiplier is
    signal product_internal : signed( (2*N)-1 downto 0);  -- Internal signed multiplication
begin
    process(A, B)
    begin
        product_internal <=  signed(A) * signed(B) ;  -- Multiply signed integers
    end process;

    P <= std_logic_vector(product_internal);  -- Convert result to std_logic_vector


end Behavioral;
