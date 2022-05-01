## Generated SDC file "capLevelSensor.out.sdc"

## Copyright (C) 2021  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and any partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details, at
## https://fpgasoftware.intel.com/eula.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 21.1.0 Build 842 10/21/2021 SJ Lite Edition"

## DATE    "Sun May  1 16:59:59 2022"

##
## DEVICE  "EP4CE22F17C6"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clk50Mhz} -period 20.000 -waveform { 0.000 10.000 } [get_ports {clk50Mhz}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {clk100Mhz} -source [get_ports {clk50Mhz}] -multiply_by 2 -master_clock {clk50Mhz} [get_nets {Inst_pll|altpll_component|auto_generated|wire_pll1_clk[0]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {clk50Mhz}] -rise_to [get_clocks {clk50Mhz}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clk50Mhz}] -fall_to [get_clocks {clk50Mhz}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk50Mhz}] -rise_to [get_clocks {clk50Mhz}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk50Mhz}] -fall_to [get_clocks {clk50Mhz}]  0.020  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -add_delay  -clock [get_clocks {clk50Mhz}]  2.000 [get_ports {uartTx}]


#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************

set_false_path  -from  [get_clocks {clk100Mhz}]  -to  [get_clocks {clk50Mhz}]


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

