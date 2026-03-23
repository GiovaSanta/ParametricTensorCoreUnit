
--------------------------------------------------------------------------------
--                            TestBench_LNSMul_4_9
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved
-- Authors: Florent de Dinechin, Cristian Klein, Nicolas Brunie (2007-2010)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity TestBench_LNSMul_4_9 is
end entity;

architecture behavorial of TestBench_LNSMul_4_9 is
   component LNSMul_4_9 is
      port ( clk, rst : in std_logic;
             nA : in  std_logic_vector(15 downto 0);
             nB : in  std_logic_vector(15 downto 0);
             nR : out  std_logic_vector(15 downto 0)   );
   end component;
   
   signal nA :  std_logic_vector(15 downto 0);
   signal nB :  std_logic_vector(15 downto 0);
   signal nR :  std_logic_vector(15 downto 0);
   signal clk : std_logic;
   signal rst : std_logic;

   -- FP compare function (found vs. real)
   function fp_equal(a : std_logic_vector; b : std_logic_vector) return boolean is
   begin
      if b(b'high downto b'high-1) = "01" then
         return a = b;
      elsif b(b'high downto b'high-1) = "11" then
         return (a(a'high downto a'high-1)=b(b'high downto b'high-1));
      else
         return a(a'high downto a'high-2) = b(b'high downto b'high-2);
      end if;
   end;



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
      return  a = (a'high downto 0 => '0');
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
begin
   test: LNSMul_4_9  -- pipelineDepth=0 maxInDelay=0
      port map ( clk  => clk,
                 rst  => rst,
                 nA => nA,
                 nB => nB,
                 nR => nR);
   -- Ticking clock signal
   process
   begin
      clk <= '0';
      wait for 5 ns;
      clk <= '1';
      wait for 5 ns;
   end process;

   -- Setting the inputs
   process
   begin
      -- Send reset
      rst <= '1';
      wait for 10 ns;
      rst <= '0';
      nA <= "1010011100100000";
      nB <= "0111010101010011";
      wait for 10 ns;
      nA <= "0111110011110011";
      nB <= "0010000011111001";
      wait for 10 ns;
      nA <= "1000101001100001";
      nB <= "0100100110000000";
      wait for 10 ns;
      nA <= "1001100101010111";
      nB <= "0110111111011111";
      wait for 10 ns;
      nA <= "0110010101110011";
      nB <= "0100100100001110";
      wait for 10 ns;
      nA <= "1101110100111011";
      nB <= "1100001111111000";
      wait for 10 ns;
      nA <= "0001110010000001";
      nB <= "1110101011000111";
      wait for 10 ns;
      nA <= "1101011011100100";
      nB <= "0110001111101001";
      wait for 10 ns;
      nA <= "0010000000100010";
      nB <= "1110100101110100";
      wait for 10 ns;
      nA <= "1011011000010001";
      nB <= "1011101110110000";
      wait for 10 ns;
      nA <= "0100000101000101";
      nB <= "0111010001101110";
      wait for 10 ns;
      nA <= "1001101000001010";
      nB <= "0000101111111000";
      wait for 10 ns;
      nA <= "0001110111111010";
      nB <= "1101111111100010";
      wait for 10 ns;
      nA <= "1011101101101111";
      nB <= "1100101001100010";
      wait for 10 ns;
      nA <= "0001110101001110";
      nB <= "0011011011011001";
      wait for 10 ns;
      nA <= "0011001111101010";
      nB <= "1110110001101111";
      wait for 10 ns;
      nA <= "0001111011111100";
      nB <= "0010000010001101";
      wait for 10 ns;
      nA <= "1000011000001110";
      nB <= "0000000101001100";
      wait for 10 ns;
      nA <= "1001110100010111";
      nB <= "0110110101110111";
      wait for 10 ns;
      nA <= "1010110000011111";
      nB <= "1110011110001001";
      wait for 10 ns;
      nA <= "1110110111100001";
      nB <= "1100010000000101";
      wait for 10 ns;
      nA <= "1100001011000101";
      nB <= "0100001110011110";
      wait for 10 ns;
      nA <= "0111110110001111";
      nB <= "0010100001010101";
      wait for 10 ns;
      nA <= "0111110111010000";
      nB <= "1011100000000101";
      wait for 10 ns;
      nA <= "1010110000011001";
      nB <= "1100101100000110";
      wait for 10 ns;
      nA <= "0001000100001100";
      nB <= "0000011111011100";
      wait for 10 ns;
      nA <= "1111011101111000";
      nB <= "1101010010001011";
      wait for 10 ns;
      nA <= "0111101101101111";
      nB <= "1101101111000101";
      wait for 10 ns;
      nA <= "0000110011001100";
      nB <= "1001110000111101";
      wait for 10 ns;
      nA <= "1100000101011001";
      nB <= "1000010000100001";
      wait for 10 ns;
      nA <= "0100001111001111";
      nB <= "0010110100111100";
      wait for 10 ns;
      nA <= "0001101010101011";
      nB <= "1111010110010000";
      wait for 10 ns;
      nA <= "1011101101100111";
      nB <= "1100011001101110";
      wait for 10 ns;
      nA <= "0111011011101101";
      nB <= "0101010010001110";
      wait for 10 ns;
      nA <= "1000100100111010";
      nB <= "1111101000010011";
      wait for 10 ns;
      nA <= "0000001001101111";
      nB <= "1100011000011101";
      wait for 10 ns;
      nA <= "0000010011111100";
      nB <= "1111010000100101";
      wait for 10 ns;
      nA <= "0011101110111101";
      nB <= "0000001011001001";
      wait for 10 ns;
      nA <= "0100010110100101";
      nB <= "1100011100001000";
      wait for 10 ns;
      nA <= "1000001000010001";
      nB <= "1010001001011100";
      wait for 10 ns;
      nA <= "1000110000101110";
      nB <= "0101110111100011";
      wait for 10 ns;
      nA <= "1001001001001100";
      nB <= "0101111110101000";
      wait for 10 ns;
      nA <= "0000110011110001";
      nB <= "1010011110110110";
      wait for 10 ns;
      nA <= "0000010001100100";
      nB <= "0000111101100011";
      wait for 10 ns;
      nA <= "0011001111000110";
      nB <= "0110111000000000";
      wait for 10 ns;
      nA <= "1111010000100000";
      nB <= "0011000111011110";
      wait for 10 ns;
      nA <= "0010001010100001";
      nB <= "0111000101101000";
      wait for 10 ns;
      nA <= "1010100110101111";
      nB <= "0111000001110101";
      wait for 10 ns;
      nA <= "0001001001000011";
      nB <= "0110100010011101";
      wait for 10 ns;
      nA <= "0010100101000000";
      nB <= "0110101010001000";
      wait for 10 ns;
      nA <= "1101110001100100";
      nB <= "0001100101010010";
      wait for 10 ns;
      nA <= "0100011000100000";
      nB <= "1011111100001101";
      wait for 10 ns;
      nA <= "0010110100001001";
      nB <= "1000010100011110";
      wait for 10 ns;
      nA <= "1111111001011001";
      nB <= "1101010011000001";
      wait for 10 ns;
      nA <= "1101000011110111";
      nB <= "0100001100101111";
      wait for 10 ns;
      nA <= "0101011100100111";
      nB <= "0110101110001110";
      wait for 10 ns;
      nA <= "0101001110111111";
      nB <= "0101111111111100";
      wait for 10 ns;
      nA <= "1001011111001111";
      nB <= "0000110110111011";
      wait for 10 ns;
      nA <= "0100011010111111";
      nB <= "0011100101100100";
      wait for 10 ns;
      nA <= "1000011110001110";
      nB <= "0100001001010101";
      wait for 10 ns;
      nA <= "1010001100101101";
      nB <= "1011011110001110";
      wait for 10 ns;
      nA <= "1100000001011101";
      nB <= "1001000000011100";
      wait for 10 ns;
      nA <= "1011000111001001";
      nB <= "0000010100001000";
      wait for 10 ns;
      nA <= "1111010101001011";
      nB <= "0010101011110110";
      wait for 10 ns;
      nA <= "0101001101110111";
      nB <= "0010011110000011";
      wait for 10 ns;
      nA <= "0111110010110110";
      nB <= "1110100001000100";
      wait for 10 ns;
      nA <= "0001101000100000";
      nB <= "0011110111010010";
      wait for 10 ns;
      nA <= "0101010101111101";
      nB <= "1111100001101100";
      wait for 10 ns;
      nA <= "0110010110010101";
      nB <= "1010011101100010";
      wait for 10 ns;
      nA <= "1101001101000011";
      nB <= "0101110100001101";
      wait for 10 ns;
      nA <= "1011111111111001";
      nB <= "1011101010000101";
      wait for 10 ns;
      nA <= "0100000011001001";
      nB <= "1010000010011011";
      wait for 10 ns;
      nA <= "0010100111100000";
      nB <= "1011011011001011";
      wait for 10 ns;
      nA <= "1010000001011111";
      nB <= "1100110011110011";
      wait for 10 ns;
      nA <= "1011001100111011";
      nB <= "1110010011111101";
      wait for 10 ns;
      nA <= "0010001100000011";
      nB <= "0111100111110100";
      wait for 10 ns;
      nA <= "0100100011000001";
      nB <= "0110100110011001";
      wait for 10 ns;
      nA <= "1101000110011000";
      nB <= "0100110110000111";
      wait for 10 ns;
      nA <= "0101111011111000";
      nB <= "0011110001000110";
      wait for 10 ns;
      nA <= "0100110010101010";
      nB <= "1110110110111010";
      wait for 10 ns;
      nA <= "0100101111011110";
      nB <= "0111111000000001";
      wait for 10 ns;
      nA <= "1111100101101100";
      nB <= "0110010111001000";
      wait for 10 ns;
      nA <= "1100111001100100";
      nB <= "1011110111111110";
      wait for 10 ns;
      nA <= "1110101010000001";
      nB <= "0110111000110010";
      wait for 10 ns;
      nA <= "1100110011011000";
      nB <= "1011010101000111";
      wait for 10 ns;
      nA <= "1011000110001101";
      nB <= "0000110110000101";
      wait for 10 ns;
      nA <= "1101010110111010";
      nB <= "0001010000001010";
      wait for 10 ns;
      nA <= "1001111011110001";
      nB <= "1100110101010101";
      wait for 10 ns;
      nA <= "0110100011001101";
      nB <= "0101010011100011";
      wait for 10 ns;
      nA <= "0000000101101001";
      nB <= "0101001010110101";
      wait for 10 ns;
      nA <= "1001100011110000";
      nB <= "0110011110001111";
      wait for 10 ns;
      nA <= "0101110001010111";
      nB <= "0101111100010110";
      wait for 10 ns;
      nA <= "0110001010001011";
      nB <= "0111011101110100";
      wait for 10 ns;
      nA <= "0110010000001010";
      nB <= "0011000000100110";
      wait for 10 ns;
      nA <= "0000100101101000";
      nB <= "0010100101001100";
      wait for 10 ns;
      nA <= "1100111110010111";
      nB <= "1111011000111010";
      wait for 10 ns;
      nA <= "0000101110100000";
      nB <= "1101010010110111";
      wait for 10 ns;
      nA <= "1011010100000101";
      nB <= "1000000000110100";
      wait for 10 ns;
      nA <= "1110000011110101";
      nB <= "0010000011011101";
      wait for 10 ns;
      nA <= "1011010110111110";
      nB <= "1000011000001100";
      wait for 10 ns;
      wait for 100000 ns; -- allow simulation to finish
   end process;

   -- Checking the outputs
   process
   begin
      wait for 10 ns; -- wait for reset to complete
      wait for 2 ns; -- wait for pipeline to flush
      -- current time: 12
      -- input: nA <= "1010011100100000";
      -- input: nB <= "0111010101010011";
      assert false or nR="1001110001110011" report "Incorrect output value for nR, expected 1001110001110011 | Test Number : 0  " severity ERROR;
      wait for 10 ns;
      -- current time: 22
      -- input: nA <= "0111110011110011";
      -- input: nB <= "0010000011111001";
      assert false or nR="0001110111101100" report "Incorrect output value for nR, expected 0001110111101100 | Test Number : 1  " severity ERROR;
      wait for 10 ns;
      -- current time: 32
      -- input: nA <= "1000101001100001";
      -- input: nB <= "0100100110000000";
      assert false or nR="1001001111100001" report "Incorrect output value for nR, expected 1001001111100001 | Test Number : 2  " severity ERROR;
      wait for 10 ns;
      -- current time: 42
      -- input: nA <= "1001100101010111";
      -- input: nB <= "0110111111011111";
      assert false or nR="1010100100110110" report "Incorrect output value for nR, expected 1010100100110110 | Test Number : 3  " severity ERROR;
      wait for 10 ns;
      -- current time: 52
      -- input: nA <= "0110010101110011";
      -- input: nB <= "0100100100001110";
      assert false or nR="1010111010000001" report "Incorrect output value for nR, expected 1010111010000001 | Test Number : 4  " severity ERROR;
      wait for 10 ns;
      -- current time: 62
      -- input: nA <= "1101110100111011";
      -- input: nB <= "1100001111111000";
      assert false or nR="1100000100110011" report "Incorrect output value for nR, expected 1100000100110011 | Test Number : 5  " severity ERROR;
      wait for 10 ns;
      -- current time: 72
      -- input: nA <= "0001110010000001";
      -- input: nB <= "1110101011000111";
      assert false or nR="1110011101001000" report "Incorrect output value for nR, expected 1110011101001000 | Test Number : 6  " severity ERROR;
      wait for 10 ns;
      -- current time: 82
      -- input: nA <= "1101011011100100";
      -- input: nB <= "0110001111101001";
      assert false or nR="1111101011001101" report "Incorrect output value for nR, expected 1111101011001101 | Test Number : 7  " severity ERROR;
      wait for 10 ns;
      -- current time: 92
      -- input: nA <= "0010000000100010";
      -- input: nB <= "1110100101110100";
      assert false or nR="1100100110010110" report "Incorrect output value for nR, expected 1100100110010110 | Test Number : 8  " severity ERROR;
      wait for 10 ns;
      -- current time: 102
      -- input: nA <= "1011011000010001";
      -- input: nB <= "1011101110110000";
      assert false or nR="1001000111000001" report "Incorrect output value for nR, expected 1001000111000001 | Test Number : 9  " severity ERROR;
      wait for 10 ns;
      -- current time: 112
      -- input: nA <= "0100000101000101";
      -- input: nB <= "0111010001101110";
      assert false or nR="1011010110110011" report "Incorrect output value for nR, expected 1011010110110011 | Test Number : 10  " severity ERROR;
      wait for 10 ns;
      -- current time: 122
      -- input: nA <= "1001101000001010";
      -- input: nB <= "0000101111111000";
      assert false or nR="1100011000000010" report "Incorrect output value for nR, expected 1100011000000010 | Test Number : 11  " severity ERROR;
      wait for 10 ns;
      -- current time: 132
      -- input: nA <= "0001110111111010";
      -- input: nB <= "1101111111100010";
      assert false or nR="1101110111011100" report "Incorrect output value for nR, expected 1101110111011100 | Test Number : 12  " severity ERROR;
      wait for 10 ns;
      -- current time: 142
      -- input: nA <= "1011101101101111";
      -- input: nB <= "1100101001100010";
      assert false or nR="1110010111010001" report "Incorrect output value for nR, expected 1110010111010001 | Test Number : 13  " severity ERROR;
      wait for 10 ns;
      -- current time: 152
      -- input: nA <= "0001110101001110";
      -- input: nB <= "0011011011011001";
      assert false or nR="0011010000100111" report "Incorrect output value for nR, expected 0011010000100111 | Test Number : 14  " severity ERROR;
      wait for 10 ns;
      -- current time: 162
      -- input: nA <= "0011001111101010";
      -- input: nB <= "1110110001101111";
      assert false or nR="1100000001011001" report "Incorrect output value for nR, expected 1100000001011001 | Test Number : 15  " severity ERROR;
      wait for 10 ns;
      -- current time: 172
      -- input: nA <= "0001111011111100";
      -- input: nB <= "0010000010001101";
      assert false or nR="0011111110001001" report "Incorrect output value for nR, expected 0011111110001001 | Test Number : 16  " severity ERROR;
      wait for 10 ns;
      -- current time: 182
      -- input: nA <= "1000011000001110";
      -- input: nB <= "0000000101001100";
      assert false or nR="1100011101011010" report "Incorrect output value for nR, expected 1100011101011010 | Test Number : 17  " severity ERROR;
      wait for 10 ns;
      -- current time: 192
      -- input: nA <= "1001110100010111";
      -- input: nB <= "0110110101110111";
      assert false or nR="1010101010001110" report "Incorrect output value for nR, expected 1010101010001110 | Test Number : 18  " severity ERROR;
      wait for 10 ns;
      -- current time: 202
      -- input: nA <= "1010110000011111";
      -- input: nB <= "1110011110001001";
      assert false or nR="1101001110101000" report "Incorrect output value for nR, expected 1101001110101000 | Test Number : 19  " severity ERROR;
      wait for 10 ns;
      -- current time: 212
      -- input: nA <= "1110110111100001";
      -- input: nB <= "1100010000000101";
      assert false or nR="1111000111100110" report "Incorrect output value for nR, expected 1111000111100110 | Test Number : 20  " severity ERROR;
      wait for 10 ns;
      -- current time: 222
      -- input: nA <= "1100001011000101";
      -- input: nB <= "0100001110011110";
      assert false or nR="1100011001100011" report "Incorrect output value for nR, expected 1100011001100011 | Test Number : 21  " severity ERROR;
      wait for 10 ns;
      -- current time: 232
      -- input: nA <= "0111110110001111";
      -- input: nB <= "0010100001010101";
      assert false or nR="0000010111100100" report "Incorrect output value for nR, expected 0000010111100100 | Test Number : 22  " severity ERROR;
      wait for 10 ns;
      -- current time: 242
      -- input: nA <= "0111110111010000";
      -- input: nB <= "1011100000000101";
      assert false or nR="1001010111010101" report "Incorrect output value for nR, expected 1001010111010101 | Test Number : 23  " severity ERROR;
      wait for 10 ns;
      -- current time: 252
      -- input: nA <= "1010110000011001";
      -- input: nB <= "1100101100000110";
      assert false or nR="1111011100011111" report "Incorrect output value for nR, expected 1111011100011111 | Test Number : 24  " severity ERROR;
      wait for 10 ns;
      -- current time: 262
      -- input: nA <= "0001000100001100";
      -- input: nB <= "0000011111011100";
      assert false or nR="0001100011101000" report "Incorrect output value for nR, expected 0001100011101000 | Test Number : 25  " severity ERROR;
      wait for 10 ns;
      -- current time: 272
      -- input: nA <= "1111011101111000";
      -- input: nB <= "1101010010001011";
      assert false or nR="1110110000000011" report "Incorrect output value for nR, expected 1110110000000011 | Test Number : 26  " severity ERROR;
      wait for 10 ns;
      -- current time: 282
      -- input: nA <= "0111101101101111";
      -- input: nB <= "1101101111000101";
      assert false or nR="1111011100110100" report "Incorrect output value for nR, expected 1111011100110100 | Test Number : 27  " severity ERROR;
      wait for 10 ns;
      -- current time: 292
      -- input: nA <= "0000110011001100";
      -- input: nB <= "1001110000111101";
      assert false or nR="1100100100001001" report "Incorrect output value for nR, expected 1100100100001001 | Test Number : 28  " severity ERROR;
      wait for 10 ns;
      -- current time: 302
      -- input: nA <= "1100000101011001";
      -- input: nB <= "1000010000100001";
      assert false or nR="1100010101111010" report "Incorrect output value for nR, expected 1100010101111010 | Test Number : 29  " severity ERROR;
      wait for 10 ns;
      -- current time: 312
      -- input: nA <= "0100001111001111";
      -- input: nB <= "0010110100111100";
      assert false or nR="0011000100001011" report "Incorrect output value for nR, expected 0011000100001011 | Test Number : 30  " severity ERROR;
      wait for 10 ns;
      -- current time: 322
      -- input: nA <= "0001101010101011";
      -- input: nB <= "1111010110010000";
      assert false or nR="1111000000111011" report "Incorrect output value for nR, expected 1111000000111011 | Test Number : 31  " severity ERROR;
      wait for 10 ns;
      -- current time: 332
      -- input: nA <= "1011101101100111";
      -- input: nB <= "1100011001101110";
      assert false or nR="1110000111010101" report "Incorrect output value for nR, expected 1110000111010101 | Test Number : 32  " severity ERROR;
      wait for 10 ns;
      -- current time: 342
      -- input: nA <= "0111011011101101";
      -- input: nB <= "0101010010001110";
      assert false or nR="1010101101111011" report "Incorrect output value for nR, expected 1010101101111011 | Test Number : 33  " severity ERROR;
      wait for 10 ns;
      -- current time: 352
      -- input: nA <= "1000100100111010";
      -- input: nB <= "1111101000010011";
      assert false or nR="1110001101001101" report "Incorrect output value for nR, expected 1110001101001101 | Test Number : 34  " severity ERROR;
      wait for 10 ns;
      -- current time: 362
      -- input: nA <= "0000001001101111";
      -- input: nB <= "1100011000011101";
      assert false or nR="1100100010001100" report "Incorrect output value for nR, expected 1100100010001100 | Test Number : 35  " severity ERROR;
      wait for 10 ns;
      -- current time: 372
      -- input: nA <= "0000010011111100";
      -- input: nB <= "1111010000100101";
      assert false or nR="1111100100100001" report "Incorrect output value for nR, expected 1111100100100001 | Test Number : 36  " severity ERROR;
      wait for 10 ns;
      -- current time: 382
      -- input: nA <= "0011101110111101";
      -- input: nB <= "0000001011001001";
      assert false or nR="0011111010000110" report "Incorrect output value for nR, expected 0011111010000110 | Test Number : 37  " severity ERROR;
      wait for 10 ns;
      -- current time: 392
      -- input: nA <= "0100010110100101";
      -- input: nB <= "1100011100001000";
      assert false or nR="1100110010101101" report "Incorrect output value for nR, expected 1100110010101101 | Test Number : 38  " severity ERROR;
      wait for 10 ns;
      -- current time: 402
      -- input: nA <= "1000001000010001";
      -- input: nB <= "1010001001011100";
      assert false or nR="1010010001101101" report "Incorrect output value for nR, expected 1010010001101101 | Test Number : 39  " severity ERROR;
      wait for 10 ns;
      -- current time: 412
      -- input: nA <= "1000110000101110";
      -- input: nB <= "0101110111100011";
      assert false or nR="1000101000010001" report "Incorrect output value for nR, expected 1000101000010001 | Test Number : 40  " severity ERROR;
      wait for 10 ns;
      -- current time: 422
      -- input: nA <= "1001001001001100";
      -- input: nB <= "0101111110101000";
      assert false or nR="1001000111110100" report "Incorrect output value for nR, expected 1001000111110100 | Test Number : 41  " severity ERROR;
      wait for 10 ns;
      -- current time: 432
      -- input: nA <= "0000110011110001";
      -- input: nB <= "1010011110110110";
      assert false or nR="1111010010100111" report "Incorrect output value for nR, expected 1111010010100111 | Test Number : 42  " severity ERROR;
      wait for 10 ns;
      -- current time: 442
      -- input: nA <= "0000010001100100";
      -- input: nB <= "0000111101100011";
      assert false or nR="0001001111000111" report "Incorrect output value for nR, expected 0001001111000111 | Test Number : 43  " severity ERROR;
      wait for 10 ns;
      -- current time: 452
      -- input: nA <= "0011001111000110";
      -- input: nB <= "0110111000000000";
      assert false or nR="0000000111000110" report "Incorrect output value for nR, expected 0000000111000110 | Test Number : 44  " severity ERROR;
      wait for 10 ns;
      -- current time: 462
      -- input: nA <= "1111010000100000";
      -- input: nB <= "0011000111011110";
      assert false or nR="1100010111111110" report "Incorrect output value for nR, expected 1100010111111110 | Test Number : 45  " severity ERROR;
      wait for 10 ns;
      -- current time: 472
      -- input: nA <= "0010001010100001";
      -- input: nB <= "0111000101101000";
      assert false or nR="0001010000001001" report "Incorrect output value for nR, expected 0001010000001001 | Test Number : 46  " severity ERROR;
      wait for 10 ns;
      -- current time: 482
      -- input: nA <= "1010100110101111";
      -- input: nB <= "0111000001110101";
      assert false or nR="1001101000100100" report "Incorrect output value for nR, expected 1001101000100100 | Test Number : 47  " severity ERROR;
      wait for 10 ns;
      -- current time: 492
      -- input: nA <= "0001001001000011";
      -- input: nB <= "0110100010011101";
      assert false or nR="0011101011100000" report "Incorrect output value for nR, expected 0011101011100000 | Test Number : 48  " severity ERROR;
      wait for 10 ns;
      -- current time: 502
      -- input: nA <= "0010100101000000";
      -- input: nB <= "0110101010001000";
      assert false or nR="0001001111001000" report "Incorrect output value for nR, expected 0001001111001000 | Test Number : 49  " severity ERROR;
      wait for 10 ns;
      -- current time: 512
      -- input: nA <= "1101110001100100";
      -- input: nB <= "0001100101010010";
      assert false or nR="1101010110110110" report "Incorrect output value for nR, expected 1101010110110110 | Test Number : 50  " severity ERROR;
      wait for 10 ns;
      -- current time: 522
      -- input: nA <= "0100011000100000";
      -- input: nB <= "1011111100001101";
      assert false or nR="1010010100101101" report "Incorrect output value for nR, expected 1010010100101101 | Test Number : 51  " severity ERROR;
      wait for 10 ns;
      -- current time: 532
      -- input: nA <= "0010110100001001";
      -- input: nB <= "1000010100011110";
      assert false or nR="1111001000100111" report "Incorrect output value for nR, expected 1111001000100111 | Test Number : 52  " severity ERROR;
      wait for 10 ns;
      -- current time: 542
      -- input: nA <= "1111111001011001";
      -- input: nB <= "1101010011000001";
      assert false or nR="1111001100011010" report "Incorrect output value for nR, expected 1111001100011010 | Test Number : 53  " severity ERROR;
      wait for 10 ns;
      -- current time: 552
      -- input: nA <= "1101000011110111";
      -- input: nB <= "0100001100101111";
      assert false or nR="1101010000100110" report "Incorrect output value for nR, expected 1101010000100110 | Test Number : 54  " severity ERROR;
      wait for 10 ns;
      -- current time: 562
      -- input: nA <= "0101011100100111";
      -- input: nB <= "0110101110001110";
      assert false or nR="1010001010110101" report "Incorrect output value for nR, expected 1010001010110101 | Test Number : 55  " severity ERROR;
      wait for 10 ns;
      -- current time: 572
      -- input: nA <= "0101001110111111";
      -- input: nB <= "0101111111111100";
      assert false or nR="1001001110111011" report "Incorrect output value for nR, expected 1001001110111011 | Test Number : 56  " severity ERROR;
      wait for 10 ns;
      -- current time: 582
      -- input: nA <= "1001011111001111";
      -- input: nB <= "0000110110111011";
      assert false or nR="1100010110001010" report "Incorrect output value for nR, expected 1100010110001010 | Test Number : 57  " severity ERROR;
      wait for 10 ns;
      -- current time: 592
      -- input: nA <= "0100011010111111";
      -- input: nB <= "0011100101100100";
      assert false or nR="0010000000100011" report "Incorrect output value for nR, expected 0010000000100011 | Test Number : 58  " severity ERROR;
      wait for 10 ns;
      -- current time: 602
      -- input: nA <= "1000011110001110";
      -- input: nB <= "0100001001010101";
      assert false or nR="1000100111100011" report "Incorrect output value for nR, expected 1000100111100011 | Test Number : 59  " severity ERROR;
      wait for 10 ns;
      -- current time: 612
      -- input: nA <= "1010001100101101";
      -- input: nB <= "1011011110001110";
      assert false or nR="1001101010111011" report "Incorrect output value for nR, expected 1001101010111011 | Test Number : 60  " severity ERROR;
      wait for 10 ns;
      -- current time: 622
      -- input: nA <= "1100000001011101";
      -- input: nB <= "1001000000011100";
      assert false or nR="1101000001111001" report "Incorrect output value for nR, expected 1101000001111001 | Test Number : 61  " severity ERROR;
      wait for 10 ns;
      -- current time: 632
      -- input: nA <= "1011000111001001";
      -- input: nB <= "0000010100001000";
      assert false or nR="1111011011010001" report "Incorrect output value for nR, expected 1111011011010001 | Test Number : 62  " severity ERROR;
      wait for 10 ns;
      -- current time: 642
      -- input: nA <= "1111010101001011";
      -- input: nB <= "0010101011110110";
      assert false or nR="1100000001000001" report "Incorrect output value for nR, expected 1100000001000001 | Test Number : 63  " severity ERROR;
      wait for 10 ns;
      -- current time: 652
      -- input: nA <= "0101001101110111";
      -- input: nB <= "0010011110000011";
      assert false or nR="0011101011111010" report "Incorrect output value for nR, expected 0011101011111010 | Test Number : 64  " severity ERROR;
      wait for 10 ns;
      -- current time: 662
      -- input: nA <= "0111110010110110";
      -- input: nB <= "1110100001000100";
      assert false or nR="1100010011111010" report "Incorrect output value for nR, expected 1100010011111010 | Test Number : 65  " severity ERROR;
      wait for 10 ns;
      -- current time: 672
      -- input: nA <= "0001101000100000";
      -- input: nB <= "0011110111010010";
      assert false or nR="0011011111110010" report "Incorrect output value for nR, expected 0011011111110010 | Test Number : 66  " severity ERROR;
      wait for 10 ns;
      -- current time: 682
      -- input: nA <= "0101010101111101";
      -- input: nB <= "1111100001101100";
      assert false or nR="1110110111101001" report "Incorrect output value for nR, expected 1110110111101001 | Test Number : 67  " severity ERROR;
      wait for 10 ns;
      -- current time: 692
      -- input: nA <= "0110010110010101";
      -- input: nB <= "1010011101100010";
      assert false or nR="1000110011110111" report "Incorrect output value for nR, expected 1000110011110111 | Test Number : 68  " severity ERROR;
      wait for 10 ns;
      -- current time: 702
      -- input: nA <= "1101001101000011";
      -- input: nB <= "0101110100001101";
      assert false or nR="1101000001010000" report "Incorrect output value for nR, expected 1101000001010000 | Test Number : 69  " severity ERROR;
      wait for 10 ns;
      -- current time: 712
      -- input: nA <= "1011111111111001";
      -- input: nB <= "1011101010000101";
      assert false or nR="1001101001111110" report "Incorrect output value for nR, expected 1001101001111110 | Test Number : 70  " severity ERROR;
      wait for 10 ns;
      -- current time: 722
      -- input: nA <= "0100000011001001";
      -- input: nB <= "1010000010011011";
      assert false or nR="1010000101100100" report "Incorrect output value for nR, expected 1010000101100100 | Test Number : 71  " severity ERROR;
      wait for 10 ns;
      -- current time: 732
      -- input: nA <= "0010100111100000";
      -- input: nB <= "1011011011001011";
      assert false or nR="1100000010101011" report "Incorrect output value for nR, expected 1100000010101011 | Test Number : 72  " severity ERROR;
      wait for 10 ns;
      -- current time: 742
      -- input: nA <= "1010000001011111";
      -- input: nB <= "1100110011110011";
      assert false or nR="1110110101010010" report "Incorrect output value for nR, expected 1110110101010010 | Test Number : 73  " severity ERROR;
      wait for 10 ns;
      -- current time: 752
      -- input: nA <= "1011001100111011";
      -- input: nB <= "1110010011111101";
      assert false or nR="1101100000111000" report "Incorrect output value for nR, expected 1101100000111000 | Test Number : 74  " severity ERROR;
      wait for 10 ns;
      -- current time: 762
      -- input: nA <= "0010001100000011";
      -- input: nB <= "0111100111110100";
      assert false or nR="0001110011110111" report "Incorrect output value for nR, expected 0001110011110111 | Test Number : 75  " severity ERROR;
      wait for 10 ns;
      -- current time: 772
      -- input: nA <= "0100100011000001";
      -- input: nB <= "0110100110011001";
      assert false or nR="1011001001011010" report "Incorrect output value for nR, expected 1011001001011010 | Test Number : 76  " severity ERROR;
      wait for 10 ns;
      -- current time: 782
      -- input: nA <= "1101000110011000";
      -- input: nB <= "0100110110000111";
      assert false or nR="1101111100011111" report "Incorrect output value for nR, expected 1101111100011111 | Test Number : 77  " severity ERROR;
      wait for 10 ns;
      -- current time: 792
      -- input: nA <= "0101111011111000";
      -- input: nB <= "0011110001000110";
      assert false or nR="0011101100111110" report "Incorrect output value for nR, expected 0011101100111110 | Test Number : 78  " severity ERROR;
      wait for 10 ns;
      -- current time: 802
      -- input: nA <= "0100110010101010";
      -- input: nB <= "1110110110111010";
      assert false or nR="1111101001100100" report "Incorrect output value for nR, expected 1111101001100100 | Test Number : 79  " severity ERROR;
      wait for 10 ns;
      -- current time: 812
      -- input: nA <= "0100101111011110";
      -- input: nB <= "0111111000000001";
      assert false or nR="1010100111011111" report "Incorrect output value for nR, expected 1010100111011111 | Test Number : 80  " severity ERROR;
      wait for 10 ns;
      -- current time: 822
      -- input: nA <= "1111100101101100";
      -- input: nB <= "0110010111001000";
      assert false or nR="1101111100110100" report "Incorrect output value for nR, expected 1101111100110100 | Test Number : 81  " severity ERROR;
      wait for 10 ns;
      -- current time: 832
      -- input: nA <= "1100111001100100";
      -- input: nB <= "1011110111111110";
      assert false or nR="1110110001100010" report "Incorrect output value for nR, expected 1110110001100010 | Test Number : 82  " severity ERROR;
      wait for 10 ns;
      -- current time: 842
      -- input: nA <= "1110101010000001";
      -- input: nB <= "0110111000110010";
      assert false or nR="1101100010110011" report "Incorrect output value for nR, expected 1101100010110011 | Test Number : 83  " severity ERROR;
      wait for 10 ns;
      -- current time: 852
      -- input: nA <= "1100110011011000";
      -- input: nB <= "1011010101000111";
      assert false or nR="1110001000011111" report "Incorrect output value for nR, expected 1110001000011111 | Test Number : 84  " severity ERROR;
      wait for 10 ns;
      -- current time: 862
      -- input: nA <= "1011000110001101";
      -- input: nB <= "0000110110000101";
      assert false or nR="1111111100010010" report "Incorrect output value for nR, expected 1111111100010010 | Test Number : 85  " severity ERROR;
      wait for 10 ns;
      -- current time: 872
      -- input: nA <= "1101010110111010";
      -- input: nB <= "0001010000001010";
      assert false or nR="1100100111000100" report "Incorrect output value for nR, expected 1100100111000100 | Test Number : 86  " severity ERROR;
      wait for 10 ns;
      -- current time: 882
      -- input: nA <= "1001111011110001";
      -- input: nB <= "1100110101010101";
      assert false or nR="1100110001000110" report "Incorrect output value for nR, expected 1100110001000110 | Test Number : 87  " severity ERROR;
      wait for 10 ns;
      -- current time: 892
      -- input: nA <= "0110100011001101";
      -- input: nB <= "0101010011100011";
      assert false or nR="1011110110110000" report "Incorrect output value for nR, expected 1011110110110000 | Test Number : 88  " severity ERROR;
      wait for 10 ns;
      -- current time: 902
      -- input: nA <= "0000000101101001";
      -- input: nB <= "0101001010110101";
      assert false or nR="0001010000011110" report "Incorrect output value for nR, expected 0001010000011110 | Test Number : 89  " severity ERROR;
      wait for 10 ns;
      -- current time: 912
      -- input: nA <= "1001100011110000";
      -- input: nB <= "0110011110001111";
      assert false or nR="1010000001111111" report "Incorrect output value for nR, expected 1010000001111111 | Test Number : 90  " severity ERROR;
      wait for 10 ns;
      -- current time: 922
      -- input: nA <= "0101110001010111";
      -- input: nB <= "0101111100010110";
      assert false or nR="1001101101101101" report "Incorrect output value for nR, expected 1001101101101101 | Test Number : 91  " severity ERROR;
      wait for 10 ns;
      -- current time: 932
      -- input: nA <= "0110001010001011";
      -- input: nB <= "0111011101110100";
      assert false or nR="1001100111111111" report "Incorrect output value for nR, expected 1001100111111111 | Test Number : 92  " severity ERROR;
      wait for 10 ns;
      -- current time: 942
      -- input: nA <= "0110010000001010";
      -- input: nB <= "0011000000100110";
      assert false or nR="0001010000110000" report "Incorrect output value for nR, expected 0001010000110000 | Test Number : 93  " severity ERROR;
      wait for 10 ns;
      -- current time: 952
      -- input: nA <= "0000100101101000";
      -- input: nB <= "0010100101001100";
      assert false or nR="0011001010110100" report "Incorrect output value for nR, expected 0011001010110100 | Test Number : 94  " severity ERROR;
      wait for 10 ns;
      -- current time: 962
      -- input: nA <= "1100111110010111";
      -- input: nB <= "1111011000111010";
      assert false or nR="1110010111010001" report "Incorrect output value for nR, expected 1110010111010001 | Test Number : 95  " severity ERROR;
      wait for 10 ns;
      -- current time: 972
      -- input: nA <= "0000101110100000";
      -- input: nB <= "1101010010110111";
      assert false or nR="1100000001010111" report "Incorrect output value for nR, expected 1100000001010111 | Test Number : 96  " severity ERROR;
      wait for 10 ns;
      -- current time: 982
      -- input: nA <= "1011010100000101";
      -- input: nB <= "1000000000110100";
      assert false or nR="1011010100111001" report "Incorrect output value for nR, expected 1011010100111001 | Test Number : 97  " severity ERROR;
      wait for 10 ns;
      -- current time: 992
      -- input: nA <= "1110000011110101";
      -- input: nB <= "0010000011011101";
      assert false or nR="1100000111010010" report "Incorrect output value for nR, expected 1100000111010010 | Test Number : 98  " severity ERROR;
      wait for 10 ns;
      -- current time: 1002
      -- input: nA <= "1011010110111110";
      -- input: nB <= "1000011000001100";
      assert false or nR="1011101111001010" report "Incorrect output value for nR, expected 1011101111001010 | Test Number : 99  " severity ERROR;
      wait for 10 ns;
      assert false report "End of simulation" severity failure;
   end process;

end architecture;