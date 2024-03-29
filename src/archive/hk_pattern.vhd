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
--!   @file                   hk_pattern.vhd
--    reference design        Bernard Bertrand (IRAP Toulouse)
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--!   @details
--
--     Compute the number of read HK words.
--
-- -------------------------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity hk_pattern is
  port(
    -- clock
    i_okClk : in std_logic;
    -- rst
    i_rst   : in std_logic;

    -- HK read data count
    i_rd_data_count_hk : in  std_logic_vector(9 downto 0);
    -- HK read data count (expressed in 32 bits words)
    o_result           : out std_logic_vector(31 downto 0)

    );
end entity;

architecture RTL of hk_pattern is

begin

  -- compute the number of HK words of 32 bits.
  p_fsm_hk : process(i_okClk)
  begin
    if rising_edge(i_okClk) then
      if i_rst = '1' then
        o_result <= x"00000000";
      else
--  truncation LSB pour obtenir un multiple de 4 mots de 32 bits, donc des multiples de 16 octets,
--  le tout remultiplier par 4 pour obtenir le bon nombre de mot de 32 bit a lire (le gse remultiplie par 4 pour obtenir le nombre d'octet a lire).
        o_result <= x"0000" & (i_rd_data_count_hk(9 downto 2) * x"04");
      end if;
    end if;
  end process p_fsm_hk;


end RTL;
