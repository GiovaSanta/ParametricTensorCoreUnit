#!/usr/bin/tclsh
set DOT_PRODUCT_GENERIC_ROOT ".."
quit -sim

exec vlib work

# exec vmap gpgpu work

set dot_product_files_vhdls [list \
	"## Package" \
	"$DOT_PRODUCT_GENERIC_ROOT/def_package.vhd" \
	"# Top-level, reference components" \
	"$DOT_PRODUCT_GENERIC_ROOT/right_shifter.vhd" \
	"$DOT_PRODUCT_GENERIC_ROOT/fp_leading_zeros_and_shift.vhd" \
	"$DOT_PRODUCT_GENERIC_ROOT/prueba.vhd" \
	"$DOT_PRODUCT_GENERIC_ROOT/suma_resta.vhd" \
	"$DOT_PRODUCT_GENERIC_ROOT/multiplier_FP.vhd" \
	"$DOT_PRODUCT_GENERIC_ROOT/dot_unit_core.vhd" \
	"# TB - Top-level" \
	"$DOT_PRODUCT_GENERIC_ROOT/dot_unit_core_tb.vhd" \
]

foreach src $dot_product_files_vhdls {
	if [expr {[string first # $src] eq 0}] {puts $src} else {
		#exec >@stdout 2>@stderr
		vcom -64 -2008 -work work $src
	}
}

vsim -64 -voptargs=+acc work.dot_unit_core_tb
#vsim -voptargs=+acc work.tb_top_level
do TB_wave_internal_golden.do
run 200 ns
