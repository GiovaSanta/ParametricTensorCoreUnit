Library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package dpuArray_package is
		

		type arraySize4_8 is array(3 downto 0) of std_logic_vector(7 downto 0);
		type arraySize4_16 is array(3 downto 0) of std_logic_vector(15 downto 0) ;
		type arraySize4_32 is array(3 downto 0) of std_logic_vector(31 downto 0) ;
		type arraySize16_8 is array(15 downto 0) of std_logic_vector(7 downto 0);
		type arraySize16_16  is array(15 downto 0) of std_logic_vector(15 downto 0) ;
		type arraySize16_32 is array(15 downto 0) of std_logic_vector(31 downto 0) ;
		
		
end package;
