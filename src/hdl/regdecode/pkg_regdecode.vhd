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
--    @file                   pkg_regdecode.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--  This package defines all constants associtated to the regdecode function and its sub-functions.
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


use work.pkg_utils;

package pkg_regdecode is

  ---------------------------------------------------------------------
  --
  ---------------------------------------------------------------------
  -- user-defined: Firmware ID Value
  constant pkg_FIRMWARE_ID_VALUE : integer := 26;  -- 0x1A

  -- user-defined: FIRMWARE name (character3)
  constant pkg_FIRMWARE_NAME_CHAR3 : character := 'T';  -- ascii character
  -- user-defined: FIRMWARE name (character2)
  constant pkg_FIRMWARE_NAME_CHAR2 : character := 'M';  -- ascii character
  -- user-defined: FIRMWARE name (character1)
  constant pkg_FIRMWARE_NAME_CHAR1 : character := 'T';  -- ascii character
  -- user-defined: FIRMWARE name (character0)
  constant pkg_FIRMWARE_NAME_CHAR0 : character := 'C';  -- ascii character

  -- auto-computed: firmware name
  constant pkg_FIRMWARE_NAME : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(character'pos(pkg_FIRMWARE_NAME_CHAR3), 8)) &
                                                                std_logic_vector(to_unsigned(character'pos(pkg_FIRMWARE_NAME_CHAR2), 8)) &
                                                                std_logic_vector(to_unsigned(character'pos(pkg_FIRMWARE_NAME_CHAR1), 8)) &
                                                                std_logic_vector(to_unsigned(character'pos(pkg_FIRMWARE_NAME_CHAR0), 8));
  -- auto-computed: firmware id
  constant pkg_FIRMWARE_ID : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(pkg_FIRMWARE_ID_VALUE, 32));


  ---------------------------------------------------------------------
  -- register field definition
  -- The following constants define the bit range of each register field.
  -- Note:
  --   .the bit range should match the bit range of the api_register doc
  --   . when the field is composed by 1 bit, only 1 XXX_IDX_H constant is defined
  --   . When the field is composed by 2 bits or more, 2 constants are defined:
  --      . XXX_IDX_H
  --      . XXX_IDX_L
  ---------------------------------------------------------------------

  -- wire in/wire out
  -----------------------------------------------------------------

  -- ctrl register
  ---------------------------------------------------------------------
  -- user-defined: ctrl rst (bit index)
  constant pkg_CTRL_RST_IDX_H : integer := 0;

  -- debug_ctrl register
  ---------------------------------------------------------------------
  -- user-defined: debug_pulse (bit index)
  constant pkg_DEBUG_CTRL_DEBUG_PULSE_IDX_H : integer := 0;
  -- user-defined: rst_status (bit index)
  constant pkg_DEBUG_CTRL_RST_STATUS_IDX_H  : integer := 1;
  -- user-defined: science_pattern_en_fifo_out
  constant pkg_DEBUG_CTRL_SC_PATTERN_EN_FIFO_OUT_IDX_H  : integer := 4;

  -- tc_hk_conf register
  ---------------------------------------------------------------------
  -- user-defined: spi_ras_select (bit index)
  constant pkg_TC_HK_CONF_SPI_RAS_SEL_IDX_H : integer := 0;

  -- error_sel register
  ---------------------------------------------------------------------
  -- user-defined: error_sel (bit index high)
  constant pkg_ERROR_SEL_IDX_H : integer := 2;
  -- user-defined: error_sel (bit index low)
  constant pkg_ERROR_SEL_IDX_L : integer := 0;
  -- auto-computed: error_sel width
  constant pkg_ERROR_SEL_WIDTH : integer := work.pkg_utils.pkg_width_from_indexes(i_idx_high => pkg_ERROR_SEL_IDX_H, i_idx_low => pkg_ERROR_SEL_IDX_L);


  -- icu conf register
  ---------------------------------------------------------------------
  -- user-defined: icu_select (bit index)
  constant pkg_ICU_CONF_SEL_IDX_H : integer := 0;

  ---------------------------------------------------------------------
  -- FIFO
  ---------------------------------------------------------------------

  -- tc_hk_conf register
  -----------------------------------------------------------------
  -- user-defined: define the fifo depth (expressed in number of words)
  constant pkg_TC_HK_CONF_FIFO_DEPTH : integer := 16;  -- must be >= 16 and a power of 2

  -- debug_ctrl register
  -----------------------------------------------------------------
  -- user-defined: define the fifo depth (expressed in number of words)
  constant pkg_DEBUG_CTRL_FIFO_DEPTH : integer := 16;  -- must be >= 16 and a power of 2

  -- science_stamp_lsb register
  -----------------------------------------------------------------
  -- user-defined: define the fifo depth (expressed in number of words)
  constant pkg_SC_STAMP_LSB_FIFO_DEPTH : integer := 16;  -- must be >= 16 and a power of 2

  -- wire loopback
  -----------------------------------------------------------------
  -- user-defined: define the number of tap delay for loopback (wire). The range is [0;max int value[
  constant pkg_WIRE_LOOPBACK_DELAY : integer := 1;

  -- tc pipe in
  -----------------------------------------------------------------
  -- user-defined: define the fifo depth (expressed in number of words)
  constant pkg_TC_FIFO_DEPTH : integer := 16;  -- must be >= 16 and a power of 2

  -- hk pipe out
  -----------------------------------------------------------------
  -- user-defined: define the fifo depth (expressed in number of words)
  constant pkg_HK_FIFO_DEPTH : integer := 256;

  -- science pipe out
  -----------------------------------------------------------------
  -- user-defined: define the fifo depth (expressed in number of words)
  constant pkg_SCIENCE_FIFO_DEPTH : integer := 131072;




end pkg_regdecode;

