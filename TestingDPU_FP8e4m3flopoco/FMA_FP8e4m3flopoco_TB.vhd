--------------------------------------------------------------------------------
--                TestBench_IEEEFPFMA_4_3_comb_uid2_comb_uid10
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved
-- Authors: Florent de Dinechin, Cristian Klein, Nicolas Brunie (2007-2010)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library std;
use std.textio.all;
library work;

entity TestBench_IEEEFPFMA_4_3_comb_uid2_comb_uid10 is
end entity;

architecture behavorial of TestBench_IEEEFPFMA_4_3_comb_uid2_comb_uid10 is
   component IEEEFPFMA_4_3_comb_uid2 is
      port ( A : in  std_logic_vector(7 downto 0);
             B : in  std_logic_vector(7 downto 0);
             C : in  std_logic_vector(7 downto 0);
             negateAB : in  std_logic;
             negateC : in  std_logic;
             RndMode : in  std_logic_vector(1 downto 0);
             R : out  std_logic_vector(7 downto 0)   );
   end component;
signal A :  std_logic_vector(7 downto 0);
signal B :  std_logic_vector(7 downto 0);
signal C :  std_logic_vector(7 downto 0);
signal negateAB :  std_logic;
signal negateC :  std_logic;
signal RndMode :  std_logic_vector(1 downto 0);
signal R :  std_logic_vector(7 downto 0);
signal clk :  std_logic;
signal rst :  std_logic;

 -- converts std_logic into a character
   function chr(sl: std_logic) return character is
      variable c: character;
   begin
      case sl is
         when 'U' => c:= 'U';
         when 'X' => c:= 'X';
         when '0' => c:= '0';
         when '1' => c:= '1';
         when 'Z' => c:= 'Z';
         when 'W' => c:= 'W';
         when 'L' => c:= 'L';
         when 'H' => c:= 'H';
         when '-' => c:= '-';
      end case;
      return c;
   end chr;

   -- converts bit to std_logic (1 to 1)
   function to_stdlogic(b : bit) return std_logic is
       variable sl : std_logic;
   begin
      case b is
         when '0' => sl := '0';
         when '1' => sl := '1';
      end case;
      return sl;
   end to_stdlogic;

   -- converts std_logic into a string (1 to 1)
   function str(sl: std_logic) return string is
    variable s: string(1 to 1);
    begin
      s(1) := chr(sl);
      return s;
   end str;

   -- converts std_logic_vector into a string (binary base)
   -- (this also takes care of the fact that the range of
   --  a string is natural while a std_logic_vector may
   --  have an integer range)
   function str(slv: std_logic_vector) return string is
      variable result : string (1 to slv'length);
      variable r : integer;
   begin
      r := 1;
      for i in slv'range loop
         result(r) := chr(slv(i));
         r := r + 1;
      end loop;
      return result;
   end str;

   -- test isZero
   function iszero(a : std_logic_vector) return boolean is
   begin
      return    a = (a'high downto 0 => '0');
   end;

   -- FP IEEE compare function (found vs. real)
   function fp_equal_ieee(a : std_logic_vector; b : std_logic_vector; we : integer; wf : integer) return boolean is
   begin
      if a(wf+we downto wf) = b(wf+we downto wf) and b(we+wf-1 downto wf) = (we downto 1 => '1') then
         if iszero(b(wf-1 downto 0)) then return  iszero(a(wf-1 downto 0));
         else return not iszero(a(wf - 1 downto 0));
         end if;
      else
         return a(a'high downto 0) = b(b'high downto 0);
      end if;
   end;

   function fp_inf_or_equal_ieee(a : std_logic_vector; b : std_logic_vector; we : integer; wf : integer) return boolean is
   begin
      return false; -- TODO
   end;

   -- FP subtypes for casting
   subtype fp8 is std_logic_vector(7 downto 0);
   function testLine(testCounter:integer; expectedOutputS: string(1 to 10000); expectedOutputSize: integer; R:  std_logic_vector(7 downto 0)) return boolean is
      variable expectedOutput: line;
      variable possibilityNumber : integer;
      variable testSuccess: boolean;
      variable errorMessage: string(1 to 10000);
      variable testSuccess_R: boolean;
      variable expected_R: bit_vector (7 downto 0); -- for list of values
      variable inf_R: bit_vector (7 downto 0); -- for intervals
      variable sup_R: bit_vector (7 downto 0); -- for intervals
   begin
      write(expectedOutput, expectedOutputS);
      read(expectedOutput, possibilityNumber); -- for R
      if possibilityNumber = 0 then
         -- TODO define what it means to have 0 possible output. Currently it means a test fails...
      end if;
      if possibilityNumber > 0 then -- a list of values
      testSuccess_R := false;
         for i in 1 to possibilityNumber loop
            read(expectedOutput, expected_R);
            if fp_equal_ieee(R, to_stdlogicvector(expected_R), 4, 3) then
               testSuccess_R := true;
            end if;
            end loop;
      end if;
      if possibilityNumber < 0  then -- an interval
         read(expectedOutput, inf_R);
         read(expectedOutput, sup_R);
         if possibilityNumber =-1  then -- an unsigned interval
            testSuccess_R := (R >= to_stdlogicvector(inf_R)) and (R <= to_stdlogicvector(sup_R));
         elsif possibilityNumber =-2  then -- a signed interval
            testSuccess_R := (signed(R) >= signed(to_stdlogicvector(inf_R))) and (signed(R) <= signed(to_stdlogicvector(sup_R)));
         elsif possibilityNumber =-3  then -- an IEEE floating-point interval
            testSuccess_R := fp_inf_or_equal_ieee(to_stdlogicvector(inf_R), R, 4, 3) and fp_inf_or_equal_ieee(R, to_stdlogicvector(sup_R), 4, 3);
         end if;
      end if;
      if testSuccess_R = false then
         report("Test #" & integer'image(testCounter) & ", incorrect output for R: " & lf & " expected values: " & expectedOutputS(1 to expectedOutputSize) & lf  & "          result:    " & str(R) ) severity error;
      end if;

      testSuccess := true and testSuccess_R;
      return testSuccess;
   end testLine;

begin
   -- Ticking clock signal
   process
   begin
      clk <= '0';
      wait for 5 ns;
      clk <= '1';
      wait for 5 ns;
   end process;

   test: IEEEFPFMA_4_3_comb_uid2
      port map ( A => A,
                 B => B,
                 C => C,
                 negateAB => negateAB,
                 negateC => negateC,
                 RndMode => RndMode,
                 R => R);
   -- Process that sets the inputs  (read from a file)
   process
      variable input, expectedOutput : line;
      variable tmpChar : character;
      file inputsFile : text is "test.input";
      variable V_A : bit_vector(7 downto 0);
      variable V_B : bit_vector(7 downto 0);
      variable V_C : bit_vector(7 downto 0);
      variable V_negateAB : bit_vector(0 downto 0);
      variable V_negateC : bit_vector(0 downto 0);
      variable V_RndMode : bit_vector(1 downto 0);
      variable V_R : bit_vector(7 downto 0);
   begin
      -- Send reset
      rst <= '1';
      wait for 10 ns;
      rst <= '0';
      readline(inputsFile, input); -- skip the first line of advertising
      while not endfile(inputsFile) loop
         readline(inputsFile, input); -- skip the comment line
         readline(inputsFile, input);
         readline(inputsFile, expectedOutput); -- comment line, unused in this process
         readline(inputsFile, expectedOutput); -- unused in this process
         read(input ,V_A);
         read(input,tmpChar);
         A <= to_stdlogicvector(V_A);
         read(input ,V_B);
         read(input,tmpChar);
         B <= to_stdlogicvector(V_B);
         read(input ,V_C);
         read(input,tmpChar);
         C <= to_stdlogicvector(V_C);
         read(input ,V_negateAB);
         read(input,tmpChar);
         negateAB <= to_stdlogicvector(V_negateAB)(0);
         read(input ,V_negateC);
         read(input,tmpChar);
         negateC <= to_stdlogicvector(V_negateC)(0);
         read(input ,V_RndMode);
         read(input,tmpChar);
         RndMode <= to_stdlogicvector(V_RndMode);
         wait for 10 ns;
      end loop;
         wait for 100 ns; -- wait for pipeline to flush (and some more)
   end process;

    -- Process that verifies the corresponding output
   process
      file inputsFile : text is "test.input";
      variable input, expectedOutput : line;
      variable testCounter : integer := 1;
      variable errorCounter : integer := 0;
      variable expectedOutputString : string(1 to 10000);
      variable testSuccess: boolean;
   begin
      wait for 12 ns; -- wait for reset
      readline(inputsFile, input); -- skip the first line of advertising
      while not endfile(inputsFile) loop
         readline(inputsFile, input); -- input comment, unused
         readline(inputsFile, input); -- input line, unused
         readline(inputsFile, expectedOutput); -- comment line, unused in this process
         readline(inputsFile, expectedOutput);
         expectedOutputString := expectedOutput.all & (expectedOutput'Length+1 to 10000 => ' ');
         testSuccess := testLine(testCounter, expectedOutputString, expectedOutput'Length, R);
         if not testSuccess then
               errorCounter := errorCounter + 1; -- incrementing global error counter
         end if;
            testCounter := testCounter + 1; -- incrementing global error counter
         wait for 10 ns;
      end loop;
      report integer'image(errorCounter) & " error(s) encoutered." severity note;
      report "End of simulation after " & integer'image(testCounter-1) & " tests" severity note;
   end process;

end architecture;