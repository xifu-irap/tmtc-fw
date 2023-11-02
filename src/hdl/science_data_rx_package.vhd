-- -------------------------------------------------------------------------------------------------------------
--                            Copyright (C) 2023-2030 Ken-ji de la ROSA, IRAP Toulouse.
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
--!   @file                   science_data_rx_package.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--!   @details
--
--             science constant definitions.
--
-- -------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.all;

package science_data_rx_package is
  -- define the number of science link
  constant pkg_LINK_NUMBER : integer := 2;
  -- define the total number of science column
  constant pkg_COL_NUMBER  : integer := pkg_LINK_NUMBER*2;
  -- define the total number of science line
  constant pkg_LINE_NUMBER : integer := pkg_COL_NUMBER*2;

  -- define the type of array of 16 bits
  type t_ARRAY16bits is array (natural range <>) of std_logic_vector(15 downto 0);
  -- define the type of array of 8 bits
  type t_ARRAY8bits is array (pkg_LINE_NUMBER-1 downto 0) of std_logic_vector(7 downto 0);
  -- define the type of array of 3 bits
  type t_ARRAY3bits is array (pkg_LINE_NUMBER-1 downto 0) of std_logic_vector(2 downto 0);
  -- define the type of array of 8 bits (for science ctrl)
  type t_ARRAY8bits_ctrl is array ((pkg_COL_NUMBER/2)-1 downto 0) of std_logic_vector(7 downto 0);
  -- define the type of array of 96 bits
  type t_ARRAY96bits is array (natural range <>) of std_logic_vector(95 downto 0);
  -- define the type of array of 128 bits
  type t_ARRAY128bits is array (natural range <>) of std_logic_vector(127 downto 0);

end science_data_rx_package;
