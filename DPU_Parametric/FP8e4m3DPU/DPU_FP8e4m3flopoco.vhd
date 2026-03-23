library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DotProductUnitFP8e4m3 is
    Port (
        aX0 : in  std_logic_vector(7 downto 0);
        aX1 : in  std_logic_vector(7 downto 0);
        aX2 : in  std_logic_vector(7 downto 0);
        aX3 : in  std_logic_vector(7 downto 0);
        bY0 : in  std_logic_vector(7 downto 0);
        bY1 : in  std_logic_vector(7 downto 0);
        bY2 : in  std_logic_vector(7 downto 0);
        bY3 : in  std_logic_vector(7 downto 0);
        cX0 : in std_logic_vector(7 downto 0);
        R  : out std_logic_vector(7 downto 0)
    );
end DotProductUnitFP8e4m3;

architecture Behavioral of DotProductUnitFP8e4m3 is

    component IEEEFPFMA_4_3_comb_uid2 is
    port (A : in  std_logic_vector(7 downto 0);
          B : in  std_logic_vector(7 downto 0);
          C : in  std_logic_vector(7 downto 0);
          negateAB : in  std_logic;
          negateC : in  std_logic;
          RndMode : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(7 downto 0)   );
    end component;

    signal r0, r1, r2 : std_logic_vector(7 downto 0);

begin

    mac0: IEEEFPFMA_4_3_comb_uid2
        port map (A => aX0, B => bY0, C => cX0 , negateAB => '0' , negateC => '0' , RndMode => "00" , R => r0 ); 

    mac1: IEEEFPFMA_4_3_comb_uid2
        port map (A => aX1, B => bY1, C => r0 , negateAB => '0' , negateC => '0' , RndMode => "00" , R => r1 ); 

    mac2: IEEEFPFMA_4_3_comb_uid2
        port map (A => aX2, B => bY2, C => r1 , negateAB => '0' , negateC => '0' , RndMode => "00" , R => r2 ); 

    mac3: IEEEFPFMA_4_3_comb_uid2
        port map (A => aX3, B => bY3, C => r2 , negateAB => '0' , negateC => '0' , RndMode => "00" , R => R ); 


end Behavioral;
