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
--    @file                   spi_top.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This module reset the DDR controller.
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg_utils;

entity spi_top is
  port (

    -- system clock
    i_clk         : in std_logic;
    -- reset
    i_rst         : in std_logic;
    ---------------------------------------------------------------------
    -- from the regdecode @i_clk
    ---------------------------------------------------------------------
    -- reset error flag(s)
    i_rst_status  : in std_logic;
    -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s)
    i_debug_pulse : in std_logic;

    -- command
    -- select the SPI chip
    i_spi_select  : in std_logic;
    -- spi write enable
    i_spi_wr_en   : in std_logic;
    -- spi write data
    i_spi_wr_data : in std_logic_vector(31 downto 0);

    ---------------------------------------------------------------------
    -- to regdecode
    ---------------------------------------------------------------------
    -- spi data valid (reading)
    o_spi_rd_data_valid : out std_logic;
     -- spi data (reading)
    o_spi_rd_data       : out std_logic_vector(31 downto 0);
    -- status
    o_spi_ready         : out std_logic;
    ---------------------------------------------------------------------
    -- from/to io: spi @i_clk
    ---------------------------------------------------------------------
    -- SPI --
    -- Shared SPI MISO
    i_spi_miso          : in  std_logic;
    -- Shared SPI MOSI
    o_spi_mosi          : out std_logic;
    -- Shared SPI clock line
    o_spi_sclk          : out std_logic;
    -- SPI chip select
    o_spi_cs_n          : out std_logic_vector(1 downto 0);

    ---------------------------------------------------------------------
    -- errors status
    ---------------------------------------------------------------------
    -- spi errors
    o_errors : out std_logic_vector(15 downto 0);
    -- spi status
    o_status : out std_logic_vector(7 downto 0)
    );
end entity spi_top;

architecture RTL of spi_top is

  ---------------------------------------------------------------------
  -- endianness
  ---------------------------------------------------------------------
  -- spi write command enable
  signal spi_wr_en   : std_logic;
  -- spi write data
  signal spi_wr_data : std_logic_vector(i_spi_wr_data'range);

begin

---------------------------------------------------------------------
-- endianess change
---------------------------------------------------------------------
  inst_endianess_change_by_generic : entity work.endianess_change_by_generic
    generic map(
      g_ENDIANESS_CHANGE => true,  -- False: no change, True: data byte are swapped
      g_DATA_WIDTH       => i_spi_wr_data'length,  -- width of the input data bus. The value must be a multiple of 8.
      g_OUTPUT_DELAY     => 0      --0: no delay, 1: one tap delay and so on.
      )
    port map(
      ---------------------------------------------------------------------
      -- input
      ---------------------------------------------------------------------
      i_clk        => i_clk,
      i_data_valid => i_spi_wr_en,
      i_data       => i_spi_wr_data,
      ---------------------------------------------------------------------
      -- output
      ---------------------------------------------------------------------
      o_data_valid => spi_wr_en,
      o_data       => spi_wr_data
      );



---------------------------------------------------------------------
-- SPI select
---------------------------------------------------------------------
  inst_spi_device_select : entity work.spi_device_select
    port map(
      i_clk               => i_clk,
      i_rst               => i_rst,
      i_rst_status        => i_rst_status,
      i_debug_pulse       => i_debug_pulse,
      ---------------------------------------------------------------------
      -- command
      ---------------------------------------------------------------------
      -- input
      i_spi_cmd_select    => i_spi_select,
      i_spi_cmd_valid     => spi_wr_en,    -- command valid
      i_spi_cmd_wr_data   => spi_wr_data,  -- data to write
      -- output
      o_spi_rd_data_valid => o_spi_rd_data_valid,  -- read data valid
      o_spi_rd_data       => o_spi_rd_data,  -- read data (device spi register value).
      o_spi_ready         => o_spi_ready,  -- 1: all spi links are ready,0: one of the spi link is busy
      ---------------------------------------------------------------------
      -- errors/status
      ---------------------------------------------------------------------
      o_errors            => o_errors,  -- errors
      o_status            => o_status,  -- status
      ---------------------------------------------------------------------
      -- from/to the IOs
      ---------------------------------------------------------------------
      ---------------------------------------------------------------------
      -- from/to io: spi @i_clk
      ---------------------------------------------------------------------
      -- SPI --
      i_spi_miso          => i_spi_miso,   -- Shared SPI MISO
      o_spi_mosi          => o_spi_mosi,   -- Shared SPI MOSI
      o_spi_sclk          => o_spi_sclk,   -- Shared SPI clock line
      o_spi_cs_n          => o_spi_cs_n    -- SPI chip select
      );


end architecture RTL;
