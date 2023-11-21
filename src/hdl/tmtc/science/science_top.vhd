-- -------------------------------------------------------------------------------------------------------------
--                            Copyright (C) 2023-2030 Ken-ji de la Rosa, IRAP Toulouse.
-- -------------------------------------------------------------------------------------------------------------
--                            This file is part of the ATHENA X-IFU DRE Telemetry and Telecommand Firmware.
--
--                            tmtc-fw is free software: you can redistribute it and/or modifyh
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
--    @file                   science_top.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This module manage the science function
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.pkg_system_tmtc.all;

entity science_top is
  generic (
    -- true: Enable the DEBUG TOOL (ILA, etc.), false: otherwise
    g_DEBUG : boolean := false
    );
  port (

    ---------------------------------------------------------------------
    -- From DDR @i_clk
    ---------------------------------------------------------------------
    -- clock
    i_clk : in std_logic;

    ---------------------------------------------------------------------
    -- from reset @i_clk
    ---------------------------------------------------------------------
    -- reset @i_clk
    i_rst : in std_logic;

    -- reset error flag(s) @i_clk
    i_rst_status  : in std_logic;
    -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s) @i_clk
    i_debug_pulse : in std_logic;


    ---------------------------------------------------------------------
    -- from/to DDR controller @ i_clk
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
    -- from io: science @i_clk
    ---------------------------------------------------------------------
    -- input science data valid
    i_science_data_valid : in std_logic;
    -- input science ctrl (serialized)
    i_science_ctrl       : in std_logic;
    -- input science data (serialized)
    i_science_data       : in std_logic_vector(pkg_SC_LIGN_NUMBER_BY_COL - 1 downto 0);

    ---------------------------------------------------------------------
    -- To RegDecode @i_clk
    ---------------------------------------------------------------------
    -- fifo prog full flag
    i_fifo_prog_full  : in  std_logic;
    -- fifo output data valid
    o_fifo_data_valid : out std_logic;
    -- fifo output science data
    o_fifo_data       : out std_logic_vector(31 downto 0);

    -- number of remaining bytes to read in the DDR
    o_ddr_stamp            : out std_logic_vector(31 downto 0);
    ---------------------------------------------------------------------
    -- to leds @i_clk
    ---------------------------------------------------------------------
    -- science data valid (serialized) bit
    o_science_data_valid   : out std_logic;
    -- detect the last bit of the synchro word
    o_science_synchro_word : out std_logic;

    ---------------------------------------------------------------------
    -- errors/status @i_clk
    ---------------------------------------------------------------------
    -- errors1
    o_errors1 : out std_logic_vector(15 downto 0);
    -- errors0
    o_errors0 : out std_logic_vector(15 downto 0);
    -- status1
    o_status1 : out std_logic_vector(7 downto 0);
    -- status0
    o_status0 : out std_logic_vector(7 downto 0)

    );
end entity science_top;

architecture RTL of science_top is


---------------------------------------------------------------------
-- science_rx_deserializer
---------------------------------------------------------------------
-- detect the last bit of the sync_word
  signal sync_word_eof0 : std_logic;
-- first bit of a science ctrl bit
  signal sof0           : std_logic;
-- last bit of a science ctrl bit
  signal eof0           : std_logic;
-- data valid of the deserialized data
  signal data_valid0    : std_logic;
-- deserialized ctrl word
  signal ctrl_word0     : std_logic_vector(7 downto 0);
-- deserialized data
  signal data_words0    : std_logic_vector(8*8-1 downto 0);
-- status
  signal status0        : std_logic_vector(o_status1'range);
-- errors
  signal errors0        : std_logic_vector(o_errors1'range);

---------------------------------------------------------------------
-- sync with the science_rx_deserializer output
---------------------------------------------------------------------
-- temporary input pipe
  signal data_pipe_tmp0 : std_logic_vector(0 downto 0);
-- temporary output pipe
  signal data_pipe_tmp1 : std_logic_vector(0 downto 0);

-- i_science_data_valid delayed (take the science_rx_deserializer module latency into account)
  signal data_valid_bit_rx : std_logic;

---------------------------------------------------------------------
-- science_rx_frame
---------------------------------------------------------------------
-- combine data_valid and init_calib_complete
  signal data_valid_tmp0 : std_logic;
-- first frame
  signal sof_frame1      : std_logic;
-- last frame
  signal eof_frame1      : std_logic;
-- fifo data valid
  signal data_valid1     : std_logic;
-- fifo data
  signal data1           : std_logic_vector(127 downto 0);


---------------------------------------------------------------------
-- sync with the science_rx_frame output
---------------------------------------------------------------------
-- temporary input pipe
  signal data_pipe_tmp2 : std_logic_vector(1 downto 0);
-- temporary output pipe
  signal data_pipe_tmp3 : std_logic_vector(1 downto 0);

-- delayed first bit of a science ctrl bit
  signal sof1 : std_logic;
-- delayed last bit of a science ctrl bit
  signal eof1 : std_logic;


  ---------------------------------------------------------------------
  -- science ddr3
  ---------------------------------------------------------------------
  -- output fifo data valid
  signal fifo_data_valid : std_logic;
  -- output fifo data
  signal fifo_data       : std_logic_vector(o_fifo_data'range);
  -- science ddr errors
  signal ddr_errors      : std_logic_vector(o_errors0'range);
  -- science ddr status
  signal ddr_status      : std_logic_vector(o_status0'range);

begin

---------------------------------------------------------------------
-- science_rx_deserializer
---------------------------------------------------------------------
  inst_science_rx_deserializer : entity work.science_rx_deserializer
    generic map(
      g_DATA_WIDTH         => i_science_data'length,  -- define the number of links (input data width)
      g_DATA_WIDTH_BY_LINK => 8  -- define the number of bits by links in order to build a word
      )
    port map(
      -- input clock
      i_clk => i_clk,
      -- input reset
      i_rst => i_rst,

      -- reset error flag(s) @i_clk
      i_rst_status  => i_rst_status,
      -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s) @i_clk
      i_debug_pulse => i_debug_pulse,

      ---------------------------------------------------------------------
      -- input
      ---------------------------------------------------------------------
      -- science data valid
      i_science_data_valid => i_science_data_valid,
      -- science ctrl (serialized)
      i_science_ctrl       => i_science_ctrl,
      -- science data (serialized)
      i_science_data       => i_science_data,
      ---------------------------------------------------------------------
      -- output
      ---------------------------------------------------------------------
      -- detect the last bit of the synchro word
      o_sync_word_eof      => sync_word_eof0,
      -- first ctrl bit (for debugging)
      o_sof                => sof0,
      -- last ctrl bit (for debugging)
      o_eof                => eof0,
      -- valid deserialized word
      o_data_valid         => data_valid0,
      -- deserialized control word
      o_ctrl_word          => ctrl_word0,
      -- deserialized data words
      o_data_words         => data_words0,

      ---------------------------------------------------------------------
      -- status
      ---------------------------------------------------------------------
      o_status => status0,
      o_errors => errors0
      );
  o_status1         <= status0;
  o_errors1         <= errors0;
---------------------------------------------------------------------
-- sync with the science_rx_deserializer
---------------------------------------------------------------------
  data_pipe_tmp0(0) <= i_science_data_valid;
  inst_pipeliner_with_init_sync_with_science_rx_deserializer_out : entity work.pipeliner_with_init
    generic map(
      g_INIT       => '0',
      g_NB_PIPES   => pkg_SC_RX_DESERIALIZER,  -- number of consecutives registers. Possibles values: [0, integer max value[
      g_DATA_WIDTH => data_pipe_tmp0'length  -- width of the input/output data.  Possibles values: [1, integer max value[
      )
    port map(
      i_clk  => i_clk,
      i_data => data_pipe_tmp0,
      o_data => data_pipe_tmp1
      );
  data_valid_bit_rx <= data_pipe_tmp1(0);

  -- output
  o_science_data_valid   <= data_valid_bit_rx;
  o_science_synchro_word <= sync_word_eof0;

---------------------------------------------------------------------
-- science_rx_frame
---------------------------------------------------------------------
  data_valid_tmp0 <= data_valid0 and i_init_calib_complete;

  inst_science_rx_frame : entity work.science_rx_frame
    port map(
      -- input clock
      i_clk        => i_clk,
      -- input reset
      i_rst        => i_rst,
      ---------------------------------------------------------------------
      -- input
      ---------------------------------------------------------------------
      -- valid deserialized word
      i_data_valid => data_valid_tmp0,
      -- deserialized control word
      i_ctrl_word  => ctrl_word0,
      -- deserialized data words
      i_data_words => data_words0,
      ---------------------------------------------------------------------
      -- output
      ---------------------------------------------------------------------
      o_sof_frame  => sof_frame1,
      o_eof_frame  => eof_frame1,
      o_data_valid => data_valid1,
      o_data       => data1
      );

---------------------------------------------------------------------
-- sync with the science_rx_frame output
---------------------------------------------------------------------
  data_pipe_tmp2(1) <= sof0;
  data_pipe_tmp2(0) <= eof0;

  inst_pipeliner_with_init_sync_with_science_rx_frame_out : entity work.pipeliner_with_init
    generic map(
      g_INIT       => '0',
      g_NB_PIPES   => pkg_SC_RX_FRAME,  -- number of consecutives registers. Possibles values: [0, integer max value[
      g_DATA_WIDTH => data_pipe_tmp2'length  -- width of the input/output data.  Possibles values: [1, integer max value[
      )
    port map(
      i_clk  => i_clk,
      i_data => data_pipe_tmp2,
      o_data => data_pipe_tmp3
      );
  sof1 <= data_pipe_tmp3(1);
  eof1 <= data_pipe_tmp3(0);

---------------------------------------------------------------------
-- science_ddr3
---------------------------------------------------------------------
  inst_science_ddr3 : entity work.science_ddr3
    port map(
      -- input clock
      i_clk                 => i_clk,
      -- input reset
      i_rst                 => i_rst,
      -- reset error flag(s) @i_clk
      i_rst_status          => i_rst_status,
      -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s) @i_clk
      i_debug_pulse         => i_debug_pulse,
      ---------------------------------------------------------------------
      -- input data
      ---------------------------------------------------------------------
      -- input data valid
      i_data_valid          => data_valid1,
      -- input data
      i_data                => data1,
      ---------------------------------------------------------------------
      -- output data
      ---------------------------------------------------------------------
      -- fifo prog full
      i_fifo_prog_full      => i_fifo_prog_full,
      -- fifo output data valid
      o_fifo_data_valid     => fifo_data_valid,
      -- fifo output data
      o_fifo_data           => fifo_data,
      ---------------------------------------------------------------------
      -- output register
      ---------------------------------------------------------------------
      -- number of remaining bytes to read in the DDR
      o_ddr_stamp           => o_ddr_stamp,
      ---------------------------------------------------------------------
      -- from/to DDR controller @ i_clk
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
      -- errors/status
      ---------------------------------------------------------------------
      -- errors
      o_errors              => ddr_errors,
      -- status
      o_status              => ddr_status
      );

  o_fifo_data_valid <= fifo_data_valid;
  o_fifo_data       <= fifo_data;

  o_errors0 <= ddr_errors;
  o_status0 <= ddr_status;


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
        i_clk                 => i_clk,
        ---------------------------------------------------------------------
        -- from DEMUX: science interface @i_science_clk
        ---------------------------------------------------------------------
        i_science_valid       => fifo_data_valid,
        i_science_data        => fifo_data,
        ---------------------------------------------------------------------
        -- to user: science interface @i_sys_clk
        ---------------------------------------------------------------------
        o_science_data_valid  => debug_science_data_valid,
        o_science_data        => debug_science_data,
        o_science_error_valid => debug_science_error_valid,
        o_science_error_cnt   => debug_science_error_cnt
        );


    inst_ila_science_top : entity work.ila_science_top
      port map (
        clk => i_clk,

        -- probe0
        probe0(8) => debug_science_error_valid,
        probe0(7) => i_rst,
        probe0(6) => i_init_calib_complete,
        probe0(5) => debug_science_data_valid,
        probe0(4) => sof1,
        probe0(3) => eof1,
        probe0(2) => sof_frame1,
        probe0(1) => eof_frame1,
        probe0(0) => data_valid1,

        -- probe1
        probe1(159 downto 128) => debug_science_data,
        probe1(127 downto 0)   => data1,
        -- probe2
        probe2(47 downto 32)   => debug_science_error_cnt,
        probe2(31 downto 16)   => errors0,
        probe2(15 downto 0)    => ddr_errors
        );


  end generate gen_debug;

end architecture RTL;
