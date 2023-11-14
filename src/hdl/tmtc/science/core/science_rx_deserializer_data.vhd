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
--    @file                   science_rx_deserializer_data.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This module deserializes the input data
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg_utils;

entity science_rx_deserializer_data is
  generic (
    -- define the number of bits by links in order to build word
    g_DATA_WIDTH_BY_LINK : integer := 8
    );
  port (

    -- input clock
    i_clk : in std_logic;
    --  input reset
    i_rst : in std_logic;

    ---------------------------------------------------------------------
    -- input
    ---------------------------------------------------------------------
    -- science data valid
    i_science_data_valid : in std_logic;
    -- science data (serialized)
    i_science_data       : in std_logic;

    ---------------------------------------------------------------------
    -- output
    ---------------------------------------------------------------------
    -- valid deserialized word
    o_data_valid : out std_logic;
    -- deserialized data words
    o_data       : out std_logic_vector(g_DATA_WIDTH_BY_LINK - 1 downto 0)

    );
end entity science_rx_deserializer_data;

architecture RTL of science_rx_deserializer_data is


  -- data valid (registered)
  signal data_valid_r1 : std_logic;
  -- deserialized input data bit
  signal data_vec_r1   : std_logic_vector(o_data'range);


begin

-- deserialized the input data bit and delayed the input data valid
  p_deserialize_data : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      data_valid_r1 <= i_science_data_valid;
      if i_science_data_valid = '1' then
        data_vec_r1 <= data_vec_r1(data_vec_r1'high - 1 downto 0) & i_science_data;
      end if;
    end if;
  end process p_deserialize_data;

---------------------------------------------------------------------
-- output
---------------------------------------------------------------------
  o_data_valid <= data_valid_r1;
  o_data       <= data_vec_r1;

end architecture RTL;
