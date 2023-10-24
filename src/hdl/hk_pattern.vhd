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
--!   @file                   hk_pattern.vhd
--    reference design        Bernard Bertrand (IRAP Toulouse)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details
--
--             Build the HK status register (number of words to read)
--
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity hk_pattern is
  port(

    okClk : in std_logic;
    reset : in std_logic;

    rd_data_count_hk : in std_logic_vector(9 downto 0);

    ep26wire : out std_logic_vector(31 downto 0)

    );
end entity;

architecture RTL of hk_pattern is

begin

  p_fsm_hk : process(reset, okClk)
  begin
    if reset = '1' then
      ep26wire <= x"00000000";
    else

      if okClk = '1' and okClk' event then

--  truncation LSB pour obtenir un multiple de 4 mots de 32 bits, donc des multiples de 16 octets,
--  le tout remultiplier par 4 pour obtenir le bon nombre de mot de 32 bit a lire (le gse remultiplie par 4 pour obtenir le nombre d'octet a lire).
        ep26wire <= x"0000"&(rd_data_count_hk(9 downto 2) * x"04");
      end if;
    end if;
  end process p_fsm_hk;


end RTL;
