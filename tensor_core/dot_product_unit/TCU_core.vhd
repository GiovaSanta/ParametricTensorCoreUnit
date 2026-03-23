----------------------------------------------------------------------------
-- Company:         	Politecnico di Torino
-- Engineer:          	Josie E. Rodriguez Condia
--
-- Create Date:     		07/04/2023
-- Module Name:   	TCU Unit
-- Project Name:   	Open TCU
-- Target Devices:		
-- Tool versions:    	ModelSim
-- Description:
--
----------------------------------------------------------------------------
-- Revisions:
--  REV:        Date:          			Description:
--  1.0.a       	07/04/2023      	 	Created Top level file
----------------------------------------------------------------------------

-- The TCU_unit process the vectorial x2 4X4 matrix multiplication
--



Library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.def_package.all;

entity TCU_core is
	
	generic(
				size_sub_tensor: natural:= 2;
				long : natural := 32
				);

	port(
			TC0_A_0X: in  operand_array(2**size_sub_tensor - 1 downto 0);			-- A_0X <= (0 => bus0, 1 => bus1, 2 => bus2, 3 => bus3);
			TC0_A_1X: in  operand_array(2**size_sub_tensor - 1 downto 0);
			TC0_A_2X: in  operand_array(2**size_sub_tensor - 1 downto 0);
			TC0_A_3X: in  operand_array(2**size_sub_tensor - 1 downto 0);

			TC1_A_0X: in  operand_array(2**size_sub_tensor - 1 downto 0);
			TC1_A_1X: in  operand_array(2**size_sub_tensor - 1 downto 0);
			TC1_A_2X: in  operand_array(2**size_sub_tensor - 1 downto 0);
			TC1_A_3X: in  operand_array(2**size_sub_tensor - 1 downto 0);
			
			TC0_B_0X: in  operand_array(2**size_sub_tensor - 1 downto 0);
			TC0_B_1X: in  operand_array(2**size_sub_tensor - 1 downto 0);
			TC0_B_2X: in  operand_array(2**size_sub_tensor - 1 downto 0);
			TC0_B_3X: in  operand_array(2**size_sub_tensor - 1 downto 0);

			TC1_B_0X: in  operand_array(2**size_sub_tensor - 1 downto 0);
			TC1_B_1X: in  operand_array(2**size_sub_tensor - 1 downto 0);
			TC1_B_2X: in  operand_array(2**size_sub_tensor - 1 downto 0);
			TC1_B_3X: in  operand_array(2**size_sub_tensor - 1 downto 0);

			TC0_C_0X: in  operand_array(2**size_sub_tensor - 1 downto 0);
			TC0_C_1X: in  operand_array(2**size_sub_tensor - 1 downto 0);
			TC0_C_2X: in  operand_array(2**size_sub_tensor - 1 downto 0);
			TC0_C_3X: in  operand_array(2**size_sub_tensor - 1 downto 0);

			TC1_C_0X: in  operand_array(2**size_sub_tensor - 1 downto 0);
			TC1_C_1X: in  operand_array(2**size_sub_tensor - 1 downto 0);
			TC1_C_2X: in  operand_array(2**size_sub_tensor - 1 downto 0);
			TC1_C_3X: in  operand_array(2**size_sub_tensor - 1 downto 0);

			TC0_W_0X3: out operand_array(2**size_sub_tensor - 1 downto 0);
			TC0_W_1X3: out operand_array(2**size_sub_tensor - 1 downto 0);
			TC0_W_2X3: out operand_array(2**size_sub_tensor - 1 downto 0);
			TC0_W_3X3: out operand_array(2**size_sub_tensor - 1 downto 0);

			TC1_W_0X3: out operand_array(2**size_sub_tensor - 1 downto 0);
			TC1_W_1X3: out operand_array(2**size_sub_tensor - 1 downto 0);
			TC1_W_2X3: out operand_array(2**size_sub_tensor - 1 downto 0);
			TC1_W_3X3: out operand_array(2**size_sub_tensor - 1 downto 0);

			underflow, overflow :out std_logic
	);
end TCU_core;



architecture ar of TCU_core is

	-- Signals for the interconnection of the cores:

	signal TC0_underflow_s :std_logic;
	signal TC0_overflow_s :std_logic;
	signal TC1_underflow_s :std_logic;		
	signal TC1_overflow_s :std_logic;

	-- remember to include the generic port to allow the size definition...

component sub_tensor_core is
	
	generic(
				size: natural:= 2;
				long : natural := 32
				);

	port(
				A_0X: in  operand_array(2**size - 1 downto 0);			-- A_0X <= (0 => bus0, 1 => bus1, 2 => bus2, 3 => bus3);
				A_1X: in  operand_array(2**size - 1 downto 0);
				A_2X: in  operand_array(2**size - 1 downto 0);
				A_3X: in  operand_array(2**size - 1 downto 0);
				B_0X: in  operand_array(2**size - 1 downto 0);
				B_1X: in  operand_array(2**size - 1 downto 0);
				B_2X: in  operand_array(2**size - 1 downto 0);
				B_3X: in  operand_array(2**size - 1 downto 0);
				C_0X: in  operand_array(2**size - 1 downto 0);
				C_1X: in  operand_array(2**size - 1 downto 0);
				C_2X: in  operand_array(2**size - 1 downto 0);
				C_3X: in operand_array(2**size - 1 downto 0);
				W_0X3: out operand_array(2**size - 1 downto 0);
				W_1X3: out operand_array(2**size - 1 downto 0);
				W_2X3: out operand_array(2**size - 1 downto 0);
				W_3X3: out operand_array(2**size - 1 downto 0);
				underflow, overflow :out std_logic
	);
end component;

	begin

	-- description of the TC0 and TC1 cores...
	-- 

	TC0: sub_tensor_core generic map(
											size => size_sub_tensor,
											long => long
									)
							port map(
											A_0X => TC0_A_0X, 
											A_1X => TC0_A_1X,
											A_2X => TC0_A_2X,
											A_3X => TC0_A_3X,
											B_0X => TC0_B_0X,
											B_1X => TC0_B_1X,
											B_2X => TC0_B_2X,
											B_3X => TC0_B_3X,
											C_0X => TC0_C_0X,
											C_1X => TC0_C_1X,
											C_2X => TC0_C_2X,
											C_3X => TC0_C_3X,
											W_0X3 => TC0_W_0X3,
											W_1X3 => TC0_W_1X3,
											W_2X3 => TC0_W_2X3,
											W_3X3 => TC0_W_3X3,
											underflow => TC0_underflow_s,
											overflow => TC0_overflow_s
									);

	TC1: sub_tensor_core generic map(
											size => size_sub_tensor,
											long => long
									)
							port map(
											A_0X => TC1_A_0X, 
											A_1X => TC1_A_1X,
											A_2X => TC1_A_2X,
											A_3X => TC1_A_3X,
											B_0X => TC1_B_0X,
											B_1X => TC1_B_1X,
											B_2X => TC1_B_2X,
											B_3X => TC1_B_3X,
											C_0X => TC1_C_0X,
											C_1X => TC1_C_1X,
											C_2X => TC1_C_2X,
											C_3X => TC1_C_3X,
											W_0X3 => TC1_W_0X3,
											W_1X3 => TC1_W_1X3,
											W_2X3 => TC1_W_2X3,
											W_3X3 => TC1_W_3X3,
											underflow => TC1_underflow_s,
											overflow => TC1_overflow_s
									);

	underflow <= ( TC0_underflow_s or TC1_underflow_s );
	overflow  <= ( TC0_overflow_s  or TC1_overflow_s );


end ar;
