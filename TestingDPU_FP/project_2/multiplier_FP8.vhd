----------------------------------------------------------------------------
-- Company:         	Politecnico di Torino
-- Engineer:          	Giovanni Santangelo
--
-- Create Date:     		23/10/2022
-- Module Name:   	Floating point multiplier (Ripple Carry)
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

--tested format has mantissa for this multiplier with 3 bits
--tested format has exponent field of 4 bits
--tested format has sign bit field of 1 bit 

Library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multiplier_FP8 is 
port(
	entrada_x, entrada_y: in std_logic_vector(7 downto 0);		
	salida: out std_logic_vector(7 downto 0);
	underflow, overflow :out std_logic
	);
end multiplier_FP8;

architecture ar of multiplier_FP8 is

	type desplazar is array(0 to 7) of std_logic_vector(7 downto 0);
	signal mantisa_finalex :desplazar := (others=>(others=>'0'));
	signal mantisa1_n,mantisa2_n :std_logic_vector(3 downto 0);
	signal mantisa_final :std_logic_vector(7 downto 0);
	signal mantisa_real :std_logic_vector(2 downto 0);
	signal resultado :std_logic_vector(7 downto 0);
	signal exponente_final :std_logic_vector(5 downto 0) := ( others => '0');
	signal exponentex,exponentey :std_logic_vector(5 downto 0);
	signal sunderflow, soverflow :std_logic;

begin
	
	-- Se suman exponentes:
	--exponente_final(7 downto 0) contiene el exponente listo.
	mantisa1_n <= '1' & entrada_x(2 downto 0);				-- inclusion de 1 en el bit mas significativo para multiplicacion. 
	mantisa2_n <= '1' & entrada_y(2 downto 0);	
	exponentex <= "00" & entrada_x(6 downto 3);   
	exponentey <= "00" & entrada_y(6 downto 3);				
	-- operacion sobre la mantisa.		
	mantisa_final<=std_logic_vector(unsigned(mantisa1_n)*unsigned(mantisa2_n));

	process(entrada_x,entrada_y,resultado,sunderflow,soverflow)	

	begin
	
		if unsigned(entrada_x) = X"00" or unsigned(entrada_y) = X"00" or unsigned(entrada_x) = X"80" or unsigned(entrada_y) = X"80"  then -- no se realiza la operacion, uno de los operandos es cero por lo tanto la respuesta es cero.
			salida <= (others=>'0');
			underflow <='0';
			overflow <= '0';
		else 						-- se realiza la operacion.
			underflow<=sunderflow;
			overflow<= soverflow;
			salida <= resultado;
			salida(7)<= (entrada_x(7) xor entrada_y(7));  -- asignacion de signo al resultado.
		end if;
	end process;	


	process(mantisa_final,exponentex,exponentey)
	
	begin
	
		if(mantisa_final(7)='1') then
			exponente_final <= std_logic_vector((unsigned(exponentex) + unsigned(exponentey)) - 6);	
		else
			exponente_final <= std_logic_vector((unsigned(exponentex) + unsigned(exponentey)) - 7);
		end if;
	end process;

	process(exponente_final,mantisa_real)
	
	begin
	
		if signed(exponente_final) > 15 then			-- finaliza la operacion si hay overflow.
			soverflow<='1'; 
			sunderflow<='0';
			resultado <= "01111000"; --modificato io (gio) se segnalo overflow, metto risultato a inf rapresentation (0x78), prima lo metteva a 0
		elsif 	signed(exponente_final) < 0 then 		-- finaliza la operacion si hay underflow.
			sunderflow<='1';
			soverflow<='0'; 
			resultado <= (others=>'0');
	   elsif signed(exponente_final) = 0 then 		-- condition added by me (Gio) which wasnt in the original fp32 multiplier where this implementation was inspired from...
			sunderflow<='1';
			soverflow<='0';
			resultado <= (others=>'0'); 
		else 											-- continue con la operacion.		
			sunderflow<='0';
			soverflow<='0';
			-- asignacion final del resultado.
			resultado(2 downto 0) <= mantisa_real;		-- Mantisa.
			resultado(6 downto 3) <= exponente_final(3 downto 0);	-- Exponente.
		end if;
	end process;

	mantisa_finalex(7) <= mantisa_final;

	NX:for i in 6 downto 0 generate
		mantisa_finalex(i) <= mantisa_finalex(i+1)(6 downto 0) & '0';
	end generate;

	process(mantisa_final,mantisa_finalex)
		
		variable var :integer;
	
	begin
		
		var:=0;
		for i in 0 to 7 loop
			if(mantisa_final(i)='1') then
				var:=i;
			end if;
		end loop;
		mantisa_real <= mantisa_finalex(var)(6 downto 4);
	end process;

end ar;
