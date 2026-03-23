--------------------------------------------------------------------------------
--                            MultTable_comb_uid7
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Florent de Dinechin, Bogdan Pasca (2007-2022)
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X
-- Output signals: Y

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity MultTable_comb_uid7 is
    port (X : in  std_logic_vector(3 downto 0);
          Y : out  std_logic_vector(3 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid7 is
signal Y0 :  std_logic_vector(3 downto 0);
attribute ram_extract: string;
attribute ram_style: string;
attribute ram_extract of Y0: signal is "yes";
attribute ram_style of Y0: signal is "distributed";
signal Y1 :  std_logic_vector(3 downto 0);
begin
   with X  select  Y0 <= 
      "0000" when "0000",
      "0000" when "0001",
      "0000" when "0010",
      "0000" when "0011",
      "0000" when "0100",
      "0001" when "0101",
      "1110" when "0110",
      "1111" when "0111",
      "0000" when "1000",
      "1110" when "1001",
      "0100" when "1010",
      "0010" when "1011",
      "0000" when "1100",
      "1111" when "1101",
      "0010" when "1110",
      "0001" when "1111",
      "----" when others;
   Y1 <= Y0; -- for the possible blockram register
   Y <= Y1;
end architecture;

--------------------------------------------------------------------------------
--                            MultTable_comb_uid11
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Florent de Dinechin, Bogdan Pasca (2007-2022)
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X
-- Output signals: Y

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity MultTable_comb_uid11 is
    port (X : in  std_logic_vector(4 downto 0);
          Y : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid11 is
signal Y0 :  std_logic_vector(4 downto 0);
attribute ram_extract: string;
attribute ram_style: string;
attribute ram_extract of Y0: signal is "yes";
attribute ram_style of Y0: signal is "distributed";
signal Y1 :  std_logic_vector(4 downto 0);
begin
   with X  select  Y0 <= 
      "00000" when "00000",
      "00000" when "00001",
      "00000" when "00010",
      "00000" when "00011",
      "00000" when "00100",
      "00000" when "00101",
      "00000" when "00110",
      "00000" when "00111",
      "00000" when "01000",
      "00001" when "01001",
      "00010" when "01010",
      "00011" when "01011",
      "00100" when "01100",
      "00101" when "01101",
      "00110" when "01110",
      "00111" when "01111",
      "00000" when "10000",
      "11110" when "10001",
      "11100" when "10010",
      "11010" when "10011",
      "11000" when "10100",
      "10110" when "10101",
      "10100" when "10110",
      "10010" when "10111",
      "00000" when "11000",
      "11111" when "11001",
      "11110" when "11010",
      "11101" when "11011",
      "11100" when "11100",
      "11011" when "11101",
      "11010" when "11110",
      "11001" when "11111",
      "-----" when others;
   Y1 <= Y0; -- for the possible blockram register
   Y <= Y1;
end architecture;

--------------------------------------------------------------------------------
--                            MultTable_comb_uid15
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Florent de Dinechin, Bogdan Pasca (2007-2022)
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X
-- Output signals: Y

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity MultTable_comb_uid15 is
    port (X : in  std_logic_vector(4 downto 0);
          Y : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid15 is
signal Y0 :  std_logic_vector(4 downto 0);
attribute ram_extract: string;
attribute ram_style: string;
attribute ram_extract of Y0: signal is "yes";
attribute ram_style of Y0: signal is "distributed";
signal Y1 :  std_logic_vector(4 downto 0);
begin
   with X  select  Y0 <= 
      "00000" when "00000",
      "00000" when "00001",
      "00000" when "00010",
      "00000" when "00011",
      "00000" when "00100",
      "00000" when "00101",
      "00000" when "00110",
      "00000" when "00111",
      "00000" when "01000",
      "00001" when "01001",
      "00010" when "01010",
      "00011" when "01011",
      "00100" when "01100",
      "00101" when "01101",
      "00110" when "01110",
      "00111" when "01111",
      "00000" when "10000",
      "11110" when "10001",
      "11100" when "10010",
      "11010" when "10011",
      "11000" when "10100",
      "10110" when "10101",
      "10100" when "10110",
      "10010" when "10111",
      "00000" when "11000",
      "11111" when "11001",
      "11110" when "11010",
      "11101" when "11011",
      "11100" when "11100",
      "11011" when "11101",
      "11010" when "11110",
      "11001" when "11111",
      "-----" when others;
   Y1 <= Y0; -- for the possible blockram register
   Y <= Y1;
end architecture;

--------------------------------------------------------------------------------
--                            MultTable_comb_uid19
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Florent de Dinechin, Bogdan Pasca (2007-2022)
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X
-- Output signals: Y

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity MultTable_comb_uid19 is
    port (X : in  std_logic_vector(3 downto 0);
          Y : out  std_logic_vector(3 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid19 is
signal Y0 :  std_logic_vector(3 downto 0);
attribute ram_extract: string;
attribute ram_style: string;
attribute ram_extract of Y0: signal is "yes";
attribute ram_style of Y0: signal is "distributed";
signal Y1 :  std_logic_vector(3 downto 0);
begin
   with X  select  Y0 <= 
      "0000" when "0000",
      "0000" when "0001",
      "0000" when "0010",
      "0000" when "0011",
      "0000" when "0100",
      "0001" when "0101",
      "1110" when "0110",
      "1111" when "0111",
      "0000" when "1000",
      "0010" when "1001",
      "1100" when "1010",
      "1110" when "1011",
      "0000" when "1100",
      "0011" when "1101",
      "1010" when "1110",
      "1101" when "1111",
      "----" when others;
   Y1 <= Y0; -- for the possible blockram register
   Y <= Y1;
end architecture;

--------------------------------------------------------------------------------
--                            MultTable_comb_uid23
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Florent de Dinechin, Bogdan Pasca (2007-2022)
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X
-- Output signals: Y

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity MultTable_comb_uid23 is
    port (X : in  std_logic_vector(4 downto 0);
          Y : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid23 is
signal Y0 :  std_logic_vector(4 downto 0);
attribute ram_extract: string;
attribute ram_style: string;
attribute ram_extract of Y0: signal is "yes";
attribute ram_style of Y0: signal is "distributed";
signal Y1 :  std_logic_vector(4 downto 0);
begin
   with X  select  Y0 <= 
      "00000" when "00000",
      "00000" when "00001",
      "00000" when "00010",
      "00000" when "00011",
      "00000" when "00100",
      "00000" when "00101",
      "00000" when "00110",
      "00000" when "00111",
      "00000" when "01000",
      "00001" when "01001",
      "00010" when "01010",
      "00011" when "01011",
      "00100" when "01100",
      "00101" when "01101",
      "00110" when "01110",
      "00111" when "01111",
      "00000" when "10000",
      "00010" when "10001",
      "00100" when "10010",
      "00110" when "10011",
      "01000" when "10100",
      "01010" when "10101",
      "01100" when "10110",
      "01110" when "10111",
      "00000" when "11000",
      "00011" when "11001",
      "00110" when "11010",
      "01001" when "11011",
      "01100" when "11100",
      "01111" when "11101",
      "10010" when "11110",
      "10101" when "11111",
      "-----" when others;
   Y1 <= Y0; -- for the possible blockram register
   Y <= Y1;
end architecture;

--------------------------------------------------------------------------------
--                            MultTable_comb_uid27
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Florent de Dinechin, Bogdan Pasca (2007-2022)
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X
-- Output signals: Y

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity MultTable_comb_uid27 is
    port (X : in  std_logic_vector(4 downto 0);
          Y : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid27 is
signal Y0 :  std_logic_vector(4 downto 0);
attribute ram_extract: string;
attribute ram_style: string;
attribute ram_extract of Y0: signal is "yes";
attribute ram_style of Y0: signal is "distributed";
signal Y1 :  std_logic_vector(4 downto 0);
begin
   with X  select  Y0 <= 
      "00000" when "00000",
      "00000" when "00001",
      "00000" when "00010",
      "00000" when "00011",
      "00000" when "00100",
      "00000" when "00101",
      "00000" when "00110",
      "00000" when "00111",
      "00000" when "01000",
      "00001" when "01001",
      "00010" when "01010",
      "00011" when "01011",
      "00100" when "01100",
      "00101" when "01101",
      "00110" when "01110",
      "00111" when "01111",
      "00000" when "10000",
      "00010" when "10001",
      "00100" when "10010",
      "00110" when "10011",
      "01000" when "10100",
      "01010" when "10101",
      "01100" when "10110",
      "01110" when "10111",
      "00000" when "11000",
      "00011" when "11001",
      "00110" when "11010",
      "01001" when "11011",
      "01100" when "11100",
      "01111" when "11101",
      "10010" when "11110",
      "10101" when "11111",
      "-----" when others;
   Y1 <= Y0; -- for the possible blockram register
   Y <= Y1;
end architecture;

--------------------------------------------------------------------------------
--                            MultTable_comb_uid31
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Florent de Dinechin, Bogdan Pasca (2007-2022)
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X
-- Output signals: Y

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity MultTable_comb_uid31 is
    port (X : in  std_logic_vector(3 downto 0);
          Y : out  std_logic_vector(3 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid31 is
signal Y0 :  std_logic_vector(3 downto 0);
attribute ram_extract: string;
attribute ram_style: string;
attribute ram_extract of Y0: signal is "yes";
attribute ram_style of Y0: signal is "distributed";
signal Y1 :  std_logic_vector(3 downto 0);
begin
   with X  select  Y0 <= 
      "0000" when "0000",
      "0000" when "0001",
      "0000" when "0010",
      "0000" when "0011",
      "0000" when "0100",
      "0001" when "0101",
      "1110" when "0110",
      "1111" when "0111",
      "0000" when "1000",
      "0010" when "1001",
      "1100" when "1010",
      "1110" when "1011",
      "0000" when "1100",
      "0011" when "1101",
      "1010" when "1110",
      "1101" when "1111",
      "----" when others;
   Y1 <= Y0; -- for the possible blockram register
   Y <= Y1;
end architecture;

--------------------------------------------------------------------------------
--                            MultTable_comb_uid35
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Florent de Dinechin, Bogdan Pasca (2007-2022)
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X
-- Output signals: Y

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity MultTable_comb_uid35 is
    port (X : in  std_logic_vector(4 downto 0);
          Y : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid35 is
signal Y0 :  std_logic_vector(4 downto 0);
attribute ram_extract: string;
attribute ram_style: string;
attribute ram_extract of Y0: signal is "yes";
attribute ram_style of Y0: signal is "distributed";
signal Y1 :  std_logic_vector(4 downto 0);
begin
   with X  select  Y0 <= 
      "00000" when "00000",
      "00000" when "00001",
      "00000" when "00010",
      "00000" when "00011",
      "00000" when "00100",
      "00000" when "00101",
      "00000" when "00110",
      "00000" when "00111",
      "00000" when "01000",
      "00001" when "01001",
      "00010" when "01010",
      "00011" when "01011",
      "00100" when "01100",
      "00101" when "01101",
      "00110" when "01110",
      "00111" when "01111",
      "00000" when "10000",
      "00010" when "10001",
      "00100" when "10010",
      "00110" when "10011",
      "01000" when "10100",
      "01010" when "10101",
      "01100" when "10110",
      "01110" when "10111",
      "00000" when "11000",
      "00011" when "11001",
      "00110" when "11010",
      "01001" when "11011",
      "01100" when "11100",
      "01111" when "11101",
      "10010" when "11110",
      "10101" when "11111",
      "-----" when others;
   Y1 <= Y0; -- for the possible blockram register
   Y <= Y1;
end architecture;

--------------------------------------------------------------------------------
--                            MultTable_comb_uid39
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Florent de Dinechin, Bogdan Pasca (2007-2022)
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X
-- Output signals: Y

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity MultTable_comb_uid39 is
    port (X : in  std_logic_vector(4 downto 0);
          Y : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid39 is
signal Y0 :  std_logic_vector(4 downto 0);
attribute ram_extract: string;
attribute ram_style: string;
attribute ram_extract of Y0: signal is "yes";
attribute ram_style of Y0: signal is "distributed";
signal Y1 :  std_logic_vector(4 downto 0);
begin
   with X  select  Y0 <= 
      "00000" when "00000",
      "00000" when "00001",
      "00000" when "00010",
      "00000" when "00011",
      "00000" when "00100",
      "00000" when "00101",
      "00000" when "00110",
      "00000" when "00111",
      "00000" when "01000",
      "00001" when "01001",
      "00010" when "01010",
      "00011" when "01011",
      "00100" when "01100",
      "00101" when "01101",
      "00110" when "01110",
      "00111" when "01111",
      "00000" when "10000",
      "00010" when "10001",
      "00100" when "10010",
      "00110" when "10011",
      "01000" when "10100",
      "01010" when "10101",
      "01100" when "10110",
      "01110" when "10111",
      "00000" when "11000",
      "00011" when "11001",
      "00110" when "11010",
      "01001" when "11011",
      "01100" when "11100",
      "01111" when "11101",
      "10010" when "11110",
      "10101" when "11111",
      "-----" when others;
   Y1 <= Y0; -- for the possible blockram register
   Y <= Y1;
end architecture;

--------------------------------------------------------------------------------
--                            MultTable_comb_uid43
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Florent de Dinechin, Bogdan Pasca (2007-2022)
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X
-- Output signals: Y

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity MultTable_comb_uid43 is
    port (X : in  std_logic_vector(3 downto 0);
          Y : out  std_logic_vector(3 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid43 is
signal Y0 :  std_logic_vector(3 downto 0);
attribute ram_extract: string;
attribute ram_style: string;
attribute ram_extract of Y0: signal is "yes";
attribute ram_style of Y0: signal is "distributed";
signal Y1 :  std_logic_vector(3 downto 0);
begin
   with X  select  Y0 <= 
      "0000" when "0000",
      "0000" when "0001",
      "0000" when "0010",
      "0000" when "0011",
      "0000" when "0100",
      "0001" when "0101",
      "1110" when "0110",
      "1111" when "0111",
      "0000" when "1000",
      "0010" when "1001",
      "1100" when "1010",
      "1110" when "1011",
      "0000" when "1100",
      "0011" when "1101",
      "1010" when "1110",
      "1101" when "1111",
      "----" when others;
   Y1 <= Y0; -- for the possible blockram register
   Y <= Y1;
end architecture;

--------------------------------------------------------------------------------
--                            MultTable_comb_uid47
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Florent de Dinechin, Bogdan Pasca (2007-2022)
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X
-- Output signals: Y

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity MultTable_comb_uid47 is
    port (X : in  std_logic_vector(4 downto 0);
          Y : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid47 is
signal Y0 :  std_logic_vector(4 downto 0);
attribute ram_extract: string;
attribute ram_style: string;
attribute ram_extract of Y0: signal is "yes";
attribute ram_style of Y0: signal is "distributed";
signal Y1 :  std_logic_vector(4 downto 0);
begin
   with X  select  Y0 <= 
      "00000" when "00000",
      "00000" when "00001",
      "00000" when "00010",
      "00000" when "00011",
      "00000" when "00100",
      "00000" when "00101",
      "00000" when "00110",
      "00000" when "00111",
      "00000" when "01000",
      "00001" when "01001",
      "00010" when "01010",
      "00011" when "01011",
      "00100" when "01100",
      "00101" when "01101",
      "00110" when "01110",
      "00111" when "01111",
      "00000" when "10000",
      "00010" when "10001",
      "00100" when "10010",
      "00110" when "10011",
      "01000" when "10100",
      "01010" when "10101",
      "01100" when "10110",
      "01110" when "10111",
      "00000" when "11000",
      "00011" when "11001",
      "00110" when "11010",
      "01001" when "11011",
      "01100" when "11100",
      "01111" when "11101",
      "10010" when "11110",
      "10101" when "11111",
      "-----" when others;
   Y1 <= Y0; -- for the possible blockram register
   Y <= Y1;
end architecture;

--------------------------------------------------------------------------------
--                            MultTable_comb_uid51
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Florent de Dinechin, Bogdan Pasca (2007-2022)
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X
-- Output signals: Y

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity MultTable_comb_uid51 is
    port (X : in  std_logic_vector(4 downto 0);
          Y : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid51 is
signal Y0 :  std_logic_vector(4 downto 0);
attribute ram_extract: string;
attribute ram_style: string;
attribute ram_extract of Y0: signal is "yes";
attribute ram_style of Y0: signal is "distributed";
signal Y1 :  std_logic_vector(4 downto 0);
begin
   with X  select  Y0 <= 
      "00000" when "00000",
      "00000" when "00001",
      "00000" when "00010",
      "00000" when "00011",
      "00000" when "00100",
      "00000" when "00101",
      "00000" when "00110",
      "00000" when "00111",
      "00000" when "01000",
      "00001" when "01001",
      "00010" when "01010",
      "00011" when "01011",
      "00100" when "01100",
      "00101" when "01101",
      "00110" when "01110",
      "00111" when "01111",
      "00000" when "10000",
      "00010" when "10001",
      "00100" when "10010",
      "00110" when "10011",
      "01000" when "10100",
      "01010" when "10101",
      "01100" when "10110",
      "01110" when "10111",
      "00000" when "11000",
      "00011" when "11001",
      "00110" when "11010",
      "01001" when "11011",
      "01100" when "11100",
      "01111" when "11101",
      "10010" when "11110",
      "10101" when "11111",
      "-----" when others;
   Y1 <= Y0; -- for the possible blockram register
   Y <= Y1;
end architecture;

--------------------------------------------------------------------------------
--                         Compressor_23_3_comb_uid54
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: 
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X1 X0
-- Output signals: R

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity Compressor_23_3_comb_uid54 is
    port (X1 : in  std_logic_vector(1 downto 0);
          X0 : in  std_logic_vector(2 downto 0);
          R : out  std_logic_vector(2 downto 0)   );
end entity;

architecture arch of Compressor_23_3_comb_uid54 is
signal X :  std_logic_vector(4 downto 0);
signal R0 :  std_logic_vector(2 downto 0);
begin
   X <= X1 & X0 ;

   with X  select  R0 <= 
      "000" when "00000",
      "001" when "00001" | "00010" | "00100",
      "010" when "00011" | "00101" | "00110" | "01000" | "10000",
      "011" when "00111" | "01001" | "01010" | "01100" | "10001" | "10010" | "10100",
      "100" when "01011" | "01101" | "01110" | "10011" | "10101" | "10110" | "11000",
      "101" when "01111" | "10111" | "11001" | "11010" | "11100",
      "110" when "11011" | "11101" | "11110",
      "111" when "11111",
      "---" when others;
   R <= R0;
end architecture;

--------------------------------------------------------------------------------
--                         Compressor_3_2_comb_uid57
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: 
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X0
-- Output signals: R

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity Compressor_3_2_comb_uid57 is
    port (X0 : in  std_logic_vector(2 downto 0);
          R : out  std_logic_vector(1 downto 0)   );
end entity;

architecture arch of Compressor_3_2_comb_uid57 is
signal X :  std_logic_vector(2 downto 0);
signal R0 :  std_logic_vector(1 downto 0);
begin
   X <= X0 ;

   with X  select  R0 <= 
      "00" when "000",
      "01" when "001" | "010" | "100",
      "10" when "011" | "101" | "110",
      "11" when "111",
      "--" when others;
   R <= R0;
end architecture;

--------------------------------------------------------------------------------
--                         Compressor_14_3_comb_uid60
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: 
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X1 X0
-- Output signals: R

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity Compressor_14_3_comb_uid60 is
    port (X1 : in  std_logic_vector(0 downto 0);
          X0 : in  std_logic_vector(3 downto 0);
          R : out  std_logic_vector(2 downto 0)   );
end entity;

architecture arch of Compressor_14_3_comb_uid60 is
signal X :  std_logic_vector(4 downto 0);
signal R0 :  std_logic_vector(2 downto 0);
begin
   X <= X1 & X0 ;

   with X  select  R0 <= 
      "000" when "00000",
      "001" when "00001" | "00010" | "00100" | "01000",
      "010" when "00011" | "00101" | "00110" | "01001" | "01010" | "01100" | "10000",
      "011" when "00111" | "01011" | "01101" | "01110" | "10001" | "10010" | "10100" | "11000",
      "100" when "01111" | "10011" | "10101" | "10110" | "11001" | "11010" | "11100",
      "101" when "10111" | "11011" | "11101" | "11110",
      "110" when "11111",
      "---" when others;
   R <= R0;
end architecture;

--------------------------------------------------------------------------------
--                         Compressor_6_3_comb_uid65
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: 
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X0
-- Output signals: R

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity Compressor_6_3_comb_uid65 is
    port (X0 : in  std_logic_vector(5 downto 0);
          R : out  std_logic_vector(2 downto 0)   );
end entity;

architecture arch of Compressor_6_3_comb_uid65 is
signal X :  std_logic_vector(5 downto 0);
signal R0 :  std_logic_vector(2 downto 0);
begin
   X <= X0 ;

   with X  select  R0 <= 
      "000" when "000000",
      "001" when "000001" | "000010" | "000100" | "001000" | "010000" | "100000",
      "010" when "000011" | "000101" | "000110" | "001001" | "001010" | "001100" | "010001" | "010010" | "010100" | "011000" | "100001" | "100010" | "100100" | "101000" | "110000",
      "011" when "000111" | "001011" | "001101" | "001110" | "010011" | "010101" | "010110" | "011001" | "011010" | "011100" | "100011" | "100101" | "100110" | "101001" | "101010" | "101100" | "110001" | "110010" | "110100" | "111000",
      "100" when "001111" | "010111" | "011011" | "011101" | "011110" | "100111" | "101011" | "101101" | "101110" | "110011" | "110101" | "110110" | "111001" | "111010" | "111100",
      "101" when "011111" | "101111" | "110111" | "111011" | "111101" | "111110",
      "110" when "111111",
      "---" when others;
   R <= R0;
end architecture;

--------------------------------------------------------------------------------
--                IntMultiplierLUT_2_signedx2_signed_comb_uid5
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: 
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X Y
-- Output signals: R

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity IntMultiplierLUT_2_signedx2_signed_comb_uid5 is
    port (X : in  std_logic_vector(1 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(3 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_2_signedx2_signed_comb_uid5 is
   component MultTable_comb_uid7 is
      port ( X : in  std_logic_vector(3 downto 0);
             Y : out  std_logic_vector(3 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(3 downto 0);
signal Y1 :  std_logic_vector(3 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid7
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                   IntMultiplierLUT_3x2_signed_comb_uid9
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: 
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X Y
-- Output signals: R

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity IntMultiplierLUT_3x2_signed_comb_uid9 is
    port (X : in  std_logic_vector(2 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_3x2_signed_comb_uid9 is
   component MultTable_comb_uid11 is
      port ( X : in  std_logic_vector(4 downto 0);
             Y : out  std_logic_vector(4 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(4 downto 0);
signal Y1 :  std_logic_vector(4 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid11
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                   IntMultiplierLUT_3x2_signed_comb_uid13
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: 
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X Y
-- Output signals: R

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity IntMultiplierLUT_3x2_signed_comb_uid13 is
    port (X : in  std_logic_vector(2 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_3x2_signed_comb_uid13 is
   component MultTable_comb_uid15 is
      port ( X : in  std_logic_vector(4 downto 0);
             Y : out  std_logic_vector(4 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(4 downto 0);
signal Y1 :  std_logic_vector(4 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid15
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                   IntMultiplierLUT_2_signedx2_comb_uid17
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: 
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X Y
-- Output signals: R

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity IntMultiplierLUT_2_signedx2_comb_uid17 is
    port (X : in  std_logic_vector(1 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(3 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_2_signedx2_comb_uid17 is
   component MultTable_comb_uid19 is
      port ( X : in  std_logic_vector(3 downto 0);
             Y : out  std_logic_vector(3 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(3 downto 0);
signal Y1 :  std_logic_vector(3 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid19
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                      IntMultiplierLUT_3x2_comb_uid21
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: 
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X Y
-- Output signals: R

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity IntMultiplierLUT_3x2_comb_uid21 is
    port (X : in  std_logic_vector(2 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_3x2_comb_uid21 is
   component MultTable_comb_uid23 is
      port ( X : in  std_logic_vector(4 downto 0);
             Y : out  std_logic_vector(4 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(4 downto 0);
signal Y1 :  std_logic_vector(4 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid23
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                      IntMultiplierLUT_3x2_comb_uid25
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: 
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X Y
-- Output signals: R

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity IntMultiplierLUT_3x2_comb_uid25 is
    port (X : in  std_logic_vector(2 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_3x2_comb_uid25 is
   component MultTable_comb_uid27 is
      port ( X : in  std_logic_vector(4 downto 0);
             Y : out  std_logic_vector(4 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(4 downto 0);
signal Y1 :  std_logic_vector(4 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid27
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                   IntMultiplierLUT_2_signedx2_comb_uid29
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: 
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X Y
-- Output signals: R

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity IntMultiplierLUT_2_signedx2_comb_uid29 is
    port (X : in  std_logic_vector(1 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(3 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_2_signedx2_comb_uid29 is
   component MultTable_comb_uid31 is
      port ( X : in  std_logic_vector(3 downto 0);
             Y : out  std_logic_vector(3 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(3 downto 0);
signal Y1 :  std_logic_vector(3 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid31
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                      IntMultiplierLUT_3x2_comb_uid33
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: 
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X Y
-- Output signals: R

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity IntMultiplierLUT_3x2_comb_uid33 is
    port (X : in  std_logic_vector(2 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_3x2_comb_uid33 is
   component MultTable_comb_uid35 is
      port ( X : in  std_logic_vector(4 downto 0);
             Y : out  std_logic_vector(4 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(4 downto 0);
signal Y1 :  std_logic_vector(4 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid35
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                      IntMultiplierLUT_3x2_comb_uid37
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: 
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X Y
-- Output signals: R

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity IntMultiplierLUT_3x2_comb_uid37 is
    port (X : in  std_logic_vector(2 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_3x2_comb_uid37 is
   component MultTable_comb_uid39 is
      port ( X : in  std_logic_vector(4 downto 0);
             Y : out  std_logic_vector(4 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(4 downto 0);
signal Y1 :  std_logic_vector(4 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid39
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                   IntMultiplierLUT_2_signedx2_comb_uid41
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: 
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X Y
-- Output signals: R

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity IntMultiplierLUT_2_signedx2_comb_uid41 is
    port (X : in  std_logic_vector(1 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(3 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_2_signedx2_comb_uid41 is
   component MultTable_comb_uid43 is
      port ( X : in  std_logic_vector(3 downto 0);
             Y : out  std_logic_vector(3 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(3 downto 0);
signal Y1 :  std_logic_vector(3 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid43
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                      IntMultiplierLUT_3x2_comb_uid45
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: 
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X Y
-- Output signals: R

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity IntMultiplierLUT_3x2_comb_uid45 is
    port (X : in  std_logic_vector(2 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_3x2_comb_uid45 is
   component MultTable_comb_uid47 is
      port ( X : in  std_logic_vector(4 downto 0);
             Y : out  std_logic_vector(4 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(4 downto 0);
signal Y1 :  std_logic_vector(4 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid47
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                      IntMultiplierLUT_3x2_comb_uid49
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: 
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X Y
-- Output signals: R

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity IntMultiplierLUT_3x2_comb_uid49 is
    port (X : in  std_logic_vector(2 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_3x2_comb_uid49 is
   component MultTable_comb_uid51 is
      port ( X : in  std_logic_vector(4 downto 0);
             Y : out  std_logic_vector(4 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(4 downto 0);
signal Y1 :  std_logic_vector(4 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid51
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                           IntAdder_11_comb_uid95
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Bogdan Pasca, Florent de Dinechin (2008-2016)
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X Y Cin
-- Output signals: R

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity IntAdder_11_comb_uid95 is
    port (X : in  std_logic_vector(10 downto 0);
          Y : in  std_logic_vector(10 downto 0);
          Cin : in  std_logic;
          R : out  std_logic_vector(10 downto 0)   );
end entity;

architecture arch of IntAdder_11_comb_uid95 is
signal Rtmp :  std_logic_vector(10 downto 0);
begin
   Rtmp <= X + Y + Cin;
   R <= Rtmp;
end architecture;

--------------------------------------------------------------------------------
--         FixMultAdd_signed_x_2_M5_y_2_M5_a_5_M10_r_5_M10_comb_uid2
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Florent de Dinechin, Matei Istoan, 2012-2014, 2024
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X Y A
-- Output signals: R

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library std;
use std.textio.all;
library work;

entity FixMultAdd_signed_x_2_M5_y_2_M5_a_5_M10_r_5_M10_comb_uid2 is
    port (X : in  std_logic_vector(7 downto 0);
          Y : in  std_logic_vector(7 downto 0);
          A : in  std_logic_vector(15 downto 0);
          R : out  std_logic_vector(15 downto 0)   );
end entity;

architecture arch of FixMultAdd_signed_x_2_M5_y_2_M5_a_5_M10_r_5_M10_comb_uid2 is
   component IntMultiplierLUT_2_signedx2_signed_comb_uid5 is
      port ( X : in  std_logic_vector(1 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(3 downto 0)   );
   end component;

   component IntMultiplierLUT_3x2_signed_comb_uid9 is
      port ( X : in  std_logic_vector(2 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(4 downto 0)   );
   end component;

   component IntMultiplierLUT_3x2_signed_comb_uid13 is
      port ( X : in  std_logic_vector(2 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(4 downto 0)   );
   end component;

   component IntMultiplierLUT_2_signedx2_comb_uid17 is
      port ( X : in  std_logic_vector(1 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(3 downto 0)   );
   end component;

   component IntMultiplierLUT_3x2_comb_uid21 is
      port ( X : in  std_logic_vector(2 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(4 downto 0)   );
   end component;

   component IntMultiplierLUT_3x2_comb_uid25 is
      port ( X : in  std_logic_vector(2 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(4 downto 0)   );
   end component;

   component IntMultiplierLUT_2_signedx2_comb_uid29 is
      port ( X : in  std_logic_vector(1 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(3 downto 0)   );
   end component;

   component IntMultiplierLUT_3x2_comb_uid33 is
      port ( X : in  std_logic_vector(2 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(4 downto 0)   );
   end component;

   component IntMultiplierLUT_3x2_comb_uid37 is
      port ( X : in  std_logic_vector(2 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(4 downto 0)   );
   end component;

   component IntMultiplierLUT_2_signedx2_comb_uid41 is
      port ( X : in  std_logic_vector(1 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(3 downto 0)   );
   end component;

   component IntMultiplierLUT_3x2_comb_uid45 is
      port ( X : in  std_logic_vector(2 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(4 downto 0)   );
   end component;

   component IntMultiplierLUT_3x2_comb_uid49 is
      port ( X : in  std_logic_vector(2 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(4 downto 0)   );
   end component;

   component Compressor_23_3_comb_uid54 is
      port ( X1 : in  std_logic_vector(1 downto 0);
             X0 : in  std_logic_vector(2 downto 0);
             R : out  std_logic_vector(2 downto 0)   );
   end component;

   component Compressor_3_2_comb_uid57 is
      port ( X0 : in  std_logic_vector(2 downto 0);
             R : out  std_logic_vector(1 downto 0)   );
   end component;

   component Compressor_14_3_comb_uid60 is
      port ( X1 : in  std_logic_vector(0 downto 0);
             X0 : in  std_logic_vector(3 downto 0);
             R : out  std_logic_vector(2 downto 0)   );
   end component;

   component Compressor_6_3_comb_uid65 is
      port ( X0 : in  std_logic_vector(5 downto 0);
             R : out  std_logic_vector(2 downto 0)   );
   end component;

   component IntAdder_11_comb_uid95 is
      port ( X : in  std_logic_vector(10 downto 0);
             Y : in  std_logic_vector(10 downto 0);
             Cin : in  std_logic;
             R : out  std_logic_vector(10 downto 0)   );
   end component;

signal XX :  signed(2+5 downto 0);
signal YY :  signed(2+5 downto 0);
signal AA :  signed(5+10 downto 0);
signal tile_0_X :  std_logic_vector(1 downto 0);
signal tile_0_Y :  std_logic_vector(1 downto 0);
signal tile_0_output :  std_logic_vector(3 downto 0);
signal tile_0_filtered_output :  signed(3-0 downto 0);
signal bh3_w2_0 :  std_logic;
signal bh3_w3_0 :  std_logic;
signal bh3_w4_0 :  std_logic;
signal bh3_w5_0 :  std_logic;
signal tile_1_X :  std_logic_vector(2 downto 0);
signal tile_1_Y :  std_logic_vector(1 downto 0);
signal tile_1_output :  std_logic_vector(4 downto 0);
signal tile_1_filtered_output :  signed(4-0 downto 0);
signal bh3_wm1_0 :  std_logic;
signal bh3_w0_0 :  std_logic;
signal bh3_w1_0 :  std_logic;
signal bh3_w2_1 :  std_logic;
signal bh3_w3_1 :  std_logic;
signal tile_2_X :  std_logic_vector(2 downto 0);
signal tile_2_Y :  std_logic_vector(1 downto 0);
signal tile_2_output :  std_logic_vector(4 downto 0);
signal tile_2_filtered_output :  signed(4-0 downto 0);
signal bh3_wm4_0 :  std_logic;
signal bh3_wm3_0 :  std_logic;
signal bh3_wm2_0 :  std_logic;
signal bh3_wm1_1 :  std_logic;
signal bh3_w0_1 :  std_logic;
signal tile_3_X :  std_logic_vector(1 downto 0);
signal tile_3_Y :  std_logic_vector(1 downto 0);
signal tile_3_output :  std_logic_vector(3 downto 0);
signal tile_3_filtered_output :  signed(3-0 downto 0);
signal bh3_w0_2 :  std_logic;
signal bh3_w1_1 :  std_logic;
signal bh3_w2_2 :  std_logic;
signal bh3_w3_2 :  std_logic;
signal tile_4_X :  std_logic_vector(2 downto 0);
signal tile_4_Y :  std_logic_vector(1 downto 0);
signal tile_4_output :  std_logic_vector(4 downto 0);
signal tile_4_filtered_output :  unsigned(4-0 downto 0);
signal bh3_wm3_1 :  std_logic;
signal bh3_wm2_1 :  std_logic;
signal bh3_wm1_2 :  std_logic;
signal bh3_w0_3 :  std_logic;
signal bh3_w1_2 :  std_logic;
signal tile_5_X :  std_logic_vector(2 downto 0);
signal tile_5_Y :  std_logic_vector(1 downto 0);
signal tile_5_output :  std_logic_vector(4 downto 0);
signal tile_5_filtered_output :  unsigned(4-0 downto 0);
signal bh3_wm6_0 :  std_logic;
signal bh3_wm5_0 :  std_logic;
signal bh3_wm4_1 :  std_logic;
signal bh3_wm3_2 :  std_logic;
signal bh3_wm2_2 :  std_logic;
signal tile_6_X :  std_logic_vector(1 downto 0);
signal tile_6_Y :  std_logic_vector(1 downto 0);
signal tile_6_output :  std_logic_vector(3 downto 0);
signal tile_6_filtered_output :  signed(3-0 downto 0);
signal bh3_wm2_3 :  std_logic;
signal bh3_wm1_3 :  std_logic;
signal bh3_w0_4 :  std_logic;
signal bh3_w1_3 :  std_logic;
signal tile_7_X :  std_logic_vector(2 downto 0);
signal tile_7_Y :  std_logic_vector(1 downto 0);
signal tile_7_output :  std_logic_vector(4 downto 0);
signal tile_7_filtered_output :  unsigned(4-0 downto 0);
signal bh3_wm5_1 :  std_logic;
signal bh3_wm4_2 :  std_logic;
signal bh3_wm3_3 :  std_logic;
signal bh3_wm2_4 :  std_logic;
signal bh3_wm1_4 :  std_logic;
signal tile_8_X :  std_logic_vector(2 downto 0);
signal tile_8_Y :  std_logic_vector(1 downto 0);
signal tile_8_output :  std_logic_vector(4 downto 0);
signal tile_8_filtered_output :  unsigned(4-0 downto 0);
signal bh3_wm8_0 :  std_logic;
signal bh3_wm7_0 :  std_logic;
signal bh3_wm6_1 :  std_logic;
signal bh3_wm5_2 :  std_logic;
signal bh3_wm4_3 :  std_logic;
signal tile_9_X :  std_logic_vector(1 downto 0);
signal tile_9_Y :  std_logic_vector(1 downto 0);
signal tile_9_output :  std_logic_vector(3 downto 0);
signal tile_9_filtered_output :  signed(3-0 downto 0);
signal bh3_wm4_4 :  std_logic;
signal bh3_wm3_4 :  std_logic;
signal bh3_wm2_5 :  std_logic;
signal bh3_wm1_5 :  std_logic;
signal tile_10_X :  std_logic_vector(2 downto 0);
signal tile_10_Y :  std_logic_vector(1 downto 0);
signal tile_10_output :  std_logic_vector(4 downto 0);
signal tile_10_filtered_output :  unsigned(4-0 downto 0);
signal bh3_wm7_1 :  std_logic;
signal bh3_wm6_2 :  std_logic;
signal bh3_wm5_3 :  std_logic;
signal bh3_wm4_5 :  std_logic;
signal bh3_wm3_5 :  std_logic;
signal tile_11_X :  std_logic_vector(2 downto 0);
signal tile_11_Y :  std_logic_vector(1 downto 0);
signal tile_11_output :  std_logic_vector(4 downto 0);
signal tile_11_filtered_output :  unsigned(4-0 downto 0);
signal bh3_wm10_0 :  std_logic;
signal bh3_wm9_0 :  std_logic;
signal bh3_wm8_1 :  std_logic;
signal bh3_wm7_2 :  std_logic;
signal bh3_wm6_3 :  std_logic;
signal bh3_wm10_1 :  std_logic;
signal bh3_wm9_1 :  std_logic;
signal bh3_wm8_2 :  std_logic;
signal bh3_wm7_3 :  std_logic;
signal bh3_wm6_4 :  std_logic;
signal bh3_wm5_4 :  std_logic;
signal bh3_wm4_6 :  std_logic;
signal bh3_wm3_6 :  std_logic;
signal bh3_wm2_6 :  std_logic;
signal bh3_wm1_6 :  std_logic;
signal bh3_w0_5 :  std_logic;
signal bh3_w1_4 :  std_logic;
signal bh3_w2_3 :  std_logic;
signal bh3_w3_3 :  std_logic;
signal bh3_w4_1 :  std_logic;
signal bh3_w5_1 :  std_logic;
signal bh3_wm1_7 :  std_logic;
signal bh3_w2_4 :  std_logic;
signal bh3_w3_4 :  std_logic;
signal Compressor_23_3_comb_uid54_bh3_uid55_In0 :  std_logic_vector(2 downto 0);
signal Compressor_23_3_comb_uid54_bh3_uid55_In1 :  std_logic_vector(1 downto 0);
signal Compressor_23_3_comb_uid54_bh3_uid55_Out0 :  std_logic_vector(2 downto 0);
signal bh3_wm10_2 :  std_logic;
signal bh3_wm9_2 :  std_logic;
signal bh3_wm8_3 :  std_logic;
signal Compressor_3_2_comb_uid57_bh3_uid58_In0 :  std_logic_vector(2 downto 0);
signal Compressor_3_2_comb_uid57_bh3_uid58_Out0 :  std_logic_vector(1 downto 0);
signal bh3_wm8_4 :  std_logic;
signal bh3_wm7_4 :  std_logic;
signal Compressor_14_3_comb_uid60_bh3_uid61_In0 :  std_logic_vector(3 downto 0);
signal Compressor_14_3_comb_uid60_bh3_uid61_In1 :  std_logic_vector(0 downto 0);
signal Compressor_14_3_comb_uid60_bh3_uid61_Out0 :  std_logic_vector(2 downto 0);
signal bh3_wm7_5 :  std_logic;
signal bh3_wm6_5 :  std_logic;
signal bh3_wm5_5 :  std_logic;
signal Compressor_14_3_comb_uid60_bh3_uid62_In0 :  std_logic_vector(3 downto 0);
signal Compressor_14_3_comb_uid60_bh3_uid62_In1 :  std_logic_vector(0 downto 0);
signal Compressor_14_3_comb_uid60_bh3_uid62_Out0 :  std_logic_vector(2 downto 0);
signal bh3_wm6_6 :  std_logic;
signal bh3_wm5_6 :  std_logic;
signal bh3_wm4_7 :  std_logic;
signal Compressor_14_3_comb_uid60_bh3_uid63_In0 :  std_logic_vector(3 downto 0);
signal Compressor_14_3_comb_uid60_bh3_uid63_In1 :  std_logic_vector(0 downto 0);
signal Compressor_14_3_comb_uid60_bh3_uid63_Out0 :  std_logic_vector(2 downto 0);
signal bh3_wm5_7 :  std_logic;
signal bh3_wm4_8 :  std_logic;
signal bh3_wm3_7 :  std_logic;
signal Compressor_6_3_comb_uid65_bh3_uid66_In0 :  std_logic_vector(5 downto 0);
signal Compressor_6_3_comb_uid65_bh3_uid66_Out0 :  std_logic_vector(2 downto 0);
signal bh3_wm4_9 :  std_logic;
signal bh3_wm3_8 :  std_logic;
signal bh3_wm2_7 :  std_logic;
signal Compressor_6_3_comb_uid65_bh3_uid67_In0 :  std_logic_vector(5 downto 0);
signal Compressor_6_3_comb_uid65_bh3_uid67_Out0 :  std_logic_vector(2 downto 0);
signal bh3_wm3_9 :  std_logic;
signal bh3_wm2_8 :  std_logic;
signal bh3_wm1_8 :  std_logic;
signal Compressor_6_3_comb_uid65_bh3_uid68_In0 :  std_logic_vector(5 downto 0);
signal Compressor_6_3_comb_uid65_bh3_uid68_Out0 :  std_logic_vector(2 downto 0);
signal bh3_wm2_9 :  std_logic;
signal bh3_wm1_9 :  std_logic;
signal bh3_w0_6 :  std_logic;
signal Compressor_23_3_comb_uid54_bh3_uid69_In0 :  std_logic_vector(2 downto 0);
signal Compressor_23_3_comb_uid54_bh3_uid69_In1 :  std_logic_vector(1 downto 0);
signal Compressor_23_3_comb_uid54_bh3_uid69_Out0 :  std_logic_vector(2 downto 0);
signal bh3_wm2_10 :  std_logic;
signal bh3_wm1_10 :  std_logic;
signal bh3_w0_7 :  std_logic;
signal Compressor_6_3_comb_uid65_bh3_uid70_In0 :  std_logic_vector(5 downto 0);
signal Compressor_6_3_comb_uid65_bh3_uid70_Out0 :  std_logic_vector(2 downto 0);
signal bh3_wm1_11 :  std_logic;
signal bh3_w0_8 :  std_logic;
signal bh3_w1_5 :  std_logic;
signal Compressor_6_3_comb_uid65_bh3_uid71_In0 :  std_logic_vector(5 downto 0);
signal Compressor_6_3_comb_uid65_bh3_uid71_Out0 :  std_logic_vector(2 downto 0);
signal bh3_w0_9 :  std_logic;
signal bh3_w1_6 :  std_logic;
signal bh3_w2_5 :  std_logic;
signal Compressor_14_3_comb_uid60_bh3_uid72_In0 :  std_logic_vector(3 downto 0);
signal Compressor_14_3_comb_uid60_bh3_uid72_In1 :  std_logic_vector(0 downto 0);
signal Compressor_14_3_comb_uid60_bh3_uid72_Out0 :  std_logic_vector(2 downto 0);
signal bh3_w1_7 :  std_logic;
signal bh3_w2_6 :  std_logic;
signal bh3_w3_5 :  std_logic;
signal Compressor_14_3_comb_uid60_bh3_uid73_In0 :  std_logic_vector(3 downto 0);
signal Compressor_14_3_comb_uid60_bh3_uid73_In1 :  std_logic_vector(0 downto 0);
signal Compressor_14_3_comb_uid60_bh3_uid73_Out0 :  std_logic_vector(2 downto 0);
signal bh3_w2_7 :  std_logic;
signal bh3_w3_6 :  std_logic;
signal bh3_w4_2 :  std_logic;
signal Compressor_14_3_comb_uid60_bh3_uid74_In0 :  std_logic_vector(3 downto 0);
signal Compressor_14_3_comb_uid60_bh3_uid74_In1 :  std_logic_vector(0 downto 0);
signal Compressor_14_3_comb_uid60_bh3_uid74_Out0 :  std_logic_vector(2 downto 0);
signal bh3_w3_7 :  std_logic;
signal bh3_w4_3 :  std_logic;
signal bh3_w5_2 :  std_logic;
signal Compressor_23_3_comb_uid54_bh3_uid75_In0 :  std_logic_vector(2 downto 0);
signal Compressor_23_3_comb_uid54_bh3_uid75_In1 :  std_logic_vector(1 downto 0);
signal Compressor_23_3_comb_uid54_bh3_uid75_Out0 :  std_logic_vector(2 downto 0);
signal bh3_w4_4 :  std_logic;
signal bh3_w5_3 :  std_logic;
signal Compressor_23_3_comb_uid54_bh3_uid76_In0 :  std_logic_vector(2 downto 0);
signal Compressor_23_3_comb_uid54_bh3_uid76_In1 :  std_logic_vector(1 downto 0);
signal Compressor_23_3_comb_uid54_bh3_uid76_Out0 :  std_logic_vector(2 downto 0);
signal bh3_wm8_5 :  std_logic;
signal bh3_wm7_6 :  std_logic;
signal bh3_wm6_7 :  std_logic;
signal Compressor_3_2_comb_uid57_bh3_uid77_In0 :  std_logic_vector(2 downto 0);
signal Compressor_3_2_comb_uid57_bh3_uid77_Out0 :  std_logic_vector(1 downto 0);
signal bh3_wm6_8 :  std_logic;
signal bh3_wm5_8 :  std_logic;
signal Compressor_23_3_comb_uid54_bh3_uid78_In0 :  std_logic_vector(2 downto 0);
signal Compressor_23_3_comb_uid54_bh3_uid78_In1 :  std_logic_vector(1 downto 0);
signal Compressor_23_3_comb_uid54_bh3_uid78_Out0 :  std_logic_vector(2 downto 0);
signal bh3_wm5_9 :  std_logic;
signal bh3_wm4_10 :  std_logic;
signal bh3_wm3_10 :  std_logic;
signal Compressor_14_3_comb_uid60_bh3_uid79_In0 :  std_logic_vector(3 downto 0);
signal Compressor_14_3_comb_uid60_bh3_uid79_In1 :  std_logic_vector(0 downto 0);
signal Compressor_14_3_comb_uid60_bh3_uid79_Out0 :  std_logic_vector(2 downto 0);
signal bh3_wm3_11 :  std_logic;
signal bh3_wm2_11 :  std_logic;
signal bh3_wm1_12 :  std_logic;
signal Compressor_3_2_comb_uid57_bh3_uid80_In0 :  std_logic_vector(2 downto 0);
signal Compressor_3_2_comb_uid57_bh3_uid80_Out0 :  std_logic_vector(1 downto 0);
signal bh3_wm2_12 :  std_logic;
signal bh3_wm1_13 :  std_logic;
signal Compressor_14_3_comb_uid60_bh3_uid81_In0 :  std_logic_vector(3 downto 0);
signal Compressor_14_3_comb_uid60_bh3_uid81_In1 :  std_logic_vector(0 downto 0);
signal Compressor_14_3_comb_uid60_bh3_uid81_Out0 :  std_logic_vector(2 downto 0);
signal bh3_wm1_14 :  std_logic;
signal bh3_w0_10 :  std_logic;
signal bh3_w1_8 :  std_logic;
signal Compressor_3_2_comb_uid57_bh3_uid82_In0 :  std_logic_vector(2 downto 0);
signal Compressor_3_2_comb_uid57_bh3_uid82_Out0 :  std_logic_vector(1 downto 0);
signal bh3_w0_11 :  std_logic;
signal bh3_w1_9 :  std_logic;
signal Compressor_14_3_comb_uid60_bh3_uid83_In0 :  std_logic_vector(3 downto 0);
signal Compressor_14_3_comb_uid60_bh3_uid83_In1 :  std_logic_vector(0 downto 0);
signal Compressor_14_3_comb_uid60_bh3_uid83_Out0 :  std_logic_vector(2 downto 0);
signal bh3_w1_10 :  std_logic;
signal bh3_w2_8 :  std_logic;
signal bh3_w3_8 :  std_logic;
signal Compressor_3_2_comb_uid57_bh3_uid84_In0 :  std_logic_vector(2 downto 0);
signal Compressor_3_2_comb_uid57_bh3_uid84_Out0 :  std_logic_vector(1 downto 0);
signal bh3_w2_9 :  std_logic;
signal bh3_w3_9 :  std_logic;
signal Compressor_23_3_comb_uid54_bh3_uid85_In0 :  std_logic_vector(2 downto 0);
signal Compressor_23_3_comb_uid54_bh3_uid85_In1 :  std_logic_vector(1 downto 0);
signal Compressor_23_3_comb_uid54_bh3_uid85_Out0 :  std_logic_vector(2 downto 0);
signal bh3_w3_10 :  std_logic;
signal bh3_w4_5 :  std_logic;
signal bh3_w5_4 :  std_logic;
signal Compressor_14_3_comb_uid60_bh3_uid86_In0 :  std_logic_vector(3 downto 0);
signal Compressor_14_3_comb_uid60_bh3_uid86_In1 :  std_logic_vector(0 downto 0);
signal Compressor_14_3_comb_uid60_bh3_uid86_Out0 :  std_logic_vector(2 downto 0);
signal bh3_w5_5 :  std_logic;
signal Compressor_23_3_comb_uid54_bh3_uid87_In0 :  std_logic_vector(2 downto 0);
signal Compressor_23_3_comb_uid54_bh3_uid87_In1 :  std_logic_vector(1 downto 0);
signal Compressor_23_3_comb_uid54_bh3_uid87_Out0 :  std_logic_vector(2 downto 0);
signal bh3_wm6_9 :  std_logic;
signal bh3_wm5_10 :  std_logic;
signal bh3_wm4_11 :  std_logic;
signal Compressor_23_3_comb_uid54_bh3_uid88_In0 :  std_logic_vector(2 downto 0);
signal Compressor_23_3_comb_uid54_bh3_uid88_In1 :  std_logic_vector(1 downto 0);
signal Compressor_23_3_comb_uid54_bh3_uid88_Out0 :  std_logic_vector(2 downto 0);
signal bh3_wm4_12 :  std_logic;
signal bh3_wm3_12 :  std_logic;
signal bh3_wm2_13 :  std_logic;
signal Compressor_3_2_comb_uid57_bh3_uid89_In0 :  std_logic_vector(2 downto 0);
signal Compressor_3_2_comb_uid57_bh3_uid89_Out0 :  std_logic_vector(1 downto 0);
signal bh3_wm2_14 :  std_logic;
signal bh3_wm1_15 :  std_logic;
signal Compressor_23_3_comb_uid54_bh3_uid90_In0 :  std_logic_vector(2 downto 0);
signal Compressor_23_3_comb_uid54_bh3_uid90_In1 :  std_logic_vector(1 downto 0);
signal Compressor_23_3_comb_uid54_bh3_uid90_Out0 :  std_logic_vector(2 downto 0);
signal bh3_wm1_16 :  std_logic;
signal bh3_w0_12 :  std_logic;
signal bh3_w1_11 :  std_logic;
signal Compressor_23_3_comb_uid54_bh3_uid91_In0 :  std_logic_vector(2 downto 0);
signal Compressor_23_3_comb_uid54_bh3_uid91_In1 :  std_logic_vector(1 downto 0);
signal Compressor_23_3_comb_uid54_bh3_uid91_Out0 :  std_logic_vector(2 downto 0);
signal bh3_w1_12 :  std_logic;
signal bh3_w2_10 :  std_logic;
signal bh3_w3_11 :  std_logic;
signal Compressor_23_3_comb_uid54_bh3_uid92_In0 :  std_logic_vector(2 downto 0);
signal Compressor_23_3_comb_uid54_bh3_uid92_In1 :  std_logic_vector(1 downto 0);
signal Compressor_23_3_comb_uid54_bh3_uid92_Out0 :  std_logic_vector(2 downto 0);
signal bh3_w3_12 :  std_logic;
signal bh3_w4_6 :  std_logic;
signal bh3_w5_6 :  std_logic;
signal Compressor_14_3_comb_uid60_bh3_uid93_In0 :  std_logic_vector(3 downto 0);
signal Compressor_14_3_comb_uid60_bh3_uid93_In1 :  std_logic_vector(0 downto 0);
signal Compressor_14_3_comb_uid60_bh3_uid93_Out0 :  std_logic_vector(2 downto 0);
signal bh3_w5_7 :  std_logic;
signal tmp_bitheapResult_bh3_5 :  std_logic_vector(5 downto 0);
signal bitheapFinalAdd_bh3_In0 :  std_logic_vector(10 downto 0);
signal bitheapFinalAdd_bh3_In1 :  std_logic_vector(10 downto 0);
signal bitheapFinalAdd_bh3_Cin :  std_logic;
signal bitheapFinalAdd_bh3_Out :  std_logic_vector(10 downto 0);
signal bitheapResult_bh3 :  std_logic_vector(15 downto 0);
signal RR :  signed(5+10 downto 0);
begin
XX <= signed(X);
YY <= signed(Y);
AA <= signed(A);
   tile_0_X <= X(7 downto 6);
   tile_0_Y <= Y(7 downto 6);
   tile_0_mult: IntMultiplierLUT_2_signedx2_signed_comb_uid5
      port map ( X => tile_0_X,
                 Y => tile_0_Y,
                 R => tile_0_output);

   tile_0_filtered_output <= signed(tile_0_output(3 downto 0));
   bh3_w2_0 <= tile_0_filtered_output(0);
   bh3_w3_0 <= tile_0_filtered_output(1);
   bh3_w4_0 <= tile_0_filtered_output(2);
   bh3_w5_0 <= not tile_0_filtered_output(3);
   tile_1_X <= X(5 downto 3);
   tile_1_Y <= Y(7 downto 6);
   tile_1_mult: IntMultiplierLUT_3x2_signed_comb_uid9
      port map ( X => tile_1_X,
                 Y => tile_1_Y,
                 R => tile_1_output);

   tile_1_filtered_output <= signed(tile_1_output(4 downto 0));
   bh3_wm1_0 <= tile_1_filtered_output(0);
   bh3_w0_0 <= tile_1_filtered_output(1);
   bh3_w1_0 <= tile_1_filtered_output(2);
   bh3_w2_1 <= tile_1_filtered_output(3);
   bh3_w3_1 <= not tile_1_filtered_output(4);
   tile_2_X <= X(2 downto 0);
   tile_2_Y <= Y(7 downto 6);
   tile_2_mult: IntMultiplierLUT_3x2_signed_comb_uid13
      port map ( X => tile_2_X,
                 Y => tile_2_Y,
                 R => tile_2_output);

   tile_2_filtered_output <= signed(tile_2_output(4 downto 0));
   bh3_wm4_0 <= tile_2_filtered_output(0);
   bh3_wm3_0 <= tile_2_filtered_output(1);
   bh3_wm2_0 <= tile_2_filtered_output(2);
   bh3_wm1_1 <= tile_2_filtered_output(3);
   bh3_w0_1 <= not tile_2_filtered_output(4);
   tile_3_X <= X(7 downto 6);
   tile_3_Y <= Y(5 downto 4);
   tile_3_mult: IntMultiplierLUT_2_signedx2_comb_uid17
      port map ( X => tile_3_X,
                 Y => tile_3_Y,
                 R => tile_3_output);

   tile_3_filtered_output <= signed(tile_3_output(3 downto 0));
   bh3_w0_2 <= tile_3_filtered_output(0);
   bh3_w1_1 <= tile_3_filtered_output(1);
   bh3_w2_2 <= tile_3_filtered_output(2);
   bh3_w3_2 <= not tile_3_filtered_output(3);
   tile_4_X <= X(5 downto 3);
   tile_4_Y <= Y(5 downto 4);
   tile_4_mult: IntMultiplierLUT_3x2_comb_uid21
      port map ( X => tile_4_X,
                 Y => tile_4_Y,
                 R => tile_4_output);

   tile_4_filtered_output <= unsigned(tile_4_output(4 downto 0));
   bh3_wm3_1 <= tile_4_filtered_output(0);
   bh3_wm2_1 <= tile_4_filtered_output(1);
   bh3_wm1_2 <= tile_4_filtered_output(2);
   bh3_w0_3 <= tile_4_filtered_output(3);
   bh3_w1_2 <= tile_4_filtered_output(4);
   tile_5_X <= X(2 downto 0);
   tile_5_Y <= Y(5 downto 4);
   tile_5_mult: IntMultiplierLUT_3x2_comb_uid25
      port map ( X => tile_5_X,
                 Y => tile_5_Y,
                 R => tile_5_output);

   tile_5_filtered_output <= unsigned(tile_5_output(4 downto 0));
   bh3_wm6_0 <= tile_5_filtered_output(0);
   bh3_wm5_0 <= tile_5_filtered_output(1);
   bh3_wm4_1 <= tile_5_filtered_output(2);
   bh3_wm3_2 <= tile_5_filtered_output(3);
   bh3_wm2_2 <= tile_5_filtered_output(4);
   tile_6_X <= X(7 downto 6);
   tile_6_Y <= Y(3 downto 2);
   tile_6_mult: IntMultiplierLUT_2_signedx2_comb_uid29
      port map ( X => tile_6_X,
                 Y => tile_6_Y,
                 R => tile_6_output);

   tile_6_filtered_output <= signed(tile_6_output(3 downto 0));
   bh3_wm2_3 <= tile_6_filtered_output(0);
   bh3_wm1_3 <= tile_6_filtered_output(1);
   bh3_w0_4 <= tile_6_filtered_output(2);
   bh3_w1_3 <= not tile_6_filtered_output(3);
   tile_7_X <= X(5 downto 3);
   tile_7_Y <= Y(3 downto 2);
   tile_7_mult: IntMultiplierLUT_3x2_comb_uid33
      port map ( X => tile_7_X,
                 Y => tile_7_Y,
                 R => tile_7_output);

   tile_7_filtered_output <= unsigned(tile_7_output(4 downto 0));
   bh3_wm5_1 <= tile_7_filtered_output(0);
   bh3_wm4_2 <= tile_7_filtered_output(1);
   bh3_wm3_3 <= tile_7_filtered_output(2);
   bh3_wm2_4 <= tile_7_filtered_output(3);
   bh3_wm1_4 <= tile_7_filtered_output(4);
   tile_8_X <= X(2 downto 0);
   tile_8_Y <= Y(3 downto 2);
   tile_8_mult: IntMultiplierLUT_3x2_comb_uid37
      port map ( X => tile_8_X,
                 Y => tile_8_Y,
                 R => tile_8_output);

   tile_8_filtered_output <= unsigned(tile_8_output(4 downto 0));
   bh3_wm8_0 <= tile_8_filtered_output(0);
   bh3_wm7_0 <= tile_8_filtered_output(1);
   bh3_wm6_1 <= tile_8_filtered_output(2);
   bh3_wm5_2 <= tile_8_filtered_output(3);
   bh3_wm4_3 <= tile_8_filtered_output(4);
   tile_9_X <= X(7 downto 6);
   tile_9_Y <= Y(1 downto 0);
   tile_9_mult: IntMultiplierLUT_2_signedx2_comb_uid41
      port map ( X => tile_9_X,
                 Y => tile_9_Y,
                 R => tile_9_output);

   tile_9_filtered_output <= signed(tile_9_output(3 downto 0));
   bh3_wm4_4 <= tile_9_filtered_output(0);
   bh3_wm3_4 <= tile_9_filtered_output(1);
   bh3_wm2_5 <= tile_9_filtered_output(2);
   bh3_wm1_5 <= not tile_9_filtered_output(3);
   tile_10_X <= X(5 downto 3);
   tile_10_Y <= Y(1 downto 0);
   tile_10_mult: IntMultiplierLUT_3x2_comb_uid45
      port map ( X => tile_10_X,
                 Y => tile_10_Y,
                 R => tile_10_output);

   tile_10_filtered_output <= unsigned(tile_10_output(4 downto 0));
   bh3_wm7_1 <= tile_10_filtered_output(0);
   bh3_wm6_2 <= tile_10_filtered_output(1);
   bh3_wm5_3 <= tile_10_filtered_output(2);
   bh3_wm4_5 <= tile_10_filtered_output(3);
   bh3_wm3_5 <= tile_10_filtered_output(4);
   tile_11_X <= X(2 downto 0);
   tile_11_Y <= Y(1 downto 0);
   tile_11_mult: IntMultiplierLUT_3x2_comb_uid49
      port map ( X => tile_11_X,
                 Y => tile_11_Y,
                 R => tile_11_output);

   tile_11_filtered_output <= unsigned(tile_11_output(4 downto 0));
   bh3_wm10_0 <= tile_11_filtered_output(0);
   bh3_wm9_0 <= tile_11_filtered_output(1);
   bh3_wm8_1 <= tile_11_filtered_output(2);
   bh3_wm7_2 <= tile_11_filtered_output(3);
   bh3_wm6_3 <= tile_11_filtered_output(4);
   bh3_wm10_1 <= AA(0);
   bh3_wm9_1 <= AA(1);
   bh3_wm8_2 <= AA(2);
   bh3_wm7_3 <= AA(3);
   bh3_wm6_4 <= AA(4);
   bh3_wm5_4 <= AA(5);
   bh3_wm4_6 <= AA(6);
   bh3_wm3_6 <= AA(7);
   bh3_wm2_6 <= AA(8);
   bh3_wm1_6 <= AA(9);
   bh3_w0_5 <= AA(10);
   bh3_w1_4 <= AA(11);
   bh3_w2_3 <= AA(12);
   bh3_w3_3 <= AA(13);
   bh3_w4_1 <= AA(14);
   bh3_w5_1 <= AA(15);

   -- Adding the constant bits 
   bh3_wm1_7 <= '1';
   bh3_w2_4 <= '1';
   bh3_w3_4 <= '1';


   Compressor_23_3_comb_uid54_bh3_uid55_In0 <= "" & bh3_wm10_1 & bh3_wm10_0 & "0";
   Compressor_23_3_comb_uid54_bh3_uid55_In1 <= "" & bh3_wm9_1 & bh3_wm9_0;
   bh3_wm10_2 <= Compressor_23_3_comb_uid54_bh3_uid55_Out0(0);
   bh3_wm9_2 <= Compressor_23_3_comb_uid54_bh3_uid55_Out0(1);
   bh3_wm8_3 <= Compressor_23_3_comb_uid54_bh3_uid55_Out0(2);
   Compressor_23_3_comb_uid54_uid55: Compressor_23_3_comb_uid54
      port map ( X0 => Compressor_23_3_comb_uid54_bh3_uid55_In0,
                 X1 => Compressor_23_3_comb_uid54_bh3_uid55_In1,
                 R => Compressor_23_3_comb_uid54_bh3_uid55_Out0);


   Compressor_3_2_comb_uid57_bh3_uid58_In0 <= "" & bh3_wm8_2 & bh3_wm8_0 & bh3_wm8_1;
   bh3_wm8_4 <= Compressor_3_2_comb_uid57_bh3_uid58_Out0(0);
   bh3_wm7_4 <= Compressor_3_2_comb_uid57_bh3_uid58_Out0(1);
   Compressor_3_2_comb_uid57_uid58: Compressor_3_2_comb_uid57
      port map ( X0 => Compressor_3_2_comb_uid57_bh3_uid58_In0,
                 R => Compressor_3_2_comb_uid57_bh3_uid58_Out0);


   Compressor_14_3_comb_uid60_bh3_uid61_In0 <= "" & bh3_wm7_3 & bh3_wm7_0 & bh3_wm7_1 & bh3_wm7_2;
   Compressor_14_3_comb_uid60_bh3_uid61_In1 <= "" & bh3_wm6_4;
   bh3_wm7_5 <= Compressor_14_3_comb_uid60_bh3_uid61_Out0(0);
   bh3_wm6_5 <= Compressor_14_3_comb_uid60_bh3_uid61_Out0(1);
   bh3_wm5_5 <= Compressor_14_3_comb_uid60_bh3_uid61_Out0(2);
   Compressor_14_3_comb_uid60_uid61: Compressor_14_3_comb_uid60
      port map ( X0 => Compressor_14_3_comb_uid60_bh3_uid61_In0,
                 X1 => Compressor_14_3_comb_uid60_bh3_uid61_In1,
                 R => Compressor_14_3_comb_uid60_bh3_uid61_Out0);


   Compressor_14_3_comb_uid60_bh3_uid62_In0 <= "" & bh3_wm6_0 & bh3_wm6_1 & bh3_wm6_2 & bh3_wm6_3;
   Compressor_14_3_comb_uid60_bh3_uid62_In1 <= "" & bh3_wm5_4;
   bh3_wm6_6 <= Compressor_14_3_comb_uid60_bh3_uid62_Out0(0);
   bh3_wm5_6 <= Compressor_14_3_comb_uid60_bh3_uid62_Out0(1);
   bh3_wm4_7 <= Compressor_14_3_comb_uid60_bh3_uid62_Out0(2);
   Compressor_14_3_comb_uid60_uid62: Compressor_14_3_comb_uid60
      port map ( X0 => Compressor_14_3_comb_uid60_bh3_uid62_In0,
                 X1 => Compressor_14_3_comb_uid60_bh3_uid62_In1,
                 R => Compressor_14_3_comb_uid60_bh3_uid62_Out0);


   Compressor_14_3_comb_uid60_bh3_uid63_In0 <= "" & bh3_wm5_0 & bh3_wm5_1 & bh3_wm5_2 & bh3_wm5_3;
   Compressor_14_3_comb_uid60_bh3_uid63_In1 <= "" & bh3_wm4_6;
   bh3_wm5_7 <= Compressor_14_3_comb_uid60_bh3_uid63_Out0(0);
   bh3_wm4_8 <= Compressor_14_3_comb_uid60_bh3_uid63_Out0(1);
   bh3_wm3_7 <= Compressor_14_3_comb_uid60_bh3_uid63_Out0(2);
   Compressor_14_3_comb_uid60_uid63: Compressor_14_3_comb_uid60
      port map ( X0 => Compressor_14_3_comb_uid60_bh3_uid63_In0,
                 X1 => Compressor_14_3_comb_uid60_bh3_uid63_In1,
                 R => Compressor_14_3_comb_uid60_bh3_uid63_Out0);


   Compressor_6_3_comb_uid65_bh3_uid66_In0 <= "" & bh3_wm4_0 & bh3_wm4_1 & bh3_wm4_2 & bh3_wm4_3 & bh3_wm4_4 & bh3_wm4_5;
   bh3_wm4_9 <= Compressor_6_3_comb_uid65_bh3_uid66_Out0(0);
   bh3_wm3_8 <= Compressor_6_3_comb_uid65_bh3_uid66_Out0(1);
   bh3_wm2_7 <= Compressor_6_3_comb_uid65_bh3_uid66_Out0(2);
   Compressor_6_3_comb_uid65_uid66: Compressor_6_3_comb_uid65
      port map ( X0 => Compressor_6_3_comb_uid65_bh3_uid66_In0,
                 R => Compressor_6_3_comb_uid65_bh3_uid66_Out0);


   Compressor_6_3_comb_uid65_bh3_uid67_In0 <= "" & bh3_wm3_6 & bh3_wm3_0 & bh3_wm3_1 & bh3_wm3_2 & bh3_wm3_3 & bh3_wm3_4;
   bh3_wm3_9 <= Compressor_6_3_comb_uid65_bh3_uid67_Out0(0);
   bh3_wm2_8 <= Compressor_6_3_comb_uid65_bh3_uid67_Out0(1);
   bh3_wm1_8 <= Compressor_6_3_comb_uid65_bh3_uid67_Out0(2);
   Compressor_6_3_comb_uid65_uid67: Compressor_6_3_comb_uid65
      port map ( X0 => Compressor_6_3_comb_uid65_bh3_uid67_In0,
                 R => Compressor_6_3_comb_uid65_bh3_uid67_Out0);


   Compressor_6_3_comb_uid65_bh3_uid68_In0 <= "" & bh3_wm2_6 & bh3_wm2_0 & bh3_wm2_1 & bh3_wm2_2 & "0" & "0";
   bh3_wm2_9 <= Compressor_6_3_comb_uid65_bh3_uid68_Out0(0);
   bh3_wm1_9 <= Compressor_6_3_comb_uid65_bh3_uid68_Out0(1);
   bh3_w0_6 <= Compressor_6_3_comb_uid65_bh3_uid68_Out0(2);
   Compressor_6_3_comb_uid65_uid68: Compressor_6_3_comb_uid65
      port map ( X0 => Compressor_6_3_comb_uid65_bh3_uid68_In0,
                 R => Compressor_6_3_comb_uid65_bh3_uid68_Out0);


   Compressor_23_3_comb_uid54_bh3_uid69_In0 <= "" & bh3_wm2_3 & bh3_wm2_4 & bh3_wm2_5;
   Compressor_23_3_comb_uid54_bh3_uid69_In1 <= "" & bh3_wm1_6 & bh3_wm1_7;
   bh3_wm2_10 <= Compressor_23_3_comb_uid54_bh3_uid69_Out0(0);
   bh3_wm1_10 <= Compressor_23_3_comb_uid54_bh3_uid69_Out0(1);
   bh3_w0_7 <= Compressor_23_3_comb_uid54_bh3_uid69_Out0(2);
   Compressor_23_3_comb_uid54_uid69: Compressor_23_3_comb_uid54
      port map ( X0 => Compressor_23_3_comb_uid54_bh3_uid69_In0,
                 X1 => Compressor_23_3_comb_uid54_bh3_uid69_In1,
                 R => Compressor_23_3_comb_uid54_bh3_uid69_Out0);


   Compressor_6_3_comb_uid65_bh3_uid70_In0 <= "" & bh3_wm1_0 & bh3_wm1_1 & bh3_wm1_2 & bh3_wm1_3 & bh3_wm1_4 & bh3_wm1_5;
   bh3_wm1_11 <= Compressor_6_3_comb_uid65_bh3_uid70_Out0(0);
   bh3_w0_8 <= Compressor_6_3_comb_uid65_bh3_uid70_Out0(1);
   bh3_w1_5 <= Compressor_6_3_comb_uid65_bh3_uid70_Out0(2);
   Compressor_6_3_comb_uid65_uid70: Compressor_6_3_comb_uid65
      port map ( X0 => Compressor_6_3_comb_uid65_bh3_uid70_In0,
                 R => Compressor_6_3_comb_uid65_bh3_uid70_Out0);


   Compressor_6_3_comb_uid65_bh3_uid71_In0 <= "" & bh3_w0_5 & bh3_w0_0 & bh3_w0_1 & bh3_w0_2 & bh3_w0_3 & bh3_w0_4;
   bh3_w0_9 <= Compressor_6_3_comb_uid65_bh3_uid71_Out0(0);
   bh3_w1_6 <= Compressor_6_3_comb_uid65_bh3_uid71_Out0(1);
   bh3_w2_5 <= Compressor_6_3_comb_uid65_bh3_uid71_Out0(2);
   Compressor_6_3_comb_uid65_uid71: Compressor_6_3_comb_uid65
      port map ( X0 => Compressor_6_3_comb_uid65_bh3_uid71_In0,
                 R => Compressor_6_3_comb_uid65_bh3_uid71_Out0);


   Compressor_14_3_comb_uid60_bh3_uid72_In0 <= "" & bh3_w1_4 & bh3_w1_0 & bh3_w1_1 & bh3_w1_2;
   Compressor_14_3_comb_uid60_bh3_uid72_In1 <= "" & bh3_w2_3;
   bh3_w1_7 <= Compressor_14_3_comb_uid60_bh3_uid72_Out0(0);
   bh3_w2_6 <= Compressor_14_3_comb_uid60_bh3_uid72_Out0(1);
   bh3_w3_5 <= Compressor_14_3_comb_uid60_bh3_uid72_Out0(2);
   Compressor_14_3_comb_uid60_uid72: Compressor_14_3_comb_uid60
      port map ( X0 => Compressor_14_3_comb_uid60_bh3_uid72_In0,
                 X1 => Compressor_14_3_comb_uid60_bh3_uid72_In1,
                 R => Compressor_14_3_comb_uid60_bh3_uid72_Out0);


   Compressor_14_3_comb_uid60_bh3_uid73_In0 <= "" & bh3_w2_4 & bh3_w2_0 & bh3_w2_1 & bh3_w2_2;
   Compressor_14_3_comb_uid60_bh3_uid73_In1 <= "" & bh3_w3_3;
   bh3_w2_7 <= Compressor_14_3_comb_uid60_bh3_uid73_Out0(0);
   bh3_w3_6 <= Compressor_14_3_comb_uid60_bh3_uid73_Out0(1);
   bh3_w4_2 <= Compressor_14_3_comb_uid60_bh3_uid73_Out0(2);
   Compressor_14_3_comb_uid60_uid73: Compressor_14_3_comb_uid60
      port map ( X0 => Compressor_14_3_comb_uid60_bh3_uid73_In0,
                 X1 => Compressor_14_3_comb_uid60_bh3_uid73_In1,
                 R => Compressor_14_3_comb_uid60_bh3_uid73_Out0);


   Compressor_14_3_comb_uid60_bh3_uid74_In0 <= "" & bh3_w3_4 & bh3_w3_0 & bh3_w3_1 & bh3_w3_2;
   Compressor_14_3_comb_uid60_bh3_uid74_In1 <= "" & "0";
   bh3_w3_7 <= Compressor_14_3_comb_uid60_bh3_uid74_Out0(0);
   bh3_w4_3 <= Compressor_14_3_comb_uid60_bh3_uid74_Out0(1);
   bh3_w5_2 <= Compressor_14_3_comb_uid60_bh3_uid74_Out0(2);
   Compressor_14_3_comb_uid60_uid74: Compressor_14_3_comb_uid60
      port map ( X0 => Compressor_14_3_comb_uid60_bh3_uid74_In0,
                 X1 => Compressor_14_3_comb_uid60_bh3_uid74_In1,
                 R => Compressor_14_3_comb_uid60_bh3_uid74_Out0);


   Compressor_23_3_comb_uid54_bh3_uid75_In0 <= "" & bh3_w4_1 & bh3_w4_0 & "0";
   Compressor_23_3_comb_uid54_bh3_uid75_In1 <= "" & bh3_w5_1 & bh3_w5_0;
   bh3_w4_4 <= Compressor_23_3_comb_uid54_bh3_uid75_Out0(0);
   bh3_w5_3 <= Compressor_23_3_comb_uid54_bh3_uid75_Out0(1);
   Compressor_23_3_comb_uid54_uid75: Compressor_23_3_comb_uid54
      port map ( X0 => Compressor_23_3_comb_uid54_bh3_uid75_In0,
                 X1 => Compressor_23_3_comb_uid54_bh3_uid75_In1,
                 R => Compressor_23_3_comb_uid54_bh3_uid75_Out0);


   Compressor_23_3_comb_uid54_bh3_uid76_In0 <= "" & bh3_wm8_4 & bh3_wm8_3 & "0";
   Compressor_23_3_comb_uid54_bh3_uid76_In1 <= "" & bh3_wm7_5 & bh3_wm7_4;
   bh3_wm8_5 <= Compressor_23_3_comb_uid54_bh3_uid76_Out0(0);
   bh3_wm7_6 <= Compressor_23_3_comb_uid54_bh3_uid76_Out0(1);
   bh3_wm6_7 <= Compressor_23_3_comb_uid54_bh3_uid76_Out0(2);
   Compressor_23_3_comb_uid54_uid76: Compressor_23_3_comb_uid54
      port map ( X0 => Compressor_23_3_comb_uid54_bh3_uid76_In0,
                 X1 => Compressor_23_3_comb_uid54_bh3_uid76_In1,
                 R => Compressor_23_3_comb_uid54_bh3_uid76_Out0);


   Compressor_3_2_comb_uid57_bh3_uid77_In0 <= "" & bh3_wm6_6 & bh3_wm6_5 & "0";
   bh3_wm6_8 <= Compressor_3_2_comb_uid57_bh3_uid77_Out0(0);
   bh3_wm5_8 <= Compressor_3_2_comb_uid57_bh3_uid77_Out0(1);
   Compressor_3_2_comb_uid57_uid77: Compressor_3_2_comb_uid57
      port map ( X0 => Compressor_3_2_comb_uid57_bh3_uid77_In0,
                 R => Compressor_3_2_comb_uid57_bh3_uid77_Out0);


   Compressor_23_3_comb_uid54_bh3_uid78_In0 <= "" & bh3_wm5_7 & bh3_wm5_6 & bh3_wm5_5;
   Compressor_23_3_comb_uid54_bh3_uid78_In1 <= "" & bh3_wm4_8 & bh3_wm4_7;
   bh3_wm5_9 <= Compressor_23_3_comb_uid54_bh3_uid78_Out0(0);
   bh3_wm4_10 <= Compressor_23_3_comb_uid54_bh3_uid78_Out0(1);
   bh3_wm3_10 <= Compressor_23_3_comb_uid54_bh3_uid78_Out0(2);
   Compressor_23_3_comb_uid54_uid78: Compressor_23_3_comb_uid54
      port map ( X0 => Compressor_23_3_comb_uid54_bh3_uid78_In0,
                 X1 => Compressor_23_3_comb_uid54_bh3_uid78_In1,
                 R => Compressor_23_3_comb_uid54_bh3_uid78_Out0);


   Compressor_14_3_comb_uid60_bh3_uid79_In0 <= "" & bh3_wm3_5 & bh3_wm3_7 & bh3_wm3_9 & bh3_wm3_8;
   Compressor_14_3_comb_uid60_bh3_uid79_In1 <= "" & bh3_wm2_10;
   bh3_wm3_11 <= Compressor_14_3_comb_uid60_bh3_uid79_Out0(0);
   bh3_wm2_11 <= Compressor_14_3_comb_uid60_bh3_uid79_Out0(1);
   bh3_wm1_12 <= Compressor_14_3_comb_uid60_bh3_uid79_Out0(2);
   Compressor_14_3_comb_uid60_uid79: Compressor_14_3_comb_uid60
      port map ( X0 => Compressor_14_3_comb_uid60_bh3_uid79_In0,
                 X1 => Compressor_14_3_comb_uid60_bh3_uid79_In1,
                 R => Compressor_14_3_comb_uid60_bh3_uid79_Out0);


   Compressor_3_2_comb_uid57_bh3_uid80_In0 <= "" & bh3_wm2_9 & bh3_wm2_8 & bh3_wm2_7;
   bh3_wm2_12 <= Compressor_3_2_comb_uid57_bh3_uid80_Out0(0);
   bh3_wm1_13 <= Compressor_3_2_comb_uid57_bh3_uid80_Out0(1);
   Compressor_3_2_comb_uid57_uid80: Compressor_3_2_comb_uid57
      port map ( X0 => Compressor_3_2_comb_uid57_bh3_uid80_In0,
                 R => Compressor_3_2_comb_uid57_bh3_uid80_Out0);


   Compressor_14_3_comb_uid60_bh3_uid81_In0 <= "" & bh3_wm1_10 & bh3_wm1_11 & bh3_wm1_9 & bh3_wm1_8;
   Compressor_14_3_comb_uid60_bh3_uid81_In1 <= "" & bh3_w0_7;
   bh3_wm1_14 <= Compressor_14_3_comb_uid60_bh3_uid81_Out0(0);
   bh3_w0_10 <= Compressor_14_3_comb_uid60_bh3_uid81_Out0(1);
   bh3_w1_8 <= Compressor_14_3_comb_uid60_bh3_uid81_Out0(2);
   Compressor_14_3_comb_uid60_uid81: Compressor_14_3_comb_uid60
      port map ( X0 => Compressor_14_3_comb_uid60_bh3_uid81_In0,
                 X1 => Compressor_14_3_comb_uid60_bh3_uid81_In1,
                 R => Compressor_14_3_comb_uid60_bh3_uid81_Out0);


   Compressor_3_2_comb_uid57_bh3_uid82_In0 <= "" & bh3_w0_9 & bh3_w0_8 & bh3_w0_6;
   bh3_w0_11 <= Compressor_3_2_comb_uid57_bh3_uid82_Out0(0);
   bh3_w1_9 <= Compressor_3_2_comb_uid57_bh3_uid82_Out0(1);
   Compressor_3_2_comb_uid57_uid82: Compressor_3_2_comb_uid57
      port map ( X0 => Compressor_3_2_comb_uid57_bh3_uid82_In0,
                 R => Compressor_3_2_comb_uid57_bh3_uid82_Out0);


   Compressor_14_3_comb_uid60_bh3_uid83_In0 <= "" & bh3_w1_3 & bh3_w1_7 & bh3_w1_6 & bh3_w1_5;
   Compressor_14_3_comb_uid60_bh3_uid83_In1 <= "" & "0";
   bh3_w1_10 <= Compressor_14_3_comb_uid60_bh3_uid83_Out0(0);
   bh3_w2_8 <= Compressor_14_3_comb_uid60_bh3_uid83_Out0(1);
   bh3_w3_8 <= Compressor_14_3_comb_uid60_bh3_uid83_Out0(2);
   Compressor_14_3_comb_uid60_uid83: Compressor_14_3_comb_uid60
      port map ( X0 => Compressor_14_3_comb_uid60_bh3_uid83_In0,
                 X1 => Compressor_14_3_comb_uid60_bh3_uid83_In1,
                 R => Compressor_14_3_comb_uid60_bh3_uid83_Out0);


   Compressor_3_2_comb_uid57_bh3_uid84_In0 <= "" & bh3_w2_7 & bh3_w2_6 & bh3_w2_5;
   bh3_w2_9 <= Compressor_3_2_comb_uid57_bh3_uid84_Out0(0);
   bh3_w3_9 <= Compressor_3_2_comb_uid57_bh3_uid84_Out0(1);
   Compressor_3_2_comb_uid57_uid84: Compressor_3_2_comb_uid57
      port map ( X0 => Compressor_3_2_comb_uid57_bh3_uid84_In0,
                 R => Compressor_3_2_comb_uid57_bh3_uid84_Out0);


   Compressor_23_3_comb_uid54_bh3_uid85_In0 <= "" & bh3_w3_7 & bh3_w3_6 & bh3_w3_5;
   Compressor_23_3_comb_uid54_bh3_uid85_In1 <= "" & bh3_w4_4 & bh3_w4_3;
   bh3_w3_10 <= Compressor_23_3_comb_uid54_bh3_uid85_Out0(0);
   bh3_w4_5 <= Compressor_23_3_comb_uid54_bh3_uid85_Out0(1);
   bh3_w5_4 <= Compressor_23_3_comb_uid54_bh3_uid85_Out0(2);
   Compressor_23_3_comb_uid54_uid85: Compressor_23_3_comb_uid54
      port map ( X0 => Compressor_23_3_comb_uid54_bh3_uid85_In0,
                 X1 => Compressor_23_3_comb_uid54_bh3_uid85_In1,
                 R => Compressor_23_3_comb_uid54_bh3_uid85_Out0);


   Compressor_14_3_comb_uid60_bh3_uid86_In0 <= "" & bh3_w5_3 & bh3_w5_2 & "0" & "0";
   Compressor_14_3_comb_uid60_bh3_uid86_In1 <= "" & "0";
   bh3_w5_5 <= Compressor_14_3_comb_uid60_bh3_uid86_Out0(0);
   Compressor_14_3_comb_uid60_uid86: Compressor_14_3_comb_uid60
      port map ( X0 => Compressor_14_3_comb_uid60_bh3_uid86_In0,
                 X1 => Compressor_14_3_comb_uid60_bh3_uid86_In1,
                 R => Compressor_14_3_comb_uid60_bh3_uid86_Out0);


   Compressor_23_3_comb_uid54_bh3_uid87_In0 <= "" & bh3_wm6_8 & bh3_wm6_7 & "0";
   Compressor_23_3_comb_uid54_bh3_uid87_In1 <= "" & bh3_wm5_9 & bh3_wm5_8;
   bh3_wm6_9 <= Compressor_23_3_comb_uid54_bh3_uid87_Out0(0);
   bh3_wm5_10 <= Compressor_23_3_comb_uid54_bh3_uid87_Out0(1);
   bh3_wm4_11 <= Compressor_23_3_comb_uid54_bh3_uid87_Out0(2);
   Compressor_23_3_comb_uid54_uid87: Compressor_23_3_comb_uid54
      port map ( X0 => Compressor_23_3_comb_uid54_bh3_uid87_In0,
                 X1 => Compressor_23_3_comb_uid54_bh3_uid87_In1,
                 R => Compressor_23_3_comb_uid54_bh3_uid87_Out0);


   Compressor_23_3_comb_uid54_bh3_uid88_In0 <= "" & bh3_wm4_9 & bh3_wm4_10 & "0";
   Compressor_23_3_comb_uid54_bh3_uid88_In1 <= "" & bh3_wm3_10 & bh3_wm3_11;
   bh3_wm4_12 <= Compressor_23_3_comb_uid54_bh3_uid88_Out0(0);
   bh3_wm3_12 <= Compressor_23_3_comb_uid54_bh3_uid88_Out0(1);
   bh3_wm2_13 <= Compressor_23_3_comb_uid54_bh3_uid88_Out0(2);
   Compressor_23_3_comb_uid54_uid88: Compressor_23_3_comb_uid54
      port map ( X0 => Compressor_23_3_comb_uid54_bh3_uid88_In0,
                 X1 => Compressor_23_3_comb_uid54_bh3_uid88_In1,
                 R => Compressor_23_3_comb_uid54_bh3_uid88_Out0);


   Compressor_3_2_comb_uid57_bh3_uid89_In0 <= "" & bh3_wm2_12 & bh3_wm2_11 & "0";
   bh3_wm2_14 <= Compressor_3_2_comb_uid57_bh3_uid89_Out0(0);
   bh3_wm1_15 <= Compressor_3_2_comb_uid57_bh3_uid89_Out0(1);
   Compressor_3_2_comb_uid57_uid89: Compressor_3_2_comb_uid57
      port map ( X0 => Compressor_3_2_comb_uid57_bh3_uid89_In0,
                 R => Compressor_3_2_comb_uid57_bh3_uid89_Out0);


   Compressor_23_3_comb_uid54_bh3_uid90_In0 <= "" & bh3_wm1_14 & bh3_wm1_13 & bh3_wm1_12;
   Compressor_23_3_comb_uid54_bh3_uid90_In1 <= "" & bh3_w0_11 & bh3_w0_10;
   bh3_wm1_16 <= Compressor_23_3_comb_uid54_bh3_uid90_Out0(0);
   bh3_w0_12 <= Compressor_23_3_comb_uid54_bh3_uid90_Out0(1);
   bh3_w1_11 <= Compressor_23_3_comb_uid54_bh3_uid90_Out0(2);
   Compressor_23_3_comb_uid54_uid90: Compressor_23_3_comb_uid54
      port map ( X0 => Compressor_23_3_comb_uid54_bh3_uid90_In0,
                 X1 => Compressor_23_3_comb_uid54_bh3_uid90_In1,
                 R => Compressor_23_3_comb_uid54_bh3_uid90_Out0);


   Compressor_23_3_comb_uid54_bh3_uid91_In0 <= "" & bh3_w1_10 & bh3_w1_9 & bh3_w1_8;
   Compressor_23_3_comb_uid54_bh3_uid91_In1 <= "" & bh3_w2_9 & bh3_w2_8;
   bh3_w1_12 <= Compressor_23_3_comb_uid54_bh3_uid91_Out0(0);
   bh3_w2_10 <= Compressor_23_3_comb_uid54_bh3_uid91_Out0(1);
   bh3_w3_11 <= Compressor_23_3_comb_uid54_bh3_uid91_Out0(2);
   Compressor_23_3_comb_uid54_uid91: Compressor_23_3_comb_uid54
      port map ( X0 => Compressor_23_3_comb_uid54_bh3_uid91_In0,
                 X1 => Compressor_23_3_comb_uid54_bh3_uid91_In1,
                 R => Compressor_23_3_comb_uid54_bh3_uid91_Out0);


   Compressor_23_3_comb_uid54_bh3_uid92_In0 <= "" & bh3_w3_10 & bh3_w3_9 & bh3_w3_8;
   Compressor_23_3_comb_uid54_bh3_uid92_In1 <= "" & bh3_w4_2 & bh3_w4_5;
   bh3_w3_12 <= Compressor_23_3_comb_uid54_bh3_uid92_Out0(0);
   bh3_w4_6 <= Compressor_23_3_comb_uid54_bh3_uid92_Out0(1);
   bh3_w5_6 <= Compressor_23_3_comb_uid54_bh3_uid92_Out0(2);
   Compressor_23_3_comb_uid54_uid92: Compressor_23_3_comb_uid54
      port map ( X0 => Compressor_23_3_comb_uid54_bh3_uid92_In0,
                 X1 => Compressor_23_3_comb_uid54_bh3_uid92_In1,
                 R => Compressor_23_3_comb_uid54_bh3_uid92_Out0);


   Compressor_14_3_comb_uid60_bh3_uid93_In0 <= "" & bh3_w5_5 & bh3_w5_4 & "0" & "0";
   Compressor_14_3_comb_uid60_bh3_uid93_In1 <= "" & "0";
   bh3_w5_7 <= Compressor_14_3_comb_uid60_bh3_uid93_Out0(0);
   Compressor_14_3_comb_uid60_uid93: Compressor_14_3_comb_uid60
      port map ( X0 => Compressor_14_3_comb_uid60_bh3_uid93_In0,
                 X1 => Compressor_14_3_comb_uid60_bh3_uid93_In1,
                 R => Compressor_14_3_comb_uid60_bh3_uid93_Out0);

   tmp_bitheapResult_bh3_5 <= bh3_wm5_10 & bh3_wm6_9 & bh3_wm7_6 & bh3_wm8_5 & bh3_wm9_2 & bh3_wm10_2;

   bitheapFinalAdd_bh3_In0 <= "0" & bh3_w5_7 & bh3_w4_6 & bh3_w3_12 & bh3_w2_10 & bh3_w1_12 & bh3_w0_12 & bh3_wm1_16 & bh3_wm2_14 & bh3_wm3_12 & bh3_wm4_11;
   bitheapFinalAdd_bh3_In1 <= "0" & bh3_w5_6 & "0" & bh3_w3_11 & "0" & bh3_w1_11 & "0" & bh3_wm1_15 & bh3_wm2_13 & "0" & bh3_wm4_12;
   bitheapFinalAdd_bh3_Cin <= '0';

   bitheapFinalAdd_bh3: IntAdder_11_comb_uid95
      port map ( Cin => bitheapFinalAdd_bh3_Cin,
                 X => bitheapFinalAdd_bh3_In0,
                 Y => bitheapFinalAdd_bh3_In1,
                 R => bitheapFinalAdd_bh3_Out);
   bitheapResult_bh3 <= bitheapFinalAdd_bh3_Out(9 downto 0) & tmp_bitheapResult_bh3_5;
   RR <= signed(bitheapResult_bh3(15 downto 0));
R <= std_logic_vector(RR);  
end architecture;

