# FlexGrip Plus dual parametric TCU synthesis
#
# Run from the Vivado Tcl Console with:
# source {scripts/run_synth_full_parametric_tcu.tcl}

set TOP_ENTITY       "dualTensorCoreWrapper"
set PART_NAME        "xc7a100tcsg324-1"
set CLOCK_PORT_NAME  "clk"
set CLOCK_PERIOD_NS  10.000

set SCRIPT_DIR [file normalize [file dirname [info script]]]
set ROOT_DIR   [file normalize [file join $SCRIPT_DIR ".."]]
set SRC_DIR    [file join $ROOT_DIR "src"]
set XDC_DIR    [file join $ROOT_DIR "constraints"]
set BUILD_DIR  [file join $ROOT_DIR "vivado" "flexgrip_dual_tcu"]
set REPORT_DIR [file join $ROOT_DIR "reports" "flexgrip_dual_tcu"]

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

proc find_file_by_tail {directory filename} {
    set matches {}

    foreach file_path [find_files_recursive $directory [list $filename]] {
        if {[string equal -nocase [file tail $file_path] $filename]} {
            lappend matches $file_path
        }
    }

    return $matches
}

proc assign_library_recursive {directory library_name} {
    set files [find_files_recursive $directory {"*.vhd" "*.vhdl"}]

    if {[llength $files] == 0} {
        error "No VHDL files found for library $library_name inside: $directory"
    }

    puts "Assigning [llength $files] file(s) to VHDL library $library_name"

    foreach file_path $files {
        set project_file [get_files -quiet [file normalize $file_path]]

        if {[llength $project_file] == 0} {
            error "File was not added to the Vivado project: $file_path"
        }

        set_property library $library_name $project_file
    }
}

if {![file isdirectory $SRC_DIR]} {
    error "Missing source directory: $SRC_DIR"
}

set GPGPU_PACKAGES [find_file_by_tail $SRC_DIR "gpgpu_package.vhd"]

if {[llength $GPGPU_PACKAGES] == 0} {
    error "Missing gpgpu_package.vhd. Copy it into src because dualTensorCoreWrapper uses work.gpgpu_package."
}

set WRAPPER_FILES [find_file_by_tail $SRC_DIR "dualTensorCoreWrapper4FlexGripPlus.vhd"]

if {[llength $WRAPPER_FILES] == 0} {
    puts "WARNING: dualTensorCoreWrapper4FlexGripPlus.vhd was not found by filename."
    puts "Vivado will still continue if entity dualTensorCoreWrapper exists in another VHDL file."
}

set PROJECT_NAME "flexgrip_dual_tcu_synth"
set PROJECT_FILE [file join $BUILD_DIR "${PROJECT_NAME}.xpr"]

catch {close_project}

if {[file exists $BUILD_DIR]} {
    file delete -force $BUILD_DIR
}

file mkdir $BUILD_DIR

create_project $PROJECT_NAME $BUILD_DIR -part $PART_NAME -force

set_property target_language VHDL [current_project]
set_property simulator_language Mixed [current_project]
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]

set VHDL_FILES    [find_files_recursive $SRC_DIR {"*.vhd" "*.vhdl"}]
set VERILOG_FILES [find_files_recursive $SRC_DIR {"*.v" "*.sv"}]

if {[llength $VHDL_FILES] == 0 && [llength $VERILOG_FILES] == 0} {
    error "No RTL files found inside: $SRC_DIR"
}

if {[llength $VHDL_FILES] > 0} {
    add_files -norecurse $VHDL_FILES

    foreach file_path $VHDL_FILES {
        set project_file [get_files -quiet [file normalize $file_path]]
        set_property file_type {VHDL 2008} $project_file
    }
}

if {[llength $VERILOG_FILES] > 0} {
    add_files -norecurse $VERILOG_FILES
}

set DPU_DIR [file join \
    $SRC_DIR \
    "parametricTCUrel0" \
    "octectCoreRel0" \
    "parametricDPU"]

if {![file isdirectory $DPU_DIR]} {
    error "Expected parametric DPU directory was not found: $DPU_DIR"
}

assign_library_recursive \
    [file join $DPU_DIR "FP8e4m3DPU"] \
    FP8_DPU

assign_library_recursive \
    [file join $DPU_DIR "FP16DPU"] \
    FP16_DPU

assign_library_recursive \
    [file join $DPU_DIR "FP32DPU"] \
    FP32_DPU

assign_library_recursive \
    [file join $DPU_DIR "posit8DPU"] \
    POSIT8_DPU

assign_library_recursive \
    [file join $DPU_DIR "posit16DPU"] \
    POSIT16_DPU

assign_library_recursive \
    [file join $DPU_DIR "posit32DPU"] \
    POSIT32_DPU

assign_library_recursive \
    [file join $DPU_DIR "FixPoint8_16DPU"] \
    FixedP8_16_dpu

assign_library_recursive \
    [file join $DPU_DIR "FixPoint16_32DPU"] \
    FixedP16_32_DPU

assign_library_recursive \
    [file join $DPU_DIR "int8_16"] \
    INT8_16_DPU

assign_library_recursive \
    [file join $DPU_DIR "int16_32"] \
    INT16_32_DPU

assign_library_recursive \
    [file join $DPU_DIR "LNS16DPU"] \
    LNS16_DPU

set XDC_FILES [find_files_recursive $XDC_DIR {"*.xdc"}]

if {[llength $XDC_FILES] == 0} {
    error "No XDC file found inside: $XDC_DIR"
}

add_files -fileset constrs_1 -norecurse $XDC_FILES

set_property top $TOP_ENTITY [get_filesets sources_1]
set_property generic {REG_W=32 ELEM_W=32} [get_filesets sources_1]

update_compile_order -fileset sources_1

puts ""
puts "Top entity: $TOP_ENTITY"
puts "FPGA part:  $PART_NAME"
puts "VHDL files added: [llength $VHDL_FILES]"
puts "Constraint files added: [llength $XDC_FILES]"
puts ""

launch_runs synth_1 -jobs 8
wait_on_run synth_1

set SYNTH_STATUS [get_property STATUS [get_runs synth_1]]
puts "Synthesis status: $SYNTH_STATUS"

if {![string match "*Complete*" $SYNTH_STATUS]} {
    error "Synthesis failed. Check the synth_1/runme.log file."
}

open_run synth_1

if {[llength [get_clocks -quiet]] == 0} {
    puts "WARNING: no clock constraint was loaded. Creating a temporary 10 ns clock for reporting."
    create_clock \
        -name flexgrip_tcu_clk \
        -period $CLOCK_PERIOD_NS \
        [get_ports $CLOCK_PORT_NAME]
}

report_utilization \
    -file [file join $REPORT_DIR "utilization.rpt"]

report_utilization \
    -hierarchical \
    -hierarchical_depth 20 \
    -file [file join $REPORT_DIR "utilization_hierarchical.rpt"]

report_timing_summary \
    -delay_type max \
    -report_unconstrained \
    -max_paths 20 \
    -file [file join $REPORT_DIR "timing_summary.rpt"]

report_clock_utilization \
    -file [file join $REPORT_DIR "clock_utilization.rpt"]

report_drc \
    -file [file join $REPORT_DIR "drc.rpt"]

write_checkpoint \
    -force \
    [file join $BUILD_DIR "flexgrip_dual_tcu_synth.dcp"]

puts ""
puts "FlexGrip Plus dual-TCU synthesis completed."
puts "Reports are in:"
puts "  $REPORT_DIR"
puts ""
puts "The Vivado project remains open for inspection."
