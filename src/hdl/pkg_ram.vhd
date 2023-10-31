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
--!   @file                   Ramtest_pack.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--!   @details
--
--             MIG configuration constants.
--
-- -------------------------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

---------------------------------------------------------------
--
-- PACKAGE
--
---------------------------------------------------------------
package pkg_ram is


  constant pkg_BANK_WIDTH   : integer := 3;  -- --// # of memory Bank Address bits.
  constant pkg_CK_WIDTH     : integer := 1;
  constant pkg_CS_WIDTH     : integer := 1;
  constant pkg_nCS_PER_RANK : integer := 1;
  constant pkg_CKE_WIDTH    : integer := 1;
  constant pkg_DM_WIDTH     : integer := 2;
  constant pkg_DQ_WIDTH     : integer := 16;
  constant pkg_DQS_WIDTH    : integer := 2;

  constant pkg_ROW_WIDTH   : integer := 15;
  constant pkg_ADDR_WIDTH  : integer := 29;
  constant pkg_nCK_PER_CLK : integer := 4;

  constant pkg_APP_DATA_WIDTH : integer := 128;  -- 2 * nCK_PER_CLK * PAYLOAD_WIDTH;
  constant pkg_APP_MASK_WIDTH : integer := 16;   -- APP_DATA_WIDTH / 8;

  -- =============================================================
  function endian64(rhs : std_logic_vector(63 downto 0)) return std_logic_vector;
  function endian32(rhs : std_logic_vector(31 downto 0)) return std_logic_vector;


end pkg_ram;

package body pkg_ram is
  -- =============================================================
  -- =============================================================
  function endian64(rhs : std_logic_vector(63 downto 0)) return std_logic_vector is
    variable x : std_logic_vector(63 downto 0);
  begin
    x(63 downto 56) := rhs(39 downto 32);
    x(55 downto 48) := rhs(47 downto 40);
    x(47 downto 40) := rhs(55 downto 48);
    x(39 downto 32) := rhs(63 downto 56);

    x(31 downto 24) := rhs(7 downto 0);
    x(23 downto 16) := rhs(15 downto 8);
    x(15 downto 8)  := rhs(23 downto 16);
    x(7 downto 0)   := rhs(31 downto 24);
    return x;
  end function endian64;
  -- =============================================================
  -- =============================================================
  function endian32(rhs : std_logic_vector(31 downto 0)) return std_logic_vector is
    variable x : std_logic_vector(31 downto 0);
  begin
    x(31 downto 24) := rhs(7 downto 0);
    x(23 downto 16) := rhs(15 downto 8);
    x(15 downto 8)  := rhs(23 downto 16);
    x(7 downto 0)   := rhs(31 downto 24);
    return x;
  end function endian32;

end pkg_ram;
