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

  constant LinkNumber : integer := 2;
  constant ColNumber  : integer := LinkNumber*2;
  constant LignNumber : integer := ColNumber*2;


  type t_ARRAY16bits is array (natural range <>) of std_logic_vector(15 downto 0);
  type t_ARRAY8bits is array (LignNumber-1 downto 0) of std_logic_vector(7 downto 0);
  type t_ARRAY3bits is array (LignNumber-1 downto 0) of std_logic_vector(2 downto 0);
  type t_ARRAY8bits_ctrl is array ((ColNumber/2)-1 downto 0) of std_logic_vector(7 downto 0);
  type t_ARRAY96bits is array (natural range <>) of std_logic_vector(95 downto 0);
  type t_ARRAY128bits is array (natural range <>) of std_logic_vector(127 downto 0);

end science_data_rx_package;
