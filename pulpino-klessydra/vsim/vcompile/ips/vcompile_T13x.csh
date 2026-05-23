#!/bin/tcsh
source ${PULP_PATH}/./vsim/vcompile/setup.csh

##############################################################################
# Settings
##############################################################################

set IP=T13x

set FP16_LIB_NAME=FP16_DPU

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

##############################################################################
# Compiling RTL
##############################################################################

#added by gio a fine tcu integration
echo "${Green}Compiling component: ${Brown} FP16_DPU ${NC}"
echo "${Red}"
vcom -2008 -quiet -suppress 2583 -work ${FP16_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/FP16DPU/FP16_FMA.vhd || goto error
vcom -2008 -quiet -suppress 2583 -work ${FP16_LIB_NAME} ${IP_PATH}/klessydra-t1-3th/TCU/parametricDPU/FP16DPU/FP16_DPU.vhd || goto error

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
