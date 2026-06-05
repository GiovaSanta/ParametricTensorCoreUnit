#!/usr/bin/tclsh
set GPGPU_GENERIC_ROOT "../RTL"
quit -sim

catch {vdel -lib work -all}
catch {file delete -force work}

exec vlib work
exec vmap gpgpu work

# ---------------------------------------------------------------------------
# Explicit DPU format libraries
#
# The parametricDPU uses VHDL library clauses such as:
#   library FP16_DPU;
#   library POSIT8_DPU;
#   library LNS16_DPU;
#
# Therefore, the corresponding DPU entities must be compiled into these
# logical libraries before the main FlexGrip hierarchy is compiled/elaborated.
# This avoids relying on stale precompiled libraries inside lib_m.
# ---------------------------------------------------------------------------

set DPU_ROOT "$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/doubleTCU/doubleParametricTCUsRel0/parametricTCUrel0/octectCoreRel0/parametricDPU"

proc reset_lib {logical_name physical_dir} {
    puts "Resetting library: $logical_name -> $physical_dir"
    catch {vdel -lib $logical_name -all}
    catch {file delete -force $physical_dir}
    exec vlib $physical_dir
    exec vmap $logical_name $physical_dir
}

proc compile_vhdl {logical_name file_path} {
    if {![file exists $file_path]} {
        puts "ERROR: missing VHDL source file:"
        puts "  $file_path"
        error "Missing VHDL source file"
    }

    puts "Compiling into $logical_name:"
    puts "  $file_path"
    vcom -64 -2008 -work $logical_name $file_path
}

proc compile_vhdl_list {logical_name file_list} {
    foreach file_path $file_list {
        compile_vhdl $logical_name $file_path
    }
}

# Create clean local libraries.
reset_lib FixedP8_16_dpu  fixedp8_16_dpu
reset_lib FixedP16_32_DPU fixedp16_32_dpu
reset_lib INT8_16_DPU     int8_16_dpu
reset_lib INT16_32_DPU    int16_32_dpu
reset_lib FP8_DPU         fp8_dpu
reset_lib FP16_DPU        fp16_dpu
reset_lib FP32_DPU        fp32_dpu
reset_lib POSIT8_DPU      posit8_dpu
reset_lib POSIT16_DPU     posit16_dpu
reset_lib POSIT32_DPU     posit32_dpu
reset_lib LNS16_DPU       lns16_dpu

# Compile DPU libraries in dependency order.
compile_vhdl_list FP16_DPU [list \
    "$DPU_ROOT/FP16DPU/FP16_FMA.vhd" \
    "$DPU_ROOT/FP16DPU/FP16_DPU.vhd" \
]

compile_vhdl_list FP8_DPU [list \
    "$DPU_ROOT/FP8e4m3DPU/FMA_FP8e4m3flopoco.vhd" \
    "$DPU_ROOT/FP8e4m3DPU/DPU_FP8e4m3flopoco.vhd" \
]

compile_vhdl_list FP32_DPU [list \
    "$DPU_ROOT/FP32DPU/FMA_FP32e8m23flopoco.vhd" \
    "$DPU_ROOT/FP32DPU/DPU_FP32e8m23flopoco.vhd" \
]

compile_vhdl_list POSIT8_DPU [list \
    "$DPU_ROOT/posit8DPU/Posit_Adder.vhd" \
    "$DPU_ROOT/posit8DPU/Posit_Mult.vhd" \
    "$DPU_ROOT/posit8DPU/Posit_DPU.vhd" \
]

compile_vhdl_list POSIT16_DPU [list \
    "$DPU_ROOT/posit16DPU/posit16_0_Add.vhd" \
    "$DPU_ROOT/posit16DPU/posit16_0_Mul.vhd" \
    "$DPU_ROOT/posit16DPU/posit16_0_DPU.vhd" \
]

compile_vhdl_list POSIT32_DPU [list \
    "$DPU_ROOT/posit32DPU/Posit32_2_Add.vhd" \
    "$DPU_ROOT/posit32DPU/Posit32_2_Mul.vhd" \
    "$DPU_ROOT/posit32DPU/Posit32_2_DPU.vhd" \
]

compile_vhdl_list FixedP8_16_dpu [list \
    "$DPU_ROOT/FixPoint8_16DPU/FixedPoint8_16_MAC.vhd" \
    "$DPU_ROOT/FixPoint8_16DPU/FixedPoint8_16DPU.vhd" \
]

compile_vhdl_list FixedP16_32_DPU [list \
    "$DPU_ROOT/FixPoint16_32DPU/FixedPointMAC.vhd" \
    "$DPU_ROOT/FixPoint16_32DPU/FixedPointDPU.vhd" \
]

compile_vhdl_list INT8_16_DPU [list \
    "$DPU_ROOT/int8_16/INT8_Adder.vhd" \
    "$DPU_ROOT/int8_16/INT8_Mult.vhd" \
    "$DPU_ROOT/int8_16/INT8_DPU.vhd" \
]

compile_vhdl_list INT16_32_DPU [list \
    "$DPU_ROOT/int16_32/def_package.vhd" \
    "$DPU_ROOT/int16_32/Adder_INT.vhd" \
    "$DPU_ROOT/int16_32/Multiplier_INT.vhd" \
    "$DPU_ROOT/int16_32/DPU_TOP_INT.vhd" \
]

# LNS16 DPU.
# Adjust the folder name below if your LNS files are stored under a different
# directory name than LNS16DPU.
compile_vhdl_list LNS16_DPU [list \
	"$DPU_ROOT/LNS16DPU/LNSSubCorrectionPkg.vhd" \
    "$DPU_ROOT/LNS16DPU/LNSMul_4_9_comb.vhd" \
    "$DPU_ROOT/LNS16DPU/LNSAddSub_4_9_comb.vhd" \
    "$DPU_ROOT/LNS16DPU/LNS16_4_9_DPU.vhd" \
]

# ---------------------------------------------------------------------------
# Main FlexGrip hierarchy starts below.
# ---------------------------------------------------------------------------


set gpgpu_vhdls [list \
	"# TB - configuration" \
	"$GPGPU_GENERIC_ROOT/TB/configuration/pick_bench.vhd" \
	"# Top-level, reference components" \
	"## Package" \
	"$GPGPU_GENERIC_ROOT/gpgpu_package.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/shift_register.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/effective_address.vhd" \
	"## DP REGISTER FILE" \
	"$GPGPU_GENERIC_ROOT/SMP/dp_regfile.vhd" \
	"## Address, Predicate, Vector(GP) registers" \
	"$GPGPU_GENERIC_ROOT/SMP/address_register_controller.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/address_register_file.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/predicate_register_controller.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/predicate_register_file.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/vector_register_controller.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/vector_register_file.vhd" \
	"## Memory controller" \
	"$GPGPU_GENERIC_ROOT/SMP/memory_controller.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/constant_memory_controller.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/global_memory_controller.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/shared_memory_controller.vhd" \
	"## SMP Controller" \
	"$GPGPU_GENERIC_ROOT/SMP/SMPController/block_id_calc.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/SMPController/thread_id_calc.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/SMPController/warps_per_block_calc.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/SMPController/streaming_multiprocessor_cntlr.vhd" \
	"## Warp Unit" \
	"$GPGPU_GENERIC_ROOT/SMP/WarpUnit/fence_registers.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/WarpUnit/warps_done_mask_LUT.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/WarpUnit/warp_id_calc.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/WarpUnit/warp_generator.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/WarpUnit/warp_scheduler.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/WarpUnit/warp_checker.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/WarpUnit/warp_unit.vhd" \
	"## Pipeline, reference components" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/bshift.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/stack.vhd" \
	"## Pipeline - Fetch" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Fetch/pipeline_fetch.vhd" \
	"## Pipeline - Read" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Read/arbiter.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Read/predicate_lut.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Read/convert_data_types.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Read/calculate_address.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Read/read_source_ops.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Read/pipeline_read.vhd" \
	"## Pipeline - Decode" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Decode/pipeline_decode.vhd" \
	"## Pipeline - Execution - ScalarProcessor" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/ScalarProcessor/shift_logic.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/ScalarProcessor/min_max.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/ScalarProcessor/boolean_functions.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/ScalarProcessor/compute_set_pred_i.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/ScalarProcessor/convert_int_int.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/ScalarProcessor/integer_add_subtract.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/ScalarProcessor/integer_mult_24.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/ScalarProcessor/scalar_processor.vhd" \
	"## Pipeline - Execution - FloatingPointUnit" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/FPU/fpu_add_32.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/FPU/fpu_conv_32.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/FPU/fpu_exceptions_32.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/FPU/fpu_fma_32.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/FPU/fpu_mul_32.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/FPU/fpu_round_32.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/FPU/fpu_sub_32.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/FPU/fpu_set_32.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/FPU/a_s.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/FPU/divisor.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/FPU/fpu_rcp_32.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/FPU/fpu_top_32_new.vhd" \
	"## Pipeline - Execution - SpecialFunctionUnit" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Components/CLZ.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Components/SFU_Exceptions.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/fused_accm_tree/Booth_PP.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/fused_accm_tree/CSA_4_2.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/fused_accm_tree/fused_accum_tree.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C0_cos.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C0_exp.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C0_ln2.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C0_ln2e0.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C0_reci.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C0_reci_sqrt_1_2.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C0_reci_sqrt_2_4.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C0_sin.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C0_sqrt_1_2.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C0_sqrt_2_4.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C1_cos.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C1_exp.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C1_ln2.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C1_ln2e0.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C1_reci.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C1_reci_sqrt_1_2.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C1_reci_sqrt_2_4.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C1_sin.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C1_sqrt_1_2.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C1_sqrt_2_4.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C2_cos.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C2_exp.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C2_ln2.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C2_ln2e0.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C2_reci.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C2_reci_sqrt_1_2.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C2_reci_sqrt_2_4.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C2_sin.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C2_sqrt_1_2.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Single_LUTS/LUT_C2_sqrt_2_4.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/squaring.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/ROM.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/Quadratic_Interpolator/Quadratic_Interpolator.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/sfu.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/SFU/sfu_proc.vhd" \
	"## Pipeline - Execution - ParametricDualTCU" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/doubleTCU/doubleParametricTCUsRel0/parametricTCUrel0/octectCoreRel0/parametricDPU/mux_rel0.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/doubleTCU/doubleParametricTCUsRel0/parametricTCUrel0/octectCoreRel0/octectBuffers.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/doubleTCU/doubleParametricTCUsRel0/parametricTCUrel0/octectCoreRel0/octectCoreTop.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/doubleTCU/doubleParametricTCUsRel0/parametricTCUrel0/octectCoreRel0/octectDPUArray.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/doubleTCU/doubleParametricTCUsRel0/parametricTCUrel0/octectCoreRel0/octectRelatedFSM.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/doubleTCU/doubleParametricTCUsRel0/parametricTCUrel0/octectCoreRel0/parametricDPU/parametricDPU.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/doubleTCU/doubleParametricTCUsRel0/tensorCoreDatapath.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/doubleTCU/doubleParametricTCUsRel0/dualTensorCoreWrapper4FlexGripPlus.vhd" \
	"## Pipeline - Execution - RangeReduceOrder" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/RRO/Components/fp_leading_zeros_and_shift.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/RRO/Components/right_shifter.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/RRO/Components/add_sub.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/RRO/Components/multFP.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/RRO/RRO_trig.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/RRO/rro.vhd"\
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/RRO/rro_proc.vhd"\
	"## Pipeline - Execution - Branch" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/branch_exec_unit.vhd" \
	"## Pipeline - Execution" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Execution/pipeline_execute.vhd" \
	"## Pipeline - Write" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Write/compute_pred_flags.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Write/increment_address.vhd" \
	"$GPGPU_GENERIC_ROOT/SMP/Pipeline/Write/pipeline_write.vhd" \
	"## SMP" \
	"$GPGPU_GENERIC_ROOT/SMP/streaming_multiprocessor.vhd" \
	"## Block Scheduler" \
	"$GPGPU_GENERIC_ROOT/block_scheduler.vhd" \
	"## DP RAM (BEHAVIORAL)" \
	"$GPGPU_GENERIC_ROOT/dp_ram.vhd" \
	"## GPGPU Configuration" \
	"$GPGPU_GENERIC_ROOT/gpgpu_configuration.vhd" \
	"## System Memory Controller" \
	"$GPGPU_GENERIC_ROOT/system_memory_cntlr.vhd" \
	"## GPGPU Top Level" \
	"$GPGPU_GENERIC_ROOT/gpgpu_ml605_top_level.vhd" \
	"# TestBench, top-level components" \
	"$GPGPU_GENERIC_ROOT/TB/txt_util.vhd" \
	"$GPGPU_GENERIC_ROOT/TB/read_data.vhd" \
	"$GPGPU_GENERIC_ROOT/TB/write_instructions.vhd" \
    "# TB - TP" \
	"$GPGPU_GENERIC_ROOT/TB/TP/TP_configuration.vhd" \
    "$GPGPU_GENERIC_ROOT/TB/TP/TP_instructions.vhd" \
	"# TB - Benchmark Configuration" \
	"$GPGPU_GENERIC_ROOT/TB/tb_configuration.vhd" \
	"# TB - Top-level" \
	"$GPGPU_GENERIC_ROOT/TB/tb_top_level.vhd" \
]

foreach src $gpgpu_vhdls {
	if [expr {[string first # $src] eq 0}] {puts $src} else {
		#exec >@stdout 2>@stderr
		vcom -64 -2008 -work work $src
	#	vcom +cover=cbesxf -coveropt 1 -64 -2008 -work work $src
	}
}

vsim -64 -voptargs=+acc work.tb_top_level
#vsim -voptargs=+acc work.tb_top_level

#do wave_custom_JDGB.do

run -all

quit