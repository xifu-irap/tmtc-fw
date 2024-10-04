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
  -- system_tmtc_top
  --   DDR OUPUT signal characterisitics
  --   Note:
  --     . The following constants must match the ddr3_256_16 Xilinx IP configuration.
  ---------------------------------------------------------------------
  -- ddr3 bank address width
  constant pkg_BANK_WIDTH     : integer := 3;
  -- ddr3 diffential clock width
  constant pkg_CK_WIDTH       : integer := 1;
  -- ddr3 chip select width (for each RANK)
  constant pkg_CS_WIDTH       : integer := 1;
  -- ddr3 number of Chip Select by RANK
  constant pkg_nCS_PER_RANK   : integer := 1;
  -- ddr3 clock enable width
  constant pkg_CKE_WIDTH      : integer := 1;
  -- ddr3 Data Mask Width
  constant pkg_DM_WIDTH       : integer := 2;
  -- ddr3 Data Bus Width
  constant pkg_DQ_WIDTH       : integer := 16;
  -- ddr3 Differential Data Strobe width
  constant pkg_DQS_WIDTH      : integer := 2;
  -- ddr3 address width
  constant pkg_ROW_WIDTH      : integer := 15;


  -- app address width
  constant pkg_ADDR_WIDTH     : integer := 29;
  -- app data width (data from read command)
  constant pkg_APP_DATA_WIDTH : integer := 128;
  -- app mask width (data for write commands)
  constant pkg_APP_MASK_WIDTH : integer := 16;

  -- From DEMUX: science signal
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

  -- IO SPI
  ---------------------------------------------------------------------
  -- user-defined : Input Delay. Number of delay clock periods for miso signal
  constant pkg_IO_SPI_MISO_DELAY : positive := 1; -- must be >= 0
  -- user-defined: Input resynchronization stage. Number of resync stage
  constant pkg_IO_SPI_MISO_RESYNC_DELAY : positive := 2; -- must be >= 2
  -- auto-computed: Number of delay clock periods for miso signal between the pads side -> user side
  constant pkg_IO_SPI_MISO_LATENCY : positive := pkg_IO_SPI_MISO_DELAY + pkg_IO_SPI_MISO_RESYNC_DELAY;
  -- user-defined : Number of delay clock periods for mosi signal between the user side -> pads side
  constant pkg_IO_SPI_MOSI_DELAY : positive := 1; -- must be >= 1

  -- user-defined: input Delay. Number of delay clock periods for science_data and science_ctrl signals between the pads side -> user side
  constant pkg_IO_SCIENCE_DELAY : positive := 2;
  -- user-defined: FIFO depth (expressed in words)
  constant pkg_IO_SCIENCE_FIFO_DEPTH : positive := 16; -- must be >= 16 and a power of 2


  ---------------------------------------------------------------------
  -- TMTC
  ---------------------------------------------------------------------
  -- tc_hk_top/endianess_change_by_generic
  ---------------------------------------------------------------------
  constant pkg_TC_HK_TOP_ENDIANNESS_DELAY : integer := 0; -- must be >= 0

  -- tc_hk_top/tc_hk_spi_device_select
  ---------------------------------------------------------------------
  -- hardcoded : latency of the p_select_spi_link process
  constant pkg_TC_HK_SPI_DEVICE_SELECT_MOSI_DELAY : positive := 1;

  -- user-defined: TC FIFO depth
  constant pkg_TC_HK_SPI_DEVICE_SELECT_FIFO_DEPTH : integer := 256; -- must be >= 16 (and a power of 2)

  ---------------------------------------------------------------------
  -- TMTC/tc_hk_top/spi_master
  ---------------------------------------------------------------------
  -- user-defined : SPI clock polarity
  constant pkg_SPI_CPOL                 : std_logic := '0';
  -- user-defined : SPI clock phase
  constant pkg_SPI_CPHA                 : std_logic := '0';

  -- SPI: Data bus size
  constant pkg_SPI_SER_WD_S : integer   := 32;
  -- SPI: Number of clock period for elaborating SPI Serial Clock low level
  constant pkg_SPI_SCLK_L   : integer   := 16*4;
  -- SPI: Number of clock period for elaborating SPI Serial Clock high level
  constant pkg_SPI_SCLK_H   : integer   := 10*4;
  -- SPI: Number of clock period between two SPI communication. Should be >2
  constant pkg_SPI_PAUSE    : positive  := 3*4;

  ---------------------------------------------------------------------
  -- TMTC/science
  ---------------------------------------------------------------------

  -- science_rx_deserializer
  ---------------------------------------------------------------------
  -- hardcoded : delay of the science_rx_deserializer (FSM)
  constant pkg_SC_RX_DESERIALIZER_FSM: integer := 1;
  -- hardcoded : delay of the science_rx_deserializer (output stage)
  constant pkg_SC_RX_DESERIALIZER_OUT_DELAY: integer := 1;
  -- auto-computed : delay of the science_rx_deserializer
  constant pkg_SC_RX_DESERIALIZER_LATENCY: integer := pkg_SC_RX_DESERIALIZER_FSM + pkg_SC_RX_DESERIALIZER_OUT_DELAY;
  -- hardcoded : delay of the science_rx_deserializer_data (must be equal to pkg_SC_RX_DESERIALIZER_FSM)
  constant pkg_SC_RX_DESERIALIZER_DATA: integer := 1;

  -- science_rx_frame
  ---------------------------------------------------------------------
  -- hardcoded : delay of the science_rx_frame
  constant pkg_SC_RX_FRAME: integer := 1;

  -- user-defined: Input FIFO depth of the science_ddr3 (expressed in word)
  --   the value should be enough large to absorb the DDR3 latency
  constant pkg_SC_DDR3_FIFO_DEPTH_IN : integer := 128; -- must be >= 16 (and a power of 2)
  -- user-defined: Output FIFO depth of the science_ddr3: 128bits -> 32 bits
  constant pkg_SC_DDR3_FIFO_DEPTH_OUT : integer := 256; -- must be >= 16 (and a power of 2)



end pkg_system_tmtc;

