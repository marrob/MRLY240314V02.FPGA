## Generated SDC file "MRLY240314V02.sdc"

## Copyright (C) 1991-2013 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 13.1.0 Build 162 10/23/2013 SJ Web Edition"

## DATE    "Sat Aug 24 15:20:54 2024"

##
## DEVICE  "EP4CE6E22C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {fdiv:fdiv_inst|clk_out} -period 20.000 -waveform { 0.000 0.500 } [get_registers {fdiv:fdiv_inst|clk_out}]
create_clock -name {clk} -period 20.000 -waveform { 0.000 10.000 } [get_ports {clk}]
create_clock -name {slu_strobe} -period 20.000 -waveform { 0.000 0.500 } [get_ports {slu_strobe}]
create_clock -name {diag_cs_n} -period 1000.000 -waveform { 0.000 0.500 } [get_ports {diag_cs_n}]
create_clock -name {diag_clk} -period 2000.000 -waveform { 0.000 0.500 } [get_ports {diag_clk}]


#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {slu_strobe}] -rise_to [get_clocks {diag_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {slu_strobe}] -fall_to [get_clocks {diag_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {slu_strobe}] -rise_to [get_clocks {slu_strobe}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {slu_strobe}] -fall_to [get_clocks {slu_strobe}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {slu_strobe}] -rise_to [get_clocks {diag_cs_n}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {slu_strobe}] -fall_to [get_clocks {diag_cs_n}]  0.040  

set_clock_uncertainty -rise_from [get_clocks {slu_strobe}] -rise_to [get_clocks {clk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {slu_strobe}] -fall_to [get_clocks {clk}]  0.040  

set_clock_uncertainty -rise_from [get_clocks {slu_strobe}] -rise_to [get_clocks {fdiv:fdiv_inst|clk_out}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {slu_strobe}] -fall_to [get_clocks {fdiv:fdiv_inst|clk_out}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {slu_strobe}] -rise_to [get_clocks {diag_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {slu_strobe}] -fall_to [get_clocks {diag_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {slu_strobe}] -rise_to [get_clocks {slu_strobe}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {slu_strobe}] -fall_to [get_clocks {slu_strobe}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {slu_strobe}] -rise_to [get_clocks {diag_cs_n}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {slu_strobe}] -fall_to [get_clocks {diag_cs_n}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {slu_strobe}] -rise_to [get_clocks {fdiv:fdiv_inst|clk_out}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {slu_strobe}] -fall_to [get_clocks {fdiv:fdiv_inst|clk_out}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk}] -rise_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clk}] -fall_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clk}] -rise_to [get_clocks {fdiv:fdiv_inst|clk_out}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk}] -fall_to [get_clocks {fdiv:fdiv_inst|clk_out}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk}] -rise_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk}] -fall_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk}] -rise_to [get_clocks {fdiv:fdiv_inst|clk_out}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk}] -fall_to [get_clocks {fdiv:fdiv_inst|clk_out}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {diag_cs_n}] -rise_to [get_clocks {diag_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {diag_cs_n}] -fall_to [get_clocks {diag_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {diag_cs_n}] -rise_to [get_clocks {diag_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {diag_cs_n}] -fall_to [get_clocks {diag_clk}]  0.030  

set_clock_uncertainty -fall_from [get_clocks {diag_cs_n}] -rise_to [get_clocks {clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {diag_cs_n}] -fall_to [get_clocks {clk}]  0.030 
set_clock_uncertainty -rise_from [get_clocks {diag_cs_n}] -rise_to [get_clocks {clk}]  0.030 

set_clock_uncertainty -fall_from [get_clocks {diag_clk}] -rise_to [get_clocks {clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {diag_clk}] -fall_to [get_clocks {clk}]  0.030 
set_clock_uncertainty -rise_from [get_clocks {diag_clk}] -rise_to [get_clocks {clk}]  0.030 

set_clock_uncertainty -rise_from [get_clocks {fdiv:fdiv_inst|clk_out}] -rise_to [get_clocks {clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fdiv:fdiv_inst|clk_out}] -fall_to [get_clocks {clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fdiv:fdiv_inst|clk_out}] -rise_to [get_clocks {fdiv:fdiv_inst|clk_out}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {fdiv:fdiv_inst|clk_out}] -fall_to [get_clocks {fdiv:fdiv_inst|clk_out}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {fdiv:fdiv_inst|clk_out}] -rise_to [get_clocks {clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fdiv:fdiv_inst|clk_out}] -fall_to [get_clocks {clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fdiv:fdiv_inst|clk_out}] -rise_to [get_clocks {fdiv:fdiv_inst|clk_out}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {fdiv:fdiv_inst|clk_out}] -fall_to [get_clocks {fdiv:fdiv_inst|clk_out}]  0.020  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

