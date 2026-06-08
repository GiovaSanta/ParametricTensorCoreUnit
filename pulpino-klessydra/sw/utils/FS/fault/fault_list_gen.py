# Author: Gustavo Vilar de Farias
# This script generates a fault list for a given input file containing signal names and types

import re
import argparse

argparser = argparse.ArgumentParser(description="Generate fault list from signal list.")
argparser.add_argument("input", type=str, default="sig_fu_wire_list.txt")

input_args = argparser.parse_args()

# Defines
input_file = input_args.input
output_file = input_file.replace("sig", "fault")
module_path = "/top_i/core_region_i/CORE/RISCV_CORE/Pipe/ACCL_generate/DSP/"

ACCL = 1
SIMD = 4

# Parameters
if ACCL == 3:
    output_file = output_file.replace(".txt", "_3accl.txt")
    params = {
        "fu_range": 3,
        "accl_range": 3,
        "ACCL_NUM": 3
    }
else:
    params = {
        "fu_range": 1,
        "accl_range": 1,
        "ACCL_NUM": 1
    }

params["SIMD"] = SIMD
params["SIMD_Width"] = 32*params["SIMD"]

params["DSP_UNIT_INSTR_SET_SIZE"] = 17 
params["Addr_Width"] = 14
params["TPS_BUF_CEIL"] = 1
params["TPS_CEIL"] = 2
params["SPM_ADDR_WID"] = 3
params["THREAD_POOL_SIZE"] = 3 - 1 # Because of the -2 in the signal list
params["Data_Width"] = 32

output_file = output_file.replace(".txt", "_" + str(SIMD) + "simd.txt")


def extr_pare_cont(line):
    return re.findall(r'\((.*?)\)', line)

def parse_param(param):
    idx = param.split()[0].split('-')[0]
    
    if not idx in params:
        if '/' in idx:
            idx = idx.split('/')
            idx = params[idx[0]] / int(idx[1])
        elif '*' in idx:
            idx = idx.split('*')
            idx = params[idx[1]] * int(idx[0])
        if not '-' in param:
            idx = int(idx) + 1

        params[idx] = int(idx)
    
    return idx

with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
    for line in infile:
        line = line.strip()

        parts = line.split()
        signal_name = parts[1]
        signal_type = line.split(":")[1].strip()

        if "std_logic_vector" in signal_type:
            idx = extr_pare_cont(signal_type)[0]
            
            for i in range(params[idx]):
                outfile.write(f"sa0 {module_path}{signal_name}({i}) -\n")
                outfile.write(f"sa1 {module_path}{signal_name}({i}) -\n")
        elif "array_2d" in signal_type:
            idx = extr_pare_cont(signal_type)

            for i in range(2):
                idx[i] = parse_param(idx[i])
            
            forbidden_j_val = []
            if 'dsp_mul_a' in signal_name or 'dsp_mul_b' in signal_name or 'dsp_mul_c' in signal_name:
                for i in range(0, int(params['SIMD_Width']/32)):
                    forbidden_j_val.extend(range(16 + i*32, 32 + (i*32)))
            for i in range(params[idx[0]]):
                for j in range(params[idx[1]]):
                    if j in forbidden_j_val:
                        continue

                    outfile.write(f"sa0 {module_path}{signal_name}({i})({j}) -\n")
                    outfile.write(f"sa1 {module_path}{signal_name}({i})({j}) -\n")
        elif "array_3d" in signal_type:
            idx = extr_pare_cont(signal_type)

            for i in range(3):
                idx[i] = parse_param(idx[i])
            
            for i in range(params[idx[0]]):
                for j in range(params[idx[1]]):
                    for k in range(params[idx[2]]):
                        outfile.write(f"sa0 {module_path}{signal_name}({i})({j})({k}) -\n")
                        outfile.write(f"sa1 {module_path}{signal_name}({i})({j})({k}) -\n")
        else:
            outfile.write(f"sa0 {module_path}{signal_name} -\n")
            outfile.write(f"sa1 {module_path}{signal_name} -\n")