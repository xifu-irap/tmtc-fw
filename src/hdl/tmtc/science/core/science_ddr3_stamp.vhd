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
--    @file                   science_ddr3_stamp.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--     @details
--
--    This module compute the DDR3 stamp value.
--
--    Note:
--      . the stamp value is the delta count between the ddr write data count and ddr read data count.
--
-- -------------------------------------------------------------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.VComponents.all;

entity science_ddr3_stamp is
  port(
    --  clock
    i_clk   : in std_logic;

    ---------------------------------------------------------------------
    -- input
    ---------------------------------------------------------------------
    -- data ddr write count
    i_buffer_new_cmd_byte_addr_wr : in std_logic_vector(54 downto 0);
    -- data ddr read count
    i_buffer_new_cmd_byte_addr_rd : in std_logic_vector(54 downto 0);

    ---------------------------------------------------------------------
    -- output
    ---------------------------------------------------------------------
    -- sub result
    o_subtraction_addr_wr_addr_rd : out std_logic_vector(31 downto 0)

    );
end entity;

architecture RTL of science_ddr3_stamp is
-- step1
-- delayed i_buffer_new_cmd_byte_addr_wr
signal a_r1 : unsigned(i_buffer_new_cmd_byte_addr_wr'range);
-- delayed i_buffer_new_cmd_byte_addr_rd
signal b_r1 : unsigned(i_buffer_new_cmd_byte_addr_rd'range);

-- step2: compute s_r2 = a_r1 - b_r1
signal s_r2 : unsigned(i_buffer_new_cmd_byte_addr_wr'range);

-- truncated value
signal s_trunc_tmp3 : std_logic_vector(o_subtraction_addr_wr_addr_rd'range);

begin

 -- compute the delta count between the ddr write data count and the ddr read data count
  p_compute_delta_count: process (i_clk)
  begin
      if rising_edge (i_clk) then
      -- step1
      a_r1 <= unsigned(i_buffer_new_cmd_byte_addr_wr);
      b_r1 <= unsigned(i_buffer_new_cmd_byte_addr_rd);

      -- step2: S = A - B
      s_r2 <= a_r1 - b_r1;
      end if;
  end process p_compute_delta_count;

-- truncated the value
s_trunc_tmp3 <= std_logic_vector(s_r2(s_trunc_tmp3'range));

---------------------------------------------------------------------
-- output
---------------------------------------------------------------------
o_subtraction_addr_wr_addr_rd <= s_trunc_tmp3;

end RTL;
