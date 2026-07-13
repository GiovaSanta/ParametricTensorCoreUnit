# Full Parametric TCU synthesis and report generation
# Run with:
# vivado -mode batch -source scripts/run_synth_full_parametric_tcu.tcl

# ---------- CHANGE THESE FIRST ----------
set TOP_ENTITY "TCU_Branch"
set PART_NAME  "xc7a100tcsg324-1"
set CLOCK_PORT_NAME "clk_i"
set CLOCK_PERIOD_NS 10.000

# ---------- PATHS ----------
set SCRIPT_DIR [file normalize [file dirname [info script]]]
set ROOT_DIR   [file normalize [file join $SCRIPT_DIR ".."]]
set SRC_DIR    [file join $ROOT_DIR "src"]
set XDC_DIR    [file join $ROOT_DIR "constraints"]
set BUILD_DIR  [file join $ROOT_DIR "vivado" "full_parametric_tcu"]
set REPORT_DIR [file join $ROOT_DIR "reports" "full_parametric_tcu"]

file mkdir $BUILD_DIR
file mkdir $REPORT_DIR

proc find_files_recursive {directory patterns} {
    set result {}
    if {![file isdirectory $directory]} {
        return $result
    }
    foreach item [glob -nocomplain -directory $directory *] {
        if {[file isdirectory $item]} {
            set result [concat $result [find_files_recursive $item $patterns]]
        } else {
            foreach pattern $patterns {
                if {[string match -nocase $pattern [file tail $item]]} {
                    lappend result [file normalize $item]
                    break
                }
            }
        }
    }
    return $result
}

set PROJECT_NAME "full_parametric_tcu_synth"
set PROJECT_FILE [file join $BUILD_DIR "${PROJECT_NAME}.xpr"]

if {[file exists $PROJECT_FILE]} {
    file delete -force $BUILD_DIR
    file mkdir $BUILD_DIR
}

create_project $PROJECT_NAME $BUILD_DIR -part $PART_NAME -force
set_property target_language VHDL [current_project]
set_property simulator_language Mixed [current_project]
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]

set VHDL_FILES [find_files_recursive $SRC_DIR {"*.vhd" "*.vhdl"}]
set VERILOG_FILES [find_files_recursive $SRC_DIR {"*.v" "*.sv"}]

if {[llength $VHDL_FILES] == 0 && [llength $VERILOG_FILES] == 0} {
    error "No RTL files found inside: $SRC_DIR"
}

if {[llength $VHDL_FILES] > 0} {
    add_files -norecurse $VHDL_FILES
    foreach f [get_files -quiet *.vhd] {
        set_property file_type {VHDL 2008} $f
    }
    foreach f [get_files -quiet *.vhdl] {
        set_property file_type {VHDL 2008} $f
    }
}

if {[llength $VERILOG_FILES] > 0} {
    add_files -norecurse $VERILOG_FILES
}

# ---------- DPU VHDL LIBRARY MAPPING ----------
# DPU-parametricDPU instantiates the arithmetic units from explicit
# libraries such as FP8_DPU, FP16_DPU, POSIT8_DPU, etc.
proc assign_library_recursive {directory library_name} {
    set files [find_files_recursive $directory {"*.vhd" "*.vhdl"}]

    if {[llength $files] == 0} {
        error "No VHDL files found for library $library_name inside: $directory"
    }

    puts "Assigning [llength $files] files to VHDL library $library_name"
    foreach file_path $files {
        set project_file [get_files -quiet [file normalize $file_path]]
        if {[llength $project_file] == 0} {
            error "File was not added to the Vivado project: $file_path"
        }
        set_property library $library_name $project_file
    }
}

set DPU_DIR [file join $SRC_DIR "TCU" "parametricDPU"]

assign_library_recursive     [file join $DPU_DIR "FP8e4m3DPU"] FP8_DPU

assign_library_recursive     [file join $DPU_DIR "FP16DPU"] FP16_DPU

assign_library_recursive     [file join $DPU_DIR "FP32DPU"] FP32_DPU

assign_library_recursive     [file join $DPU_DIR "posit8DPU"] POSIT8_DPU

assign_library_recursive     [file join $DPU_DIR "posit16DPU"] POSIT16_DPU

assign_library_recursive     [file join $DPU_DIR "posit32DPU"] POSIT32_DPU

assign_library_recursive     [file join $DPU_DIR "FixPoint8_16DPU"] FixedP8_16_dpu

assign_library_recursive     [file join $DPU_DIR "FixPoint16_32DPU"] FixedP16_32_DPU

assign_library_recursive     [file join $DPU_DIR "int8_16"] INT8_16_DPU

assign_library_recursive     [file join $DPU_DIR "int16_32"] INT16_32_DPU

assign_library_recursive     [file join $DPU_DIR "LNS16DPU"] LNS16_DPU

set XDC_FILES [find_files_recursive $XDC_DIR {"*.xdc"}]
if {[llength $XDC_FILES] > 0} {
    add_files -fileset constrs_1 -norecurse $XDC_FILES
}

set_property top $TOP_ENTITY [get_filesets sources_1]
# TCU_Branch requires THREAD_POOL_SIZE; the current architecture assumes 16 lanes.
set_property generic {THREAD_POOL_SIZE=16} [get_filesets sources_1]
update_compile_order -fileset sources_1

launch_runs synth_1 -jobs 8
wait_on_run synth_1

set SYNTH_STATUS [get_property STATUS [get_runs synth_1]]
puts "Synthesis status: $SYNTH_STATUS"

if {![string match "*Complete*" $SYNTH_STATUS]} {
    error "Synthesis failed. Check the Vivado log."
}

open_run synth_1

if {[llength $XDC_FILES] == 0} {
    set CLK_PORT [get_ports -quiet $CLOCK_PORT_NAME]
    if {[llength $CLK_PORT] > 0} {
        create_clock -name tcu_clock -period $CLOCK_PERIOD_NS $CLK_PORT
    } else {
        puts "WARNING: clock port '$CLOCK_PORT_NAME' not found."
    }
}

report_utilization     -file [file join $REPORT_DIR "utilization.rpt"]

report_utilization     -hierarchical     -hierarchical_depth 20     -file [file join $REPORT_DIR "utilization_hierarchical.rpt"]

report_timing_summary     -delay_type max     -report_unconstrained     -max_paths 20     -file [file join $REPORT_DIR "timing_summary.rpt"]

report_clock_utilization     -file [file join $REPORT_DIR "clock_utilization.rpt"]

report_drc     -file [file join $REPORT_DIR "drc.rpt"]

write_checkpoint -force     [file join $BUILD_DIR "full_parametric_tcu_synth.dcp"]

puts "Done. Reports are in: $REPORT_DIR"

close_project
exit
