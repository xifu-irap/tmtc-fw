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
--!   @file                   pkg_func_math.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--!   @details
--
--             Utilitary functions
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package pkg_func_math is

  function log2_ceil (X : in integer) return integer;  --! return logarithm base 2 of X  (ceil integer)
  function div_ceil (X  : in integer; Y : in integer) return integer;  --! returns X/Y (ceil integer)
  function div_floor (X : in integer; Y : in integer) return integer;  --! returns X/Y (floor integer)
  function div_round (X : in integer; Y : in integer) return integer;  --! returns X/Y (round integer)

end pkg_func_math;

package body pkg_func_math is

  -- ------------------------------------------------------------------------------------------------------
  --! return logarithm base 2 of X  (ceil integer)
  -- ------------------------------------------------------------------------------------------------------
  function log2_ceil (X : in integer) return integer is
  begin
    return integer(ceil(log2(real(X))));
  end function;

  -- ------------------------------------------------------------------------------------------------------
  --! returns X/Y (ceil integer)
  -- ------------------------------------------------------------------------------------------------------
  function div_ceil (X : in integer; Y : in integer) return integer is
  begin
    return integer(ceil(real(X)/real(Y)));
  end function;

  -- ------------------------------------------------------------------------------------------------------
  --! returns X/Y (floor integer)
  -- ------------------------------------------------------------------------------------------------------
  function div_floor (X : in integer; Y : in integer) return integer is
  begin
    return integer(floor(real(X)/real(Y)));
  end function;

  -- ------------------------------------------------------------------------------------------------------
  --! returns X/Y (round integer)
  -- ------------------------------------------------------------------------------------------------------
  function div_round (X : in integer; Y : in integer) return integer is
  begin
    return integer(round(real(X)/real(Y)));
  end function;

end pkg_func_math;
