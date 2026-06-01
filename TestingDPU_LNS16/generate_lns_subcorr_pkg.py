import math
from pathlib import Path

SCALE = 512
OUT = Path(__file__).parent / "LNSSubCorrectionPkg.vhd"

def to_slv14_signed(v: int) -> str:
    # clamp to 14-bit signed range
    if v < -8192:
        v = -8192
    if v > 8191:
        v = 8191
    return format(v & 0x3FFF, "014b")

with OUT.open("w", newline="\n") as f:
    f.write("""library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package LNSSubCorrectionPkg is
    function lns_sub_corr_4_9(
        Z : std_logic_vector(13 downto 0)
    ) return std_logic_vector;
end package;

package body LNSSubCorrectionPkg is

    function lns_sub_corr_4_9(
        Z : std_logic_vector(13 downto 0)
    ) return std_logic_vector is

        variable d      : integer;
        variable result : std_logic_vector(13 downto 0);

    begin

        -- Z is expected to be <= 0 for subtraction correction.
        -- d = -Z_scaled.
        d := -to_integer(signed(Z));

        case d is
""")

    # d = 0 corresponds to exact cancellation: log2(0), special zero case.
    # We return the most negative correction for now, but exact zero must be handled separately.
    f.write(f'            when 0 => result := "{to_slv14_signed(-8192)}";\n')

    for d in range(1, 4096):
        z_real = -d / SCALE
        value = math.log2(1.0 - (2.0 ** z_real)) * SCALE
        corr = int(round(value))
        f.write(f'            when {d} => result := "{to_slv14_signed(corr)}";\n')

    f.write("""            when others => result := (others => '0');
        end case;

        return result;

    end function;

end package body;
""")

print(f"Wrote {OUT}")
