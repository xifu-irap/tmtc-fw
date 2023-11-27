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
--    @file                   io_top.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This module manages the IOs
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.pkg_system_tmtc.all;

entity io_top is
  generic (
    g_SPI_CS_N_WIDTH : integer := 2
    );
  port (

    ---------------------------------------------------------------------
    -- from DEMUX: science interface @i_science_clk
    ---------------------------------------------------------------------
    -- differential_p science clock
    i_science_clk_p : in std_logic;
    -- differential_n science clock
    i_science_clk_n : in std_logic;

    -- Differential_p science ctrl
    i_science_ctrl_p : in std_logic;
    -- Differential_n science ctrl
    i_science_ctrl_n : in std_logic;

    -- Differential_p science data
    i_science_data_p : in std_logic_vector(pkg_SC_LIGN_NUMBER_BY_COL - 1 downto 0);
    -- Differential_n science data
    i_science_data_n : in std_logic_vector(pkg_SC_LIGN_NUMBER_BY_COL - 1 downto 0);

    ---------------------------------------------------------------------
    -- to user: science interface @i_sys_clk
    ---------------------------------------------------------------------
    -- output clock
    i_sys_clk            : in  std_logic;
    -- output science data valid
    o_science_data_valid : out std_logic;
    -- output science ctrl
    o_science_ctrl       : out std_logic;
    -- output science data
    o_science_data       : out std_logic_vector(pkg_SC_LIGN_NUMBER_BY_COL - 1 downto 0);

    ---------------------------------------------------------------------
    -- from/to FPGA io: spi @i_sys_spi_clk
    ---------------------------------------------------------------------
    -- system spi clock
    i_sys_spi_clk : in  std_logic;
    -- SPI --
    -- Shared SPI MISO
    i_spi_miso    : in  std_logic;
    -- Shared SPI MOSI
    o_spi_mosi    : out std_logic;
    -- Shared SPI clock line
    o_spi_sclk    : out std_logic;
     -- SPI chip select
    o_spi_cs_n    : out std_logic_vector(g_SPI_CS_N_WIDTH - 1 downto 0);

    ---------------------------------------------------------------------
    -- to user: spi interface @i_sys_spi_clk
    ---------------------------------------------------------------------
    -- SPI --
    -- Shared SPI MISO
    o_ui_spi_miso : out std_logic;
    -- Shared SPI MOSI
    i_ui_spi_mosi : in  std_logic;
    -- Shared SPI clock line
    i_ui_spi_sclk : in  std_logic;
    -- SPI chip select
    i_ui_spi_cs_n : in  std_logic_vector(g_SPI_CS_N_WIDTH - 1 downto 0)

    );
end entity io_top;

architecture RTL of io_top is



begin

  ---------------------------------------------------------------------
  -- science
  ---------------------------------------------------------------------
  inst_io_science : entity work.io_science
     generic map(
      g_FIFO_DEPTH_OUT => pkg_IO_SCIENCE_FIFO_DEPTH
      )
    port map(
      ---------------------------------------------------------------------
      -- from DEMUX: science interface @i_science_clk
      ---------------------------------------------------------------------
      i_science_clk_p      => i_science_clk_p,
      i_science_clk_n      => i_science_clk_n,
      i_science_ctrl_p     => i_science_ctrl_p,
      i_science_ctrl_n     => i_science_ctrl_n,
      i_science_data_p     => i_science_data_p,
      i_science_data_n     => i_science_data_n,
      ---------------------------------------------------------------------
      -- to user: science interface @i_sys_clk
      ---------------------------------------------------------------------
      i_sys_clk            => i_sys_clk,
      o_science_data_valid => o_science_data_valid,
      o_science_ctrl       => o_science_ctrl,
      o_science_data       => o_science_data
      );

  ---------------------------------------------------------------------
  -- spi
  ---------------------------------------------------------------------
  inst_io_spi : entity work.io_spi
    generic map(
      g_SPI_CS_N_WIDTH => i_ui_spi_cs_n'length
      )
    port map(
      ---------------------------------------------------------------------
      -- from/to FPGA io: spi @i_sys_spi_clk
      ---------------------------------------------------------------------
      i_sys_spi_clk => i_sys_spi_clk,
      -- SPI --
      i_spi_miso    => i_spi_miso,
      o_spi_mosi    => o_spi_mosi,
      o_spi_sclk    => o_spi_sclk,
      o_spi_cs_n    => o_spi_cs_n,
      ---------------------------------------------------------------------
      -- to user: science interface @i_sys_spi_clk
      ---------------------------------------------------------------------
      -- SPI --
      o_ui_spi_miso => o_ui_spi_miso,
      i_ui_spi_mosi => i_ui_spi_mosi,
      i_ui_spi_sclk => i_ui_spi_sclk,
      i_ui_spi_cs_n => i_ui_spi_cs_n
      );


end architecture RTL;
