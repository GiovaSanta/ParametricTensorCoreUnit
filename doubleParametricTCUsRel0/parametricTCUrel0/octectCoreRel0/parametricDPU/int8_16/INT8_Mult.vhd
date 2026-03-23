--------------------------------------------------------------------------------
--                            MultTable_comb_uid8
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

entity MultTable_comb_uid8 is
    port (X : in  std_logic_vector(3 downto 0);
          Y : out  std_logic_vector(3 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid8 is
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
--                            MultTable_comb_uid12
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

entity MultTable_comb_uid12 is
    port (X : in  std_logic_vector(4 downto 0);
          Y : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid12 is
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
--                            MultTable_comb_uid16
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

entity MultTable_comb_uid16 is
    port (X : in  std_logic_vector(4 downto 0);
          Y : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid16 is
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
--                            MultTable_comb_uid20
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

entity MultTable_comb_uid20 is
    port (X : in  std_logic_vector(3 downto 0);
          Y : out  std_logic_vector(3 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid20 is
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
--                            MultTable_comb_uid24
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

entity MultTable_comb_uid24 is
    port (X : in  std_logic_vector(4 downto 0);
          Y : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid24 is
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
--                            MultTable_comb_uid28
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

entity MultTable_comb_uid28 is
    port (X : in  std_logic_vector(4 downto 0);
          Y : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid28 is
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
--                            MultTable_comb_uid32
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

entity MultTable_comb_uid32 is
    port (X : in  std_logic_vector(3 downto 0);
          Y : out  std_logic_vector(3 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid32 is
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
--                            MultTable_comb_uid36
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

entity MultTable_comb_uid36 is
    port (X : in  std_logic_vector(4 downto 0);
          Y : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid36 is
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
--                            MultTable_comb_uid40
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

entity MultTable_comb_uid40 is
    port (X : in  std_logic_vector(4 downto 0);
          Y : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid40 is
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
--                            MultTable_comb_uid44
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

entity MultTable_comb_uid44 is
    port (X : in  std_logic_vector(3 downto 0);
          Y : out  std_logic_vector(3 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid44 is
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
--                            MultTable_comb_uid48
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

entity MultTable_comb_uid48 is
    port (X : in  std_logic_vector(4 downto 0);
          Y : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid48 is
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
--                            MultTable_comb_uid52
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

entity MultTable_comb_uid52 is
    port (X : in  std_logic_vector(4 downto 0);
          Y : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of MultTable_comb_uid52 is
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
--                         Compressor_23_3_comb_uid55
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

entity Compressor_23_3_comb_uid55 is
    port (X1 : in  std_logic_vector(1 downto 0);
          X0 : in  std_logic_vector(2 downto 0);
          R : out  std_logic_vector(2 downto 0)   );
end entity;

architecture arch of Compressor_23_3_comb_uid55 is
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
--                         Compressor_3_2_comb_uid58
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

entity Compressor_3_2_comb_uid58 is
    port (X0 : in  std_logic_vector(2 downto 0);
          R : out  std_logic_vector(1 downto 0)   );
end entity;

architecture arch of Compressor_3_2_comb_uid58 is
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
--                         Compressor_14_3_comb_uid61
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

entity Compressor_14_3_comb_uid61 is
    port (X1 : in  std_logic_vector(0 downto 0);
          X0 : in  std_logic_vector(3 downto 0);
          R : out  std_logic_vector(2 downto 0)   );
end entity;

architecture arch of Compressor_14_3_comb_uid61 is
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
--                IntMultiplierLUT_2_signedx2_signed_comb_uid6
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

entity IntMultiplierLUT_2_signedx2_signed_comb_uid6 is
    port (X : in  std_logic_vector(1 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(3 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_2_signedx2_signed_comb_uid6 is
   component MultTable_comb_uid8 is
      port ( X : in  std_logic_vector(3 downto 0);
             Y : out  std_logic_vector(3 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(3 downto 0);
signal Y1 :  std_logic_vector(3 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid8
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                   IntMultiplierLUT_3x2_signed_comb_uid10
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

entity IntMultiplierLUT_3x2_signed_comb_uid10 is
    port (X : in  std_logic_vector(2 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_3x2_signed_comb_uid10 is
   component MultTable_comb_uid12 is
      port ( X : in  std_logic_vector(4 downto 0);
             Y : out  std_logic_vector(4 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(4 downto 0);
signal Y1 :  std_logic_vector(4 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid12
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                   IntMultiplierLUT_3x2_signed_comb_uid14
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

entity IntMultiplierLUT_3x2_signed_comb_uid14 is
    port (X : in  std_logic_vector(2 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_3x2_signed_comb_uid14 is
   component MultTable_comb_uid16 is
      port ( X : in  std_logic_vector(4 downto 0);
             Y : out  std_logic_vector(4 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(4 downto 0);
signal Y1 :  std_logic_vector(4 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid16
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                   IntMultiplierLUT_2_signedx2_comb_uid18
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

entity IntMultiplierLUT_2_signedx2_comb_uid18 is
    port (X : in  std_logic_vector(1 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(3 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_2_signedx2_comb_uid18 is
   component MultTable_comb_uid20 is
      port ( X : in  std_logic_vector(3 downto 0);
             Y : out  std_logic_vector(3 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(3 downto 0);
signal Y1 :  std_logic_vector(3 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid20
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                      IntMultiplierLUT_3x2_comb_uid22
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

entity IntMultiplierLUT_3x2_comb_uid22 is
    port (X : in  std_logic_vector(2 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_3x2_comb_uid22 is
   component MultTable_comb_uid24 is
      port ( X : in  std_logic_vector(4 downto 0);
             Y : out  std_logic_vector(4 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(4 downto 0);
signal Y1 :  std_logic_vector(4 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid24
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                      IntMultiplierLUT_3x2_comb_uid26
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

entity IntMultiplierLUT_3x2_comb_uid26 is
    port (X : in  std_logic_vector(2 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_3x2_comb_uid26 is
   component MultTable_comb_uid28 is
      port ( X : in  std_logic_vector(4 downto 0);
             Y : out  std_logic_vector(4 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(4 downto 0);
signal Y1 :  std_logic_vector(4 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid28
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                   IntMultiplierLUT_2_signedx2_comb_uid30
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

entity IntMultiplierLUT_2_signedx2_comb_uid30 is
    port (X : in  std_logic_vector(1 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(3 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_2_signedx2_comb_uid30 is
   component MultTable_comb_uid32 is
      port ( X : in  std_logic_vector(3 downto 0);
             Y : out  std_logic_vector(3 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(3 downto 0);
signal Y1 :  std_logic_vector(3 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid32
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                      IntMultiplierLUT_3x2_comb_uid34
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

entity IntMultiplierLUT_3x2_comb_uid34 is
    port (X : in  std_logic_vector(2 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_3x2_comb_uid34 is
   component MultTable_comb_uid36 is
      port ( X : in  std_logic_vector(4 downto 0);
             Y : out  std_logic_vector(4 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(4 downto 0);
signal Y1 :  std_logic_vector(4 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid36
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                      IntMultiplierLUT_3x2_comb_uid38
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

entity IntMultiplierLUT_3x2_comb_uid38 is
    port (X : in  std_logic_vector(2 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_3x2_comb_uid38 is
   component MultTable_comb_uid40 is
      port ( X : in  std_logic_vector(4 downto 0);
             Y : out  std_logic_vector(4 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(4 downto 0);
signal Y1 :  std_logic_vector(4 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid40
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                   IntMultiplierLUT_2_signedx2_comb_uid42
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

entity IntMultiplierLUT_2_signedx2_comb_uid42 is
    port (X : in  std_logic_vector(1 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(3 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_2_signedx2_comb_uid42 is
   component MultTable_comb_uid44 is
      port ( X : in  std_logic_vector(3 downto 0);
             Y : out  std_logic_vector(3 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(3 downto 0);
signal Y1 :  std_logic_vector(3 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid44
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                      IntMultiplierLUT_3x2_comb_uid46
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

entity IntMultiplierLUT_3x2_comb_uid46 is
    port (X : in  std_logic_vector(2 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_3x2_comb_uid46 is
   component MultTable_comb_uid48 is
      port ( X : in  std_logic_vector(4 downto 0);
             Y : out  std_logic_vector(4 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(4 downto 0);
signal Y1 :  std_logic_vector(4 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid48
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                      IntMultiplierLUT_3x2_comb_uid50
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

entity IntMultiplierLUT_3x2_comb_uid50 is
    port (X : in  std_logic_vector(2 downto 0);
          Y : in  std_logic_vector(1 downto 0);
          R : out  std_logic_vector(4 downto 0)   );
end entity;

architecture arch of IntMultiplierLUT_3x2_comb_uid50 is
   component MultTable_comb_uid52 is
      port ( X : in  std_logic_vector(4 downto 0);
             Y : out  std_logic_vector(4 downto 0)   );
   end component;

signal Xtable :  std_logic_vector(4 downto 0);
signal Y1 :  std_logic_vector(4 downto 0);
begin
Xtable <= Y & X;
   R <= Y1;
   TableMult: MultTable_comb_uid52
      port map ( X => Xtable,
                 Y => Y1);
end architecture;

--------------------------------------------------------------------------------
--                           IntAdder_10_comb_uid88
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

entity IntAdder_10_comb_uid88 is
    port (X : in  std_logic_vector(9 downto 0);
          Y : in  std_logic_vector(9 downto 0);
          Cin : in  std_logic;
          R : out  std_logic_vector(9 downto 0)   );
end entity;

architecture arch of IntAdder_10_comb_uid88 is
signal Rtmp :  std_logic_vector(9 downto 0);
begin
   Rtmp <= X + Y + Cin;
   R <= Rtmp;
end architecture;

--------------------------------------------------------------------------------
--                       IntMultiplier_8x8_16_comb_uid2
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved
-- Authors: Martin Kumm, Florent de Dinechin, Kinga Illyes, Bogdan Popa, Bogdan Pasca, 2012-
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X Y
-- Output signals: R

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library std;
use std.textio.all;
library work;

entity IntMultiplier_8x8_16_comb_uid2 is
    port (X : in  std_logic_vector(7 downto 0);
          Y : in  std_logic_vector(7 downto 0);
          R : out  std_logic_vector(15 downto 0)   );
end entity;

architecture arch of IntMultiplier_8x8_16_comb_uid2 is
   component IntMultiplierLUT_2_signedx2_signed_comb_uid6 is
      port ( X : in  std_logic_vector(1 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(3 downto 0)   );
   end component;

   component IntMultiplierLUT_3x2_signed_comb_uid10 is
      port ( X : in  std_logic_vector(2 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(4 downto 0)   );
   end component;

   component IntMultiplierLUT_3x2_signed_comb_uid14 is
      port ( X : in  std_logic_vector(2 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(4 downto 0)   );
   end component;

   component IntMultiplierLUT_2_signedx2_comb_uid18 is
      port ( X : in  std_logic_vector(1 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(3 downto 0)   );
   end component;

   component IntMultiplierLUT_3x2_comb_uid22 is
      port ( X : in  std_logic_vector(2 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(4 downto 0)   );
   end component;

   component IntMultiplierLUT_3x2_comb_uid26 is
      port ( X : in  std_logic_vector(2 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(4 downto 0)   );
   end component;

   component IntMultiplierLUT_2_signedx2_comb_uid30 is
      port ( X : in  std_logic_vector(1 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(3 downto 0)   );
   end component;

   component IntMultiplierLUT_3x2_comb_uid34 is
      port ( X : in  std_logic_vector(2 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(4 downto 0)   );
   end component;

   component IntMultiplierLUT_3x2_comb_uid38 is
      port ( X : in  std_logic_vector(2 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(4 downto 0)   );
   end component;

   component IntMultiplierLUT_2_signedx2_comb_uid42 is
      port ( X : in  std_logic_vector(1 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(3 downto 0)   );
   end component;

   component IntMultiplierLUT_3x2_comb_uid46 is
      port ( X : in  std_logic_vector(2 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(4 downto 0)   );
   end component;

   component IntMultiplierLUT_3x2_comb_uid50 is
      port ( X : in  std_logic_vector(2 downto 0);
             Y : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(4 downto 0)   );
   end component;

   component Compressor_23_3_comb_uid55 is
      port ( X1 : in  std_logic_vector(1 downto 0);
             X0 : in  std_logic_vector(2 downto 0);
             R : out  std_logic_vector(2 downto 0)   );
   end component;

   component Compressor_3_2_comb_uid58 is
      port ( X0 : in  std_logic_vector(2 downto 0);
             R : out  std_logic_vector(1 downto 0)   );
   end component;

   component Compressor_14_3_comb_uid61 is
      port ( X1 : in  std_logic_vector(0 downto 0);
             X0 : in  std_logic_vector(3 downto 0);
             R : out  std_logic_vector(2 downto 0)   );
   end component;

   component Compressor_6_3_comb_uid65 is
      port ( X0 : in  std_logic_vector(5 downto 0);
             R : out  std_logic_vector(2 downto 0)   );
   end component;

   component IntAdder_10_comb_uid88 is
      port ( X : in  std_logic_vector(9 downto 0);
             Y : in  std_logic_vector(9 downto 0);
             Cin : in  std_logic;
             R : out  std_logic_vector(9 downto 0)   );
   end component;

signal XX_m3 :  std_logic_vector(7 downto 0);
signal YY_m3 :  std_logic_vector(7 downto 0);
signal tile_0_X :  std_logic_vector(1 downto 0);
signal tile_0_Y :  std_logic_vector(1 downto 0);
signal tile_0_output :  std_logic_vector(3 downto 0);
signal tile_0_filtered_output :  signed(3-0 downto 0);
signal bh4_w12_0 :  std_logic;
signal bh4_w13_0 :  std_logic;
signal bh4_w14_0 :  std_logic;
signal bh4_w15_0 :  std_logic;
signal tile_1_X :  std_logic_vector(2 downto 0);
signal tile_1_Y :  std_logic_vector(1 downto 0);
signal tile_1_output :  std_logic_vector(4 downto 0);
signal tile_1_filtered_output :  signed(4-0 downto 0);
signal bh4_w9_0 :  std_logic;
signal bh4_w10_0 :  std_logic;
signal bh4_w11_0 :  std_logic;
signal bh4_w12_1 :  std_logic;
signal bh4_w13_1 :  std_logic;
signal tile_2_X :  std_logic_vector(2 downto 0);
signal tile_2_Y :  std_logic_vector(1 downto 0);
signal tile_2_output :  std_logic_vector(4 downto 0);
signal tile_2_filtered_output :  signed(4-0 downto 0);
signal bh4_w6_0 :  std_logic;
signal bh4_w7_0 :  std_logic;
signal bh4_w8_0 :  std_logic;
signal bh4_w9_1 :  std_logic;
signal bh4_w10_1 :  std_logic;
signal tile_3_X :  std_logic_vector(1 downto 0);
signal tile_3_Y :  std_logic_vector(1 downto 0);
signal tile_3_output :  std_logic_vector(3 downto 0);
signal tile_3_filtered_output :  signed(3-0 downto 0);
signal bh4_w10_2 :  std_logic;
signal bh4_w11_1 :  std_logic;
signal bh4_w12_2 :  std_logic;
signal bh4_w13_2 :  std_logic;
signal tile_4_X :  std_logic_vector(2 downto 0);
signal tile_4_Y :  std_logic_vector(1 downto 0);
signal tile_4_output :  std_logic_vector(4 downto 0);
signal tile_4_filtered_output :  unsigned(4-0 downto 0);
signal bh4_w7_1 :  std_logic;
signal bh4_w8_1 :  std_logic;
signal bh4_w9_2 :  std_logic;
signal bh4_w10_3 :  std_logic;
signal bh4_w11_2 :  std_logic;
signal tile_5_X :  std_logic_vector(2 downto 0);
signal tile_5_Y :  std_logic_vector(1 downto 0);
signal tile_5_output :  std_logic_vector(4 downto 0);
signal tile_5_filtered_output :  unsigned(4-0 downto 0);
signal bh4_w4_0 :  std_logic;
signal bh4_w5_0 :  std_logic;
signal bh4_w6_1 :  std_logic;
signal bh4_w7_2 :  std_logic;
signal bh4_w8_2 :  std_logic;
signal tile_6_X :  std_logic_vector(1 downto 0);
signal tile_6_Y :  std_logic_vector(1 downto 0);
signal tile_6_output :  std_logic_vector(3 downto 0);
signal tile_6_filtered_output :  signed(3-0 downto 0);
signal bh4_w8_3 :  std_logic;
signal bh4_w9_3 :  std_logic;
signal bh4_w10_4 :  std_logic;
signal bh4_w11_3 :  std_logic;
signal tile_7_X :  std_logic_vector(2 downto 0);
signal tile_7_Y :  std_logic_vector(1 downto 0);
signal tile_7_output :  std_logic_vector(4 downto 0);
signal tile_7_filtered_output :  unsigned(4-0 downto 0);
signal bh4_w5_1 :  std_logic;
signal bh4_w6_2 :  std_logic;
signal bh4_w7_3 :  std_logic;
signal bh4_w8_4 :  std_logic;
signal bh4_w9_4 :  std_logic;
signal tile_8_X :  std_logic_vector(2 downto 0);
signal tile_8_Y :  std_logic_vector(1 downto 0);
signal tile_8_output :  std_logic_vector(4 downto 0);
signal tile_8_filtered_output :  unsigned(4-0 downto 0);
signal bh4_w2_0 :  std_logic;
signal bh4_w3_0 :  std_logic;
signal bh4_w4_1 :  std_logic;
signal bh4_w5_2 :  std_logic;
signal bh4_w6_3 :  std_logic;
signal tile_9_X :  std_logic_vector(1 downto 0);
signal tile_9_Y :  std_logic_vector(1 downto 0);
signal tile_9_output :  std_logic_vector(3 downto 0);
signal tile_9_filtered_output :  signed(3-0 downto 0);
signal bh4_w6_4 :  std_logic;
signal bh4_w7_4 :  std_logic;
signal bh4_w8_5 :  std_logic;
signal bh4_w9_5 :  std_logic;
signal tile_10_X :  std_logic_vector(2 downto 0);
signal tile_10_Y :  std_logic_vector(1 downto 0);
signal tile_10_output :  std_logic_vector(4 downto 0);
signal tile_10_filtered_output :  unsigned(4-0 downto 0);
signal bh4_w3_1 :  std_logic;
signal bh4_w4_2 :  std_logic;
signal bh4_w5_3 :  std_logic;
signal bh4_w6_5 :  std_logic;
signal bh4_w7_5 :  std_logic;
signal tile_11_X :  std_logic_vector(2 downto 0);
signal tile_11_Y :  std_logic_vector(1 downto 0);
signal tile_11_output :  std_logic_vector(4 downto 0);
signal tile_11_filtered_output :  unsigned(4-0 downto 0);
signal bh4_w0_0 :  std_logic;
signal bh4_w1_0 :  std_logic;
signal bh4_w2_1 :  std_logic;
signal bh4_w3_2 :  std_logic;
signal bh4_w4_3 :  std_logic;
signal bh4_w9_6 :  std_logic;
signal bh4_w12_3 :  std_logic;
signal bh4_w13_3 :  std_logic;
signal Compressor_23_3_comb_uid55_bh4_uid56_In0 :  std_logic_vector(2 downto 0);
signal Compressor_23_3_comb_uid55_bh4_uid56_In1 :  std_logic_vector(1 downto 0);
signal Compressor_23_3_comb_uid55_bh4_uid56_Out0 :  std_logic_vector(2 downto 0);
signal bh4_w1_1 :  std_logic;
signal bh4_w2_2 :  std_logic;
signal bh4_w3_3 :  std_logic;
signal Compressor_3_2_comb_uid58_bh4_uid59_In0 :  std_logic_vector(2 downto 0);
signal Compressor_3_2_comb_uid58_bh4_uid59_Out0 :  std_logic_vector(1 downto 0);
signal bh4_w3_4 :  std_logic;
signal bh4_w4_4 :  std_logic;
signal Compressor_14_3_comb_uid61_bh4_uid62_In0 :  std_logic_vector(3 downto 0);
signal Compressor_14_3_comb_uid61_bh4_uid62_In1 :  std_logic_vector(0 downto 0);
signal Compressor_14_3_comb_uid61_bh4_uid62_Out0 :  std_logic_vector(2 downto 0);
signal bh4_w4_5 :  std_logic;
signal bh4_w5_4 :  std_logic;
signal bh4_w6_6 :  std_logic;
signal Compressor_3_2_comb_uid58_bh4_uid63_In0 :  std_logic_vector(2 downto 0);
signal Compressor_3_2_comb_uid58_bh4_uid63_Out0 :  std_logic_vector(1 downto 0);
signal bh4_w5_5 :  std_logic;
signal bh4_w6_7 :  std_logic;
signal Compressor_6_3_comb_uid65_bh4_uid66_In0 :  std_logic_vector(5 downto 0);
signal Compressor_6_3_comb_uid65_bh4_uid66_Out0 :  std_logic_vector(2 downto 0);
signal bh4_w6_8 :  std_logic;
signal bh4_w7_6 :  std_logic;
signal bh4_w8_6 :  std_logic;
signal Compressor_6_3_comb_uid65_bh4_uid67_In0 :  std_logic_vector(5 downto 0);
signal Compressor_6_3_comb_uid65_bh4_uid67_Out0 :  std_logic_vector(2 downto 0);
signal bh4_w7_7 :  std_logic;
signal bh4_w8_7 :  std_logic;
signal bh4_w9_7 :  std_logic;
signal Compressor_6_3_comb_uid65_bh4_uid68_In0 :  std_logic_vector(5 downto 0);
signal Compressor_6_3_comb_uid65_bh4_uid68_Out0 :  std_logic_vector(2 downto 0);
signal bh4_w8_8 :  std_logic;
signal bh4_w9_8 :  std_logic;
signal bh4_w10_5 :  std_logic;
signal Compressor_6_3_comb_uid65_bh4_uid69_In0 :  std_logic_vector(5 downto 0);
signal Compressor_6_3_comb_uid65_bh4_uid69_Out0 :  std_logic_vector(2 downto 0);
signal bh4_w9_9 :  std_logic;
signal bh4_w10_6 :  std_logic;
signal bh4_w11_4 :  std_logic;
signal Compressor_14_3_comb_uid61_bh4_uid70_In0 :  std_logic_vector(3 downto 0);
signal Compressor_14_3_comb_uid61_bh4_uid70_In1 :  std_logic_vector(0 downto 0);
signal Compressor_14_3_comb_uid61_bh4_uid70_Out0 :  std_logic_vector(2 downto 0);
signal bh4_w10_7 :  std_logic;
signal bh4_w11_5 :  std_logic;
signal bh4_w12_4 :  std_logic;
signal Compressor_3_2_comb_uid58_bh4_uid71_In0 :  std_logic_vector(2 downto 0);
signal Compressor_3_2_comb_uid58_bh4_uid71_Out0 :  std_logic_vector(1 downto 0);
signal bh4_w11_6 :  std_logic;
signal bh4_w12_5 :  std_logic;
signal Compressor_14_3_comb_uid61_bh4_uid72_In0 :  std_logic_vector(3 downto 0);
signal Compressor_14_3_comb_uid61_bh4_uid72_In1 :  std_logic_vector(0 downto 0);
signal Compressor_14_3_comb_uid61_bh4_uid72_Out0 :  std_logic_vector(2 downto 0);
signal bh4_w12_6 :  std_logic;
signal bh4_w13_4 :  std_logic;
signal bh4_w14_1 :  std_logic;
signal Compressor_3_2_comb_uid58_bh4_uid73_In0 :  std_logic_vector(2 downto 0);
signal Compressor_3_2_comb_uid58_bh4_uid73_Out0 :  std_logic_vector(1 downto 0);
signal bh4_w13_5 :  std_logic;
signal bh4_w14_2 :  std_logic;
signal Compressor_23_3_comb_uid55_bh4_uid74_In0 :  std_logic_vector(2 downto 0);
signal Compressor_23_3_comb_uid55_bh4_uid74_In1 :  std_logic_vector(1 downto 0);
signal Compressor_23_3_comb_uid55_bh4_uid74_Out0 :  std_logic_vector(2 downto 0);
signal bh4_w3_5 :  std_logic;
signal bh4_w4_6 :  std_logic;
signal bh4_w5_6 :  std_logic;
signal Compressor_3_2_comb_uid58_bh4_uid75_In0 :  std_logic_vector(2 downto 0);
signal Compressor_3_2_comb_uid58_bh4_uid75_Out0 :  std_logic_vector(1 downto 0);
signal bh4_w5_7 :  std_logic;
signal bh4_w6_9 :  std_logic;
signal Compressor_23_3_comb_uid55_bh4_uid76_In0 :  std_logic_vector(2 downto 0);
signal Compressor_23_3_comb_uid55_bh4_uid76_In1 :  std_logic_vector(1 downto 0);
signal Compressor_23_3_comb_uid55_bh4_uid76_Out0 :  std_logic_vector(2 downto 0);
signal bh4_w6_10 :  std_logic;
signal bh4_w7_8 :  std_logic;
signal bh4_w8_9 :  std_logic;
signal Compressor_3_2_comb_uid58_bh4_uid77_In0 :  std_logic_vector(2 downto 0);
signal Compressor_3_2_comb_uid58_bh4_uid77_Out0 :  std_logic_vector(1 downto 0);
signal bh4_w8_10 :  std_logic;
signal bh4_w9_10 :  std_logic;
signal Compressor_14_3_comb_uid61_bh4_uid78_In0 :  std_logic_vector(3 downto 0);
signal Compressor_14_3_comb_uid61_bh4_uid78_In1 :  std_logic_vector(0 downto 0);
signal Compressor_14_3_comb_uid61_bh4_uid78_Out0 :  std_logic_vector(2 downto 0);
signal bh4_w9_11 :  std_logic;
signal bh4_w10_8 :  std_logic;
signal bh4_w11_7 :  std_logic;
signal Compressor_23_3_comb_uid55_bh4_uid79_In0 :  std_logic_vector(2 downto 0);
signal Compressor_23_3_comb_uid55_bh4_uid79_In1 :  std_logic_vector(1 downto 0);
signal Compressor_23_3_comb_uid55_bh4_uid79_Out0 :  std_logic_vector(2 downto 0);
signal bh4_w10_9 :  std_logic;
signal bh4_w11_8 :  std_logic;
signal bh4_w12_7 :  std_logic;
signal Compressor_23_3_comb_uid55_bh4_uid80_In0 :  std_logic_vector(2 downto 0);
signal Compressor_23_3_comb_uid55_bh4_uid80_In1 :  std_logic_vector(1 downto 0);
signal Compressor_23_3_comb_uid55_bh4_uid80_Out0 :  std_logic_vector(2 downto 0);
signal bh4_w12_8 :  std_logic;
signal bh4_w13_6 :  std_logic;
signal bh4_w14_3 :  std_logic;
signal Compressor_3_2_comb_uid58_bh4_uid81_In0 :  std_logic_vector(2 downto 0);
signal Compressor_3_2_comb_uid58_bh4_uid81_Out0 :  std_logic_vector(1 downto 0);
signal bh4_w14_4 :  std_logic;
signal bh4_w15_1 :  std_logic;
signal Compressor_23_3_comb_uid55_bh4_uid82_In0 :  std_logic_vector(2 downto 0);
signal Compressor_23_3_comb_uid55_bh4_uid82_In1 :  std_logic_vector(1 downto 0);
signal Compressor_23_3_comb_uid55_bh4_uid82_Out0 :  std_logic_vector(2 downto 0);
signal bh4_w5_8 :  std_logic;
signal bh4_w6_11 :  std_logic;
signal bh4_w7_9 :  std_logic;
signal Compressor_23_3_comb_uid55_bh4_uid83_In0 :  std_logic_vector(2 downto 0);
signal Compressor_23_3_comb_uid55_bh4_uid83_In1 :  std_logic_vector(1 downto 0);
signal Compressor_23_3_comb_uid55_bh4_uid83_Out0 :  std_logic_vector(2 downto 0);
signal bh4_w8_11 :  std_logic;
signal bh4_w9_12 :  std_logic;
signal bh4_w10_10 :  std_logic;
signal Compressor_3_2_comb_uid58_bh4_uid84_In0 :  std_logic_vector(2 downto 0);
signal Compressor_3_2_comb_uid58_bh4_uid84_Out0 :  std_logic_vector(1 downto 0);
signal bh4_w10_11 :  std_logic;
signal bh4_w11_9 :  std_logic;
signal Compressor_23_3_comb_uid55_bh4_uid85_In0 :  std_logic_vector(2 downto 0);
signal Compressor_23_3_comb_uid55_bh4_uid85_In1 :  std_logic_vector(1 downto 0);
signal Compressor_23_3_comb_uid55_bh4_uid85_Out0 :  std_logic_vector(2 downto 0);
signal bh4_w11_10 :  std_logic;
signal bh4_w12_9 :  std_logic;
signal bh4_w13_7 :  std_logic;
signal Compressor_23_3_comb_uid55_bh4_uid86_In0 :  std_logic_vector(2 downto 0);
signal Compressor_23_3_comb_uid55_bh4_uid86_In1 :  std_logic_vector(1 downto 0);
signal Compressor_23_3_comb_uid55_bh4_uid86_Out0 :  std_logic_vector(2 downto 0);
signal bh4_w14_5 :  std_logic;
signal bh4_w15_2 :  std_logic;
signal tmp_bitheapResult_bh4_6 :  std_logic_vector(6 downto 0);
signal bitheapFinalAdd_bh4_In0 :  std_logic_vector(9 downto 0);
signal bitheapFinalAdd_bh4_In1 :  std_logic_vector(9 downto 0);
signal bitheapFinalAdd_bh4_Cin :  std_logic;
signal bitheapFinalAdd_bh4_Out :  std_logic_vector(9 downto 0);
signal bitheapResult_bh4 :  std_logic_vector(15 downto 0);
begin
   XX_m3 <= X ;
   YY_m3 <= Y ;
   tile_0_X <= X(7 downto 6);
   tile_0_Y <= Y(7 downto 6);
   tile_0_mult: IntMultiplierLUT_2_signedx2_signed_comb_uid6
      port map ( X => tile_0_X,
                 Y => tile_0_Y,
                 R => tile_0_output);

   tile_0_filtered_output <= signed(tile_0_output(3 downto 0));
   bh4_w12_0 <= tile_0_filtered_output(0);
   bh4_w13_0 <= tile_0_filtered_output(1);
   bh4_w14_0 <= tile_0_filtered_output(2);
   bh4_w15_0 <= not tile_0_filtered_output(3);
   tile_1_X <= X(5 downto 3);
   tile_1_Y <= Y(7 downto 6);
   tile_1_mult: IntMultiplierLUT_3x2_signed_comb_uid10
      port map ( X => tile_1_X,
                 Y => tile_1_Y,
                 R => tile_1_output);

   tile_1_filtered_output <= signed(tile_1_output(4 downto 0));
   bh4_w9_0 <= tile_1_filtered_output(0);
   bh4_w10_0 <= tile_1_filtered_output(1);
   bh4_w11_0 <= tile_1_filtered_output(2);
   bh4_w12_1 <= tile_1_filtered_output(3);
   bh4_w13_1 <= not tile_1_filtered_output(4);
   tile_2_X <= X(2 downto 0);
   tile_2_Y <= Y(7 downto 6);
   tile_2_mult: IntMultiplierLUT_3x2_signed_comb_uid14
      port map ( X => tile_2_X,
                 Y => tile_2_Y,
                 R => tile_2_output);

   tile_2_filtered_output <= signed(tile_2_output(4 downto 0));
   bh4_w6_0 <= tile_2_filtered_output(0);
   bh4_w7_0 <= tile_2_filtered_output(1);
   bh4_w8_0 <= tile_2_filtered_output(2);
   bh4_w9_1 <= tile_2_filtered_output(3);
   bh4_w10_1 <= not tile_2_filtered_output(4);
   tile_3_X <= X(7 downto 6);
   tile_3_Y <= Y(5 downto 4);
   tile_3_mult: IntMultiplierLUT_2_signedx2_comb_uid18
      port map ( X => tile_3_X,
                 Y => tile_3_Y,
                 R => tile_3_output);

   tile_3_filtered_output <= signed(tile_3_output(3 downto 0));
   bh4_w10_2 <= tile_3_filtered_output(0);
   bh4_w11_1 <= tile_3_filtered_output(1);
   bh4_w12_2 <= tile_3_filtered_output(2);
   bh4_w13_2 <= not tile_3_filtered_output(3);
   tile_4_X <= X(5 downto 3);
   tile_4_Y <= Y(5 downto 4);
   tile_4_mult: IntMultiplierLUT_3x2_comb_uid22
      port map ( X => tile_4_X,
                 Y => tile_4_Y,
                 R => tile_4_output);

   tile_4_filtered_output <= unsigned(tile_4_output(4 downto 0));
   bh4_w7_1 <= tile_4_filtered_output(0);
   bh4_w8_1 <= tile_4_filtered_output(1);
   bh4_w9_2 <= tile_4_filtered_output(2);
   bh4_w10_3 <= tile_4_filtered_output(3);
   bh4_w11_2 <= tile_4_filtered_output(4);
   tile_5_X <= X(2 downto 0);
   tile_5_Y <= Y(5 downto 4);
   tile_5_mult: IntMultiplierLUT_3x2_comb_uid26
      port map ( X => tile_5_X,
                 Y => tile_5_Y,
                 R => tile_5_output);

   tile_5_filtered_output <= unsigned(tile_5_output(4 downto 0));
   bh4_w4_0 <= tile_5_filtered_output(0);
   bh4_w5_0 <= tile_5_filtered_output(1);
   bh4_w6_1 <= tile_5_filtered_output(2);
   bh4_w7_2 <= tile_5_filtered_output(3);
   bh4_w8_2 <= tile_5_filtered_output(4);
   tile_6_X <= X(7 downto 6);
   tile_6_Y <= Y(3 downto 2);
   tile_6_mult: IntMultiplierLUT_2_signedx2_comb_uid30
      port map ( X => tile_6_X,
                 Y => tile_6_Y,
                 R => tile_6_output);

   tile_6_filtered_output <= signed(tile_6_output(3 downto 0));
   bh4_w8_3 <= tile_6_filtered_output(0);
   bh4_w9_3 <= tile_6_filtered_output(1);
   bh4_w10_4 <= tile_6_filtered_output(2);
   bh4_w11_3 <= not tile_6_filtered_output(3);
   tile_7_X <= X(5 downto 3);
   tile_7_Y <= Y(3 downto 2);
   tile_7_mult: IntMultiplierLUT_3x2_comb_uid34
      port map ( X => tile_7_X,
                 Y => tile_7_Y,
                 R => tile_7_output);

   tile_7_filtered_output <= unsigned(tile_7_output(4 downto 0));
   bh4_w5_1 <= tile_7_filtered_output(0);
   bh4_w6_2 <= tile_7_filtered_output(1);
   bh4_w7_3 <= tile_7_filtered_output(2);
   bh4_w8_4 <= tile_7_filtered_output(3);
   bh4_w9_4 <= tile_7_filtered_output(4);
   tile_8_X <= X(2 downto 0);
   tile_8_Y <= Y(3 downto 2);
   tile_8_mult: IntMultiplierLUT_3x2_comb_uid38
      port map ( X => tile_8_X,
                 Y => tile_8_Y,
                 R => tile_8_output);

   tile_8_filtered_output <= unsigned(tile_8_output(4 downto 0));
   bh4_w2_0 <= tile_8_filtered_output(0);
   bh4_w3_0 <= tile_8_filtered_output(1);
   bh4_w4_1 <= tile_8_filtered_output(2);
   bh4_w5_2 <= tile_8_filtered_output(3);
   bh4_w6_3 <= tile_8_filtered_output(4);
   tile_9_X <= X(7 downto 6);
   tile_9_Y <= Y(1 downto 0);
   tile_9_mult: IntMultiplierLUT_2_signedx2_comb_uid42
      port map ( X => tile_9_X,
                 Y => tile_9_Y,
                 R => tile_9_output);

   tile_9_filtered_output <= signed(tile_9_output(3 downto 0));
   bh4_w6_4 <= tile_9_filtered_output(0);
   bh4_w7_4 <= tile_9_filtered_output(1);
   bh4_w8_5 <= tile_9_filtered_output(2);
   bh4_w9_5 <= not tile_9_filtered_output(3);
   tile_10_X <= X(5 downto 3);
   tile_10_Y <= Y(1 downto 0);
   tile_10_mult: IntMultiplierLUT_3x2_comb_uid46
      port map ( X => tile_10_X,
                 Y => tile_10_Y,
                 R => tile_10_output);

   tile_10_filtered_output <= unsigned(tile_10_output(4 downto 0));
   bh4_w3_1 <= tile_10_filtered_output(0);
   bh4_w4_2 <= tile_10_filtered_output(1);
   bh4_w5_3 <= tile_10_filtered_output(2);
   bh4_w6_5 <= tile_10_filtered_output(3);
   bh4_w7_5 <= tile_10_filtered_output(4);
   tile_11_X <= X(2 downto 0);
   tile_11_Y <= Y(1 downto 0);
   tile_11_mult: IntMultiplierLUT_3x2_comb_uid50
      port map ( X => tile_11_X,
                 Y => tile_11_Y,
                 R => tile_11_output);

   tile_11_filtered_output <= unsigned(tile_11_output(4 downto 0));
   bh4_w0_0 <= tile_11_filtered_output(0);
   bh4_w1_0 <= tile_11_filtered_output(1);
   bh4_w2_1 <= tile_11_filtered_output(2);
   bh4_w3_2 <= tile_11_filtered_output(3);
   bh4_w4_3 <= tile_11_filtered_output(4);

   -- Adding the constant bits
   bh4_w9_6 <= '1';
   bh4_w12_3 <= '1';
   bh4_w13_3 <= '1';


   Compressor_23_3_comb_uid55_bh4_uid56_In0 <= "" & bh4_w1_0 & "0" & "0";
   Compressor_23_3_comb_uid55_bh4_uid56_In1 <= "" & bh4_w2_0 & bh4_w2_1;
   bh4_w1_1 <= Compressor_23_3_comb_uid55_bh4_uid56_Out0(0);
   bh4_w2_2 <= Compressor_23_3_comb_uid55_bh4_uid56_Out0(1);
   bh4_w3_3 <= Compressor_23_3_comb_uid55_bh4_uid56_Out0(2);
   Compressor_23_3_comb_uid55_uid56: Compressor_23_3_comb_uid55
      port map ( X0 => Compressor_23_3_comb_uid55_bh4_uid56_In0,
                 X1 => Compressor_23_3_comb_uid55_bh4_uid56_In1,
                 R => Compressor_23_3_comb_uid55_bh4_uid56_Out0);


   Compressor_3_2_comb_uid58_bh4_uid59_In0 <= "" & bh4_w3_0 & bh4_w3_1 & bh4_w3_2;
   bh4_w3_4 <= Compressor_3_2_comb_uid58_bh4_uid59_Out0(0);
   bh4_w4_4 <= Compressor_3_2_comb_uid58_bh4_uid59_Out0(1);
   Compressor_3_2_comb_uid58_uid59: Compressor_3_2_comb_uid58
      port map ( X0 => Compressor_3_2_comb_uid58_bh4_uid59_In0,
                 R => Compressor_3_2_comb_uid58_bh4_uid59_Out0);


   Compressor_14_3_comb_uid61_bh4_uid62_In0 <= "" & bh4_w4_0 & bh4_w4_1 & bh4_w4_2 & bh4_w4_3;
   Compressor_14_3_comb_uid61_bh4_uid62_In1 <= "" & bh4_w5_0;
   bh4_w4_5 <= Compressor_14_3_comb_uid61_bh4_uid62_Out0(0);
   bh4_w5_4 <= Compressor_14_3_comb_uid61_bh4_uid62_Out0(1);
   bh4_w6_6 <= Compressor_14_3_comb_uid61_bh4_uid62_Out0(2);
   Compressor_14_3_comb_uid61_uid62: Compressor_14_3_comb_uid61
      port map ( X0 => Compressor_14_3_comb_uid61_bh4_uid62_In0,
                 X1 => Compressor_14_3_comb_uid61_bh4_uid62_In1,
                 R => Compressor_14_3_comb_uid61_bh4_uid62_Out0);


   Compressor_3_2_comb_uid58_bh4_uid63_In0 <= "" & bh4_w5_1 & bh4_w5_2 & bh4_w5_3;
   bh4_w5_5 <= Compressor_3_2_comb_uid58_bh4_uid63_Out0(0);
   bh4_w6_7 <= Compressor_3_2_comb_uid58_bh4_uid63_Out0(1);
   Compressor_3_2_comb_uid58_uid63: Compressor_3_2_comb_uid58
      port map ( X0 => Compressor_3_2_comb_uid58_bh4_uid63_In0,
                 R => Compressor_3_2_comb_uid58_bh4_uid63_Out0);


   Compressor_6_3_comb_uid65_bh4_uid66_In0 <= "" & bh4_w6_0 & bh4_w6_1 & bh4_w6_2 & bh4_w6_3 & bh4_w6_4 & bh4_w6_5;
   bh4_w6_8 <= Compressor_6_3_comb_uid65_bh4_uid66_Out0(0);
   bh4_w7_6 <= Compressor_6_3_comb_uid65_bh4_uid66_Out0(1);
   bh4_w8_6 <= Compressor_6_3_comb_uid65_bh4_uid66_Out0(2);
   Compressor_6_3_comb_uid65_uid66: Compressor_6_3_comb_uid65
      port map ( X0 => Compressor_6_3_comb_uid65_bh4_uid66_In0,
                 R => Compressor_6_3_comb_uid65_bh4_uid66_Out0);


   Compressor_6_3_comb_uid65_bh4_uid67_In0 <= "" & bh4_w7_0 & bh4_w7_1 & bh4_w7_2 & bh4_w7_3 & bh4_w7_4 & bh4_w7_5;
   bh4_w7_7 <= Compressor_6_3_comb_uid65_bh4_uid67_Out0(0);
   bh4_w8_7 <= Compressor_6_3_comb_uid65_bh4_uid67_Out0(1);
   bh4_w9_7 <= Compressor_6_3_comb_uid65_bh4_uid67_Out0(2);
   Compressor_6_3_comb_uid65_uid67: Compressor_6_3_comb_uid65
      port map ( X0 => Compressor_6_3_comb_uid65_bh4_uid67_In0,
                 R => Compressor_6_3_comb_uid65_bh4_uid67_Out0);


   Compressor_6_3_comb_uid65_bh4_uid68_In0 <= "" & bh4_w8_0 & bh4_w8_1 & bh4_w8_2 & bh4_w8_3 & bh4_w8_4 & bh4_w8_5;
   bh4_w8_8 <= Compressor_6_3_comb_uid65_bh4_uid68_Out0(0);
   bh4_w9_8 <= Compressor_6_3_comb_uid65_bh4_uid68_Out0(1);
   bh4_w10_5 <= Compressor_6_3_comb_uid65_bh4_uid68_Out0(2);
   Compressor_6_3_comb_uid65_uid68: Compressor_6_3_comb_uid65
      port map ( X0 => Compressor_6_3_comb_uid65_bh4_uid68_In0,
                 R => Compressor_6_3_comb_uid65_bh4_uid68_Out0);


   Compressor_6_3_comb_uid65_bh4_uid69_In0 <= "" & bh4_w9_6 & bh4_w9_0 & bh4_w9_1 & bh4_w9_2 & bh4_w9_3 & bh4_w9_4;
   bh4_w9_9 <= Compressor_6_3_comb_uid65_bh4_uid69_Out0(0);
   bh4_w10_6 <= Compressor_6_3_comb_uid65_bh4_uid69_Out0(1);
   bh4_w11_4 <= Compressor_6_3_comb_uid65_bh4_uid69_Out0(2);
   Compressor_6_3_comb_uid65_uid69: Compressor_6_3_comb_uid65
      port map ( X0 => Compressor_6_3_comb_uid65_bh4_uid69_In0,
                 R => Compressor_6_3_comb_uid65_bh4_uid69_Out0);


   Compressor_14_3_comb_uid61_bh4_uid70_In0 <= "" & bh4_w10_0 & bh4_w10_1 & bh4_w10_2 & bh4_w10_3;
   Compressor_14_3_comb_uid61_bh4_uid70_In1 <= "" & bh4_w11_0;
   bh4_w10_7 <= Compressor_14_3_comb_uid61_bh4_uid70_Out0(0);
   bh4_w11_5 <= Compressor_14_3_comb_uid61_bh4_uid70_Out0(1);
   bh4_w12_4 <= Compressor_14_3_comb_uid61_bh4_uid70_Out0(2);
   Compressor_14_3_comb_uid61_uid70: Compressor_14_3_comb_uid61
      port map ( X0 => Compressor_14_3_comb_uid61_bh4_uid70_In0,
                 X1 => Compressor_14_3_comb_uid61_bh4_uid70_In1,
                 R => Compressor_14_3_comb_uid61_bh4_uid70_Out0);


   Compressor_3_2_comb_uid58_bh4_uid71_In0 <= "" & bh4_w11_1 & bh4_w11_2 & bh4_w11_3;
   bh4_w11_6 <= Compressor_3_2_comb_uid58_bh4_uid71_Out0(0);
   bh4_w12_5 <= Compressor_3_2_comb_uid58_bh4_uid71_Out0(1);
   Compressor_3_2_comb_uid58_uid71: Compressor_3_2_comb_uid58
      port map ( X0 => Compressor_3_2_comb_uid58_bh4_uid71_In0,
                 R => Compressor_3_2_comb_uid58_bh4_uid71_Out0);


   Compressor_14_3_comb_uid61_bh4_uid72_In0 <= "" & bh4_w12_3 & bh4_w12_0 & bh4_w12_1 & bh4_w12_2;
   Compressor_14_3_comb_uid61_bh4_uid72_In1 <= "" & bh4_w13_3;
   bh4_w12_6 <= Compressor_14_3_comb_uid61_bh4_uid72_Out0(0);
   bh4_w13_4 <= Compressor_14_3_comb_uid61_bh4_uid72_Out0(1);
   bh4_w14_1 <= Compressor_14_3_comb_uid61_bh4_uid72_Out0(2);
   Compressor_14_3_comb_uid61_uid72: Compressor_14_3_comb_uid61
      port map ( X0 => Compressor_14_3_comb_uid61_bh4_uid72_In0,
                 X1 => Compressor_14_3_comb_uid61_bh4_uid72_In1,
                 R => Compressor_14_3_comb_uid61_bh4_uid72_Out0);


   Compressor_3_2_comb_uid58_bh4_uid73_In0 <= "" & bh4_w13_0 & bh4_w13_1 & bh4_w13_2;
   bh4_w13_5 <= Compressor_3_2_comb_uid58_bh4_uid73_Out0(0);
   bh4_w14_2 <= Compressor_3_2_comb_uid58_bh4_uid73_Out0(1);
   Compressor_3_2_comb_uid58_uid73: Compressor_3_2_comb_uid58
      port map ( X0 => Compressor_3_2_comb_uid58_bh4_uid73_In0,
                 R => Compressor_3_2_comb_uid58_bh4_uid73_Out0);


   Compressor_23_3_comb_uid55_bh4_uid74_In0 <= "" & bh4_w3_4 & bh4_w3_3 & "0";
   Compressor_23_3_comb_uid55_bh4_uid74_In1 <= "" & bh4_w4_5 & bh4_w4_4;
   bh4_w3_5 <= Compressor_23_3_comb_uid55_bh4_uid74_Out0(0);
   bh4_w4_6 <= Compressor_23_3_comb_uid55_bh4_uid74_Out0(1);
   bh4_w5_6 <= Compressor_23_3_comb_uid55_bh4_uid74_Out0(2);
   Compressor_23_3_comb_uid55_uid74: Compressor_23_3_comb_uid55
      port map ( X0 => Compressor_23_3_comb_uid55_bh4_uid74_In0,
                 X1 => Compressor_23_3_comb_uid55_bh4_uid74_In1,
                 R => Compressor_23_3_comb_uid55_bh4_uid74_Out0);


   Compressor_3_2_comb_uid58_bh4_uid75_In0 <= "" & bh4_w5_5 & bh4_w5_4 & "0";
   bh4_w5_7 <= Compressor_3_2_comb_uid58_bh4_uid75_Out0(0);
   bh4_w6_9 <= Compressor_3_2_comb_uid58_bh4_uid75_Out0(1);
   Compressor_3_2_comb_uid58_uid75: Compressor_3_2_comb_uid58
      port map ( X0 => Compressor_3_2_comb_uid58_bh4_uid75_In0,
                 R => Compressor_3_2_comb_uid58_bh4_uid75_Out0);


   Compressor_23_3_comb_uid55_bh4_uid76_In0 <= "" & bh4_w6_7 & bh4_w6_6 & bh4_w6_8;
   Compressor_23_3_comb_uid55_bh4_uid76_In1 <= "" & bh4_w7_7 & bh4_w7_6;
   bh4_w6_10 <= Compressor_23_3_comb_uid55_bh4_uid76_Out0(0);
   bh4_w7_8 <= Compressor_23_3_comb_uid55_bh4_uid76_Out0(1);
   bh4_w8_9 <= Compressor_23_3_comb_uid55_bh4_uid76_Out0(2);
   Compressor_23_3_comb_uid55_uid76: Compressor_23_3_comb_uid55
      port map ( X0 => Compressor_23_3_comb_uid55_bh4_uid76_In0,
                 X1 => Compressor_23_3_comb_uid55_bh4_uid76_In1,
                 R => Compressor_23_3_comb_uid55_bh4_uid76_Out0);


   Compressor_3_2_comb_uid58_bh4_uid77_In0 <= "" & bh4_w8_8 & bh4_w8_7 & bh4_w8_6;
   bh4_w8_10 <= Compressor_3_2_comb_uid58_bh4_uid77_Out0(0);
   bh4_w9_10 <= Compressor_3_2_comb_uid58_bh4_uid77_Out0(1);
   Compressor_3_2_comb_uid58_uid77: Compressor_3_2_comb_uid58
      port map ( X0 => Compressor_3_2_comb_uid58_bh4_uid77_In0,
                 R => Compressor_3_2_comb_uid58_bh4_uid77_Out0);


   Compressor_14_3_comb_uid61_bh4_uid78_In0 <= "" & bh4_w9_5 & bh4_w9_9 & bh4_w9_8 & bh4_w9_7;
   Compressor_14_3_comb_uid61_bh4_uid78_In1 <= "" & bh4_w10_4;
   bh4_w9_11 <= Compressor_14_3_comb_uid61_bh4_uid78_Out0(0);
   bh4_w10_8 <= Compressor_14_3_comb_uid61_bh4_uid78_Out0(1);
   bh4_w11_7 <= Compressor_14_3_comb_uid61_bh4_uid78_Out0(2);
   Compressor_14_3_comb_uid61_uid78: Compressor_14_3_comb_uid61
      port map ( X0 => Compressor_14_3_comb_uid61_bh4_uid78_In0,
                 X1 => Compressor_14_3_comb_uid61_bh4_uid78_In1,
                 R => Compressor_14_3_comb_uid61_bh4_uid78_Out0);


   Compressor_23_3_comb_uid55_bh4_uid79_In0 <= "" & bh4_w10_7 & bh4_w10_6 & bh4_w10_5;
   Compressor_23_3_comb_uid55_bh4_uid79_In1 <= "" & bh4_w11_6 & bh4_w11_5;
   bh4_w10_9 <= Compressor_23_3_comb_uid55_bh4_uid79_Out0(0);
   bh4_w11_8 <= Compressor_23_3_comb_uid55_bh4_uid79_Out0(1);
   bh4_w12_7 <= Compressor_23_3_comb_uid55_bh4_uid79_Out0(2);
   Compressor_23_3_comb_uid55_uid79: Compressor_23_3_comb_uid55
      port map ( X0 => Compressor_23_3_comb_uid55_bh4_uid79_In0,
                 X1 => Compressor_23_3_comb_uid55_bh4_uid79_In1,
                 R => Compressor_23_3_comb_uid55_bh4_uid79_Out0);


   Compressor_23_3_comb_uid55_bh4_uid80_In0 <= "" & bh4_w12_6 & bh4_w12_5 & bh4_w12_4;
   Compressor_23_3_comb_uid55_bh4_uid80_In1 <= "" & bh4_w13_5 & bh4_w13_4;
   bh4_w12_8 <= Compressor_23_3_comb_uid55_bh4_uid80_Out0(0);
   bh4_w13_6 <= Compressor_23_3_comb_uid55_bh4_uid80_Out0(1);
   bh4_w14_3 <= Compressor_23_3_comb_uid55_bh4_uid80_Out0(2);
   Compressor_23_3_comb_uid55_uid80: Compressor_23_3_comb_uid55
      port map ( X0 => Compressor_23_3_comb_uid55_bh4_uid80_In0,
                 X1 => Compressor_23_3_comb_uid55_bh4_uid80_In1,
                 R => Compressor_23_3_comb_uid55_bh4_uid80_Out0);


   Compressor_3_2_comb_uid58_bh4_uid81_In0 <= "" & bh4_w14_0 & bh4_w14_2 & bh4_w14_1;
   bh4_w14_4 <= Compressor_3_2_comb_uid58_bh4_uid81_Out0(0);
   bh4_w15_1 <= Compressor_3_2_comb_uid58_bh4_uid81_Out0(1);
   Compressor_3_2_comb_uid58_uid81: Compressor_3_2_comb_uid58
      port map ( X0 => Compressor_3_2_comb_uid58_bh4_uid81_In0,
                 R => Compressor_3_2_comb_uid58_bh4_uid81_Out0);


   Compressor_23_3_comb_uid55_bh4_uid82_In0 <= "" & bh4_w5_7 & bh4_w5_6 & "0";
   Compressor_23_3_comb_uid55_bh4_uid82_In1 <= "" & bh4_w6_9 & bh4_w6_10;
   bh4_w5_8 <= Compressor_23_3_comb_uid55_bh4_uid82_Out0(0);
   bh4_w6_11 <= Compressor_23_3_comb_uid55_bh4_uid82_Out0(1);
   bh4_w7_9 <= Compressor_23_3_comb_uid55_bh4_uid82_Out0(2);
   Compressor_23_3_comb_uid55_uid82: Compressor_23_3_comb_uid55
      port map ( X0 => Compressor_23_3_comb_uid55_bh4_uid82_In0,
                 X1 => Compressor_23_3_comb_uid55_bh4_uid82_In1,
                 R => Compressor_23_3_comb_uid55_bh4_uid82_Out0);


   Compressor_23_3_comb_uid55_bh4_uid83_In0 <= "" & bh4_w8_10 & bh4_w8_9 & "0";
   Compressor_23_3_comb_uid55_bh4_uid83_In1 <= "" & bh4_w9_11 & bh4_w9_10;
   bh4_w8_11 <= Compressor_23_3_comb_uid55_bh4_uid83_Out0(0);
   bh4_w9_12 <= Compressor_23_3_comb_uid55_bh4_uid83_Out0(1);
   bh4_w10_10 <= Compressor_23_3_comb_uid55_bh4_uid83_Out0(2);
   Compressor_23_3_comb_uid55_uid83: Compressor_23_3_comb_uid55
      port map ( X0 => Compressor_23_3_comb_uid55_bh4_uid83_In0,
                 X1 => Compressor_23_3_comb_uid55_bh4_uid83_In1,
                 R => Compressor_23_3_comb_uid55_bh4_uid83_Out0);


   Compressor_3_2_comb_uid58_bh4_uid84_In0 <= "" & bh4_w10_9 & bh4_w10_8 & "0";
   bh4_w10_11 <= Compressor_3_2_comb_uid58_bh4_uid84_Out0(0);
   bh4_w11_9 <= Compressor_3_2_comb_uid58_bh4_uid84_Out0(1);
   Compressor_3_2_comb_uid58_uid84: Compressor_3_2_comb_uid58
      port map ( X0 => Compressor_3_2_comb_uid58_bh4_uid84_In0,
                 R => Compressor_3_2_comb_uid58_bh4_uid84_Out0);


   Compressor_23_3_comb_uid55_bh4_uid85_In0 <= "" & bh4_w11_4 & bh4_w11_8 & bh4_w11_7;
   Compressor_23_3_comb_uid55_bh4_uid85_In1 <= "" & bh4_w12_8 & bh4_w12_7;
   bh4_w11_10 <= Compressor_23_3_comb_uid55_bh4_uid85_Out0(0);
   bh4_w12_9 <= Compressor_23_3_comb_uid55_bh4_uid85_Out0(1);
   bh4_w13_7 <= Compressor_23_3_comb_uid55_bh4_uid85_Out0(2);
   Compressor_23_3_comb_uid55_uid85: Compressor_23_3_comb_uid55
      port map ( X0 => Compressor_23_3_comb_uid55_bh4_uid85_In0,
                 X1 => Compressor_23_3_comb_uid55_bh4_uid85_In1,
                 R => Compressor_23_3_comb_uid55_bh4_uid85_Out0);


   Compressor_23_3_comb_uid55_bh4_uid86_In0 <= "" & bh4_w14_4 & bh4_w14_3 & "0";
   Compressor_23_3_comb_uid55_bh4_uid86_In1 <= "" & bh4_w15_0 & bh4_w15_1;
   bh4_w14_5 <= Compressor_23_3_comb_uid55_bh4_uid86_Out0(0);
   bh4_w15_2 <= Compressor_23_3_comb_uid55_bh4_uid86_Out0(1);
   Compressor_23_3_comb_uid55_uid86: Compressor_23_3_comb_uid55
      port map ( X0 => Compressor_23_3_comb_uid55_bh4_uid86_In0,
                 X1 => Compressor_23_3_comb_uid55_bh4_uid86_In1,
                 R => Compressor_23_3_comb_uid55_bh4_uid86_Out0);

   tmp_bitheapResult_bh4_6 <= bh4_w6_11 & bh4_w5_8 & bh4_w4_6 & bh4_w3_5 & bh4_w2_2 & bh4_w1_1 & bh4_w0_0;

   bitheapFinalAdd_bh4_In0 <= "0" & bh4_w15_2 & bh4_w14_5 & bh4_w13_6 & bh4_w12_9 & bh4_w11_10 & bh4_w10_11 & bh4_w9_12 & bh4_w8_11 & bh4_w7_8;
   bitheapFinalAdd_bh4_In1 <= "0" & "0" & "0" & bh4_w13_7 & "0" & bh4_w11_9 & bh4_w10_10 & "0" & "0" & bh4_w7_9;
   bitheapFinalAdd_bh4_Cin <= '0';

   bitheapFinalAdd_bh4: IntAdder_10_comb_uid88
      port map ( Cin => bitheapFinalAdd_bh4_Cin,
                 X => bitheapFinalAdd_bh4_In0,
                 Y => bitheapFinalAdd_bh4_In1,
                 R => bitheapFinalAdd_bh4_Out);
   bitheapResult_bh4 <= bitheapFinalAdd_bh4_Out(8 downto 0) & tmp_bitheapResult_bh4_6;
   R <= bitheapResult_bh4(15 downto 0);
end architecture;