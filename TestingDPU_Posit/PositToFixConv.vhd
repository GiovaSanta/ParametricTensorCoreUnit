library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Posit8ToFix is
    port (
        P       : in std_logic_vector(7 downto 0);       -- Posit8 input
        FixOut  : out std_logic_vector(15 downto 0)      -- Q5.10 output
    );
end entity;

architecture Behavioral of Posit8ToFix is
begin
    process(P)
        variable sign         : std_logic;
        variable regime_sign  : std_logic;
        variable regime_k     : integer := 0;
        variable scale        : integer;
        variable bits         : std_logic_vector(7 downto 0);
        variable frac_raw     : unsigned(15 downto 0) := (others => '0');
        variable shifted      : signed(15 downto 0);
        
        variable frac_start : integer ;
        variable frac_len   : integer ;
    
    begin
        -- Copy input
        bits := P;
        sign := bits(7);

        -- Take 2's complement if negative
        if sign = '1' then
            bits := std_logic_vector(unsigned(not bits) + 1);
        end if;

        -- Decode regime
        regime_sign := bits(6);
        regime_k := 0;
        for i in 6 downto 0 loop
            if bits(i) = regime_sign then
                regime_k := regime_k + 1;
            else
                exit;
            end if;
        end loop;

        if regime_sign = '1' then
            scale := regime_k;
        else
            scale := -regime_k + 1;
        end if;

        -- Fraction start and length
        frac_start := 1 + regime_k;
        frac_len  := 7 - frac_start + 1;

        -- Load raw fraction (right-aligned)
        if frac_len > 0 and frac_start <= 7 then
            frac_raw(14 downto 14 - frac_len + 1) := unsigned(bits(frac_start - 1 downto 0));
        end if;

        -- Insert hidden bit
        frac_raw(15) := '1';

        -- Apply scale
        if scale >= 0 then
            shifted := signed(shift_left(frac_raw, scale));
        else
            shifted := signed(shift_right(frac_raw, -scale));
        end if;

        -- Apply sign and assign output
        if sign = '1' then
            FixOut <= std_logic_vector(-shifted);
        else
            FixOut <= std_logic_vector(shifted);
        end if;
    end process;
end architecture;
