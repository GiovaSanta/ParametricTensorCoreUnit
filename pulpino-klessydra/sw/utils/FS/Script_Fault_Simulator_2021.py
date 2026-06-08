# ---------------------------------------------------------------------------------------------
#                     Python fault injection for FlexGripPlus
# ---------------------------------------------------------------------------------------------
# Author: Josie Esteban Rodriguez Condia.
# ESR 1.4 RESCUE-ETN
# CAD Group
# Politecnico di Torino
# DAUIN Department
# 2017-2021

# Required software: ModelSim 10.7b or equivalent QuestaSim version.
# Python 2.7 and Python 3.6

# Launch a fault simulation:
# python Script_Fault_Simulator_2021.py name_application(TP) Name_fault_list total_threads (32)

# The fault list should include the .txt extension. By default loaded during the command line.

# ---------------------------------------------------------------------------------------------


import os
from afs_func import *
import subprocess
import filecmp
import argparse
from import_project import *
#from FaultyScript import *
from datetime import datetime
from datetime import date

import os.path
from os import path
import random

import threading
from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor, as_completed

# pending the checkpoint... check all

def main():
    # Definition of the arguments to considered:
    # Target application.
    # The target fault list.
    # Configuration ?.  future...

    parser = argparse.ArgumentParser()
    parser.add_argument('--fault_list', help='fault_list', type=str, required=True)
    parser.add_argument('--application_name', help='application', type=str)   # it will be used when all check are passed.
    parser.add_argument('--env', help='env', type=str, required=True)
    parser.add_argument('--vsim_golden', help='vsim_golden', type=str, required=True)
#	parser.add_argument('thread_number', help='thread_number', type=int)
    
    # parser.add_argument('fault_list', help='fault_list', type=str)				# potential new parameter, enable fault simulation, debug mode, execution time, future steps.
    
    args=parser.parse_args()

    # generate_pick_bench()  # pending function to generate the configuration of the environment.

    # definition of the object to manage the name strings of the input parameters.
    fault_list = args.fault_list						# Strings
    application_name = args.application_name			# Strings
    env = args.env	                            		# Strings
    vsim_golden = args.vsim_golden                 		# Strings

    resume = 1
    cold = 0
    start_type = cold


    fault_list_name = fault_list
    print(fault_list_name)

    # checking the fault list before start the importing:
        
    if not path.exists(fault_list_name):								# checking if the file storing the check pointing information is present
        print("There is an error in the fault list name. Please check that the file is present in the path")
        exit()															# stop the execution of the fault injector by lack of input resources

    
    max_threads = 55
    Debug_mode = 0														# Change this value to forced debug operations
    store_data = 0													    # Change this value to store the data in the folder "result_memory_files"
    golden_launch = 0													# With 0 it means that the fault injection is performed, with 1 it means that the fault injection is not performed.
    # select the app to apply the fault injection, parameters of fault type and signals should be stored in a text file.
    
#-----------------------------------------------------------------------
    print("Starting the Simulator execution...")   							# 257065000 ps partially, check with the step sim.

    os.system("rm mem0.log")											# Remove previous simulation results
    os.system("rm check_point_file.txt")											# Remove previous simulation results
    
    if not path.exists("check_point_file.txt"):								# checking if the file storing the check pointing information is present
        new_checker = open("check_point_file.txt", 'w')
        new_checker.write("0\n0\n0\n0\n0\n0\n")
        new_checker.close()
        start_type = cold
    else:
        start_type = resume
        
    if not path.exists("result_memory_files/"):			# checking the folder to store memories:
        os.system("mkdir result_memory_files")								# generate folder to store results
        print("The storing folder was created")
    else:
        if start_type == cold:		# checking that if really needed to generate the new folder
            today = date.today()
            now = datetime.now()
            t = now.strftime("%H_%M_%S")
            time_name = str(today.year) + "_" + str(today.month) + "_" + str(today.day) + "_" + t

            source_name_x = 'result_memory_files'
            destiny_name_y = 'result_memory_files_' + time_name
            os.rename(source_name_x, destiny_name_y)

            os.system("mkdir result_memory_files")								# generate folder to store results
            print("The storing folder was renamed")
    

    # final file to store the quantitative results:
    inFile_final = open("final_result_"+ str(application_name) + ".txt", 'a')						# file for final save test



    # Initial compilation command of the entire project (could be replaced by calling the tcl file):
    #             with the command: vsim -c -do \"vsim -t %s work.%s -novopt; source gpgpu_compile.tcl;quit -sim;quit -f;\"

    # mod command
    #	cmd_vsim ="""
    # 	vsim -c -do \"vsim -t %s work.%s -novopt;run %s;simstats totaltime;simstats totalcpu;quit -sim;quit -f;\"
    #	""" %('1ns', 'tb_top_level', default_execution_time[Select_app])
    cmd_vsim ="""%s\\ vsim\\ -c\\ -t\\ %s\\ -64\\ -do\\ \'%srun\\ -all\\;simstats\\ totaltime\\;simstats\\ totalcpu\\;quit\\ -sim\\;quit\\ -f\\;\' 
    """ %(env, '1ns', vsim_golden)


    #if start_type == cold:														# checking that if really needed to generate the golden simulation
    (total_time, totalcpu_time, official_kernel_op_time, official_op_time) = Launch_golden_sim(cmd_vsim, Debug_mode, application_name)


    if total_time == 0 and totalcpu_time == 0:
        print("program terminated: the Simulation time of the Golden Sim was not sufficient or the process of execution failed, check the debug mode for more info.")
        exit(0)


    # -------------------------------------------------------------------------------------------
    # openning the fault injection file for fault injection purposes:
    
    print("Opening fault injection file...")
    inFile = open(fault_list_name, 'r')								# Use a test file ( It includes a format : [Fault_type Signal_name - ])
    num_fault_lines = sum(1 for line_present in open(fault_list_name))
    if	num_fault_lines == 0:
        print("Error: check the fault list file, the total number of fault to apply cannot be zero...")
        exit()														# Finish the program to prevent the wrong lecture or injection of parameters.
    else:
        print("Fault list correctly open. [" + str(num_fault_lines) + "] lines to inject" )
    
    
    # -------------------------------------------------------------------------------------------
    #                                  FAULT SIMULATION CODE ZONE
    # -------------------------------------------------------------------------------------------
    actual_value = 0
    check_open=0
    i=0
    lines=0
    crashed_event=0
    count=0
    passed_event=0
    fault_memory_count=0
    error_by_stall=0
    error_by_memory=0
    error_by_degradation=0						# In time
    error_by_degradation_in_memory = 0			# In time
    error_by_degradation_but_mem_ok = 0			# In time
    flat_degradation=0
    error_not_detected=0						# fault not detected by the app. (dont affect performance or result)
    start_point = 0								# initialization for the SA0 and SA1 cases.
    perioded = 0
    fault_injection_counter = 0.0
    total_fault_lines = num_fault_lines			# defining the total number of fault to be applied in this fault simulation
    finished_sim = 0

    if golden_launch == 0:			# the fault injector can be launched:
        print("--------------------------------------------------------------------------------------- \n")
        print("                            Fault Simulation enabled...\n")
        print("--------------------------------------------------------------------------------------- \n")


        # Checking the actual fault simulation point:
#		input_check_file = open('check_point_file.txt', 'r')
        
        with open('check_point_file.txt', 'r') as input_check_file:
            actual_value = int( input_check_file.readline() )
            print (str(actual_value))
        
            if (actual_value == 0):
                print ("cold start")
                os.system("rm final_fault_dictionary_" + str(application_name) + ".txt" )
            else:
                print ("resume start")
                print ( str(total_fault_lines) )
                error_by_stall = int( input_check_file.readline() )
                error_by_memory = int( input_check_file.readline() )
                error_by_degradation_in_memory = int( input_check_file.readline() )
                error_not_detected = int( input_check_file.readline() )
                error_by_degradation_but_mem_ok = int( input_check_file.readline() )
                # restoring the dictionary file:
                os.system("cp final_fault_dictionary_back_up_" + str(application_name) + ".txt final_fault_dictionary_" + str(application_name) + ".txt" )

        # Fault injector execution:
        #with ProcessPoolExecutor(max_workers=80) as executor:
        #with ProcessPoolExecutor(max_workers=max_threads) as executor:
        with ProcessPoolExecutor() as executor:
            futures = []

            for line in inFile:
                  if actual_value == total_fault_lines:
                      fault_injection_counter = total_fault_lines
                      finished_sim = 1
                  elif actual_value > count:
                      count = count + 1
                      fault_injection_counter = fault_injection_counter + 1.0
                  else:
                      future = executor.submit(inject_fault, line, application_name, Debug_mode, official_kernel_op_time, official_op_time, env, vsim_golden, fault_injection_counter, total_fault_lines, store_data)
                      futures.append(future)

                      fault_injection_counter = fault_injection_counter + 1.0
            
            for future in as_completed(futures):
                try:
                    (memory, degradation, stall, degradation_in_memory, crashed, degradation_but_mem_ok, not_detected, passed, File_dictionary, File_final) = future.result()
                except Exception as e:
                    print(f"Error: {e}")
                    for f in futures:
                        f.cancel()
                    break

                error_by_memory += memory
                error_by_degradation += degradation
                error_by_stall += stall
                error_by_degradation_in_memory += degradation_in_memory
                error_by_degradation_but_mem_ok += degradation_but_mem_ok
                crashed_event += crashed
                error_not_detected += not_detected
                passed_event += passed

                print("Fault list employed:  " + str(fault_list_name))
#				  print("Simulating the configuration of : " + str(total_thread_number) + " Threads")
                print("Error_by_halt:..................................." + str(error_by_stall))   												# initial parameter to observe
                print("Error_by_Silent_data_corruption(SDC):............" + str(error_by_memory))   												# initial parameter to observe
                print("Error_by_time_out:..............................." + str(error_by_degradation_in_memory))   								# initial parameter to observe
                print("Error_not_detected( silent):....................." + str(error_not_detected - error_by_degradation_in_memory))  	 		# initial parameter to observe
            #	  print("Error_by_time_out_(Error in memory not detected):" + str(error_by_degradation_in_memory))   								# initial parameter to observe
            #	  print("Error_by_time_out_(Error in memory detected)....." + str(error_by_degradation_but_mem_ok))   								# initial parameter to observe
                print("----------------------------------------------------------------------------------- \n")
                  
                # Updating checkpoint:
                input_check_file = open("check_point_file.txt", "w").close()						# Clearing the content of the checkpoint file
                input_check_file = open("check_point_file.txt", "w")
                input_check_file.write(str(count)+"\n")
                input_check_file.write(str(error_by_stall)+"\n")
                input_check_file.write(str(error_by_memory)+"\n")
                input_check_file.write(str(error_by_degradation_in_memory)+"\n")
                input_check_file.write(str(error_not_detected)+"\n")
                input_check_file.write(str(error_by_degradation_but_mem_ok)+"\n")
                input_check_file.close()

                inFile_dictionary = open("final_fault_dictionary_" + str(application_name) + ".txt", 'a')
                inFile_dictionary.write(File_dictionary)
                inFile_dictionary.close()
                os.system("cp final_fault_dictionary_" + str(application_name) + ".txt final_fault_dictionary_back_up_" + str(application_name) + ".txt" )

                inFile_final.write(File_final)
                  
    inFile_final.write("Total # Faults evaluated :\t\t" + str(count) +"\n")
    inFile_final.write("Total # Faults detected :\t\t"   +   str( error_by_stall + error_by_memory + error_by_degradation - error_by_degradation_but_mem_ok )  +   "\n")
    inFile_final.write("Total # Faults not detected :\t\t" +  str( error_not_detected ) +"\n")
              
    inFile_final.write("Error_by_halt:..................................." + str(error_by_stall)+"\n")   										# initial parameter to observe
    inFile_final.write("Error_by_Silent_data_corruption(SDC):............" + str(error_by_memory)+"\n")   										# initial parameter to observe
    inFile_final.write("Error_by_time_out:..............................." + str(error_by_degradation_in_memory)+"\n")   						# initial parameter to observe
    inFile_final.write("Error_not_detected( silent):....................." + str(error_not_detected - error_by_degradation_in_memory)+"\n")   	# initial parameter to observe
    inFile_final.write("Error_by_time_out_(Error in memory not detected):" + str(error_by_degradation_in_memory)+"\n")   						# initial parameter to observe
    inFile_final.write("Error_by_time_out_(Error in memory detected)....." + str(error_by_degradation_but_mem_ok)+"\n")   						# initial parameter to observe											

    inFile_final.write("(SDC) Detected events: " + str(crashed_event)+f" ({100*(crashed_event)/(crashed_event+passed_event):.2f}%)\n")  	 																# initial parameter to observe
    inFile_final.write("(SDC) Not Detected events: " + str(passed_event)+f" ({100*(passed_event)/(crashed_event+passed_event):.2f}%)\n")


    if finished_sim == 1:
        finished_sim = 0

        input_check_file = open("check_point_file.txt", "w").close()						# Clearing the content of the checkpoint file
        input_check_file = open("check_point_file.txt", "w")
        input_check_file.write(str(0)+"\n")
        input_check_file.write(str(0)+"\n")
        input_check_file.write(str(0)+"\n")
        input_check_file.write(str(0)+"\n")
        input_check_file.write(str(0)+"\n")
        input_check_file.write(str(0)+"\n")
        input_check_file.close()		
        
        print(" Simulation finished, Now the checkpoint file is clear, please retrive results \n")
    
    
    
    print("--------------------------------------------------------------------------------------- \n")
    print("                                 Fault injection finished ")
    print("--------------------------------------------------------------------------------------- \n")
    print("Total Faults by Halt:.........................." + str(error_by_stall) + f" ({100*error_by_stall/fault_injection_counter:.2f}%)")  	 														# initial parameter to observe
    print("Total Faults by Silent Data Corruption (SDC):.." + str(error_by_memory) + f" ({100*error_by_memory/fault_injection_counter:.2f}%)")   															# initial parameter to observe
    print("Total Faults by Time Out(100%):................" + str(error_by_degradation_in_memory) + f" ({100*error_by_degradation_in_memory/fault_injection_counter:.2f}%)")   											# initial parameter to observe
    print("Total Faults not detected (Silent Faults):....." + str(error_not_detected - error_by_degradation_in_memory) + f" ({100*(error_not_detected - error_by_degradation_in_memory)/fault_injection_counter:.2f}%)")   						# initial parameter to observe
    print("--------------------------------------------------------------------------------------- \n")

    inFile_final.close()
    os.system("mv final_result_" + str(application_name) + ".txt result_memory_files/final_result_" + str(application_name) + ".txt" )
    os.system("mv final_fault_dictionary_" + str(application_name) + ".txt result_memory_files/final_fault_dictionary_" + str(application_name) + ".txt" )
    
    #os.system("python redable_report_top.py")
    os.system("rm check_point_file.txt")
    
    
    
    
main()
