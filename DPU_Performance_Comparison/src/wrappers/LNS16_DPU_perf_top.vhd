library ieee;
use ieee.std_logic_1164.all;

library lns16_lib;

--------------------------------------------------------------------------------
-- LNS16_DPU_perf_top
--
-- Registered performance wrapper for LNS16_4_9_DPU.
--
-- Structure:
--   input registers -> combinational LNS16 DPU -> output register
--
-- Measured critical path:
--   input registers -> LNS16_4_9_DPU -> output register
--
-- Registered latency:
--   1 clock cycle
--
-- Throughput:
--   1 dot-product result per clock cycle
--------------------------------------------------------------------------------

entity LNS16_DPU_perf_top is
    port (
        clk : in std_logic;

        A0_in : in std_logic_vector(15 downto 0);
        A1_in : in std_logic_vector(15 downto 0);
        A2_in : in std_logic_vector(15 downto 0);
        A3_in : in std_logic_vector(15 downto 0);

        B0_in : in std_logic_vector(15 downto 0);
        B1_in : in std_logic_vector(15 downto 0);
        B2_in : in std_logic_vector(15 downto 0);
        B3_in : in std_logic_vector(15 downto 0);

        C0_in : in std_logic_vector(15 downto 0);

        R_out : out std_logic_vector(15 downto 0)
    );
end entity LNS16_DPU_perf_top;

architecture rtl of LNS16_DPU_perf_top is

    signal A0_r : std_logic_vector(15 downto 0);
    signal A1_r : std_logic_vector(15 downto 0);
    signal A2_r : std_logic_vector(15 downto 0);
    signal A3_r : std_logic_vector(15 downto 0);

    signal B0_r : std_logic_vector(15 downto 0);
    signal B1_r : std_logic_vector(15 downto 0);
    signal B2_r : std_logic_vector(15 downto 0);
    signal B3_r : std_logic_vector(15 downto 0);

    signal C0_r : std_logic_vector(15 downto 0);

    signal R_comb : std_logic_vector(15 downto 0);
    signal R_r    : std_logic_vector(15 downto 0);

begin

    ---------------------------------------------------------------------------
    -- Input/output register boundary
    ---------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            A0_r <= A0_in;
            A1_r <= A1_in;
            A2_r <= A2_in;
            A3_r <= A3_in;

            B0_r <= B0_in;
            B1_r <= B1_in;
            B2_r <= B2_in;
            B3_r <= B3_in;

            C0_r <= C0_in;

            R_r <= R_comb;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Combinational LNS16 dot-product unit under test
    ---------------------------------------------------------------------------
    dpu_inst : entity lns16_lib.LNS16_4_9_DPU
        port map (
            A0 => A0_r,
            A1 => A1_r,
            A2 => A2_r,
            A3 => A3_r,

            B0 => B0_r,
            B1 => B1_r,
            B2 => B2_r,
            B3 => B3_r,

            C0 => C0_r,

            R  => R_comb
        );

    R_out <= R_r;

end architecture rtl;