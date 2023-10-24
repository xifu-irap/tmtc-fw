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
--!   @file                   manage_pipe_out.vhd
--    reference design        Bernard Bertrand (IRAP Toulouse)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details
--
--             Build the Science status register (number of words to read)
--
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library UNISIM;
use UNISIM.VComponents.all;

entity manage_pipe_out is
  port(
    --  global
    clk   : in std_logic;
    okClk : in std_logic;
    reset : in std_logic;

    --  fifo interface
    rd_data_count : in std_logic_vector(16 downto 0);

    --  ctrl interface
    ep20wire_three : out std_logic_vector(31 downto 0)

    );
end entity;

architecture RTL of manage_pipe_out is


begin

  p_reshape : process (okClk, reset)
  begin
    if reset = '1' then
      ep20wire_three <= (others => '0');
    else

      if rising_edge(okClk) then
        ep20wire_three <= x"0000" & '0' & (rd_data_count(16 downto 2));
      end if;
    end if;
  end process p_reshape;


end RTL;
