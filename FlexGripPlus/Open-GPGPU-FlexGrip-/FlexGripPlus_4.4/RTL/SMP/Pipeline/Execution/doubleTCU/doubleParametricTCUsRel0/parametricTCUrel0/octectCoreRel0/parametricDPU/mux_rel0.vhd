library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux_rel0 is
  Port ( widthSel: in std_logic_vector( 1 downto 0); --selects the width
         typeSel: in std_logic_vector( 2 downto 0);  --selects the type
         float8e4m3out: in std_logic_vector( 7 downto 0);
         float16out: in std_logic_vector( 15 downto 0);
         float32out: in std_logic_vector( 31 downto 0);
         posit8out: in std_logic_vector( 7 downto 0);
         posit16out: in std_logic_vector( 15 downto 0);
         posit32out: in std_logic_vector( 31 downto 0);
         fixP8_16out: in std_logic_vector( 15 downto 0);
         fixP16_32out: in std_logic_vector ( 31 downto 0 );
         int8_16out: in std_logic_vector (15 downto 0);
         int16_32out: in std_logic_vector(31 downto 0);
         out8bit : out std_logic_vector( 7 downto 0 );
         out16bit: out std_logic_vector( 15 downto 0);
         out32bit: out std_logic_vector( 31 downto 0) );
         
end mux_rel0;

architecture Behavioral of mux_rel0 is

begin

--about the widthSel signal: 00 --> 8 bit input operands
--                           01 --> 16 bit input operands
--                           10 --> 32 bit input operands

--about the typeSel signal: 000 --> floating point format selection (rel 0)
--                          001 --> posit format selection (rel 0)
--                          010 --> fixedPoint format selection (rel 0)
--                          011 --> integer format selection (rel 0)
--                          100 --> LNS format selection (for rel_1 parametric DPU=

process( widthSel,
         typeSel,
         float8e4m3out,
         float16out,
         float32out,
         posit8out,
         posit16out,
         posit32out,
         fixP8_16out,
         fixP16_32out,
         int8_16out
         )

    begin
        
        if( widthSel = "00" AND typeSel = "000" ) then
            out8bit <= float8e4m3out ;
            out16bit <= (others => '0') ;
            out32bit <= (others => '0') ;
            
        elsif( widthSel = "01" AND typeSel = "000" ) then
            out8bit <= (others => '0') ;
            out16bit <= float16out ; 
            out32bit <= (others => '0') ;
            
        elsif( widthSel = "10" AND typeSel = "000" ) then
            out8bit <= (others => '0') ;
            out16bit <= (others => '0') ;
            out32bit <= float32out ;
            
        elsif( widthSel = "00" AND typeSel = "001" ) then
            out8bit <= posit8out ;
            out16bit <= (others => '0') ;
            out32bit <= (others => '0') ;
            
        elsif( widthSel = "01" AND typeSel = "001" ) then
            out8bit <= (others => '0');
            out16bit <= posit16out ;
            out32bit <= (others => '0');
            
        elsif( widthSel = "10" AND typeSel = "001" ) then
            out8bit <= (others => '0');
            out16bit <= (others => '0');
            out32bit <= posit32out;
        
        elsif( widthSel = "00" AND typeSel = "010" ) then 
            out8bit <= (others => '0') ;
            out16bit <= fixP8_16out;
            out32bit <= (others => '0');
        
        elsif( widthSel = "01" AND typeSel = "010" ) then
            out8bit <= (others => '0');
            out16bit <= (others => '0');
            out32bit <= fixP16_32out ;
        
        elsif( widthSel = "00" AND typeSel = "011" ) then 
            out8bit <= (others => '0') ;
            out16bit <= int8_16out;
            out32bit <= (others => '0') ;
        
        elsif ( widthSel = "01" AND typeSel = "011") then
            out8bit <= (others => '0') ;
            out16bit <= (others => '0') ;
            out32bit <= int16_32out ;
        
        else
            out8bit <= (others => '0');
            out16bit <= (others => '0');
            out32bit <= (others => '0');
        
        end if;
        
    end process ;

end Behavioral;
