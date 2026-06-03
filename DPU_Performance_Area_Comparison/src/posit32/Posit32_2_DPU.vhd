library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DotProductUnitPosit32 is
    Port (
        aX0 : in  std_logic_vector(31 downto 0);
        aX1 : in  std_logic_vector(31 downto 0);
        aX2 : in  std_logic_vector(31 downto 0);
        aX3 : in  std_logic_vector(31 downto 0);
        bY0 : in  std_logic_vector(31 downto 0);
        bY1 : in  std_logic_vector(31 downto 0);
        bY2 : in  std_logic_vector(31 downto 0);
        bY3 : in  std_logic_vector(31 downto 0);
        cX0 : in  std_logic_vector(31 downto 0);
        R  : out std_logic_vector(31 downto 0)
    );
end DotProductUnitPosit32;

architecture Behavioral of DotProductUnitPosit32 is

    -- Signals for the interconnection of the cores:
	signal a_X0_b_X0_s :std_logic_vector(31 downto 0);
	signal a_X1_b_X1_s :std_logic_vector(31 downto 0);
	signal a_X2_b_X2_s :std_logic_vector(31 downto 0);
	signal a_X3_b_X3_s :std_logic_vector(31 downto 0);
	signal c_XX_s :std_logic_vector(31 downto 0);

	signal a_X0_b_X0_plus_a_X1_b_X1_s: std_logic_vector(31 downto 0);
	signal a_X2_b_X2_plus_a_X3_b_X3_s: std_logic_vector(31 downto 0);
	signal a_plus_b_s: std_logic_vector(31 downto 0);
	signal w_XX3_s: std_logic_vector(31 downto 0);
	
    component PositMult_32_2_F0_uid2
        Port (X : in  std_logic_vector(31 downto 0);
              Y : in  std_logic_vector(31 downto 0);
              R : out  std_logic_vector(31 downto 0)
        );
    end component;
    
    component PositAdd2_32_2_F0_uid2
        port (X : in  std_logic_vector(31 downto 0);
              Y : in  std_logic_vector(31 downto 0);
              R : out  std_logic_vector(31 downto 0)
         );
    end component;

begin

    c_XX_s <= cX0;

    posit16_mul0: PositMult_32_2_F0_uid2
        port map (X => aX0, Y => bY0, R => a_X0_b_X0_s); 

    posit16_mul1: PositMult_32_2_F0_uid2
        port map (X => aX1, Y => bY1, R => a_X1_b_X1_s);

    posit16_mul2: PositMult_32_2_F0_uid2
        port map (X => aX2, Y => bY2, R => a_X2_b_X2_s );

    posit16_mul3: PositMult_32_2_F0_uid2
        port map (X => aX3, Y => bY3, R => a_X3_b_X3_s );
        
    posit16_add0: PositAdd2_32_2_F0_uid2
        port map (X => a_X0_b_X0_s, Y => a_X1_b_X1_s, R => a_X0_b_X0_plus_a_X1_b_X1_s); 

    posit16_add1: PositAdd2_32_2_F0_uid2
        port map (X => a_X2_b_X2_s, Y => a_X3_b_X3_s, R => a_X2_b_X2_plus_a_X3_b_X3_s) ;
    
    posit16_add2: PositAdd2_32_2_F0_uid2
        port map (X => a_X0_b_X0_plus_a_X1_b_X1_s , Y=> a_X2_b_X2_plus_a_X3_b_X3_s, R=> a_plus_b_s ) ;
        
    posit16_add3: PositAdd2_32_2_F0_uid2
        port map (X => a_plus_b_s , Y => c_XX_s, R => w_XX3_s ) ;
     
     R <= w_XX3_s;
       
end Behavioral;
