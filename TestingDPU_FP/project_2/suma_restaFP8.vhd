----------------------------------------------------------------------------
-- Company:         	Politecnico di Torino
-- Engineer:          	Josie E. Rodriguez Condia, Giovanni Santangelo
--
-- Create Date:     		23/10/2022
-- Module Name:   	Floating point adder
-- Project Name:   	Open TCU
-- Target Devices:		
-- Tool versions:    	ModelSim
-- Description:
--
----------------------------------------------------------------------------
-- Revisions:
--  REV:        Date:          			Description:
--  1.0.a       	23/10/2022      	 	Created Top level file
----------------------------------------------------------------------------

-- operacion de suma y resta en flotante.

Library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use IEEE.numeric_bit.all;

--use IEEE.STD_LOGIC_ARITH.ALL;

entity adder_FP8 is 
	generic(
		long: natural := 8
	);
     
	port(
		operando1, operando2: in unsigned(long-1 downto 0);
		operacion: in unsigned(3 downto 0);
		resultado: out unsigned(long-1 downto 0)
	);
end adder_FP8;

architecture ar of adder_FP8 is
	
	component pruebaFP8 is
		Port ( 	FP_A : in  std_logic_vector (7 downto 0);
				FP_B : in  std_logic_vector (7 downto 0);
				add_sub: in std_logic;  			
				FP_Z : out  std_logic_vector (7 downto 0)
				);
	end component;

	begin

	P2: pruebaFP8 port map(
										FP_A =>STD_LOGIC_VECTOR(operando1),
										FP_B =>STD_LOGIC_VECTOR(operando2),
										add_sub =>operacion(0),  									-- Only adding operation is selected.
										unsigned(FP_Z) =>resultado 
									);
	end ar;

































