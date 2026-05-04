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
--    @file                   reset_top.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This module manages reset mechanism
--    It performs the following steps:
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity reset_top is
  port (

    ---------------------------------------------------------------------
    -- from usb  @usb_clk
    ---------------------------------------------------------------------
    -- clock
    i_usb_clk : in std_logic;
    -- software reset
    i_usb_rst : in std_logic;

    ---------------------------------------------------------------------
    -- to DDR interface @i_usb_clk
    ---------------------------------------------------------------------
     -- reset the DDR controller
    o_ddr_ctrl_rst : out std_logic;
    ---------------------------------------------------------------------
    -- from DDR interface @i_sys_clk
    ---------------------------------------------------------------------
    -- ddr user side
    -- system clock
    i_sys_clk      : in  std_logic;
    -- reset
    i_sys_rst      : in  std_logic;

    ---------------------------------------------------------------------
    -- to the user @i_sys_clk
    ---------------------------------------------------------------------
    -- output reset
    o_sys_rst : out std_logic

    );
end entity reset_top;

architecture RTL of reset_top is

  ---------------------------------------------------------------------
  -- reset_ddr_controller
  ---------------------------------------------------------------------
  -- reset the DDR infrastructure
  signal ddr_ctrl_rst : std_logic;

  ---------------------------------------------------------------------
  -- user reset
  ---------------------------------------------------------------------
  -- delayed i_sys_rst
  signal sys_rst_tmp1 : std_logic;


begin

---------------------------------------------------------------------
-- generate reset for the DDR infrastructure
---------------------------------------------------------------------
  inst_reset_ddr_controller : entity work.reset_ddr_controller
    generic map(
      g_RST_DURATION => 1000  -- duration of the rst signal. the value range is [1;max integer value[
      )
    port map(
      ---------------------------------------------------------------------
      -- input
      ---------------------------------------------------------------------
      i_clk => i_usb_clk,
      i_rst => i_usb_rst,

      ---------------------------------------------------------------------
      -- output
      ---------------------------------------------------------------------
      o_rst => ddr_ctrl_rst
      );
  -- output
  o_ddr_ctrl_rst <= ddr_ctrl_rst;


---------------------------------------------------------------------
-- add an optional output delay
---------------------------------------------------------------------
  sys_rst_tmp1 <= i_sys_rst;

  gen_optional_pipe : if true generate
    -- temporary input pipe signals
    signal data_tmp0 : std_logic_vector(0 downto 0);
    -- temporary output pipe signals
    signal data_tmp1 : std_logic_vector(0 downto 0);
  begin
    data_tmp0(0) <= sys_rst_tmp1;

    inst_pipeliner_with_init_optional_sys_rst : entity work.pipeliner_with_init
      generic map(
        g_INIT       => '0',
        g_NB_PIPES   => 1,
        g_DATA_WIDTH => data_tmp0'length
        )
      port map(
        i_clk  => i_sys_clk,
        i_data => data_tmp0,
        o_data => data_tmp1
        );
    -- output
    o_sys_rst <= data_tmp1(0);

  end generate gen_optional_pipe;


end architecture RTL;
