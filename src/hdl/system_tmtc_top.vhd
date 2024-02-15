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
--    @file                   system_tmtc_top.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--     @details
--
--    This module is the fpga top level
--
-- -------------------------------------------------------------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg_system_tmtc_debug.all;
use work.pkg_system_tmtc.all;
use work.pkg_regdecode.all;

entity system_tmtc_top is
  port(
    --  Opal Kelly inouts --
    -- usb interface signal
    i_okUH  : in    std_logic_vector(4 downto 0);
    -- usb interface signal
    o_okHU  : out   std_logic_vector(2 downto 0);
    -- usb interface signal
    b_okUHU : inout std_logic_vector(31 downto 0);
    -- usb interface signal
    b_okAA  : inout std_logic;

    ---------------------------------------------------------------------
    -- On board
    ---------------------------------------------------------------------
    -- hardware id register (reading)
    i_hardware_id : in std_logic_vector(7 downto 0);



    ---------------------------------------------------------------------
    -- DDR input clock
    ---------------------------------------------------------------------
    -- Differential_p input DDR clock @200M
    i_sys_clk_p  : in    std_logic;
    -- Differential_n input DDR clock @200M
    i_sys_clk_n  : in    std_logic;
    ---------------------------------------------------------------------
    -- DDR interface
    ---------------------------------------------------------------------
    -- ddr3 Data Bus
    ddr3_dq      : inout std_logic_vector (pkg_DQ_WIDTH-1 downto 0);
    -- ddr3 address
    ddr3_addr    : out   std_logic_vector (pkg_ROW_WIDTH-1 downto 0);
    -- ddr3 Bank Address
    ddr3_ba      : out   std_logic_vector (pkg_BANK_WIDTH-1 downto 0);
    -- ddr3 differential_n clock
    ddr3_ck_p    : out   std_logic_vector (pkg_CK_WIDTH-1 downto 0);
    -- ddr3 differential_p clock
    ddr3_ck_n    : out   std_logic_vector (pkg_CK_WIDTH-1 downto 0);
    -- ddr3 clock enable
    ddr3_cke     : out   std_logic_vector (pkg_CKE_WIDTH-1 downto 0);
    -- ddr3 chip select
    ddr3_cs_n    : out   std_logic_vector ((pkg_CS_WIDTH*pkg_nCS_PER_RANK)-1 downto 0);
    -- ddr3 column address select
    ddr3_cas_n   : out   std_logic;
    -- ddr3 row address select
    ddr3_ras_n   : out   std_logic;
    -- ddr3 write enable
    ddr3_we_n    : out   std_logic;
    -- ddr3 On-Die Termination enable
    ddr3_odt     : out   std_logic_vector ((pkg_CS_WIDTH*pkg_nCS_PER_RANK)-1 downto 0);
    -- ddr3 Data Mask
    ddr3_dm      : out   std_logic_vector (pkg_DM_WIDTH-1 downto 0);
    -- ddr3 Differential_p Data Strobe
    ddr3_dqs_p   : inout std_logic_vector (pkg_DQS_WIDTH-1 downto 0);
    -- ddr3 Differential_n Data Strobe
    ddr3_dqs_n   : inout std_logic_vector (pkg_DQS_WIDTH-1 downto 0);
    -- ddr3 reset_n
    ddr3_reset_n : out   std_logic;

    ---------------------------------------------------------------------
    -- DEMUX: science interface
    ---------------------------------------------------------------------
    -- differential_p science clock
    i_science_clk_p : in std_logic_vector(1 downto 0);  -- bit1, not used
    -- differential_n science clock
    i_science_clk_n : in std_logic_vector(1 downto 0);  -- bit1, not used

    -- Differential_p science ctrl
    i_science_ctrl_p : in std_logic_vector(1 downto 0);  -- bit1, not used
    -- Differential_n science ctrl
    i_science_ctrl_n : in std_logic_vector(1 downto 0);  -- bit1, not used

    -- Differential_p science data
    i_science_data_p : in std_logic_vector(pkg_SC_LIGN_NUMBER_BY_COL - 1 downto 0);
    -- Differential_n science data
    i_science_data_n : in std_logic_vector(pkg_SC_LIGN_NUMBER_BY_COL - 1 downto 0);

    ---------------------------------------------------------------------
    -- DEMUX: SPI interface
    ---------------------------------------------------------------------
    -- SPI --
    -- Shared SPI MISO
    i_spi_miso : in  std_logic;
    -- Shared SPI MOSI
    o_spi_mosi : out std_logic;
    -- Shared SPI clock
    o_spi_sclk : out std_logic;
    -- SPI chip select (bit0: RAS, bit1: DEMUX)
    o_spi_cs_n : out std_logic_vector(1 downto 0);

    ---------------------------------------------------------------------
    -- ICU: Selection
    ---------------------------------------------------------------------
    -- ICU selection : 0 for main, 1 for redundant
    o_sel_main_n : out std_logic;

    ---------------------------------------------------------------------
    -- Leds
    ---------------------------------------------------------------------
    -- Opal Kelly LEDs
    o_leds : out std_logic_vector(3 downto 0);

    -- facade leds
    ---------------------------------------------------------------------
    -- loaded firwware led
    o_led_fw       : out std_logic;
    -- pll lock led
    o_led_pll_lock : out std_logic;

    -- debugging signal (spare)
    ---------------------------------------------------------------------
    -- spare for debugging
    o_debug : out std_logic_vector(3 downto 0)

    );
end entity system_tmtc_top;

architecture RTL of system_tmtc_top is

---------------------------------------------------------------------
-- regdecode
---------------------------------------------------------------------
-- usb clock
  signal usb_clk : std_logic;
  -- software reset @usb_clk
  signal usb_rst : std_logic;


  -- reset error flag(s) @sys_clk
  signal rst_status  : std_logic;
  -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s) @ sys_clk
  signal debug_pulse : std_logic;

  -- '1': Fill the output FIFO with a pre-defined pattern, '0': fill the output FIFO with data from the DDR
  signal science_pattern_en_fifo_out : std_logic;

  signal hardware_id : std_logic_vector(i_hardware_id'range);


  -- write enable spi command
  signal tc_valid : std_logic;
  -- write spi data command
  signal tc       : std_logic_vector(31 downto 0);

  -- spi read data valid
  signal hk_valid : std_logic;
  -- spi read data
  signal hk       : std_logic_vector(31 downto 0);


  -- spi_conf register value
  signal reg_tc_hk_conf : std_logic_vector(31 downto 0);
  -- icu_conf register value
  signal reg_icu_conf   : std_logic_vector(31 downto 0);
  -- debug_ctrl register value
  signal reg_debug_ctrl : std_logic_vector(31 downto 0);

  -- science_stamp_lsb register value
  signal reg_science_stamp_lsb : std_logic_vector(31 downto 0);


  -- fifo science data valid
  signal fifo_science_data_valid : std_logic;
  -- fifo science data
  signal fifo_science_data       : std_logic_vector(31 downto 0);
  -- fifo science prog full
  signal fifo_science_prog_full  : std_logic;

  -- status register: errors1
  signal reg_wire_errors1 : std_logic_vector(31 downto 0);
  -- status register: errors0
  signal reg_wire_errors0 : std_logic_vector(31 downto 0);
  -- status register: status1
  signal reg_wire_status1 : std_logic_vector(31 downto 0);
  -- status register: status0
  signal reg_wire_status0 : std_logic_vector(31 downto 0);

  -- extracted bits
  ---------------------------------------------------------------------
  -- spi_select bit
  signal spi_select : std_logic;
  -- icu_select bit
  signal icu_select : std_logic;


---------------------------------------------------------------------
-- reset_top
---------------------------------------------------------------------
  -- DDR reset for the PHY
  signal ddr_ctrl_rst : std_logic;
  -- ui DDR clock
  signal sys_clk      : std_logic;
  -- ui DDR reset (resynchronized)
  signal ui_sys_rst   : std_logic;
  -- system reset
  signal sys_rst      : std_logic;

  ---------------------------------------------------------------------
  -- tmtc_top
  ---------------------------------------------------------------------
  -- number of remaining bytes to read in the DDR
  signal ddr_stamp : std_logic_vector(31 downto 0);

  -- FPGA board: status leds
  signal leds         : std_logic_vector(o_leds'range);
  -- FMC firmware led
  signal led_fw       : std_logic;
  -- FMC PLL lock led
  signal led_pll_lock : std_logic;

  -- tc_hk_errors
  signal tc_hk_errors : std_logic_vector(15 downto 0);
  -- tc_hk_status
  signal tc_hk_status : std_logic_vector(7 downto 0);

  -- science errors1
  signal science_errors1 : std_logic_vector(15 downto 0);
  -- science errors0
  signal science_errors0 : std_logic_vector(15 downto 0);
  -- science status1
  signal science_status1 : std_logic_vector(7 downto 0);
  -- science status0
  signal science_status0 : std_logic_vector(7 downto 0);


  ---------------------------------------------------------------------
  -- DDR3 controller
  ---------------------------------------------------------------------
  -- PHY asserts init_calib_complete when calibration is finished
  signal init_calib_complete : std_logic;
  -- addr of the current request
  signal app_addr            : std_logic_vector (pkg_ADDR_WIDTH-1 downto 0);
  -- command for the current request
  signal app_cmd             : std_logic_vector (2 downto 0);
  -- active-High strobe for the app_addr[], app_cmd[2:0], app_sz, and app_hi_pri inputs
  signal app_en              : std_logic;
  --  data for write commands.
  signal app_wdf_data        : std_logic_vector (pkg_APP_DATA_WIDTH-1 downto 0);
  -- active-High input indicates that the current clock cycle is the last cycle of input data on app_wdf_data[].
  signal app_wdf_end         : std_logic;
  -- active-High strobe for app_wdf_data[].
  signal app_wdf_wren        : std_logic;
  -- data from read commands
  signal app_rd_data         : std_logic_vector (pkg_APP_DATA_WIDTH-1 downto 0);
  -- active-High output indicates that the current clock cycle is the last cycle of output data on app_rd_data[]. This is valid only
  -- when app_rd_data_valid is active-High.
  signal app_rd_data_end     : std_logic;
  -- active-High output indicates that app_rd_data[] is valid.
  signal app_rd_data_valid   : std_logic;
  -- output indicates that the UI is ready to accept commands.If the signal is deasserted when app_en is enabled, the current
  -- app_cmd and app_addr must be retried until app_rdy is asserted.
  signal app_rdy             : std_logic;
  -- This output indicates that the write data FIFO is ready to receive data. Write data is accepted when app_wdf_rdy = 1’b1 and app_wdf_wren = 1’b1.
  signal app_wdf_rdy         : std_logic;
  -- mask for app_wdf_data[].
  signal app_wdf_mask        : std_logic_vector (pkg_APP_MASK_WIDTH-1 downto 0);


  ---------------------------------------------------------------------
  -- io top
  ---------------------------------------------------------------------
  -- science data valid (user side)
  signal science_data_valid : std_logic;
  -- science ctrl (user side)
  signal science_ctrl       : std_logic;
  -- science data (user side)
  signal science_data       : std_logic_vector(i_science_data_p'range);

  -- Shared SPI MISO (user side)
  signal ui_spi_miso : std_logic;
  -- Shared SPI MOSI (user side)
  signal ui_spi_mosi : std_logic;
  -- Shared SPI clock line (user side)
  signal ui_spi_sclk : std_logic;
  -- SPI chip select (user side)
  signal ui_spi_cs_n : std_logic_vector(o_spi_cs_n'range);

begin

  hardware_id <= i_hardware_id;

---------------------------------------------------------------------
-- regdecode
---------------------------------------------------------------------
  inst_regdecode_top : entity work.regdecode_top
    generic map(
      g_DEBUG => pkg_REGDECODE_TOP_DEBUG
      )
    port map(
      --  Opal Kelly inouts --
      i_okUH  => i_okUH,
      o_okHU  => o_okHU,
      b_okUHU => b_okUHU,
      b_okAA  => b_okAA,

      ---------------------------------------------------------------------
      -- from IOs
      ---------------------------------------------------------------------
      i_hardware_id => hardware_id,
      ---------------------------------------------------------------------
      -- to the user @o_usb_clk
      ---------------------------------------------------------------------
      o_usb_clk     => usb_clk,
      o_usb_rst     => usb_rst,

      ---------------------------------------------------------------------
      -- from/to the user @i_out_clk
      ---------------------------------------------------------------------
      i_out_clk => sys_clk,
      i_out_rst => sys_rst,

      -- HK
      ---------------------------------------------------------------------
      -- pipe_out spi hk(pipe)
      i_hk_valid       => hk_valid,
      i_hk             => hk,
      -- pipe
      o_tc_valid       => tc_valid,
      o_tc             => tc,
      -- wire
      o_reg_ctrl       => open,
      o_reg_tc_hk_conf => reg_tc_hk_conf,

      -- ICU
      ---------------------------------------------------------------------
      o_reg_icu_conf => reg_icu_conf,

      -- science
      ---------------------------------------------------------------------
      -- wire_out:
      i_reg_science_stamp_lsb => reg_science_stamp_lsb,

      -- from science
      i_fifo_science_data_valid => fifo_science_data_valid,
      i_fifo_science_data       => fifo_science_data,
      o_fifo_science_prog_full  => fifo_science_prog_full,

      -- debug_ctrl
      ---------------------------------------------------------------------
      o_reg_debug_ctrl_valid => open,
      o_reg_debug_ctrl       => reg_debug_ctrl,

      -- errors/status
      ---------------------------------------------------------------------
      i_reg_wire_errors1 => reg_wire_errors1,
      i_reg_wire_errors0 => reg_wire_errors0,
      i_reg_wire_status1 => reg_wire_status1,
      i_reg_wire_status0 => reg_wire_status0
      );


-- extract bits from register
  -- tc_hk_conf register
  spi_select                  <= reg_tc_hk_conf(pkg_TC_HK_CONF_SPI_RAS_SEL_IDX_H);
  -- icu_conf register
  icu_select                  <= reg_icu_conf(pkg_ICU_CONF_SEL_IDX_H);
  -- debug_ctrl register
  rst_status                  <= reg_debug_ctrl(pkg_DEBUG_CTRL_RST_STATUS_IDX_H);
  debug_pulse                 <= reg_debug_ctrl(pkg_DEBUG_CTRL_DEBUG_PULSE_IDX_H);
  science_pattern_en_fifo_out <= reg_debug_ctrl(pkg_DEBUG_CTRL_SC_PATTERN_EN_FIFO_OUT_IDX_H);

  -- to registers
  reg_science_stamp_lsb <= ddr_stamp;

  -- errors0
  reg_wire_errors0(31 downto 16) <= science_errors1;
  reg_wire_errors0(15 downto 0)  <= science_errors0;
  -- status0
  reg_wire_status0(31 downto 24) <= (others => '0');
  reg_wire_status0(23 downto 16) <= science_status1;
  reg_wire_status0(15 downto 8)  <= (others => '0');
  reg_wire_status0(7 downto 0)   <= science_status0;

  -- errors1
  reg_wire_errors1(31 downto 16) <= (others => '0');
  reg_wire_errors1(15 downto 0)  <= tc_hk_errors;
  -- status1
  reg_wire_status1(31 downto 24) <= (others => '0');
  reg_wire_status1(23 downto 16) <= (others => '0');
  reg_wire_status1(15 downto 8)  <= (others => '0');
  reg_wire_status1(7 downto 0)   <= tc_hk_status;



---------------------------------------------------------------------
-- reset_top
---------------------------------------------------------------------
  inst_reset_top : entity work.reset_top
    port map(
      ---------------------------------------------------------------------
      -- frome usb @usb_clk
      ---------------------------------------------------------------------
      -- clock
      i_usb_clk      => usb_clk,
      -- software reset
      i_usb_rst      => usb_rst,
      ---------------------------------------------------------------------
      -- to DDR interface @i_usb_clk
      ---------------------------------------------------------------------
      -- reset the DDR controller
      o_ddr_ctrl_rst => ddr_ctrl_rst,
      ---------------------------------------------------------------------
      -- from DDR interface @i_sys_clk
      ---------------------------------------------------------------------
      -- ddr user side
      -- system clock
      i_sys_clk      => sys_clk,
      -- reset
      i_sys_rst      => ui_sys_rst,
      ---------------------------------------------------------------------
      -- to the user @ i_sys_clk
      ---------------------------------------------------------------------
      -- output reset
      o_sys_rst      => sys_rst
      );

  ---------------------------------------------------------------------
  -- tmtc_top
  ---------------------------------------------------------------------
  inst_tmtc_top : entity work.tmtc_top
    port map(
      ---------------------------------------------------------------------
      -- From DDR @i_clk
      ---------------------------------------------------------------------
      -- system clock
      i_clk         => sys_clk,
      ---------------------------------------------------------------------
      -- from reset @i_clk
      ---------------------------------------------------------------------
      -- system reset
      i_rst         => sys_rst,
      ---------------------------------------------------------------------
      -- Regdecode
      ---------------------------------------------------------------------
      -- from regdecode
      -- reset error flag(s)
      i_rst_status  => rst_status,
      -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s)
      i_debug_pulse => debug_pulse,

      -- '1': Fill the science output FIFO with a pre-defined pattern, '0': fill the science output FIFO with data from the DDR
      i_science_pattern_en_fifo_out => science_pattern_en_fifo_out,


      -- HK: SPI
      ---------------------------------------------------------------------
      -- spi_select bit
      i_spi_select => spi_select,
      -- write enable tc command
      i_tc_valid   => tc_valid,
      -- write tc data command
      i_tc         => tc,

      -- hk read data valid
      o_hk_valid => hk_valid,
      -- hk read data
      o_hk       => hk,

      -- to regdecode
      -- science
      ---------------------------------------------------------------------
      -- fifo prog full
      i_fifo_science_prog_full  => fifo_science_prog_full,
      -- fifo data valid (write enable)
      o_fifo_science_data_valid => fifo_science_data_valid,
      -- fifo data
      o_fifo_science_data       => fifo_science_data,

      -- status
      ---------------------------------------------------------------------
      -- to regdecode
      o_ddr_stamp => ddr_stamp,

      ---------------------------------------------------------------------
      -- from/to DDR controller @sys_clk
      ---------------------------------------------------------------------
      -- PHY asserts init_calib_complete when calibration is finished
      i_init_calib_complete => init_calib_complete,
      -- addr of the current request
      o_app_addr            => app_addr,
      -- command for the current request
      o_app_cmd             => app_cmd,
      -- active-High strobe for the app_addr[], app_cmd[2:0], app_sz, and app_hi_pri inputs
      o_app_en              => app_en,
      --  data for write commands.
      o_app_wdf_data        => app_wdf_data,
      -- active-High input indicates that the current clock cycle is the last cycle of input data on app_wdf_data[].
      o_app_wdf_end         => app_wdf_end,
      -- active-High strobe for app_wdf_data[].
      o_app_wdf_wren        => app_wdf_wren,
      -- data from read commands
      i_app_rd_data         => app_rd_data,
      -- active-High output indicates that the current clock cycle is the last cycle of output data on app_rd_data[]. This is valid only
      -- when app_rd_data_valid is active-High.
      i_app_rd_data_end     => app_rd_data_end,
      -- active-High output indicates that app_rd_data[] is valid.
      i_app_rd_data_valid   => app_rd_data_valid,
      -- output indicates that the UI is ready to accept commands.If the signal is deasserted when app_en is enabled, the current
      -- app_cmd and app_addr must be retried until app_rdy is asserted.
      i_app_rdy             => app_rdy,
      -- This output indicates that the write data FIFO is ready to receive data. Write data is accepted when app_wdf_rdy = 1’b1 and app_wdf_wren = 1’b1.
      i_app_wdf_rdy         => app_wdf_rdy,
      -- mask for app_wdf_data[].
      o_app_wdf_mask        => app_wdf_mask,
      ---------------------------------------------------------------------
      -- from io: science @sys_clk
      ---------------------------------------------------------------------
      -- input science data valid
      i_science_data_valid  => science_data_valid,
      -- input science ctrl
      i_science_ctrl        => science_ctrl,
      -- input science data
      i_science_data        => science_data,

      ---------------------------------------------------------------------
      -- from/to io: spi @sys_clk
      ---------------------------------------------------------------------
      -- SPI --
      i_spi_miso     => ui_spi_miso,
      o_spi_mosi     => ui_spi_mosi,
      o_spi_sclk     => ui_spi_sclk,
      o_spi_cs_n     => ui_spi_cs_n,
      ---------------------------------------------------------------------
      -- leds
      ---------------------------------------------------------------------
      o_leds         => leds,
      o_led_fw       => led_fw,
      o_led_pll_lock => led_pll_lock,

      ---------------------------------------------------------------------
      -- debug
      ---------------------------------------------------------------------
      -- tc_hk_errors
      o_tc_hk_errors => tc_hk_errors,
      -- tc_hk_status
      o_tc_hk_status => tc_hk_status,

      -- science errors1
      o_science_errors1 => science_errors1,
      -- science errors0
      o_science_errors0 => science_errors0,
      -- science status1
      o_science_status1 => science_status1,
      -- science status0
      o_science_status0 => science_status0
      );

  o_sel_main_n <= icu_select;

  o_leds         <= leds;
  o_led_fw       <= led_fw;
  o_led_pll_lock <= led_pll_lock;

----------------------------------------------------
--      Controller DDR3
----------------------------------------------------
  inst_ddr3_256_16 : entity work.ddr3_256_16
    port map (
      ---------------------------------------------------------------------
      -- DDR interface
      ---------------------------------------------------------------------
      ddr3_addr           => ddr3_addr,
      ddr3_ba             => ddr3_ba,
      ddr3_cas_n          => ddr3_cas_n,
      ddr3_ck_n           => ddr3_ck_n,
      ddr3_ck_p           => ddr3_ck_p,
      ddr3_cke            => ddr3_cke,
      ddr3_ras_n          => ddr3_ras_n,
      ddr3_reset_n        => ddr3_reset_n,
      ddr3_we_n           => ddr3_we_n,
      ddr3_dq             => ddr3_dq,
      ddr3_dqs_n          => ddr3_dqs_n,
      ddr3_dqs_p          => ddr3_dqs_p,
      init_calib_complete => init_calib_complete,

      ddr3_cs_n         => ddr3_cs_n,
      ddr3_dm           => ddr3_dm,
      ddr3_odt          => ddr3_odt,
      ---------------------------------------------------------------------
      -- User interface
      --  data part
      ---------------------------------------------------------------------
      app_addr          => app_addr,
      app_cmd           => app_cmd,
      app_en            => app_en,
      app_wdf_data      => app_wdf_data,
      app_wdf_end       => app_wdf_end,
      app_wdf_wren      => app_wdf_wren,
      app_rd_data       => app_rd_data,
      app_rd_data_end   => app_rd_data_end,
      app_rd_data_valid => app_rd_data_valid,
      app_rdy           => app_rdy,
      app_wdf_rdy       => app_wdf_rdy,
      app_sr_req        => '0',
      app_sr_active     => open,
      app_ref_req       => '0',
      app_ref_ack       => open,
      app_zq_req        => '0',
      app_zq_ack        => open,
      app_wdf_mask      => app_wdf_mask,

      ---------------------------------------------------------------------
      -- user interface
      --  clock, reset
      ---------------------------------------------------------------------
      ui_clk          => sys_clk,
      ui_clk_sync_rst => ui_sys_rst,

      ---------------------------------------------------------------------
      -- controller interface
      --   clock, reset
      ---------------------------------------------------------------------
      sys_clk_p => i_sys_clk_p,
      sys_clk_n => i_sys_clk_n,

      sys_rst => ddr_ctrl_rst
      );

---------------------------------------------------------------------
-- IOs
---------------------------------------------------------------------
  inst_io_top : entity work.io_top
    generic map(
      g_SPI_CS_N_WIDTH => ui_spi_cs_n'length
      )
    port map(
      ---------------------------------------------------------------------
      -- from DEMUX: science interface @i_science_clk
      ---------------------------------------------------------------------
      i_science_clk_p      => i_science_clk_p(0),
      i_science_clk_n      => i_science_clk_n(0),
      i_science_ctrl_p     => i_science_ctrl_p(0),
      i_science_ctrl_n     => i_science_ctrl_n(0),
      i_science_data_p     => i_science_data_p,
      i_science_data_n     => i_science_data_n,
      ---------------------------------------------------------------------
      -- to user: science interface @i_sys_clk
      ---------------------------------------------------------------------
      i_sys_clk            => sys_clk,
      o_science_data_valid => science_data_valid,
      o_science_ctrl       => science_ctrl,
      o_science_data       => science_data,

      ---------------------------------------------------------------------
      -- from/to FPGA io: spi @i_sys_spi_clk
      ---------------------------------------------------------------------
      i_sys_spi_clk => sys_clk,
      -- SPI --
      i_spi_miso    => i_spi_miso,
      o_spi_mosi    => o_spi_mosi,
      o_spi_sclk    => o_spi_sclk,
      o_spi_cs_n    => o_spi_cs_n,
      ---------------------------------------------------------------------
      -- to user: spi interface @i_sys_spi_clk
      ---------------------------------------------------------------------
      -- SPI --
      o_ui_spi_miso => ui_spi_miso,
      i_ui_spi_mosi => ui_spi_mosi,
      i_ui_spi_sclk => ui_spi_sclk,
      i_ui_spi_cs_n => ui_spi_cs_n
      );

     ---------------------------------------------------------------------
     -- debugging
     ---------------------------------------------------------------------
     o_debug <= (others => '0');


end architecture RTL;
