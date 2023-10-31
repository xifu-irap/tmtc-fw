-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            Copyright (C) 2023-2030 Ken-ji de la ROSA, IRAP Toulouse.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    email                   kenji.delarosa@alten.com
--!   @file                   ddr_stamp.vhd
--    reference design        Bernard Bertrand (IRAP Toulouse)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details
--
--            Compute the DDR stamp
--
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity ddr_stamp is
  port(

    --  global
    i_clk : in std_logic;
    i_rst : in std_logic;

    --  input
    i_buffer_new_cmd_byte_addr_wr : in std_logic_vector(54 downto 0);
    i_buffer_new_cmd_byte_addr_rd : in std_logic_vector(54 downto 0);

    --  output
    o_sub_addr_wr_addr_rd : out std_logic_vector(54 downto 0)

    );
end entity;

architecture RTL of ddr_stamp is


begin

-- ----------------------------------------------------
--
-- ----------------------------------------------------
  p_compute : process (i_clk)
  begin

    if rising_edge (i_clk) then
      if i_rst = '1' then
        o_sub_addr_wr_addr_rd <= (others => '0');
      else
        o_sub_addr_wr_addr_rd <= i_buffer_new_cmd_byte_addr_wr - i_buffer_new_cmd_byte_addr_rd;
      end if;
    end if;
  end process p_compute;

end RTL;
