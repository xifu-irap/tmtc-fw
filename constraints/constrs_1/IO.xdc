###############################################################################################################
##                            Copyright (C) 2023-2030 Ken-ji de la Rosa, IRAP Toulouse.
###############################################################################################################
##                            This file is part of the ATHENA X-IFU DRE Telemetry and Telecommand Firmware.
##
##                            tmtc-fw is free software: you can redistribute it and/or modify
##                            it under the terms of the GNU General Public License as published by
##                            the Free Software Foundation, either version 3 of the License, or
##                            (at your option) any later version.
##
##                            This program is distributed in the hope that it will be useful,
##                            but WITHOUT ANY WARRANTY; without even the implied warranty of
##                            MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##                            GNU General Public License for more details.
##
##                            You should have received a copy of the GNU General Public License
##                            along with this program.  If not, see <https://www.gnu.org/licenses/>.
###############################################################################################################
#    email                   kenji.delarosa@alten.com
#    @file                   IO.xdc
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
# create_clock -name sys_clk -period 5 [get_ports i_sys_clk_p]

###############################################################################################################
# usb @100.8 MHz
###############################################################################################################
# 100.8 MHz
create_clock -period 9.920 -name usb_clk_in [get_ports {i_okUH[0]}];
create_clock -name virt_usb_clk_in -period 9.920;

 # 62.5 MHz
create_clock -period 16 -name science_clk1 [get_ports {i_science_clk_p[0]}]

# science
#    create the associated virtual input clock to science_clk1 and science_clk2
#      science_clk1 and science_clk2 have the same source.
create_clock -period 16 -name virtual_science_clk;

# DDR
create_clock -period 10  -name virtual_ddr_clk;


###############################################################################################################
# rename auto-derived clock
###############################################################################################################
# define variables
set usb_clk_in_pin [get_pins inst_regdecode_top/inst_usb_opal_kelly/inst_Opal_Kelly_Host/mmcm0/CLKIN1]
set usb_clk_out_pin  [get_pins inst_regdecode_top/inst_usb_opal_kelly/inst_Opal_Kelly_Host/mmcm0/CLKOUT0]
set ddr_clk_in_pin       [get_pins inst_ddr3_256_16/u_ddr3_256_16_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKIN1];
set ddr_clk_user_out_pin [get_pins inst_ddr3_256_16/u_ddr3_256_16_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT];


# rename clock
create_generated_clock -name usb_clk       -source $usb_clk_in_pin $usb_clk_out_pin;
create_generated_clock -name ddr_user_clk  -source $ddr_clk_in_pin $ddr_clk_user_out_pin;


###############################################################################################################
# ODDR : forward clock
###############################################################################################################
create_generated_clock -name gen_spi_clk -multiply_by 1 -source [get_pins inst_io_top/inst_io_spi/gen_user_to_pads_clk.inst_oddr/C] [get_ports {o_spi_sclk}]


###############################################################################################################
# usb: constraints register/Q on register/clk
###############################################################################################################
set usb_src [get_pins inst_regdecode_top/inst_usb_opal_kelly/inst_Opal_Kelly_Host/core0/core0/a0/d0/lc4da648cb12eeeb24e4d199c1195ed93_reg[4]/C];
set usb_dest [get_pins inst_regdecode_top/inst_usb_opal_kelly/inst_Opal_Kelly_Host/core0/core0/a0/d0/lc4da648cb12eeeb24e4d199c1195ed93_reg[4]/Q];
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

set input_clock         virt_usb_clk_in;      # Name of input clock
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

set input_clock         virt_usb_clk_in;      # Name of input clock
set input_clock_period  9.92;    # Period of input clock
set dv_bre              1.920;             # Data valid before the rising clock edge
set dv_are              0.000;             # Data valid after the rising clock edge
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

set fwclk        ddr_user_clk;      # forwarded clock name (generated using create_generated_clock at output clock port)
set tsu          1;           # destination device setup time requirement
set thd          1;           # destination device hold time requirement
set trce_dly_max 0.000;            # maximum board trace delay
set trce_dly_min 0.000;            # minimum board trace delay
set output_ports {o_spi_mosi o_spi_cs_n[*]};   # list of output ports

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

set input_clock         virtual_ddr_clk;      # Name of input clock
set input_clock_period  5;              # Period of input clock
set dv_bre              1;          # Data valid before the rising clock edge
set dv_are              1;          # Data valid after the rising clock edge
set input_ports         {i_spi_miso};     # List of input ports

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

set input_clock         virtual_science_clk;      # Name of input clock
set input_clock_period  16;    # Period of input clock
set dv_bre              2.50;             # Data valid before the rising clock edge
set dv_are              2.5000;             # Data valid after the rising clock edge
set input_ports         {i_science_ctrl_p[*] i_science_data_p[*]};     # List of input ports

# Input Delay Constraint
set_input_delay -clock $input_clock -max [expr $input_clock_period - $dv_bre] [get_ports $input_ports] -add_delay;
set_input_delay -clock $input_clock -min $dv_are                              [get_ports $input_ports] -add_delay;


# Force the MMCM placement
# set_property LOC MMCME2_ADV_X1Y1 [get_cells -hier -filter {NAME =~ *u_ddr3_256_16_mig/u_iodelay_ctrl/clk_ref_mmcm_gen.mmcm_i}]
# set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_pins -hierarchical *clk_ref_mmcm_gen.mmcm_i*CLKIN1]

# constraints ddr sys_rst reset (input reset)
set_max_delay -from [get_clocks usb_clk] -to [get_clocks ddr_user_clk] -datapath_only 5.0; #200 MHz
set_bus_skew -from [get_clocks usb_clk] -to [get_clocks ddr_user_clk] 5.0; #200 MHz

set_max_delay -from [get_clocks usb_clk] -to [get_clocks mmcm_ps_clk_bufg_in] -datapath_only 10.0; #100 MHz
set_bus_skew -from [get_clocks usb_clk] -to [get_clocks mmcm_ps_clk_bufg_in] 10.0; #100 MHz


set_max_delay -from [get_clocks ddr_user_clk] -to [get_ports {ddr3_reset_n}] -datapath_only 5.0; #200 MHz
set_max_delay -from [get_ports {ddr3_dqs_p[*]}] -to [get_clocks ddr_user_clk] -datapath_only 5.0; #200 MHz


set_max_delay -from [get_clocks ddr_user_clk] -to [get_clocks usb_clk] -datapath_only 5.0; #200 MHz
# set_bus_skew -from [get_clocks ddr_user_clk] -to [get_clocks usb_clk] 5.0; #200 MHz



###############################################################################################################
# Unrelated asynchronuous clocks
#  by default, set_clock_group on a master clock are NOT applied to generated clocks by default.
#  You need to explicitly include it as in the command below.
###############################################################################################################
set_clock_groups -name async_mmcm_usb_user_virt -asynchronous -group {usb_clk} -group {virt_usb_clk_in}
# set_clock_groups -name async_science -group {science_clk1 science_clk2}

set_false_path -setup  -rise_from [get_clocks virtual_science_clk] -fall_to [get_clocks science_clk1]
set_false_path -setup  -fall_from [get_clocks virtual_science_clk] -rise_to [get_clocks science_clk1]
set_false_path -hold   -rise_from [get_clocks virtual_science_clk] -fall_to [get_clocks science_clk1]
set_false_path -hold   -fall_from [get_clocks virtual_science_clk] -rise_to [get_clocks science_clk1]

set_false_path -setup  -rise_from [get_clocks ddr_user_clk] -fall_to [get_clocks gen_spi_clk]
set_false_path -setup  -fall_from [get_clocks ddr_user_clk] -rise_to [get_clocks gen_spi_clk]
set_false_path -hold   -rise_from [get_clocks ddr_user_clk] -fall_to [get_clocks gen_spi_clk]
set_false_path -hold   -fall_from [get_clocks ddr_user_clk] -rise_to [get_clocks gen_spi_clk]

set_false_path -setup  -rise_from [get_clocks virtual_ddr_clk] -fall_to [get_clocks ddr_user_clk]
set_false_path -setup  -fall_from [get_clocks virtual_ddr_clk] -rise_to [get_clocks ddr_user_clk]
set_false_path -hold   -rise_from [get_clocks virtual_ddr_clk] -fall_to [get_clocks ddr_user_clk]
set_false_path -hold   -fall_from [get_clocks virtual_ddr_clk] -rise_to [get_clocks ddr_user_clk]


##################################################################################
# others (input ports): asynchronuous ports
##################################################################################
set_false_path -to   [get_ports o_debug[*]];
set_false_path -to   [get_ports o_leds[*]];
set_false_path -to   [get_ports o_sel_main_n];
set_false_path -to   [get_ports o_led_fw];
set_false_path -to   [get_ports o_led_pll_lock];
set_false_path -from [get_ports i_hardware_id[*]];

##################################################################################
# SPI: IO
#   use IO register when possible
##################################################################################
# shared spi links
set_property IOB true [get_ports o_spi_mosi];
set_property IOB true [get_ports o_spi_sclk];
set_property IOB true [get_ports i_spi_miso];
# cs
set_property IOB true [get_ports o_spi_cs_n[*]];


##################################################################################
# sciences
##################################################################################
set_property IOB true [get_ports i_science_ctrl_p[*]];
set_property IOB true [get_ports i_science_data_p[*]];
