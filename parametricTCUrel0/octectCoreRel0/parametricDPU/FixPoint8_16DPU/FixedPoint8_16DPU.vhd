library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DotProductUnit_FixedPoint8_16 is
    Port (
        aX0 : in  std_logic_vector(7 downto 0);
        aX1 : in  std_logic_vector(7 downto 0);
        aX2 : in  std_logic_vector(7 downto 0);
        aX3 : in  std_logic_vector(7 downto 0);
        bY0 : in  std_logic_vector(7 downto 0);
        bY1 : in  std_logic_vector(7 downto 0);
        bY2 : in  std_logic_vector(7 downto 0);
        bY3 : in  std_logic_vector(7 downto 0);
        cX0 : in std_logic_vector(15 downto 0);
        R  : out std_logic_vector(15 downto 0)
    );
end DotProductUnit_FixedPoint8_16;

architecture Behavioral of DotProductUnit_FixedPoint8_16 is


    component FixMultAdd_signed_x_2_M5_y_2_M5_a_5_M10_r_5_M10_comb_uid2
        Port (
            X : in  std_logic_vector(7 downto 0);
            Y : in  std_logic_vector(7 downto 0);
            A : in  std_logic_vector(15 downto 0);
            R : out std_logic_vector(15 downto 0)
        );
    end component;

    signal  r0, r1, r2 : std_logic_vector(15 downto 0);

begin

    mac0: FixMultAdd_signed_x_2_M5_y_2_M5_a_5_M10_r_5_M10_comb_uid2
        port map (X => aX0, Y => bY0, A => cX0, R => r0); 
 
    mac1: FixMultAdd_signed_x_2_M5_y_2_M5_a_5_M10_r_5_M10_comb_uid2
        port map (X => aX1, Y => bY1, A => r0, R => r1);

    mac2: FixMultAdd_signed_x_2_M5_y_2_M5_a_5_M10_r_5_M10_comb_uid2
        port map (X => aX2, Y => bY2, A => r1, R => r2);

    mac3: FixMultAdd_signed_x_2_M5_y_2_M5_a_5_M10_r_5_M10_comb_uid2
        port map (X => aX3, Y => bY3, A => r2, R => R);

end Behavioral;
