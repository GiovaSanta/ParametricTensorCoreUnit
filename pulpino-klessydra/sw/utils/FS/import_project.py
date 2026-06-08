# Function to import all the files in the project: (FP version for FlexGripPlus)

import os
import filecmp
import subprocess
from afs_func import *
import random
import threading
from datetime import datetime


def Extract_time_params(out, debug_mode):
	# File generation:
	
	if debug_mode ==1: 
		print(out)
	total_time = (find_substr(out, "totaltime", "# simstats"))		# partially extract the value for the string chain.
	totalcpu_time = (find_substr(out, "totalcpu", "# quit"))
	
	if debug_mode ==1:
		print("\n")
		print(str(out))
		print("\n")
	
	match = re.search(r"#\s*([\d.]+)", total_time)
	if match:
		total_time_short_short = float(match.group(1))
	match = re.search(r"#\s*([\d.]+)", totalcpu_time)
	if match:
		totalcpu_time_short_short = float(match.group(1))

	if debug_mode ==1:	
		print(str(float(total_time_short_short) ))
		print(str(float(totalcpu_time_short_short) ))

	return(float(total_time_short_short), float(totalcpu_time_short_short))


def Extract_GPU_time_params(out2, Debug_mode):
	official_kernel_op_time = 1					# Variable initialization
	official_op_time = 0 
	
	official_op_time = int(find_substr(out2, "TIME_END ", " ns "))
	official_kernel_op_time = official_op_time

	if Debug_mode == 1:
		print("Official op time function: " + str(official_op_time))
	
	return(official_kernel_op_time, official_op_time)
	
	
	
# Function employed to launch the fault simulator:
def Lauch_execution(cmd_vsim, Enabled_Debug, num_fault_lines):				# The enabled_debug mode allows to find the performance parameters of the app.
	#print(cmd_vsim)
	err_c = -1
	while err_c != 0:
		#p = subprocess.Popen(cmd_vsim, stdout=subprocess.PIPE, shell=True)
		p = subprocess.Popen(cmd_vsim, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
		out, error = p.communicate()
		err_c = p.returncode
		print("Fault simulation finished", error)
	out = out.decode('utf-8')					# decode the output to string.
	out = out.replace("\n", "")							# remove the new line characters.

	num_fault_lines = num_fault_lines - 1			# reduce the total number of fault to be applied.

	#if Enabled_Debug == 1 :
	#	print (out) 						#enable if you want to read the modelsim output
	
	totalcpu_time = 0.0						# by default, under not debug mode activation.
	total_time = 0.0
	official_kernel_op_time  = 0.0
	official_op_time  = 0.0

	# Extraction of execution time parameters:
	(total_time, totalcpu_time) = Extract_time_params(out, Enabled_Debug)

	# Extraction of GPGPU execution parameters:
	(official_kernel_op_time, official_op_time) = Extract_GPU_time_params(out, Enabled_Debug)

	if Enabled_Debug == 1 :
		print("-> Total Execution time: " + str(total_time) + "s.")
		print("-> Total CPU Execution time: " + str(totalcpu_time) + "s.")
		print("-> Total Kernel Execution time: (GPGPU execution) " + str(official_kernel_op_time) + "ns.")
				
	if (total_time == 0) | (totalcpu_time == 0) |(official_kernel_op_time == 0) |(official_op_time == 0):
		print("An error has occured during simulation execution, check the GPGPU simulation in Debug mode\n")

	return(total_time, totalcpu_time, official_kernel_op_time, official_op_time, out, num_fault_lines)

	
def Launch_golden_sim(cmd_vsim, Debug_mode, app_name):
	
	# Golden Simulation:
	print("--------------------------------------------------------------------------------------- \n")
	print("                                Golden simulation...\n")
	print("--------------------------------------------------------------------------------------- \n")
		
	# sub functions to establish the performance parameters
	p = subprocess.Popen(cmd_vsim, stdout=subprocess.PIPE, shell=True)
	out, error = p.communicate()
	out = out.decode('utf-8')					# decode the output to string.
	out = out.replace("\n", "")							# remove the new line characters.

	#print(out.decode('utf-8'))		# enable if you want to read the modelsim output
	
	os.system("mv mem0.log " + str(app_name) + "_reference_mem.log")
		
	# Extraction of execution time parameters:
	(total_time, totalcpu_time) = Extract_time_params(out, Debug_mode)

	# Extraction of GPGPU execution parameters:
	(official_kernel_op_time, official_op_time) = Extract_GPU_time_params(out, Debug_mode)
	
	print("--------------------------------------------------------------------------------------- \n")
	print("                       Golden simulation Finished\n")
	print("-> Total Execution time: " + str(total_time) + "s.")
	print("-> Total CPU Execution time: " + str(totalcpu_time) + "s.")
	print("-> Total Kernel Execution time: (execution) " + str(official_kernel_op_time) + "ns.")
	print("--------------------------------------------------------------------------------------- \n")
	
	if (total_time == 0) | (totalcpu_time == 0):
		print("An error has occured during simulation execution, check the GPGPU simulation in Debug mode (fault list could be corrupted)\n")
	
	return(total_time, totalcpu_time, official_kernel_op_time, official_op_time)
	
	
def inject_fault(line, application_name, Debug_mode, official_kernel_op_time, official_op_time, env, vsim_golden, fault_injection_counter, total_fault_lines, store_data):
  thr_n = int(fault_injection_counter)
  i = thr_n

  # File for fault detection dictionary
  inFile_dictionary = ""
  inFile_final = ""

  if Debug_mode == 1:
    print("Decoding the fault to inject... \n")

  words = line.split()
  fault_type = words[0]
  location = words[1]
  other_signal = words[2]
  
  if fault_type == "bflip":		# Collect other parameter if the test fault model is bitflip, in other case, it should be SA0 or SA1.						
        operative_ranges_low = 2000
        operative_ranges_high = int(official_kernel_op_time)
        start_point = random.randint(operative_ranges_low, operative_ranges_high)

        Internal_Gen = open("Internal_gen_fault_injection_list_"+ str(application_name) + ".txt", 'a')						# file for final save test
        Internal_Gen.write(fault_type + "_c " + location + " - " + str(start_point)  + " 11\n" )
        Internal_Gen.close()
  elif fault_type == "bflip_c":			  
        start_point = words[3]
        perioded = words[4]
  elif fault_type == "behave_signal":	# The fault is behavioral and a special case should be considered
        start_point = words[3]
        perioded = words[4]
  else:
        start_point = '0'			# SA0 of SA1 or other cases.
        perioded = '0'
  
  os.system(f"rm mem{thr_n}.log")
  inFile_dictionary+=str(location) + " : "

  # Generation of command according to the fault type in file and location of fault, including the total launh time and the steps length.
  cmd_vsim = build_cmd(fault_type, location, other_signal, "tb", int(int(official_op_time) * 1.8), "1ns", "gpgpu_ml605_top_level", start_point, perioded, env, vsim_golden, thr_n)
                                            
  if Debug_mode == 1:
    print("Printing command to apply: \n")
    print(str(cmd_vsim))
    #print("\n")

  if Debug_mode == 1:
    print("Appliying the Fault # " +  str( int(fault_injection_counter)) + " of " + str(total_fault_lines) )				

  # Launching the GPGPU with the selected fault:
  (total_time, totalcpu_time, actual_kernel_op_time, actual_op_time, out, num_fault_lines) = Lauch_execution(cmd_vsim, Debug_mode, 0)						# not debug mode enabled

  # ---------------------------------------------------------------------------------------------------
  # classification (checker and classifier):
  # silent: not effect
  # time out: (not finished on a selected period of time)
  # detected: Memory miss...
  # Silent data corruption (SDC) memory results comparison.

  # Execution ending...	  
  check_open=0
  check=0
  flat_degradation = 0
  # check if the sim really finish or it stalls (time out) in some part by efect of the fault.
  try:
     inFilex = open(f"mem{thr_n}.log", 'r')		# use the final memory, after the fault generation.
                # #inFilex = open("fault1_log.txt", 'r')		# use the test file
     inFilex.seek(0) #ensure you're at the start of the file
     check_open=1
  except IOError:		# there is not file for memory results.
     check_open=0
     if Debug_mode == 1:
        print ("Could not open file!")

  if (check_open==1):					# the simulation ended and the memory file was created
    check=1
    if Debug_mode == 1:
        print ("open memory file, checking if its empty...")

    first_char = inFilex.read(1) 			#get the first character

    if not first_char:
         check=0					# there is not mandatory to compare an empty file with the reference memory file
         if Debug_mode == 1:
            print ("memory file empty")
    else: 							# file not empty
         check=1					# a comparison of memory files(reference and new) should be carried out.
         if Debug_mode == 1:
            print ("memory file not empty")
    inFilex.close()		#first character is the empty string..
    
  else: # there is not a memory file for simulation, circuit stalls in sim. due to fault.
    # nothing else to do, this means that even the simulation colapsed by timeout
    check=0

  error_by_memory=0
  error_by_degradation=0
  error_by_stall=0
  error_by_degradation_in_memory=0
  crashed_event=0
  error_by_degradation_but_mem_ok=0
  passed_event=0
  error_not_detected=0

   # comparison line by line, classify by degradation or good.
  if(check==1):					# comparison of files:
      check=0																	# memory write
      
      #check the degradation, probably it finished but with long time.
    # print("Checking Degradation in time....")
      if Debug_mode == 1:
        print("Actual simulation kernel time:    " + str(actual_kernel_op_time))
        print("Golden simulation kernel time:    " + str(official_kernel_op_time))
      
      if(actual_kernel_op_time > official_kernel_op_time):	# there is a degradation by the fault
         if Debug_mode == 1:
           print("Timeout faulure present (Degradation in performance)")
         flat_degradation=1
         error_by_degradation = 1

      # Store memory files in directory
      
      os.system(f"mv mem{thr_n}.log result_memory_files/memory_" +  str(application_name) + "_" + str(i) + ".log")
         
      # Comparison of memory results (fault memory, golden memory)
      # True mean equal files.
      if filecmp.cmp("result_memory_files/memory_" + str(application_name) + "_" +  str(i) + ".log", str(application_name) + "_reference_mem.log"):
            if Debug_mode == 1:
                print("Memory match")
            passed_event=1
            error_not_detected=1								# error in memory not detected

            if(flat_degradation == 1):
                error_by_degradation_in_memory = 1				# there is presence of performance degradation.
                flat_degradation=0
                inFile_dictionary+="	D	Time out (Degradation by Performance)	" + str(fault_type) + "\n"
                inFile_final+="signal failed	D	Time out	: " + str(cmd_vsim) + "Log #: " + str(thr_n) + "\n"
            else:
                inFile_dictionary+="	ND  "+ str(fault_type) +"\n"			# not detection of fault, silent fault	

            if not store_data:
                os.system("rm result_memory_files/memory_" + str(application_name) + "_" + str(i) + ".log")	# remove the memory file, not needed.
      else:
            if Debug_mode == 1:
                print("No Memory match (SDC)")
            inFile_dictionary+="	D	(SDC)"+ str(fault_type) +"\n"
            
            crashed_event=1
            error_by_memory=1

            inFile_final+="signal failed	D	(SDC)	: " + str(location) + "\n" + "Injection time:  ("+ str(start_point) + ")"+ "\n" + "Log #: " + str(thr_n) + "\n"

            error_by_degradation_but_mem_ok= 1				# In time
      
            if not store_data:
                os.system("rm result_memory_files/memory_" + str(application_name) + "_" + str(i) + ".log")
            else:
                os.system("mv result_memory_files/memory_" + str(application_name) + "_" +  str(i) + ".log result_memory_files/memory_" + str(application_name) + "_" + datetime.now().strftime('%d-%m-%Y-%H:%M:%S') + "_" + str(i) + ".log" )
  else:							# memory didnt write, stall
    # second chance: run again with the double time, probably was degradation in time: (double time)
    if Debug_mode == 1:
        print ("error! halt")
    error_by_stall = 1
    inFile_dictionary+="	D	Halted"+ str(fault_type) +"\n"

  return (error_by_memory, error_by_degradation, error_by_stall, error_by_degradation_in_memory, crashed_event, error_by_degradation_but_mem_ok, error_not_detected, passed_event, inFile_dictionary, inFile_final)