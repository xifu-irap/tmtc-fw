-- -------------------------------------------------------------------------------------------------------------
--                            Copyright (C) 2023-2030 Ken-ji de la Rosa, IRAP Toulouse.
-- -------------------------------------------------------------------------------------------------------------
--                            This file is part of the ATHENA X-IFU DRE Telemetry and Telecommand Firmware.
--
--                            tmtc-fw is free software: you can redistribute it and/or modify
--                            it under the terms of the GNU General Public License as published by
--                            the Free Software Foundation, either version 3 of the License, or
--                            (at your option) any later version.
--
--                            This program is distributed in the hope that it will be useful,
--                            but WITHOUT ANY WARRANTY; without even the implied warranty of
--                            MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--                            GNU General Public License for more details.
--
--                            You should have received a copy of the GNU General Public License
--                            along with this program.  If not, see <https://www.gnu.org/licenses/>.
-- -------------------------------------------------------------------------------------------------------------
--    email                   kenji.delarosa@alten.com
--    @file                   usb_opal_kelly.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This module instanciates the necessary different opal kelly component
--
--    requirement: FPASIM-FW-REQ-0250
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.frontpanel.all;

entity usb_opal_kelly is
  port(
    --  Opal Kelly inouts --
    -- usb interface signal
    i_okUH                              : in    std_logic_vector(4 downto 0);
    -- usb interface signal
    o_okHU                              : out   std_logic_vector(2 downto 0);
    -- usb interface signal
    b_okUHU                             : inout std_logic_vector(31 downto 0);
    -- usb interface signal
    b_okAA                              : inout std_logic;
    ---------------------------------------------------------------------
    -- from the user @o_usb_clk
    ---------------------------------------------------------------------
    -- wire_out
    -- science_wr_data_count register (reading)
    i_usb_wireout_science_wr_data_count : in    std_logic_vector(31 downto 0);
    -- science_stamp_lsb register (reading)
    i_usb_wireout_science_stamp_lsb     : in    std_logic_vector(31 downto 0);
    -- tc_hk_conf register (reading)
    i_usb_wireout_tc_hk_conf            : in    std_logic_vector(31 downto 0);
    -- spi_rd_data_count register (reading)
    i_usb_wireout_hk_rd_data_count      : in    std_logic_vector(31 downto 0);
    -- hardware id register (reading)
    i_usb_wireout_hardware_id           : in    std_logic_vector(31 downto 0);
    -- firmware_name register (reading)
    i_usb_wireout_firmware_name         : in    std_logic_vector(31 downto 0);
    -- firmware_id register (reading)
    i_usb_wireout_firmware_id           : in    std_logic_vector(31 downto 0);

    -- errors/status
    -- debug_ctrl register (reading)
    i_usb_wireout_debug_ctrl : in std_logic_vector(31 downto 0);
    -- sel_errors register (reading)
    i_usb_wireout_sel_errors : in std_logic_vector(31 downto 0);
    -- errors register (reading)
    i_usb_wireout_errors     : in std_logic_vector(31 downto 0);
    -- status register (reading)
    i_usb_wireout_status     : in std_logic_vector(31 downto 0);

    -- rd science pipe
    -- read fifo
    o_usb_pipeout_science_rd_data_valid : out std_logic;
    -- input data fifo
    i_usb_pipeout_science_rd_data       : in  std_logic_vector(31 downto 0);

    -- read spi pipe
    -- read fifo
    o_usb_pipeout_rd_hk_valid : out std_logic;
    -- input data fifo
    i_usb_pipeout_rd_hk       : in  std_logic_vector(31 downto 0);
    ---------------------------------------------------------------------
    -- to the user @o_usb_clk
    ---------------------------------------------------------------------
    -- usb clock
    o_usb_clk                 : out std_logic;
    -- pipe
    -- pipein data valid
    o_usb_pipein_tc_valid     : out std_logic;
    -- pipein data
    o_usb_pipein_tc           : out std_logic_vector(31 downto 0);

    -- wire
    -- ctrl register (writting)
    o_usb_wirein_ctrl       : out std_logic_vector(31 downto 0);
    -- tc_hk_conf register (writting)
    o_usb_wirein_tc_hk_conf : out std_logic_vector(31 downto 0);
    -- icu_conf register (writting)
    o_usb_wirein_icu_conf   : out std_logic_vector(31 downto 0);
    -- debugging
    -- debug_ctrl register (writting)
    o_usb_wirein_debug_ctrl : out std_logic_vector(31 downto 0);
    -- sel_errors register (writting)
    o_usb_wirein_sel_errors : out std_logic_vector(31 downto 0)
    );
end entity usb_opal_kelly;

architecture RTL of usb_opal_kelly is

  -- total number of used wire out, pipe out, pipe in and trigger out
  constant c_WIRE_PIPE_TRIG_NUMBER_OUT : integer := 14;

  ---- Opal Kelly signals ----
  -- usb interface signal
  signal okClk : std_logic;
  -- usb interface signal
  signal okHE  : std_logic_vector(112 downto 0);
  -- usb interface signal
  signal okEH  : std_logic_vector(64 downto 0);
  -- usb interface signal
  signal okEHx : std_logic_vector(c_WIRE_PIPE_TRIG_NUMBER_OUT * 65 - 1 downto 0);

  type t_array65 is array (0 to c_WIRE_PIPE_TRIG_NUMBER_OUT - 1) of std_logic_vector(64 downto 0);
  signal okEHx_array : t_array65;

  -- wires in
  signal ep00_wire : std_logic_vector(31 downto 0);  -- wire in00
  signal ep01_wire : std_logic_vector(31 downto 0);  -- wire in01
  signal ep02_wire : std_logic_vector(31 downto 0);  -- wire in02
  --signal ep03_wire : std_logic_vector(31 downto 0);-- wire in03
  --signal ep04_wire : std_logic_vector(31 downto 0);-- wire in04
  --signal ep05_wire : std_logic_vector(31 downto 0);-- wire in05
  --signal ep06_wire : std_logic_vector(31 downto 0);-- wire in06
  --signal ep07_wire : std_logic_vector(31 downto 0);-- wire in07
  --signal ep08_wire : std_logic_vector(31 downto 0);-- wire in08
  --signal ep09_wire : std_logic_vector(31 downto 0);-- wire in09
  --signal ep0A_wire : std_logic_vector(31 downto 0);-- wire in10
  --signal ep0B_wire : std_logic_vector(31 downto 0);-- wire in11
  --signal ep0C_wire : std_logic_vector(31 downto 0);-- wire in12
  --signal ep0D_wire : std_logic_vector(31 downto 0);-- wire in13
  --signal ep0E_wire : std_logic_vector(31 downto 0);-- wire in14
  --signal ep0F_wire : std_logic_vector(31 downto 0);-- wire in15
  --signal ep10_wire : std_logic_vector(31 downto 0);-- wire in16
  --signal ep11_wire : std_logic_vector(31 downto 0);-- wire in17
  --signal ep12_wire : std_logic_vector(31 downto 0);-- wire in18
  --signal ep13_wire : std_logic_vector(31 downto 0);-- wire in19
  --signal ep14_wire : std_logic_vector(31 downto 0);-- wire in20
  --signal ep15_wire : std_logic_vector(31 downto 0);-- wire in21
  --signal ep16_wire : std_logic_vector(31 downto 0);-- wire in22
  --signal ep17_wire : std_logic_vector(31 downto 0);-- wire in23
  signal ep18_wire : std_logic_vector(31 downto 0);  -- wire in24
  signal ep19_wire : std_logic_vector(31 downto 0);  -- wire in25
  --signal ep1A_wire : std_logic_vector(31 downto 0);-- wire in26
  --signal ep1B_wire : std_logic_vector(31 downto 0);-- wire in27
  --signal ep1C_wire : std_logic_vector(31 downto 0);-- wire in28
  --signal ep1D_wire : std_logic_vector(31 downto 0);-- wire in29
  --signal ep1E_wire : std_logic_vector(31 downto 0);-- wire in30
  --signal ep1F_wire : std_logic_vector(31 downto 0);-- wire in31

  -- wires out
  --signal ep20_wire : std_logic_vector(31 downto 0); -- wire out00
  signal ep21_wire : std_logic_vector(31 downto 0);  -- wire out01
  --signal ep22_wire : std_logic_vector(31 downto 0);  -- wire out02
  signal ep23_wire : std_logic_vector(31 downto 0);  -- wire out03
  signal ep24_wire : std_logic_vector(31 downto 0);  -- wire out04
  --signal ep25_wire : std_logic_vector(31 downto 0);  -- wire out05
  signal ep26_wire : std_logic_vector(31 downto 0);  -- wire out06
  --signal ep27_wire : std_logic_vector(31 downto 0);  -- wire out07
  --signal ep28_wire : std_logic_vector(31 downto 0);  -- wire out08
  --signal ep29_wire : std_logic_vector(31 downto 0);  -- wire out09
  --signal ep2A_wire : std_logic_vector(31 downto 0); -- wire out10
  --signal ep2B_wire : std_logic_vector(31 downto 0); -- wire out11
  --signal ep2C_wire : std_logic_vector(31 downto 0); -- wire out12
  --signal ep2D_wire : std_logic_vector(31 downto 0); -- wire out13
  --signal ep2E_wire : std_logic_vector(31 downto 0); -- wire out14
  --signal ep2F_wire : std_logic_vector(31 downto 0); -- wire out15
  --signal ep30_wire : std_logic_vector(31 downto 0); -- wire out16
  --signal ep31_wire : std_logic_vector(31 downto 0); -- wire out17
  --signal ep32_wire : std_logic_vector(31 downto 0); -- wire out18
  --signal ep33_wire : std_logic_vector(31 downto 0); -- wire out19
  --signal ep34_wire : std_logic_vector(31 downto 0); -- wire out20
  --signal ep35_wire : std_logic_vector(31 downto 0); -- wire out21
  --signal ep36_wire : std_logic_vector(31 downto 0); -- wire out22
  --signal ep37_wire : std_logic_vector(31 downto 0); -- wire out23
  signal ep38_wire : std_logic_vector(31 downto 0);  -- wire out24
  signal ep39_wire : std_logic_vector(31 downto 0);  -- wire out25
  signal ep3A_wire : std_logic_vector(31 downto 0);  -- wire out26
  signal ep3B_wire : std_logic_vector(31 downto 0);  -- wire out27
  --signal ep3C_wire : std_logic_vector(31 downto 0); -- wire out28
  signal ep3D_wire : std_logic_vector(31 downto 0);  -- wire out29
  signal ep3E_wire : std_logic_vector(31 downto 0);  -- wire out30
  signal ep3F_wire : std_logic_vector(31 downto 0);  -- wire out31

  -- pipe in
  -- pipe in valid
  signal ep80_pipe_valid : std_logic;
  -- pipe in data
  signal ep80_pipe       : std_logic_vector(31 downto 0);

  -- pipe out
  -- pipe out read
  signal epA0_pipe_rd : std_logic;
  -- pipe out data to read
  signal epA0_pipe    : std_logic_vector(31 downto 0);

  -- pipe out read
  signal epA1_pipe_rd : std_logic;
  -- pipe out data to read
  signal epA1_pipe    : std_logic_vector(31 downto 0);

begin

  ----------------------------------------------------
  --    Opal Kelly Host
  ----------------------------------------------------
  inst_Opal_Kelly_Host : okHost
    port map(
      okUH  => i_okUH,
      okHU  => o_okHU,
      okUHU => b_okUHU,
      okAA  => b_okAA,
      okClk => okClk,  -- Clock Opal Kelly generated in the okLibrary
      okHE  => okHE,
      okEH  => okEH
      );
  ----------------------------------------------------
  --    Opal Kelly Wire OR
  ----------------------------------------------------
  inst_wireor_opak_kelly : okWireOR
    generic map(N => c_WIRE_PIPE_TRIG_NUMBER_OUT)  -- N = Number of wires + pipes used
    port map(
      okEH  => okEH,
      okEHx => okEHx
      );

  ---------------------------------------------------------------------
  -- inputs
  ---------------------------------------------------------------------
  -- to wire_out: main
  ep21_wire <= i_usb_wireout_science_wr_data_count;
  ep23_wire <= i_usb_wireout_science_stamp_lsb;
  ep24_wire <= i_usb_wireout_tc_hk_conf;
  ep26_wire <= i_usb_wireout_hk_rd_data_count;


  -- to wire_out: debug
  ep38_wire <= i_usb_wireout_debug_ctrl;
  ep39_wire <= i_usb_wireout_sel_errors;
  ep3A_wire <= i_usb_wireout_errors;
  ep3B_wire <= i_usb_wireout_status;

  ep3D_wire <= i_usb_wireout_hardware_id;
  ep3E_wire <= i_usb_wireout_firmware_name;
  ep3F_wire <= i_usb_wireout_firmware_id;

  -- from/to pipe out
  o_usb_pipeout_science_rd_data_valid <= epA0_pipe_rd;
  epA0_pipe                           <= i_usb_pipeout_science_rd_data;

  -- from/to pipeout
  o_usb_pipeout_rd_hk_valid <= epA1_pipe_rd;
  epA1_pipe                 <= i_usb_pipeout_rd_hk;

  ----------------------------------------------------
  --    Opal Kelly Wire in
  ----------------------------------------------------
  inst_okwirein_ep00 : okWireIn
    port map(
      okHE       => okHE,
      ep_addr    => x"00",              -- Endpoint address
      ep_dataout => ep00_wire           -- Endpoint data in 32 bits
      );

  inst_okwirein_ep01 : okWireIn
    port map(
      okHE       => okHE,
      ep_addr    => x"01",              -- Endpoint address
      ep_dataout => ep01_wire           -- Endpoint data in 32 bits
      );

  inst_okwirein_ep02 : okWireIn
    port map(
      okHE       => okHE,
      ep_addr    => x"02",              -- Endpoint address
      ep_dataout => ep02_wire           -- Endpoint data in 32 bits
      );




  inst_okwirein_ep18 : okWireIn
    port map(
      okHE       => okHE,
      ep_addr    => x"18",              -- Endpoint address
      ep_dataout => ep18_wire           -- Endpoint data in 32 bits
      );

  inst_okwirein_ep19 : okWireIn
    port map(
      okHE       => okHE,
      ep_addr    => x"19",              -- Endpoint address
      ep_dataout => ep19_wire           -- Endpoint data in 32 bits
      );


  ----------------------------------------------------
  --    Opal Kelly Wire out
  ----------------------------------------------------
  gen_array : for i in 0 to c_WIRE_PIPE_TRIG_NUMBER_OUT - 1 generate
    okEHx(65*(i+1)-1 downto i*65) <= okEHx_array(i);
  end generate gen_array;

  inst_okwireout_ep21 : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(0),
      ep_addr   => x"21",               -- Endpoint address
      ep_datain => ep21_wire            -- Endpoint data out 32 bits
      );


  inst_okwireout_ep23 : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(1),
      ep_addr   => x"23",               -- Endpoint address
      ep_datain => ep23_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep24 : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(2),
      ep_addr   => x"24",               -- Endpoint address
      ep_datain => ep24_wire            -- Endpoint data out 32 bits
      );


  inst_okwireout_ep26 : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(3),
      ep_addr   => x"26",               -- Endpoint address
      ep_datain => ep26_wire            -- Endpoint data out 32 bits
      );


  inst_okwireout_ep38 : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(4),
      ep_addr   => x"38",               -- Endpoint address
      ep_datain => ep38_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep39 : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(5),
      ep_addr   => x"39",               -- Endpoint address
      ep_datain => ep39_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep3A : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(6),
      ep_addr   => x"3A",               -- Endpoint address
      ep_datain => ep3A_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep3B : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(7),
      ep_addr   => x"3B",               -- Endpoint address
      ep_datain => ep3B_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep3D : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(8),
      ep_addr   => x"3D",               -- Endpoint address
      ep_datain => ep3D_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep3E : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(9),
      ep_addr   => x"3E",               -- Endpoint address
      ep_datain => ep3E_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep3F : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(10),
      ep_addr   => x"3F",               -- Endpoint address
      ep_datain => ep3F_wire            -- Endpoint data out 32 bits
      );



  ----------------------------------------------------
  --    Opal Kelly Pipe in
  ----------------------------------------------------
  inst_okpipein_ep80 : okPipeIn
    port map(
      okHE       => okHE,
      okEH       => okEHx_array(11),
      ep_addr    => x"80",
      ep_write   => ep80_pipe_valid,
      ep_dataout => ep80_pipe
      );

  ----------------------------------------------------
  --    Opal Kelly Pipe out
  ----------------------------------------------------
  inst_okpipeout_epA0 : okPipeOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(12),
      ep_addr   => x"A0",
      ep_read   => epA0_pipe_rd,
      ep_datain => epA0_pipe
      );

  inst_okpipeout_epA1 : okPipeOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(13),
      ep_addr   => x"A1",
      ep_read   => epA1_pipe_rd,
      ep_datain => epA1_pipe
      );

  ---------------------------------------------------------------------
  -- output
  ---------------------------------------------------------------------
  -- from okhost
  o_usb_clk             <= okClk;
  -- from pipe in
  o_usb_pipein_tc_valid <= ep80_pipe_valid;
  o_usb_pipein_tc       <= ep80_pipe;

  -- from wire in
  o_usb_wirein_ctrl       <= ep00_wire;
  o_usb_wirein_tc_hk_conf <= ep01_wire;
  o_usb_wirein_icu_conf   <= ep02_wire;

  o_usb_wirein_debug_ctrl <= ep18_wire;
  o_usb_wirein_sel_errors <= ep19_wire;

end architecture RTL;
