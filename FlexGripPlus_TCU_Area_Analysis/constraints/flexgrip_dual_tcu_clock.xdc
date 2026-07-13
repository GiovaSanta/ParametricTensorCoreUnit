# FlexGrip Plus dual parametric TCU
# 10.000 ns period = 100 MHz target clock.

create_clock \
    -name flexgrip_tcu_clk \
    -period 10.000 \
    [get_ports clk]
