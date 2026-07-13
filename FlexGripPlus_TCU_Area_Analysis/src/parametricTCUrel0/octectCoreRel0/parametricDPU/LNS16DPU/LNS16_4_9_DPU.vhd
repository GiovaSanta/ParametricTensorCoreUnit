--------------------------------------------------------------------------------
-- LNS16_4_9_DPU
--
-- Combinational 4-lane LNS16 dot-product / multiply-accumulate block:
--
--     R = A0*B0 + A1*B1 + A2*B2 + A3*B3 + C0
--
-- LNS format:
--   total width = 16 bits
--   wE = 4
--   wF = 9
--
-- Required modules in work library:
--   - LNSMul_4_9_comb
--   - LNSAddSub_4_9_comb
--
-- Notes:
--   - Purely combinational: no clk, no rst, no pipeline registers.
--   - Additions are performed using LNSAddSub_4_9_comb.
--   - Subtraction behavior is naturally handled by the sign bits inside
--     the LNS operands, as in the validated LNSAddSub module.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity LNS16_4_9_DPU is
    port (
        A0 : in  std_logic_vector(15 downto 0);
        A1 : in  std_logic_vector(15 downto 0);
        A2 : in  std_logic_vector(15 downto 0);
        A3 : in  std_logic_vector(15 downto 0);
        B0 : in  std_logic_vector(15 downto 0);
        B1 : in  std_logic_vector(15 downto 0);
        B2 : in  std_logic_vector(15 downto 0);
        B3 : in  std_logic_vector(15 downto 0);
        C0 : in  std_logic_vector(15 downto 0);
        R  : out std_logic_vector(15 downto 0)
    );
end entity LNS16_4_9_DPU;

architecture structural of LNS16_4_9_DPU is

    -- Product terms
    signal P0 : std_logic_vector(15 downto 0);
    signal P1 : std_logic_vector(15 downto 0);
    signal P2 : std_logic_vector(15 downto 0);
    signal P3 : std_logic_vector(15 downto 0);

    -- Partial sums
    signal S01    : std_logic_vector(15 downto 0);
    signal S23    : std_logic_vector(15 downto 0);
    signal S0123  : std_logic_vector(15 downto 0);
    signal SFINAL : std_logic_vector(15 downto 0);

begin

    ---------------------------------------------------------------------------
    -- Four parallel LNS multiplications
    ---------------------------------------------------------------------------

    mul_0 : entity work.LNSMul_4_9_comb
        port map (
            nA => A0,
            nB => B0,
            nR => P0
        );

    mul_1 : entity work.LNSMul_4_9_comb
        port map (
            nA => A1,
            nB => B1,
            nR => P1
        );

    mul_2 : entity work.LNSMul_4_9_comb
        port map (
            nA => A2,
            nB => B2,
            nR => P2
        );

    mul_3 : entity work.LNSMul_4_9_comb
        port map (
            nA => A3,
            nB => B3,
            nR => P3
        );

    ---------------------------------------------------------------------------
    -- Balanced LNS accumulation tree
    --
    --   S01    = P0 + P1
    --   S23    = P2 + P3
    --   S0123  = S01 + S23
    --   SFINAL = S0123 + C0
    ---------------------------------------------------------------------------

    add_01 : entity work.LNSAddSub_4_9_comb
        port map (
            nA => P0,
            nB => P1,
            nR => S01
        );

    add_23 : entity work.LNSAddSub_4_9_comb
        port map (
            nA => P2,
            nB => P3,
            nR => S23
        );

    add_products : entity work.LNSAddSub_4_9_comb
        port map (
            nA => S01,
            nB => S23,
            nR => S0123
        );

    add_c0 : entity work.LNSAddSub_4_9_comb
        port map (
            nA => S0123,
            nB => C0,
            nR => SFINAL
        );

    R <= SFINAL;

end architecture structural;
