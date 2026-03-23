--------------------------------------------------------------------------------
--                       Normalizer_ZO_6_6_7_comb_uid4
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Florent de Dinechin, (2007-2020)
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: X OZb
-- Output signals: Count R

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity Normalizer_ZO_6_6_7_comb_uid4 is
    port (X : in  std_logic_vector(5 downto 0);
          OZb : in  std_logic;
          Count : out  std_logic_vector(2 downto 0);
          R : out  std_logic_vector(5 downto 0)   );
end entity;

architecture arch of Normalizer_ZO_6_6_7_comb_uid4 is
signal level3 :  std_logic_vector(5 downto 0);
signal sozb :  std_logic;
signal count2 :  std_logic;
signal level2 :  std_logic_vector(5 downto 0);
signal count1 :  std_logic;
signal level1 :  std_logic_vector(5 downto 0);
signal count0 :  std_logic;
signal level0 :  std_logic_vector(5 downto 0);
signal sCount :  std_logic_vector(2 downto 0);
begin
   level3 <= X ;
   sozb<= OZb;
   count2<= '1' when level3(5 downto 2) = (5 downto 2=>sozb) else '0';
   level2<= level3(5 downto 0) when count2='0' else level3(1 downto 0) & (3 downto 0 => '0');

   count1<= '1' when level2(5 downto 4) = (5 downto 4=>sozb) else '0';
   level1<= level2(5 downto 0) when count1='0' else level2(3 downto 0) & (1 downto 0 => '0');

   count0<= '1' when level1(5 downto 5) = (5 downto 5=>sozb) else '0';
   level0<= level1(5 downto 0) when count0='0' else level1(4 downto 0) & (0 downto 0 => '0');

   R <= level0;
   sCount <= count2 & count1 & count0;
   Count <= sCount;
end architecture;

--------------------------------------------------------------------------------
--                               Posit2PIF_8_0
--                         (Posit2PIF_8_0_comb_uid2)
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Oregane Desrentes 2019
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: I
-- Output signals: O

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity Posit2PIF_8_0 is
    port (I : in  std_logic_vector(7 downto 0);
          O : out  std_logic_vector(14 downto 0)   );
end entity;

architecture arch of Posit2PIF_8_0 is
   component Normalizer_ZO_6_6_7_comb_uid4 is
      port ( X : in  std_logic_vector(5 downto 0);
             OZb : in  std_logic;
             Count : out  std_logic_vector(2 downto 0);
             R : out  std_logic_vector(5 downto 0)   );
   end component;

signal s :  std_logic;
signal count_type :  std_logic;
signal remainder :  std_logic_vector(5 downto 0);
signal not_s :  std_logic;
signal zero_NAR :  std_logic;
signal is_NAR :  std_logic;
signal is_not_zero :  std_logic;
signal implicit_bit :  std_logic;
signal neg_count :  std_logic;
signal lzCount :  std_logic_vector(2 downto 0);
signal usefulBits :  std_logic_vector(5 downto 0);
signal extended_neg_count :  std_logic_vector(4 downto 0);
signal comp2_range_count :  std_logic_vector(4 downto 0);
signal fraction :  std_logic_vector(4 downto 0);
signal exponent :  std_logic_vector(4 downto 0);
signal biased_exponent :  std_logic_vector(4 downto 0);
signal extended_is_not_zero :  std_logic_vector(4 downto 0);
signal final_biased_exponent :  std_logic_vector(4 downto 0);
signal round :  std_logic;
signal sticky :  std_logic;
begin
--------------------------- Start of vhdl generation ---------------------------
s<= I(7);
count_type<= I(6);
remainder<= I(5 downto 0);
not_s<= not s;
zero_NAR <= not count_type when remainder="000000" else '0';
is_NAR<= zero_NAR and s;
is_not_zero<= not(zero_NAR and not_s);
implicit_bit<= is_not_zero and not_s;
neg_count<= not (s xor count_type);
   lzoc: Normalizer_ZO_6_6_7_comb_uid4
      port map ( OZb => count_type,
                 X => remainder,
                 Count => lzCount,
                 R => usefulBits);
with neg_count  select  extended_neg_count <= 
   "00000" when '0', 
   "11111" when '1', 
   "-----" when others;
comp2_range_count<= extended_neg_count xor ("00" & lzCount);
fraction<= usefulBits(4 downto 0);
exponent<= comp2_range_count;
biased_exponent<= exponent + 7;
with is_not_zero  select   extended_is_not_zero <= 
   "00000" when '0', 
   "11111" when '1', 
   "-----" when others;
final_biased_exponent<= extended_is_not_zero and biased_exponent;
round<= '0';
sticky<= '0';
O <= is_NAR & s & final_biased_exponent & implicit_bit & fraction & round & sticky;
---------------------------- End of vhdl generation ----------------------------
end architecture;

