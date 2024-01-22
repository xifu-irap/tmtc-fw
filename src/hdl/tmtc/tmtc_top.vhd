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
--    @file                   tmtc_top.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This module is the top level of the TMTC function
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.pkg_system_tmtc.all;
use work.pkg_system_tmtc_debug.all;

entity tmtc_top is
  port (

    ---------------------------------------------------------------------
    -- From DDR @i_clk
    ---------------------------------------------------------------------
    -- system clock
    i_clk : in std_logic;

    ---------------------------------------------------------------------
    -- from reset @i_clk
    ---------------------------------------------------------------------
    -- system reset
    i_rst : in std_logic;

    ---------------------------------------------------------------------
    -- Regdecode @sys_clk
    ---------------------------------------------------------------------
    -- reset error flag(s)
    i_rst_status  : in std_logic;
    -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s)
    i_debug_pulse : in std_logic;

    -- '1': Fill the science output FIFO with a pre-defined pattern, '0': fill the science output FIFO with data from the DDR
    i_science_pattern_en_fifo_out : in std_logic;


    -- HK: SPI
    ---------------------------------------------------------------------
    -- spi_select bit
    i_spi_select : in std_logic;
    -- write enable tc command
    i_tc_valid   : in std_logic;
    -- write tc data command
    i_tc         : in std_logic_vector(31 downto 0);

    -- hk read data valid
    o_hk_valid : out std_logic;
    -- hk read data
    o_hk       : out std_logic_vector(31 downto 0);

    -- to regdecode
    -- science
    ---------------------------------------------------------------------
    -- fifo prog full
    i_fifo_science_prog_full  : in  std_logic;
    -- fifo data valid (write enable)
    o_fifo_science_data_valid : out std_logic;
    -- fifo data
    o_fifo_science_data       : out std_logic_vector(31 downto 0);

    -- status
    ---------------------------------------------------------------------
    -- ddr stamp register
    o_ddr_stamp : out std_logic_vector(31 downto 0);


    ---------------------------------------------------------------------
    -- from/to DDR controller @ sys_clk
    ---------------------------------------------------------------------
    -- PHY asserts init_calib_complete when calibration is finished
    i_init_calib_complete : in std_logic;

    -- addr of the current request
    o_app_addr          : out std_logic_vector(28 downto 0);
    -- command for the current request
    o_app_cmd           : out std_logic_vector(2 downto 0);
    -- active-High strobe for the app_addr[], app_cmd[2:0], app_sz, and app_hi_pri inputs
    o_app_en            : out std_logic;
    --  data for write commands.
    o_app_wdf_data      : out std_logic_vector(127 downto 0);
    -- active-High input indicates that the current clock cycle is the last cycle of input data on app_wdf_data[].
    o_app_wdf_end       : out std_logic;
    -- active-High strobe for app_wdf_data[].
    o_app_wdf_wren      : out std_logic;
    -- data from read commands
    i_app_rd_data       : in  std_logic_vector(127 downto 0);
    -- active-High output indicates that the current clock cycle is the last cycle of output data on app_rd_data[]. This is valid only
    -- when app_rd_data_valid is active-High.
    i_app_rd_data_end   : in  std_logic;
    -- active-High output indicates that app_rd_data[] is valid.
    i_app_rd_data_valid : in  std_logic;
    -- output indicates that the UI is ready to accept commands.If the signal is deasserted when app_en is enabled, the current
    -- app_cmd and app_addr must be retried until app_rdy is asserted.
    i_app_rdy           : in  std_logic;
    -- This output indicates that the write data FIFO is ready to receive data. Write data is accepted when app_wdf_rdy = 1’b1 and app_wdf_wren = 1’b1.
    i_app_wdf_rdy       : in  std_logic;
    -- mask for app_wdf_data[].
    o_app_wdf_mask      : out std_logic_vector(15 downto 0);

    ---------------------------------------------------------------------
    -- from io: science @sys_clk
    ---------------------------------------------------------------------
    -- input science data valid
    i_science_data_valid : in std_logic;
    -- input science ctrl
    i_science_ctrl       : in std_logic;
    -- input science data
    i_science_data       : in std_logic_vector(pkg_SC_LIGN_NUMBER_BY_COL - 1 downto 0);

    ---------------------------------------------------------------------
    -- from/to io: spi @sys_clk
    ---------------------------------------------------------------------
    -- SPI --
    -- Shared SPI MISO
    i_spi_miso : in  std_logic;
    -- Shared SPI MOSI
    o_spi_mosi : out std_logic;
    -- Shared SPI clock line
    o_spi_sclk : out std_logic;
    -- SPI chip select
    o_spi_cs_n : out std_logic_vector(1 downto 0);

    ---------------------------------------------------------------------
    -- leds
    ---------------------------------------------------------------------
    -- FPGA board: status leds
    o_leds         : out std_logic_vector(3 downto 0);
    -- FMC firmware led
    o_led_fw       : out std_logic;
    -- FMC PLL lock led
    o_led_pll_lock : out std_logic;

    ---------------------------------------------------------------------
    -- debug
    ---------------------------------------------------------------------
    -- tc_hk_errors
    o_tc_hk_errors : out std_logic_vector(15 downto 0);
    -- tc_hk_status
    o_tc_hk_status : out std_logic_vector(7 downto 0);

    -- science errors1
    o_science_errors1 : out std_logic_vector(15 downto 0);
    -- science errors0
    o_science_errors0 : out std_logic_vector(15 downto 0);
    -- science status1
    o_science_status1 : out std_logic_vector(7 downto 0);
    -- science status0
    o_science_status0 : out std_logic_vector(7 downto 0)
    );
end entity tmtc_top;

architecture RTL of tmtc_top is

---------------------------------------------------------------------
-- hk management
---------------------------------------------------------------------
  -- spi errors
  signal tc_hk_errors : std_logic_vector(o_tc_hk_errors'range);
  -- spi status
  signal tc_hk_status : std_logic_vector(o_tc_hk_status'range);

  ---------------------------------------------------------------------
  -- science_top
  ---------------------------------------------------------------------
  -- science data valid
  signal science_data_valid : std_logic;
  -- science data
  signal science_data       : std_logic_vector(o_fifo_science_data'range);
  -- number of remaining bytes to read in the DDR
  signal ddr_stamp          : std_logic_vector(o_ddr_stamp'range);

  -- science errors1
  signal science_errors1 : std_logic_vector(o_science_errors1'range);
  -- science errors0
  signal science_errors0 : std_logic_vector(o_science_errors0'range);
  -- science status1
  signal science_status1 : std_logic_vector(o_science_status1'range);
  -- science status0
  signal science_status0 : std_logic_vector(o_science_status0'range);

  -- science data valid (serialized)
  signal science_data_valid_bit : std_logic;
  -- detect the last bit of the synchro word
  signal science_synchro_word   : std_logic;

begin


---------------------------------------------------------------------
-- hk management
---------------------------------------------------------------------
  inst_tc_hk_top : entity work.tc_hk_top
    generic map(
      g_DEBUG => pkg_TC_HK_TOP_DEBUG
      )
    port map(
      i_clk         => i_clk,
      i_rst         => i_rst,
      ---------------------------------------------------------------------
      -- from the regdecode @i_clk
      ---------------------------------------------------------------------
      i_rst_status  => i_rst_status,
      i_debug_pulse => i_debug_pulse,
      -- command
      i_spi_select  => i_spi_select,
      i_tc_valid    => i_tc_valid,
      i_tc          => i_tc,
      ---------------------------------------------------------------------
      -- to regdecode
      ---------------------------------------------------------------------
      o_hk_valid    => o_hk_valid,
      o_hk          => o_hk,
      -- status
      o_ready       => open,
      ---------------------------------------------------------------------
      -- from/to io: spi @i_clk
      ---------------------------------------------------------------------
      -- SPI --
      i_spi_miso    => i_spi_miso,
      o_spi_mosi    => o_spi_mosi,
      o_spi_sclk    => o_spi_sclk,
      o_spi_cs_n    => o_spi_cs_n,
      ---------------------------------------------------------------------
      -- errors status
      ---------------------------------------------------------------------
      o_errors      => tc_hk_errors,
      o_status      => tc_hk_status
      );

  o_tc_hk_errors <= tc_hk_errors;
  o_tc_hk_status <= tc_hk_status;

---------------------------------------------------------------------
-- science
---------------------------------------------------------------------
  inst_science_top : entity work.science_top
    generic map(
      g_DEBUG => pkg_SCIENCE_TOP_DEBUG
      )
    port map(
      ---------------------------------------------------------------------
      -- From DDR @sys_clk
      ---------------------------------------------------------------------
      -- clock
      i_clk => i_clk,
      ---------------------------------------------------------------------
      -- from reset @sys_clk
      ---------------------------------------------------------------------
      -- reset @i_clk
      i_rst => i_rst,

      -- reset error flag(s) @i_clk
      i_rst_status  => i_rst_status,
      -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s) @i_clk
      i_debug_pulse => i_debug_pulse,

      -- '1': Fill the output FIFO with a pre-defined pattern, '0': fill the output FIFO with data from the DDR
      i_pattern_en_fifo_out => i_science_pattern_en_fifo_out,

      ---------------------------------------------------------------------
      -- from/to DDR controller @ sys_clk
      ---------------------------------------------------------------------
      -- PHY asserts init_calib_complete when calibration is finished
      i_init_calib_complete => i_init_calib_complete,
      -- addr of the current request
      o_app_addr            => o_app_addr,
      -- command for the current request
      o_app_cmd             => o_app_cmd,
      -- active-High strobe for the app_addr[], app_cmd[2:0], app_sz, and app_hi_pri inputs
      o_app_en              => o_app_en,
      --  data for write commands.
      o_app_wdf_data        => o_app_wdf_data,
      -- active-High input indicates that the current clock cycle is the last cycle of input data on app_wdf_data[].
      o_app_wdf_end         => o_app_wdf_end,
      -- active-High strobe for app_wdf_data[].
      o_app_wdf_wren        => o_app_wdf_wren,
      -- data from read commands
      i_app_rd_data         => i_app_rd_data,
      -- active-High output indicates that the current clock cycle is the last cycle of output data on app_rd_data[]. This is valid only
      -- when app_rd_data_valid is active-High.
      i_app_rd_data_end     => i_app_rd_data_end,
      -- active-High output indicates that app_rd_data[] is valid.
      i_app_rd_data_valid   => i_app_rd_data_valid,
      -- output indicates that the UI is ready to accept commands.If the signal is deasserted when app_en is enabled, the current
      -- app_cmd and app_addr must be retried until app_rdy is asserted.
      i_app_rdy             => i_app_rdy,
      -- This output indicates that the write data FIFO is ready to receive data. Write data is accepted when app_wdf_rdy = 1’b1 and app_wdf_wren = 1’b1.
      i_app_wdf_rdy         => i_app_wdf_rdy,
      -- mask for app_wdf_data[].
      o_app_wdf_mask        => o_app_wdf_mask,
      ---------------------------------------------------------------------
      -- from io: science @sys_clk
      ---------------------------------------------------------------------
      -- input science data valid
      i_science_data_valid  => i_science_data_valid,
      -- input science ctrl (serialized)
      i_science_ctrl        => i_science_ctrl,
      -- input science data (serialized)
      i_science_data        => i_science_data,
      ---------------------------------------------------------------------
      -- To RegDecode @sys_clk
      ---------------------------------------------------------------------
      -- fifo prog full flag
      i_fifo_prog_full      => i_fifo_science_prog_full,
      -- fifo output data valid
      o_fifo_data_valid     => science_data_valid,
      -- fifo output science data
      o_fifo_data           => science_data,

      -- number of remaining bytes to read in the DDR
      o_ddr_stamp            => ddr_stamp,
      ---------------------------------------------------------------------
      -- leds @sys_clk
      ---------------------------------------------------------------------
      -- link leds
      o_science_data_valid   => science_data_valid_bit,
      o_science_synchro_word => science_synchro_word,

      ---------------------------------------------------------------------
      -- errors/status @sys_clk
      ---------------------------------------------------------------------
      -- errors1
      o_errors1 => science_errors1,
      -- errors0
      o_errors0 => science_errors0,
      -- status1
      o_status1 => science_status1,
      -- status0
      o_status0 => science_status0
      );

  o_fifo_science_data_valid <= science_data_valid;
  o_fifo_science_data       <= science_data;
  o_ddr_stamp               <= ddr_stamp;

  o_science_errors1 <= science_errors1;
  o_science_errors0 <= science_errors0;
  o_science_status1 <= science_status1;
  o_science_status0 <= science_status0;


  ---------------------------------------------------------------------
  -- science_leds
  ---------------------------------------------------------------------
  inst_leds_top : entity work.leds_top
    port map(
      ---------------------------------------------------------------------
      -- input @i_clk
      ---------------------------------------------------------------------
      -- clock
      i_clk                 => i_clk,
      -- reset  @i_clk
      i_rst                 => i_rst,
      ---------------------------------------------------------------------
      -- from DDR controller @i_clk
      ---------------------------------------------------------------------
      -- PHY asserts init_calib_complete when calibration is finished
      i_init_calib_complete => i_init_calib_complete,

      ---------------------------------------------------------------------
      -- from science @i_clk
      ---------------------------------------------------------------------
      -- data valid (serialized bit)
      i_science_data_valid => science_data_valid_bit,
      -- detect the last bit of the synchro word
      i_science_sync       => science_synchro_word,
      ---------------------------------------------------------------------
      -- output @i_clk
      ---------------------------------------------------------------------
      -- output leds
      o_leds               => o_leds,
      o_led_fw             => o_led_fw,
      o_led_pll_lock       => o_led_pll_lock
      );


end architecture RTL;
