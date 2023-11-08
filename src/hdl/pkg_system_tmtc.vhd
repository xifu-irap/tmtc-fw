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
--    @file                   pkg_system_tmtc.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This package defines all constants associated to the tmtc function and its sub-functions (debugging)
--
-- -------------------------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

package pkg_system_tmtc is

  ---------------------------------------------------------------------
  -- DDR OUPUT signal characterisitics
  ---------------------------------------------------------------------
  constant pkg_BANK_WIDTH     : integer := 3;  -- --// # of memory Bank Address bits.
  constant pkg_CK_WIDTH       : integer := 1;
  constant pkg_CS_WIDTH       : integer := 1;
  constant pkg_nCS_PER_RANK   : integer := 1;
  constant pkg_CKE_WIDTH      : integer := 1;
  constant pkg_DM_WIDTH       : integer := 2;
  constant pkg_DQ_WIDTH       : integer := 16;
  constant pkg_DQS_WIDTH      : integer := 2;
--constant ODT_WIDTH             :      integer := 1;
  constant pkg_ROW_WIDTH      : integer := 15;
  constant pkg_ADDR_WIDTH     : integer := 29;
  --constant pkg_nCK_PER_CLK    : integer := 4;
--constant PAYLOAD_WIDTH         :      integer := 16;
  constant pkg_APP_DATA_WIDTH : integer := 128;  -- 2 * nCK_PER_CLK * PAYLOAD_WIDTH;
  constant pkg_APP_MASK_WIDTH : integer := 16;   -- APP_DATA_WIDTH / 8;

--OK RamTest Parameters
--constant BLOCK_SIZE   :       integer := 128;
--constant FIFO_SIZE    :       integer := 1024;

  ---------------------------------------------------------------------
  -- From DEMUX: science signal characterisitics
  ---------------------------------------------------------------------
  -- user-defined: Number of links
  constant pkg_SC_LINK_NUMBER        : integer := 2;
  -- user-defined: Number of column by links
  constant pkg_SC_COL_NUMBER_BY_LINK : integer := pkg_SC_LINK_NUMBER*2;
  -- user-defined: Number of line by column
  constant pkg_SC_LIGN_NUMBER_BY_COL : integer := pkg_SC_COL_NUMBER_BY_LINK*2;


  ---------------------------------------------------------------------
  -- IO
  ---------------------------------------------------------------------
  -- hardcoded : Number of delay clock periods for miso signal between the pads side -> user side
  constant pkg_IO_SPI_MISO_DELAY : positive := 1;
  -- hardcoded : Number of delay clock periods for mosi signal between the user side -> pads side
  constant pkg_IO_SPI_MOSI_DELAY : positive := 1;

  -- hardcoded: Number of delay clock periods for science_data and science_ctrl signals between the pads side -> user side
  constant pkg_IO_SCIENCE_DELAY : positive := 2;


  ---------------------------------------------------------------------
  -- TMTC/regdecode
  ---------------------------------------------------------------------
  -- user-defined : usb_clock frequency
  constant pkg_USB_SYSTEM_FREQUENCY_HZ : positive := 100_800_000;

  ---------------------------------------------------------------------
  -- TMTC/spi_top/spi_device_select
  ---------------------------------------------------------------------
  -- hardcoded : Number of clock periods for mosi signal (spi_master) between the spi devices and the module output
  constant pkg_SPI_DEVICE_SELECT_MOSI_DELAY : positive := 1;

  ---------------------------------------------------------------------
  -- TMTC/spi_top/spi_master
  ---------------------------------------------------------------------
  -- user-defined : SPI clock polarity
  constant pkg_SPI_CPOL                 : std_logic := '0';
  -- user-defined : SPI clock phase
  constant pkg_SPI_CPHA                 : std_logic := '0';
  -- auto-computed : input clock frequency of the module (expressed in Hz). (possible values: ]2*g_SPI_FREQUENCY_MAX_HZ: max_integer_value])
  constant pkg_SPI_SYSTEM_FREQUENCY_HZ  : positive  := pkg_USB_SYSTEM_FREQUENCY_HZ;
  -- user-defined : spi output clock frequency to generate (expressed in Hz)
  constant pkg_SPI_SPI_FREQUENCY_MAX_HZ : positive  := 4_000_000;  -- 4 MHz max
  -- user-defined : Number of clock period for mosi signal between the state machine output to the output ports (spi_master)
  -- (possible values [0;max_integer_value[)
  constant pkg_SPI_MOSI_DELAY           : natural   := 0;
  -- auto-computed : Number of clock period for miso signal by considering the FPGA loopback delay
  -- (the external device delay is not taken into account): FSM (spi_master) -> IO (out) -> IO (IN). (possible values [0;max_integer_value[)
  constant pkg_SPI_MISO_DELAY           : natural   := pkg_SPI_MOSI_DELAY +
                                           pkg_SPI_DEVICE_SELECT_MOSI_DELAY +
                                           pkg_IO_SPI_MOSI_DELAY +
                                           pkg_IO_SPI_MISO_DELAY;

  ---------------------------------------------------------------------
  -- TMTC/spi_top/spi_master
  ---------------------------------------------------------------------
  -- hardcoded : delay of the science_rx_deserializer
  constant pkg_SC_RX_DESERIALIZER: integer := 1;



end pkg_system_tmtc;

