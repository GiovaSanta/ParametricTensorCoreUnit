#!/bin/tcsh
source ${PULP_PATH}/./vsim/vcompile/setup.csh

#general comment: this compile script will revert to the instructions not including compilation of TCU vhdl files...
#...if the update-ips.py script is reran !! Beware.

##############################################################################
# Settings
##############################################################################


set IP=T13x

set FP16_LIB_NAME=FP16_DPU
set POSIT16_LIB_NAME=POSIT16_DPU
set FP8_LIB_NAME=FP8_DPU
set POSIT8_LIB_NAME=POSIT8_DPU
set INT8_16_LIB_NAME=INT8_16_DPU
set FIXED8_16_LIB_NAME=FixedP8_16_dpu
set FP32_LIB_NAME=FP32_DPU
set POSIT32_LIB_NAME=POSIT32_DPU
set INT16_32_LIB_NAME=INT16_32_DPU


##############################################################################
# Check settings
##############################################################################

# check if environment variables are defined
if (! $?MSIM_LIBS_PATH ) then
  echo "${Red} MSIM_LIBS_PATH is not defined ${NC}"
  exit 1
endif

if (! $?IPS_PATH ) then
  echo "${Red} IPS_PATH is not defined ${NC}"
  exit 1
endif

set FP16_LIB_PATH="${MSIM_LIBS_PATH}/${FP16_LIB_NAME}_lib"
set POSIT16_LIB_PATH="${MSIM_LIBS_PATH}/${POSIT16_LIB_NAME}_lib"
set FP8_LIB_PATH="${MSIM_LIBS_PATH}/${FP8_LIB_NAME}_lib"
set POSIT8_LIB_PATH="${MSIM_LIBS_PATH}/${POSIT8_LIB_NAME}_lib"
set INT8_16_LIB_PATH="${MSIM_LIBS_PATH}/${INT8_16_LIB_NAME}_lib"
set FIXED8_16_LIB_PATH="${MSIM_LIBS_PATH}/${FIXED8_16_LIB_NAME}_lib"
set FP32_LIB_PATH="${MSIM_LIBS_PATH}/${FP32_LIB_NAME}_lib"
set POSIT32_LIB_PATH="${MSIM_LIBS_PATH}/${POSIT32_LIB_NAME}_lib"
set INT16_32_LIB_PATH="${MSIM_LIBS_PATH}/${INT16_32_LIB_NAME}_lib"

set LIB_NAME="${IP}_lib"
set LIB_PATH="${MSIM_LIBS_PATH}/${LIB_NAME}"
set IP_PATH="${IPS_PATH}/T13x"
set RTL_PATH="${RTL_PATH}"

##############################################################################
# Preparing library
##############################################################################

echo "${Green}--> Compiling ${IP}... ${NC}"

rm -rf $LIB_PATH

vlib $LIB_PATH
vmap $LIB_NAME $LIB_PATH

#added by gio a fine tcu integration
rm -rf $FP16_LIB_PATH  

vlib $FP16_LIB_PATH
vmap $FP16_LIB_NAME $FP16_LIB_PATH

rm -rf $POSIT16_LIB_PATH

vlib $POSIT16_LIB_PATH
vmap $POSIT16_LIB_NAME $POSIT16_LIB_PATH

rm -rf $FP8_LIB_PATH  

vlib $FP8_LIB_PATH
vmap $FP8_LIB_NAME $FP8_LIB_PATH

rm -rf $POSIT8_LIB_PATH

vlib $POSIT8_LIB_PATH
vmap $POSIT8_LIB_NAME $POSIT8_LIB_PATH

rm -rf $INT8_16_LIB_PATH  

vlib $INT8_16_LIB_PATH
vmap $INT8_16_LIB_NAME $INT8_16_LIB_PATH

rm -rf $FIXED8_16_LIB_PATH  

vlib $FIXED8_16_LIB_PATH
vmap $FIXED8_16_LIB_NAME $FIXED8_16_LIB_PATH

rm -rf $FP32_LIB_PATH

vlib $FP32_LIB_PATH
vmap $FP32_LIB_NAME $FP32_LIB_PATH

rm -rf $POSIT32_LIB_PATH

vlib $POSIT32_LIB_PATH
vmap $POSIT32_LIB_NAME $POSIT32_LIB_PATH

rm -rf $INT16_32_LIB_PATH

vlib $INT16_32_LIB_PATH
vmap $INT16_32_LIB_NAME $INT16_32_LIB_PATH

##############################################################################
# Compiling RTL
##############################################################################

#added by gio a fine tcu integration
echo "${Green}Compiling component: ${Brown} FP16_DPU ${NC}"
echo "${Red}"
vcom -2008 -quiet -suppress 2583 -work ${FP16_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/FP16DPU/FP16_FMA.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${FP16_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/FP16DPU/FP16_DPU.vhd || goto error

echo "${Green}Compiling component: ${Brown} POSIT16_DPU ${NC}"
echo "${Red}"
vcom -2008 -quiet -suppress 2583 -work ${POSIT16_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/posit16DPU/posit16_0_Add.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${POSIT16_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/posit16DPU/posit16_0_Mul.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${POSIT16_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/posit16DPU/posit16_0_DPU.vhd || goto error

echo "${Green}Compiling component: ${Brown} FP8_DPU ${NC}"
echo "${Red}"
vcom -2008 -quiet -suppress 2583 -work ${FP8_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/FP8e4m3DPU/FMA_FP8e4m3flopoco.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${FP8_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/FP8e4m3DPU/DPU_FP8e4m3flopoco.vhd || goto error

echo "${Green}Compiling component: ${Brown} POSIT8_DPU ${NC}"
echo "${Red}"
vcom -2008 -quiet -suppress 2583 -work ${POSIT8_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/posit8DPU/Posit_Adder.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${POSIT8_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/posit8DPU/Posit_Mult.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${POSIT8_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/posit8DPU/Posit_DPU.vhd || goto error

echo "${Green}Compiling component: ${Brown} INT8_16_DPU ${NC}"
echo "${Red}"
vcom -2008 -quiet -suppress 2583 -work ${INT8_16_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/int8_16/INT8_Adder.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${INT8_16_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/int8_16/INT8_Mult.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${INT8_16_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/int8_16/INT8_DPU.vhd || goto error

echo "${Green}Compiling component: ${Brown} FIXED8_16_DPU ${NC}"
echo "${Red}"
vcom -2008 -quiet -suppress 2583 -work ${FIXED8_16_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/FixPoint8_16DPU/FixedPoint8_16_MAC.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${FIXED8_16_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/FixPoint8_16DPU/FixedPoint8_16DPU.vhd || goto error

echo "${Green}Compiling component: ${Brown} FP32_DPU ${NC}"
echo "${Red}"

vcom -2008 -quiet -suppress 2583 -work ${FP32_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/FP32DPU/FMA_FP32e8m23flopoco.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${FP32_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/FP32DPU/DPU_FP32e8m23flopoco.vhd || goto error

echo "${Green}Compiling component: ${Brown} POSIT32_DPU ${NC}"
echo "${Red}"
vcom -2008 -quiet -suppress 2583 -work ${POSIT32_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/posit32DPU/Posit32_2_Add.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${POSIT32_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/posit32DPU/Posit32_2_Mul.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${POSIT32_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/posit32DPU/Posit32_2_DPU.vhd || goto error

echo "${Green}Compiling component: ${Brown} INT16_32_DPU ${NC}"
echo "${Red}"
vcom -2008 -quiet -suppress 2583 -work ${INT16_32_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/int16_32/def_package.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${INT16_32_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/int16_32/Adder_INT.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${INT16_32_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/int16_32/Multiplier_INT.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${INT16_32_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/int16_32/DPU_TOP_INT.vhd || goto error

echo "${Green}Compiling component: ${Brown} Klessydra-T13x ${NC}"
echo "${Red}"
vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/PKG_RiscV_Klessydra.vhd || goto error

# NEW (added by gio) Tensor core hierarchy, compiled into T13x_lib
vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/DPU-mux_rel0.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/DPU-parametricDPU.vhd || goto error

vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/TCU/TCU-octectDPUarray.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/TCU/TCU-octectBuffers.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/TCU/TCU-octectCoreTop.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/TCU/TCU-tensorCoreDatapath.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/TCU/TCU-internalFSM.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/TCU/TCU-singleTensorCoreWrapper.vhd || goto error
###############################################################################

vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/RTL-Load_Store_Unit.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/RTL-Accumulator.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/RTL-ParametricTCU.vhd || goto error  #new compile line for TCU new module
vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/RTL-Processing_Pipeline.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/RTL-CSR_Unit.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/RTL-Program_Counter_unit.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/RTL-Debug_Unit.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/RTL-Registerfile.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/RTL-DSP_Unit.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/RTL-Scratchpad_Memory_Interface.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/RTL-ID_STAGE.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/RTL-Scratchpad_Memory.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/RTL-IE_STAGE.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/STR-Klessydra_top.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${LIB_PATH}   ${IP_PATH}/klessydra-t1-3th/RTL-IF_STAGE.vhd || goto error

echo "${Cyan}--> ${IP} compilation complete! ${NC}"
exit 0

##############################################################################
# Error handler
##############################################################################

error:
echo "${NC}"
exit 1
