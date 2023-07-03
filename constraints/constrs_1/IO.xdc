###############################################################################################################
#                              Copyright (C) 2022-2030 Ken-ji de la Rosa, IRAP Toulouse.
###############################################################################################################
#                              This file is part of the ATHENA X-IFU DRE Focal Plane Assembly simulator.
#
#                              fpasim-fw is free software: you can redistribute it and/or modify
#                              it under the terms of the GNU General Public License as published by
#                              the Free Software Foundation, either version 3 of the License, or
#                              (at your option) any later version.
#
#                              This program is distributed in the hope that it will be useful,
#                              but WITHOUT ANY WARRANTY; without even the implied warranty of
#                              MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#                              GNU General Public License for more details.
#
#                              You should have received a copy of the GNU General Public License
#                              along with this program.  If not, see <https://www.gnu.org/licenses/>.
###############################################################################################################
#    email                   kenji.delarosa@alten.com
#    @file                   test_IO.xdc
###############################################################################################################
#    Automatic Generation    No
#    Code Rules Reference    N/A
###############################################################################################################
#    @details                
#    This file set the timing constraints on the top_level I/O ports (temporary)
#    
# 
###############################################################################################################

###############################################################################################################
# xem7350 : system clock
###############################################################################################################
#  Not defined because this clock is already defined in the configuration of the DDR IP
# create_clock -name sys_clk -period 5 [get_ports sys_clkp]

###############################################################################################################
# usb @100.8 MHz
###############################################################################################################
create_clock -period 9.920 -name okUH0 [get_ports {i_okUH[0]}]
create_clock -name virt_okUH0 -period 9.920
 # 62.5 MHz
create_clock -period 16 -name science_clk1 [get_ports {clk_science_p[0]}]
create_clock -period 16 -name science_clk2 [get_ports {clk_science_p[1]}]

###############################################################################################################
# Unrelated asynchronuous clocks
###############################################################################################################
set_clock_groups -name async-mmcm-user-virt -asynchronous -group {usb_clk} -group {virt_okUH0}

###############################################################################################################
# ODDR : forward clock
###############################################################################################################
create_generated_clock -name gen_spi_clk -multiply_by 1 -source [get_pins spi_mgt1/I_dac_spi_master/o_sclk/C] [get_ports {o_sclk}]


###############################################################################################################
# usb: constraints register/Q on register/clk
###############################################################################################################
set usb_src [get_pins inst_fpasim_top/inst_regdecode_top/inst_usb_opal_kelly/Opal_Kelly_Host/core0/core0/a0/d0/lc4da648cb12eeeb24e4d199c1195ed93_reg[4]/C]
set usb_dest [get_pins inst_fpasim_top/inst_regdecode_top/inst_usb_opal_kelly/Opal_Kelly_Host/core0/core0/a0/d0/lc4da648cb12eeeb24e4d199c1195ed93_reg[4]/Q]
create_generated_clock -name usb_clk_regQ_on_clk_pin -source $usb_src -divide_by 2 $usb_dest;

###############################################################################################################
# usb (input ports)
###############################################################################################################
# Center-Aligned Rising Edge Source Synchronous Inputs 
#
# For a center-aligned Source Synchronous interface, the clock
# transition is aligned with the center of the data valid window.
# The same clock edge is used for launching and capturing the
# data. The constraints below rely on the default timing
# analysis (setup = 1 cycle, hold = 0 cycle).
#
# input    ____           __________    
# clock        |_________|          |_____
#                        |                 
#                 dv_bre | dv_are    
#                <------>|<------>  
#          __    ________|________    __
# data     __XXXX____Rise_Data____XXXX__
#

# set input_clock         usb_clk;      # Name of input clock
set input_clock         virt_okUH0;      # Name of input clock
set input_clock_period  9.92;    # Period of input clock
set dv_bre              1.920;             # Data valid before the rising clock edge
set dv_are              0.000;             # Data valid after the rising clock edge
set input_ports         {i_okUH[*]};     # List of input ports

# Input Delay Constraint
set_input_delay -clock $input_clock -max [expr $input_clock_period - $dv_bre] [get_ports $input_ports] -add_delay;
set_input_delay -clock $input_clock -min $dv_are                              [get_ports $input_ports] -add_delay;

# Center-Aligned Rising Edge Source Synchronous Inputs 
#
# For a center-aligned Source Synchronous interface, the clock
# transition is aligned with the center of the data valid window.
# The same clock edge is used for launching and capturing the
# data. The constraints below rely on the default timing
# analysis (setup = 1 cycle, hold = 0 cycle).
#
# input    ____           __________    
# clock        |_________|          |_____
#                        |                 
#                 dv_bre | dv_are    
#                <------>|<------>  
#          __    ________|________    __
# data     __XXXX____Rise_Data____XXXX__
#

# set input_clock         usb_clk;      # Name of input clock
set input_clock         virt_okUH0;      # Name of input clock
set input_clock_period  9.92;    # Period of input clock
set dv_bre              1.920;             # Data valid before the rising clock edge
set dv_are              2.000;             # Data valid after the rising clock edge
set input_ports         {b_okUHU[*] b_okAA};     # List of input ports

# Input Delay Constraint
set_input_delay -clock $input_clock -max [expr $input_clock_period - $dv_bre] [get_ports $input_ports] -add_delay;
set_input_delay -clock $input_clock -min $dv_are                              [get_ports $input_ports] -add_delay;

###############################################################################################################
# usb (output ports)
###############################################################################################################

#  Rising Edge Source Synchronous Outputs 
#
#  Source synchronous output interfaces can be constrained either by the max data skew
#  relative to the generated clock or by the destination device setup/hold requirements.
#
#  Setup/Hold Case:
#  Setup and hold requirements for the destination device and board trace delays are known.
#  
# forwarded         ____                      ___________________ 
# clock                 |____________________|                   |____________ 
#                                            |
#                                     tsu    |    thd
#                                <---------->|<--------->
#                                ____________|___________
# data @ destination    XXXXXXXXX________________________XXXXX
#
# Example of creating generated clock at clock output port
# create_generated_clock -name <gen_clock_name> -multiply_by 1 -source [get_pins <source_pin>] [get_ports <output_clock_port>]
# gen_clock_name is the name of forwarded clock here. It should be used below for defining "fwclk".	

# set fwclk        $usb_clk;     # forwarded clock name (generated using create_generated_clock at output clock port)        
set fwclk        usb_clk;     # forwarded clock name (generated using create_generated_clock at output clock port)        
set tsu          2.000;            # destination device setup time requirement
set thd          0.500;            # destination device hold time requirement
set trce_dly_max 0.000;            # maximum board trace delay
set trce_dly_min 0.000;            # minimum board trace delay
set output_ports {o_okHU[*] b_okUHU[*] b_okAA};   # list of output ports

# Output Delay Constraints
set_output_delay -clock $fwclk -max [expr $trce_dly_max + $tsu] [get_ports $output_ports] -add_delay;
set_output_delay -clock $fwclk -min [expr $trce_dly_min - $thd] [get_ports $output_ports] -add_delay;


##################################################################################
# SPI: timing constraints (output ports)
#    for all spi, we consider the worst case (CDCE @20MHz: cdce72010)
##################################################################################
#  Rising Edge Source Synchronous Outputs 
#
#  Source synchronous output interfaces can be constrained either by the max data skew
#  relative to the generated clock or by the destination device setup/hold requirements.
#
#  Setup/Hold Case:
#  Setup and hold requirements for the destination device and board trace delays are known.
#  
# forwarded         ____                      ___________________ 
# clock                 |____________________|                   |____________ 
#                                            |
#                                     tsu    |    thd
#                                <---------->|<--------->
#                                ____________|___________
# data @ destination    XXXXXXXXX________________________XXXXX
#
# Example of creating generated clock at clock output port
# create_generated_clock -name <gen_clock_name> -multiply_by 1 -source [get_pins <source_pin>] [get_ports <output_clock_port>]
# gen_clock_name is the name of forwarded clock here. It should be used below for defining "fwclk".	

# set fwclk        usb_clk;      # forwarded clock name (generated using create_generated_clock at output clock port)        
set fwclk        gen_spi_clk;      # forwarded clock name (generated using create_generated_clock at output clock port)        
set tsu          2.5;           # destination device setup time requirement
set thd          2.5;           # destination device hold time requirement
set trce_dly_max 0.000;            # maximum board trace delay
set trce_dly_min 0.000;            # minimum board trace delay
# set output_ports {o_spi_sdata o_cdce_n_en o_cdce_n_reset o_cdce_n_pd o_ref_en o_adc_n_en o_adc_reset o_dac_n_en o_dac_tx_present o_mon_n_en o_mon_n_reset};   # list of output ports
set output_ports {o_mosi o_sync_n};   # list of output ports

# Output Delay Constraints
set_output_delay -clock $fwclk -max [expr $trce_dly_max + $tsu] [get_ports $output_ports];
set_output_delay -clock $fwclk -min [expr $trce_dly_min - $thd] [get_ports $output_ports];

##################################################################################
# SPI: timing constraints (input ports)
#    for all spi, we consider the worst case (CDCE @20MHz: cdce72010)
##################################################################################
# Center-Aligned Rising Edge Source Synchronous Inputs 
#
# For a center-aligned Source Synchronous interface, the clock
# transition is aligned with the center of the data valid window.
# The same clock edge is used for launching and capturing the
# data. The constraints below rely on the default timing
# analysis (setup = 1 cycle, hold = 0 cycle).
#
# input    ____           __________    
# clock        |_________|          |_____
#                        |                 
#                 dv_bre | dv_are    
#                <------>|<------>  
#          __    ________|________    __
# data     __XXXX____Rise_Data____XXXX__
#

set input_clock         usb_clk;      # Name of input clock
set input_clock_period  10;              # Period of input clock
set dv_bre              2.5;          # Data valid before the rising clock edge
set dv_are              2.500;          # Data valid after the rising clock edge
# set input_ports         {i_cdce_sdo i_cdce_pll_status i_adc_sdo i_dac_sdo i_mon_sdo i_mon_n_int};     # List of input ports
set input_ports         {i_miso};     # List of input ports

# Input Delay Constraint
set_input_delay -clock $input_clock -max [expr $input_clock_period - $dv_bre] [get_ports $input_ports];
set_input_delay -clock $input_clock -min $dv_are                              [get_ports $input_ports];


###############################################################################################################
# science1 (input ports)
###############################################################################################################
# Center-Aligned Rising Edge Source Synchronous Inputs 
#
# For a center-aligned Source Synchronous interface, the clock
# transition is aligned with the center of the data valid window.
# The same clock edge is used for launching and capturing the
# data. The constraints below rely on the default timing
# analysis (setup = 1 cycle, hold = 0 cycle).
#
# input    ____           __________    
# clock        |_________|          |_____
#                        |                 
#                 dv_bre | dv_are    
#                <------>|<------>  
#          __    ________|________    __
# data     __XXXX____Rise_Data____XXXX__
#

# set input_clock         usb_clk;      # Name of input clock
set input_clock         science_clk1;      # Name of input clock
set input_clock_period  16;    # Period of input clock
set dv_bre              1.920;             # Data valid before the rising clock edge
set dv_are              0.000;             # Data valid after the rising clock edge
set input_ports         {i_science_ctrl_p[0] i_science_data_p[0] i_science_data_p[1] i_science_data_p[2] i_science_data_p[3]};     # List of input ports

# Input Delay Constraint
set_input_delay -clock $input_clock -max [expr $input_clock_period - $dv_bre] [get_ports $input_ports] -add_delay;
set_input_delay -clock $input_clock -min $dv_are                              [get_ports $input_ports] -add_delay;

###############################################################################################################
# science2 (input ports)
###############################################################################################################
# Center-Aligned Rising Edge Source Synchronous Inputs 
#
# For a center-aligned Source Synchronous interface, the clock
# transition is aligned with the center of the data valid window.
# The same clock edge is used for launching and capturing the
# data. The constraints below rely on the default timing
# analysis (setup = 1 cycle, hold = 0 cycle).
#
# input    ____           __________    
# clock        |_________|          |_____
#                        |                 
#                 dv_bre | dv_are    
#                <------>|<------>  
#          __    ________|________    __
# data     __XXXX____Rise_Data____XXXX__
#

# set input_clock         usb_clk;      # Name of input clock
set input_clock         science_clk2;      # Name of input clock
set input_clock_period  16;    # Period of input clock
set dv_bre              1.920;             # Data valid before the rising clock edge
set dv_are              0.000;             # Data valid after the rising clock edge
set input_ports         {i_science_ctrl_p[1] i_science_data_p[4] i_science_data_p[5] i_science_data_p[6] i_science_data_p[7]};     # List of input ports

# Input Delay Constraint
set_input_delay -clock $input_clock -max [expr $input_clock_period - $dv_bre] [get_ports $input_ports] -add_delay;
set_input_delay -clock $input_clock -min $dv_are                              [get_ports $input_ports] -add_delay;

##################################################################################
# others (input ports): asynchronuous ports
##################################################################################
set_false_path -to   [get_ports "leds*"]

##################################################################################
# SPI: IO
#   use IO register when possible
##################################################################################
# shared spi links
set_property IOB true [get_ports o_mosi]
set_property IOB true [get_ports o_sclk]
set_property IOB true [get_ports i_miso]
# cs
set_property IOB true [get_ports o_sync_n]


##################################################################################
# sciences
##################################################################################
set_property IOB true [get_ports clk_science_p[*]]
set_property IOB true [get_ports i_science_ctrl_p[*]]
set_property IOB true [get_ports i_science_data_p[*]]
