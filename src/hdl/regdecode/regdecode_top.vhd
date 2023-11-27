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
--    @file                   regdecode_top.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg_regdecode.all;

entity regdecode_top is
  generic (
    g_DEBUG : boolean := false
    );
  port (
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
    -- From IO
    ---------------------------------------------------------------------
    -- hardware id register (reading)
    i_hardware_id : in std_logic_vector(7 downto 0);

    ---------------------------------------------------------------------
    -- to the user @o_usb_clk
    ---------------------------------------------------------------------
    -- usb clock
    o_usb_clk : out std_logic;
    -- reset @usb_clk
    o_usb_rst : out std_logic;


    ---------------------------------------------------------------------
    -- from/to the user: @i_out_clk
    ---------------------------------------------------------------------
    -- clock (user side)
    i_out_clk : in std_logic;
    -- reset @i_out_clk
    i_out_rst : in std_logic;

    -- HK
    ---------------------------------------------------------------------

    -- pipe_out hk data valid
    i_hk_valid : in  std_logic;
    -- pipe_out HK data
    i_hk       : in  std_logic_vector(31 downto 0);
    -- pipe
    -- TC pipein data valid
    o_tc_valid : out std_logic;
    -- TC pipein data
    o_tc       : out std_logic_vector(31 downto 0);

    -- wire
    -- ctrl register (writting)
    o_reg_ctrl       : out std_logic_vector(31 downto 0);
    -- tc_hk_conf register (writting)
    o_reg_tc_hk_conf : out std_logic_vector(31 downto 0);

    -- ICU
    ---------------------------------------------------------------------
    -- icu_conf register (writting)
    o_reg_icu_conf : out std_logic_vector(31 downto 0);

    -- science
    ---------------------------------------------------------------------
    -- science_stamp_lsb register (reading)
    i_reg_science_stamp_lsb : in std_logic_vector(31 downto 0);

    -- from science
    -- fifo science data valid
    i_fifo_science_data_valid : in  std_logic;
    -- fifo science data
    i_fifo_science_data       : in  std_logic_vector(31 downto 0);
    -- fifo prog full
    o_fifo_science_prog_full  : out std_logic;

    -- debug_ctrl
    ---------------------------------------------------------------------
    -- debug_ctrl data valid
    o_reg_debug_ctrl_valid : out std_logic;
    -- debug_ctrl register value
    o_reg_debug_ctrl       : out std_logic_vector(31 downto 0);

    -- errors/status
    ---------------------------------------------------------------------
    -- status register: errors1
    i_reg_wire_errors1 : in std_logic_vector(31 downto 0);
    -- status register: errors0
    i_reg_wire_errors0 : in std_logic_vector(31 downto 0);
    -- status register: status1
    i_reg_wire_status1 : in std_logic_vector(31 downto 0);
    -- status register: status0
    i_reg_wire_status0 : in std_logic_vector(31 downto 0)

    );
end entity regdecode_top;

architecture RTL of regdecode_top is

-- define an array of 32 bit words
  type t_array32 is array (natural range <>) of std_logic_vector(31 downto 0);
-- define an array of 16 bit words
  type t_array16 is array (natural range <>) of std_logic_vector(15 downto 0);
-- define an array of 8 bit words
  type t_array8 is array (natural range <>) of std_logic_vector(7 downto 0);
---------------------------------------------------------------------
-- usb_opal_kelly
---------------------------------------------------------------------

-- Common Register configuration
---------------------------------------------------------------------
-- science_wr_data_count register value
  signal usb_wireout_science_wr_data_count : std_logic_vector(31 downto 0);


-- science_stamp_lsb register value
  signal usb_wireout_science_stamp_lsb : std_logic_vector(31 downto 0);

-- tc_hk_conf register value
  signal usb_wireout_tc_hk_conf : std_logic_vector(31 downto 0);

  -- spi_rd_data_count register
  signal usb_wireout_hk_rd_data_count : std_logic_vector(31 downto 0);

-- firmware_id register value
  signal usb_wireout_firmware_id : std_logic_vector(31 downto 0);

-- hardware_id register value
  signal usb_wireout_hardware_id : std_logic_vector(31 downto 0);


-- firmware_name register value
  signal usb_wireout_firmware_name : std_logic_vector(31 downto 0);

-- Debugging Registers
---------------------------------------------------------------------
-- debug_ctrl register value
  signal usb_wireout_debug_ctrl : std_logic_vector(31 downto 0);
  -- sel_errors register value
  signal usb_wireout_sel_errors : std_logic_vector(31 downto 0);
  -- errors register value
  signal usb_wireout_errors     : std_logic_vector(31 downto 0);
  -- status register value
  signal usb_wireout_status     : std_logic_vector(31 downto 0);

  -- Science pipeout
  ---------------------------------------------------------------------
  -- science pipeout read enable
  signal usb_pipeout_science_rd_en         : std_logic;
  -- science pipeout read data valid
  signal usb_pipeout_science_rd_data_valid : std_logic;
  -- science pipeout read data
  signal usb_pipeout_science_rd_data       : std_logic_vector(31 downto 0);

  -- spi pipeout
  ---------------------------------------------------------------------
  -- spi pipeout data valid
  signal usb_pipeout_rd_hk_valid : std_logic;
  -- spi pipeout data
  signal usb_pipeout_rd_hk       : std_logic_vector(31 downto 0);


-- Common Register configuration
---------------------------------------------------------------------
-- ctrl register value
  signal usb_wirein_ctrl       : std_logic_vector(31 downto 0);
-- tc_hk_conf register value
  signal usb_wirein_tc_hk_conf : std_logic_vector(31 downto 0);
-- icu_conf register value
  signal usb_wirein_icu_conf   : std_logic_vector(31 downto 0);
-- Debugging Registers
---------------------------------------------------------------------
-- debug_ctrl register value
  signal usb_wirein_debug_ctrl : std_logic_vector(31 downto 0);
-- sel_errors register value
  signal usb_wirein_sel_errors : std_logic_vector(31 downto 0);

-- SPI Pipe_In
---------------------------------------------------------------------
  -- spi pipein data valid
  signal usb_pipein_tc_valid : std_logic;
  -- spi pipein data
  signal usb_pipein_tc       : std_logic_vector(31 downto 0);


  -- usb clock
  signal usb_clk         : std_logic;
  -- rst @usb_clk
  signal usb_rst         : std_logic;
  -- rst_status @usb_clk
  signal usb_rst_status  : std_logic;
  -- debug_pulse @usb_clk
  signal usb_debug_pulse : std_logic;

  signal sel_errors : std_logic_vector(pkg_ERROR_SEL_WIDTH - 1 downto 0);


  ---------------------------------------------------------------------
  -- regdecode_science_fifo
  ---------------------------------------------------------------------
  -- count the number of science word in the pipeout fifo
  signal science_wr_data_count : std_logic_vector(15 downto 0);
  -- science errors
  signal science_errors        : std_logic_vector(15 downto 0);
  -- science status
  signal science_status        : std_logic_vector(7 downto 0);

  ---------------------------------------------------------------------
  -- HK pipe_in: regdecode_pipe_usb_to_user
  ---------------------------------------------------------------------
  -- HK pipein data valid
  signal tc_valid          : std_logic;
  -- HK pipe_in data
  signal tc                : std_logic_vector(o_tc'range);
  -- spi errors
  signal hk_pipe_in_errors : std_logic_vector(15 downto 0);
  -- spi status
  signal hk_pipe_in_status : std_logic_vector(7 downto 0);


  ---------------------------------------------------------------------
  -- hk pipe_out: regdecode_pipe_user_to_usb_data_count
  ---------------------------------------------------------------------
  -- count the number of spi word in the pipeout fifo
  signal hk_wr_data_count   : std_logic_vector(15 downto 0);
  -- spi errors
  signal hk_pipe_out_errors : std_logic_vector(15 downto 0);
  -- spi status
  signal hk_pipe_out_status : std_logic_vector(7 downto 0);

  ---------------------------------------------------------------------
  -- tc_hk_conf regdecode_register_to_user
  ---------------------------------------------------------------------
  --signal spi_conf_valid : std_logic;
  signal tc_hk_conf        : std_logic_vector(o_reg_tc_hk_conf'range);
  -- tc_hk_conf errors
  signal tc_hk_conf_errors : std_logic_vector(15 downto 0);
  -- tc_hk_conf status
  signal tc_hk_conf_status : std_logic_vector(7 downto 0);

  ---------------------------------------------------------------------
  -- debug_ctrl regdecode_register_to_user
  ---------------------------------------------------------------------
  signal reg_debug_ctrl_valid : std_logic;
  signal reg_debug_ctrl       : std_logic_vector(o_reg_debug_ctrl'range);
  -- debug_ctrl errors
  signal debug_ctrl_errors    : std_logic_vector(15 downto 0);
  -- debug_ctrl status
  signal debug_ctrl_status    : std_logic_vector(7 downto 0);

  ---------------------------------------------------------------------
  -- regdecode_register_to_usb
  ---------------------------------------------------------------------
  -- science_stamp_lsb errors
  signal science_stamp_lsb_errors : std_logic_vector(15 downto 0);
  -- science_stamp_lsb status
  signal science_stamp_lsb_status : std_logic_vector(7 downto 0);

  ---------------------------------------------------------------------
  -- build errors/status
  ---------------------------------------------------------------------
  -- errors2
  signal usb_wire_errors2 : std_logic_vector(31 downto 0);
  -- errors1
  signal usb_wire_errors1 : std_logic_vector(31 downto 0);
  -- errors0
  signal usb_wire_errors0 : std_logic_vector(31 downto 0);
  -- status2
  signal usb_wire_status2 : std_logic_vector(31 downto 0);
  -- status1
  signal usb_wire_status1 : std_logic_vector(31 downto 0);
  -- status0
  signal usb_wire_status0 : std_logic_vector(31 downto 0);
  ---------------------------------------------------------------------
  -- regdecode_wire_errors
  ---------------------------------------------------------------------
  -- selected wire
  signal wire_errors      : std_logic_vector(31 downto 0);
  -- selected status
  signal wire_status      : std_logic_vector(31 downto 0);

begin

  usb_wireout_hardware_id   <= std_logic_vector(resize(unsigned(i_hardware_id), usb_wireout_hardware_id'length));
  usb_wireout_firmware_id   <= pkg_FIRMWARE_ID;
  usb_wireout_firmware_name <= pkg_FIRMWARE_NAME;

  inst_usb_opal_kelly : entity work.usb_opal_kelly
    port map(
      --  Opal Kelly inouts --
      i_okUH                              => i_okUH,
      o_okHU                              => o_okHU,
      b_okUHU                             => b_okUHU,
      b_okAA                              => b_okAA,
      ---------------------------------------------------------------------
      -- from the user @o_usb_clk
      ---------------------------------------------------------------------
      -- wire_out
      i_usb_wireout_science_wr_data_count => usb_wireout_science_wr_data_count,  -- science_wr_data_count register (reading)
      i_usb_wireout_science_stamp_lsb     => usb_wireout_science_stamp_lsb,  -- science_stamp_lsb register (reading)
      i_usb_wireout_tc_hk_conf            => usb_wireout_tc_hk_conf,  -- tc_hk_conf register (reading)
      i_usb_wireout_hk_rd_data_count      => usb_wireout_hk_rd_data_count,  -- spi_rd_data_count register (reading)
      i_usb_wireout_hardware_id           => usb_wireout_hardware_id,  -- hardware id register (reading)
      i_usb_wireout_firmware_name         => usb_wireout_firmware_name,  -- firmware_name register (reading)
      i_usb_wireout_firmware_id           => usb_wireout_firmware_id,  -- firmware_id register (reading)

      -- errors/status
      i_usb_wireout_debug_ctrl => usb_wireout_debug_ctrl,  -- debug_ctrl register (reading)
      i_usb_wireout_sel_errors => usb_wireout_sel_errors,  -- sel_errors register (reading)
      i_usb_wireout_errors     => usb_wireout_errors,  -- errors register (reading)
      i_usb_wireout_status     => usb_wireout_status,  -- status register (reading)

      -- rd science pipe
      o_usb_pipeout_science_rd_data_valid => usb_pipeout_science_rd_en,
      i_usb_pipeout_science_rd_data       => usb_pipeout_science_rd_data,

      -- read spi pipe
      o_usb_pipeout_rd_hk_valid => usb_pipeout_rd_hk_valid,
      i_usb_pipeout_rd_hk       => usb_pipeout_rd_hk,

      ---------------------------------------------------------------------
      -- to the user @o_usb_clk
      ---------------------------------------------------------------------
      o_usb_clk => usb_clk,             -- usb clock

      -- pipe
      o_usb_pipein_tc_valid => usb_pipein_tc_valid,  -- pipein data valid
      o_usb_pipein_tc       => usb_pipein_tc,        -- pipein data

      -- wire
      o_usb_wirein_ctrl       => usb_wirein_ctrl,  -- ctrl register (writting)
      o_usb_wirein_tc_hk_conf => usb_wirein_tc_hk_conf,  -- tc_hk_conf register (writting)
      o_usb_wirein_icu_conf   => usb_wirein_icu_conf,  -- icu_conf register (writting)

      -- debugging
      o_usb_wirein_debug_ctrl => usb_wirein_debug_ctrl,  -- debug_ctrl register (writting)
      o_usb_wirein_sel_errors => usb_wirein_sel_errors  -- sel_errors register (writting)
      );

  -- extract bits
  usb_rst_status  <= usb_wirein_debug_ctrl(pkg_DEBUG_CTRL_RST_STATUS_IDX_H);
  usb_debug_pulse <= usb_wirein_debug_ctrl(pkg_DEBUG_CTRL_DEBUG_PULSE_IDX_H);
  usb_rst         <= usb_wirein_ctrl(pkg_CTRL_RST_IDX_H);
  sel_errors      <= usb_wirein_sel_errors(pkg_ERROR_SEL_IDX_H downto pkg_ERROR_SEL_IDX_L);
  ---------------------------------------------------------------------
  -- output @usb_clk
  ---------------------------------------------------------------------

  o_reg_ctrl     <= usb_wirein_ctrl;
  o_reg_icu_conf <= usb_wirein_icu_conf;

  o_usb_rst <= usb_rst;

  o_usb_clk <= usb_clk;

---------------------------------------------------------------------
-- internal loopback
---------------------------------------------------------------------
  inst_pipeliner_with_init_optional_pipe_spi_conf : entity work.pipeliner_with_init
    generic map(
      g_INIT       => '0',
      g_NB_PIPES   => pkg_WIRE_LOOPBACK_DELAY,  -- number of consecutives registers. Possibles values: [0, integer max value[
      g_DATA_WIDTH => usb_wirein_tc_hk_conf'length  -- width of the input/output data.  Possibles values: [1, integer max value[
      )
    port map(
      i_clk  => usb_clk,
      i_data => usb_wirein_tc_hk_conf,
      o_data => usb_wireout_tc_hk_conf
      );

  inst_pipeliner_with_init_optional_pipe_debug_ctrl : entity work.pipeliner_with_init
    generic map(
      g_INIT       => '0',
      g_NB_PIPES   => pkg_WIRE_LOOPBACK_DELAY,  -- number of consecutives registers. Possibles values: [0, integer max value[
      g_DATA_WIDTH => usb_wirein_debug_ctrl'length  -- width of the input/output data.  Possibles values: [1, integer max value[
      )
    port map(
      i_clk  => usb_clk,
      i_data => usb_wirein_debug_ctrl,
      o_data => usb_wireout_debug_ctrl
      );

  inst_pipeliner_with_init_optional_pipe_sel_errors : entity work.pipeliner_with_init
    generic map(
      g_INIT       => '0',
      g_NB_PIPES   => pkg_WIRE_LOOPBACK_DELAY,  -- number of consecutives registers. Possibles values: [0, integer max value[
      g_DATA_WIDTH => usb_wirein_sel_errors'length  -- width of the input/output data.  Possibles values: [1, integer max value[
      )
    port map(
      i_clk  => usb_clk,
      i_data => usb_wirein_sel_errors,
      o_data => usb_wireout_sel_errors
      );


  ---------------------------------------------------------------------
  -- Science pipe_out: buffer
  --   cross clock domain: @i_clk -> @i_out_clk
  ---------------------------------------------------------------------
  inst_regdecode_science_fifo : entity work.regdecode_science_fifo
    generic map(
      g_DATA_WIDTH     => i_fifo_science_data'length,
      g_FIFO_DEPTH_OUT => pkg_SCIENCE_FIFO_DEPTH
      )
    port map(
      ---------------------------------------------------------------------
      -- from the user:  @i_out_clk
      ---------------------------------------------------------------------
      i_out_clk                => i_out_clk,
      i_out_rst                => i_out_rst,
      -- data
      i_fifo_data_valid        => i_fifo_science_data_valid,
      i_fifo_data              => i_fifo_science_data,
      o_fifo_prog_full         => o_fifo_science_prog_full,
      ---------------------------------------------------------------------
      -- to the usb: @i_clk
      ---------------------------------------------------------------------
      i_clk                    => usb_clk,
      i_rst                    => usb_rst,
      i_rst_status             => usb_rst_status,
      i_debug_pulse            => usb_debug_pulse,
      -- data
      i_usb_fifo_rd            => usb_pipeout_science_rd_en,
      o_usb_fifo_data_valid    => usb_pipeout_science_rd_data_valid,  -- to debug
      o_usb_fifo_data          => usb_pipeout_science_rd_data,
      o_usb_fifo_empty         => open,
      o_usb_fifo_wr_data_count => science_wr_data_count,
      ---------------------------------------------------------------------
      -- errors/status @ i_clk
      ---------------------------------------------------------------------
      o_errors                 => science_errors,
      o_status                 => science_status
      );
  -- count the number of packets with 1 packet = 4 words of 32 bits.
  usb_wireout_science_wr_data_count <= std_logic_vector(resize(unsigned(science_wr_data_count(15 downto 2)), usb_wireout_science_wr_data_count'length));

  ---------------------------------------------------------------------
  -- TC pipe_in:
  --   cross clock domain: @i_clk -> @i_out_clk
  ---------------------------------------------------------------------
  inst_hk_pipe_in_regdecode_pipe_usb_to_user : entity work.regdecode_pipe_usb_to_user
    generic map(
      g_DATA_WIDTH => usb_pipein_tc'length,
      g_FIFO_DEPTH => pkg_TC_FIFO_DEPTH
      )
    port map(
      ---------------------------------------------------------------------
      -- from usb:  @i_clk
      ---------------------------------------------------------------------
      i_clk             => usb_clk,
      i_rst             => usb_rst,
      i_rst_status      => usb_rst_status,
      i_debug_pulse     => usb_debug_pulse,
      -- input
      i_data_valid      => usb_pipein_tc_valid,
      i_data            => usb_pipein_tc,
      ---------------------------------------------------------------------
      -- to the user: @i_out_clk
      ---------------------------------------------------------------------
      i_out_clk         => i_out_clk,
      -- data
      o_fifo_data_valid => tc_valid,
      o_fifo_data       => tc,
      ---------------------------------------------------------------------
      -- errors/status @ i_clk
      ---------------------------------------------------------------------
      o_errors          => hk_pipe_in_errors,
      o_status          => hk_pipe_in_status
      );


  o_tc_valid <= tc_valid;
  o_tc       <= tc;

  ---------------------------------------------------------------------
  -- HK pipe_out:
  --   cross clock domain: @i_out_clk -> @i_clk
  ---------------------------------------------------------------------
  inst_hk_pipe_out_regdecode_pipe_user_to_usb_data_count : entity work.regdecode_pipe_user_to_usb_data_count
    generic map(
      g_DATA_WIDTH     => i_hk'length,
      g_FIFO_DEPTH_OUT => pkg_HK_FIFO_DEPTH
      )
    port map(
      ---------------------------------------------------------------------
      -- from the user:  @i_out_clk
      ---------------------------------------------------------------------
      -- data
      i_out_clk                => i_out_clk,
      i_out_rst                => i_out_rst,
      i_data_valid             => i_hk_valid,
      i_data                   => i_hk,
      ---------------------------------------------------------------------
      -- to the usb: @i_clk
      ---------------------------------------------------------------------
      i_clk                    => usb_clk,
      i_rst                    => usb_rst,
      i_rst_status             => usb_rst_status,
      i_debug_pulse            => usb_debug_pulse,
      -- data
      i_usb_fifo_rd            => usb_pipeout_rd_hk_valid,
      o_usb_fifo_data_valid    => open,
      o_usb_fifo_data          => usb_pipeout_rd_hk,
      o_usb_fifo_empty         => open,
      o_usb_fifo_wr_data_count => hk_wr_data_count,
      ---------------------------------------------------------------------
      -- errors/status @ i_clk
      ---------------------------------------------------------------------
      o_errors                 => hk_pipe_out_errors,
      o_status                 => hk_pipe_out_status
      );
  -- authorized values of the read data count: multiple of 4 words of 32 bits (example: 0,4,8,12,16, etc)
  --   1. convert the number of words into number of USB packets: X= hk_wr_data_count(hk_wr_data_count'high downto 2))
  --   2. convert the number of USB packets into words of 32 bits: X*4
  usb_wireout_hk_rd_data_count <= std_logic_vector(resize(unsigned(hk_wr_data_count(hk_wr_data_count'high downto 2)) * 4, usb_wireout_hk_rd_data_count'length));


---------------------------------------------------------------------
  -- tc_hk_conf register
  --   cross clock domain: @i_clk -> @i_out_clk
  ---------------------------------------------------------------------
  inst_tc_hk_conf_regdecode_register_to_user : entity work.regdecode_register_to_user
    generic map(
      g_DATA_WIDTH     => usb_wirein_tc_hk_conf'length,
      g_FIFO_DEPTH_OUT => pkg_TC_HK_CONF_FIFO_DEPTH
      )
    port map(
      ---------------------------------------------------------------------
      -- from/to the usb:  @i_clk
      ---------------------------------------------------------------------
      i_clk         => usb_clk,
      i_rst         => usb_rst,
      i_rst_status  => usb_rst_status,
      i_debug_pulse => usb_debug_pulse,
      -- input
      i_data        => usb_wirein_tc_hk_conf,
      ---------------------------------------------------------------------
      -- to the user: @i_out_clk
      ---------------------------------------------------------------------
      i_out_clk     => i_out_clk,

      -- data
      o_fifo_data_valid => open,
      o_fifo_data       => tc_hk_conf,
      ---------------------------------------------------------------------
      -- errors/status @ i_clk
      ---------------------------------------------------------------------
      o_errors          => tc_hk_conf_errors,
      o_status          => tc_hk_conf_status
      );


  o_reg_tc_hk_conf <= tc_hk_conf;

  ---------------------------------------------------------------------
  -- debug_ctrl register
  --   cross clock domain: @i_clk -> @i_out_clk
  ---------------------------------------------------------------------
  inst_regdecode_register_to_user_debug_ctrl : entity work.regdecode_register_to_user
    generic map(
      g_DATA_WIDTH     => usb_wirein_debug_ctrl'length,
      g_FIFO_DEPTH_OUT => pkg_DEBUG_CTRL_FIFO_DEPTH
      )
    port map(
      ---------------------------------------------------------------------
      -- from/to the usb:  @i_clk
      ---------------------------------------------------------------------
      i_clk         => usb_clk,
      i_rst         => usb_rst,
      i_rst_status  => usb_rst_status,
      i_debug_pulse => usb_debug_pulse,
      -- input
      i_data        => usb_wirein_debug_ctrl,
      ---------------------------------------------------------------------
      -- to the user: @i_out_clk
      ---------------------------------------------------------------------
      i_out_clk     => i_out_clk,

      -- data
      o_fifo_data_valid => reg_debug_ctrl_valid,
      o_fifo_data       => reg_debug_ctrl,
      ---------------------------------------------------------------------
      -- errors/status @ i_clk
      ---------------------------------------------------------------------
      o_errors          => debug_ctrl_errors,
      o_status          => debug_ctrl_status
      );

  o_reg_debug_ctrl_valid <= reg_debug_ctrl_valid;
  o_reg_debug_ctrl       <= reg_debug_ctrl;

  ---------------------------------------------------------------------
  -- science_status register
  -- science_stamp_lsb register
  -- science_debug0 register
  -- science_debug1 register
  --   cross clock domain: @i_clk -> @i_out_clk
  ---------------------------------------------------------------------
  gen_sync_reg : if true generate
    -- number of registers to synchronized
    constant c_NB_REGS : integer := 1;
    -- temporary input register array
    signal reg_tmp0    : t_array32(0 to c_NB_REGS - 1);
    -- temporary output register array
    signal reg_tmp1    : t_array32(0 to c_NB_REGS - 1);
    -- temporary output errors array
    signal errors_tmp1 : t_array16(0 to c_NB_REGS - 1);
    -- temporary output status array
    signal status_tmp1 : t_array8(0 to c_NB_REGS - 1);
  begin
    reg_tmp0(0) <= i_reg_science_stamp_lsb;

    gen_reg : for i in reg_tmp0'range generate
      inst_regdecode_register_to_usb : entity work.regdecode_register_to_usb
        generic map(
          g_DATA_WIDTH     => reg_tmp0(i)'length,
          g_FIFO_DEPTH_OUT => pkg_SC_STAMP_LSB_FIFO_DEPTH
          )
        port map(
          ---------------------------------------------------------------------
          -- from user:  @i_out_clk
          ---------------------------------------------------------------------
          i_out_clk         => i_out_clk,
          i_out_rst         => i_out_rst,
          -- input
          i_data            => reg_tmp0(i),
          ---------------------------------------------------------------------
          -- to the usb: @i_clk
          ---------------------------------------------------------------------
          i_clk             => usb_clk,
          i_rst_status      => usb_rst_status,
          i_debug_pulse     => usb_debug_pulse,
          -- data
          o_fifo_data_valid => open,
          o_fifo_data       => reg_tmp1(i),
          ---------------------------------------------------------------------
          -- errors/status @ i_clk
          ---------------------------------------------------------------------
          o_errors          => errors_tmp1(i),
          o_status          => status_tmp1(i)
          );

    end generate gen_reg;

    usb_wireout_science_stamp_lsb <= reg_tmp1(0);
    science_stamp_lsb_errors      <= errors_tmp1(0);
    science_stamp_lsb_status      <= status_tmp1(0);
  end generate gen_sync_reg;

  ---------------------------------------------------------------------
  -- build error/status @usb_clk
  ---------------------------------------------------------------------
  -- errors0
  usb_wire_errors0(31 downto 16) <= hk_pipe_in_errors;
  usb_wire_errors0(15 downto 0)  <= science_errors;

  -- status0
  usb_wire_status0(31 downto 24) <= (others => '0');
  usb_wire_status0(23 downto 16) <= hk_pipe_in_status;
  usb_wire_status0(15 downto 8)  <= (others => '0');
  usb_wire_status0(7 downto 0)   <= science_status;

  -- errors1
  usb_wire_errors1(31 downto 16) <= tc_hk_conf_errors;
  usb_wire_errors1(15 downto 0)  <= hk_pipe_out_errors;

  -- status1
  usb_wire_status1(31 downto 24) <= (others => '0');
  usb_wire_status1(23 downto 16) <= tc_hk_conf_status;
  usb_wire_status1(15 downto 8)  <= (others => '0');
  usb_wire_status1(7 downto 0)   <= hk_pipe_out_status;


  -- errors2
  usb_wire_errors2(31 downto 16) <= science_stamp_lsb_errors;
  usb_wire_errors2(15 downto 0)  <= debug_ctrl_errors;

  -- status2
  usb_wire_status2(31 downto 24) <= (others => '0');
  usb_wire_status2(23 downto 16) <= science_stamp_lsb_status;
  usb_wire_status2(15 downto 8)  <= (others => '0');
  usb_wire_status2(7 downto 0)   <= debug_ctrl_status;

  ---------------------------------------------------------------------
  -- errors/status wire
  ---------------------------------------------------------------------
  inst_regdecode_wire_errors : entity work.regdecode_wire_errors
    generic map(
      g_ERROR_SEL_WIDTH => sel_errors'length  -- define the width of the error selection
      )
    port map(
      ---------------------------------------------------------------------
      -- input @i_out_clk
      ---------------------------------------------------------------------
      i_out_clk          => i_out_clk,  -- clock
      -- errors
      i_reg_wire_errors1 => i_reg_wire_errors1,  -- errors value
      i_reg_wire_errors0 => i_reg_wire_errors0,  -- errors value
      -- status
      i_reg_wire_status1 => i_reg_wire_status1,  -- status value
      i_reg_wire_status0 => i_reg_wire_status0,  -- status value
      ---------------------------------------------------------------------
      -- input @i_clk
      ---------------------------------------------------------------------
      i_clk              => usb_clk,    -- clock
      i_error_sel        => sel_errors,  -- select the errors/status to output
      -- errors
      i_usb_reg_errors2  => usb_wire_errors2,    -- errors value
      i_usb_reg_errors1  => usb_wire_errors1,    -- errors value
      i_usb_reg_errors0  => usb_wire_errors0,    -- errors value
      -- status
      i_usb_reg_status2  => usb_wire_status2,    -- status value
      i_usb_reg_status1  => usb_wire_status1,    -- status value
      i_usb_reg_status0  => usb_wire_status0,    -- status value
      ---------------------------------------------------------------------
      -- output @ i_clk
      ---------------------------------------------------------------------
      o_wire_errors      => wire_errors,      -- output errors
      o_wire_status      => wire_status  -- output status
      );

  usb_wireout_errors <= wire_errors;
  usb_wireout_status <= wire_status;

  ---------------------------------------------------------------------
  -- debug
  ---------------------------------------------------------------------
  gen_debug : if g_DEBUG generate
    -- debug science data valid
    signal debug_science_data_valid  : std_logic;
    -- debug science data
    signal debug_science_data        : std_logic_vector(31 downto 0);
    -- debug science error (header)
    signal debug_science_error_valid : std_logic;
    -- debug science error counter (header)
    signal debug_science_error_cnt   : std_logic_vector(15 downto 0);
  begin

    inst_science_check_header_w32 : entity work.science_check_header_w32
      port map(
        i_clk                 => usb_clk,
        ---------------------------------------------------------------------
        -- from DEMUX: science interface @i_science_clk
        ---------------------------------------------------------------------
        i_science_valid       => usb_pipeout_science_rd_data_valid,
        i_science_data        => usb_pipeout_science_rd_data,
        ---------------------------------------------------------------------
        -- to user: science interface @i_sys_clk
        ---------------------------------------------------------------------
        o_science_data_valid  => debug_science_data_valid,
        o_science_data        => debug_science_data,
        o_science_error_valid => debug_science_error_valid,
        o_science_error_cnt   => debug_science_error_cnt
        );


    inst_ila_regdecode_top : entity work.ila_regdecode_top
      port map (
        clk => usb_clk,

        -- probe0
        probe0(1) => debug_science_error_valid,
        probe0(0) => debug_science_data_valid,

        -- probe1
        probe1(79 downto 64) => debug_science_error_cnt,
        probe1(63 downto 32) => usb_wireout_science_wr_data_count,
        probe1(31 downto 0)  => debug_science_data,

        -- probe2
        probe2(127 downto 96) => usb_wireout_science_stamp_lsb,
        probe2(95 downto 64)  => usb_wire_errors2,
        probe2(63 downto 32)  => usb_wire_errors1,
        probe2(31 downto 0)   => usb_wire_errors0
        );


  end generate gen_debug;


end architecture RTL;
