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
--!   @file                   pkg_project.vhd
--    reference design        Paul MARBEAU (IRAP Toulouse)
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--!   @details
--
--    SPI constants
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package pkg_project is

  constant pkg_SPI_CPOL     : std_logic := '0';  --! SPI: Clock polarity
  constant pkg_SPI_CPHA     : std_logic := '0';  --! SPI: Clock phase
  constant pkg_SPI_SER_WD_S : integer   := 32;  --! SPI: Data bus size
  constant pkg_SPI_SCLK_L   : integer   := 24;  --! SPI: Number of clock period for elaborating SPI Serial Clock low level
  constant pkg_SPI_SCLK_H   : integer   := 2;  --! SPI: Number of clock period for elaborating SPI Serial Clock high level
  constant pkg_SPI_PAUSE    : positive  := 3;  --! SPI: Number of clock period between two SPI communication. Should be >2

end pkg_project;
