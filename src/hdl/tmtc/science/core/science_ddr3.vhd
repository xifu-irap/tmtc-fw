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
--    @file                   science_ddr3.vhd
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


entity science_ddr3 is
  generic (
    -- input FIFO DEPTH
    g_FIFO_DEPTH_IN  : integer;
    -- Output FIFO DEPTH
    g_FIFO_DEPTH_OUT : integer
    );
  port (

    -- input clock
    i_clk         : in std_logic;
    -- input reset
    i_rst         : in std_logic;
    -- reset error flag(s) @i_clk
    i_rst_status  : in std_logic;
    -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s) @i_clk
    i_debug_pulse : in std_logic;

    ---------------------------------------------------------------------
    -- input data
    ---------------------------------------------------------------------
    -- input data valid
    i_data_valid : in std_logic;
    -- input data
    i_data       : in std_logic_vector(127 downto 0);

    ---------------------------------------------------------------------
    -- output data
    ---------------------------------------------------------------------
    -- fifo prog full
    i_fifo_prog_full  : in  std_logic;
    -- fifo output data valid
    o_fifo_data_valid : out std_logic;
    -- fifo output data
    o_fifo_data       : out std_logic_vector(31 downto 0);

    ---------------------------------------------------------------------
    -- output register
    ---------------------------------------------------------------------
    -- number of remaining bytes to read in the DDR
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
    -- errors/status
    ---------------------------------------------------------------------
    -- errors
    o_errors : out std_logic_vector(15 downto 0);
    -- status
    o_status : out std_logic_vector(7 downto 0)
    );
end entity science_ddr3;

architecture RTL of science_ddr3 is

  ---------------------------------------------------------------------
  -- fifo cross clock domain
  ---------------------------------------------------------------------
  -- index0: low
  constant c_FIFO_IDX0_L : integer := 0;
  -- index0: high
  constant c_FIFO_IDX0_H : integer := c_FIFO_IDX0_L + i_data'length - 1;

  -- FIFO depth (expressed in number of words)
  constant c_FIFO_DEPTH0     : integer := g_FIFO_DEPTH_IN;
  -- FIFO prog full (expressed in number of words)
  constant c_FIFO_PROG_FULL0 : integer := c_FIFO_DEPTH0 - integer(real(c_FIFO_DEPTH0/2));
  -- FIFO width (expressed in bits)
  constant c_FIFO_WIDTH0     : integer := c_FIFO_IDX0_H + 1;

  -- fifo write side
  -- fifo rst
  signal wr_rst0       : std_logic;
  -- fifo write
  signal wr_tmp0       : std_logic;
  -- fifo data_in
  signal wr_data_tmp0  : std_logic_vector(c_FIFO_WIDTH0 - 1 downto 0);
  -- fifo full flag
  -- signal wr_full0      : std_logic;
  -- fifo prog full
  signal wr_prog_full0 : std_logic;
  -- fifo rst_busy flag
  -- signal wr_rst_busy0  : std_logic;

  -- fifo read side
  -- fifo read
  signal rd1         : std_logic;
  -- fifo data_valid flag
  signal data_valid1 : std_logic;
  -- fifo data_out
  signal data_tmp1   : std_logic_vector(c_FIFO_WIDTH0 - 1 downto 0);
  -- fifo empty flag
  signal empty1      : std_logic;
  -- fifo rst_busy flag
  -- signal rd_rst_busy1 : std_logic;

  -- fifo resynchronized errors
  signal errors_sync1 : std_logic_vector(3 downto 0);
  -- fifo resynchronized empty flag
  signal empty_sync1  : std_logic;

  ---------------------------------------------------------------------
  -- science_ddr3_ctrl
  ---------------------------------------------------------------------
  -- output data valid
  signal data_valid2                 : std_logic;
  -- output data
  signal data2                       : std_logic_vector(i_data'range);
  -- ddr write data count
  signal buffer_new_cmd_byte_addr_wr : std_logic_vector(54 downto 0);
  -- ddr read data count
  signal buffer_new_cmd_byte_addr_rd : std_logic_vector(54 downto 0);

  ---------------------------------------------------------------------
  -- output fifo
  ---------------------------------------------------------------------
  -- FIFO depth (expressed in number of words)
  constant c_FIFO_DEPTH2     : integer := g_FIFO_DEPTH_OUT;
  -- FIFO prog full (expressed in number of words)
  constant c_FIFO_PROG_FULL2 : integer := c_FIFO_DEPTH2 - 4;
  -- FIFO width (expressed in bits)
  constant c_FIFO_WIDTH2     : integer := c_FIFO_IDX0_H + 1;

  -- fifo write side
  -- fifo rst
  signal wr_rst2       : std_logic;
  -- fifo write
  signal wr_tmp2       : std_logic;
  -- fifo data_in
  signal wr_data_tmp2  : std_logic_vector(c_FIFO_WIDTH2 - 1 downto 0);
  -- fifo prog full
  signal wr_prog_full2 : std_logic;
  -- fifo full flag
  -- signal wr_full2       : std_logic;
  -- fifo rst_busy flag
  -- signal wr_rst_busy2   : std_logic;

  -- fifo read side
  -- fifo read
  signal rd3          : std_logic;
  -- fifo data_valid flag
  signal data_valid3  : std_logic;
  -- fifo data_out
  signal data_tmp3    : std_logic_vector(o_fifo_data'range);
  -- fifo empty flag
  signal empty3       : std_logic;
  -- fifo rst_busy flag
  signal rd_rst_busy3 : std_logic;

  -- data
  signal data3 : std_logic_vector(o_fifo_data'range);

  -- fifo resynchronized errors
  signal errors_sync3 : std_logic_vector(3 downto 0);
  -- fifo resynchronized empty flag
  signal empty_sync3  : std_logic;

  ---------------------------------------------------------------------
  -- error latching
  ---------------------------------------------------------------------
  -- define the width of the temporary errors signals
  constant c_NB_ERRORS : integer := 6;
  -- temporary input errors
  signal error_tmp     : std_logic_vector(c_NB_ERRORS - 1 downto 0);
  -- temporary output errors
  signal error_tmp_bis : std_logic_vector(c_NB_ERRORS - 1 downto 0);


begin


---------------------------------------------------------------------
-- clock cross domain : @i_out_clk -> i_clk
---------------------------------------------------------------------
  wr_rst0                                          <= i_rst;
  wr_tmp0                                          <= i_data_valid;
  wr_data_tmp0(c_FIFO_IDX0_H downto c_FIFO_IDX0_L) <= i_data;

  inst_fifo_sync_with_error : entity work.fifo_sync_with_error_prog_full
    generic map(
      g_FIFO_MEMORY_TYPE  => "auto",
      g_FIFO_READ_LATENCY => 1,
      g_FIFO_WRITE_DEPTH  => c_FIFO_DEPTH0,
      g_PROG_FULL_THRESH  => c_FIFO_PROG_FULL0,
      g_READ_DATA_WIDTH   => wr_data_tmp0'length,
      g_READ_MODE         => "std",
      g_WRITE_DATA_WIDTH  => wr_data_tmp0'length
      )
    port map(
      ---------------------------------------------------------------------
      -- write side
      ---------------------------------------------------------------------
      i_wr_clk        => i_clk,
      i_wr_rst        => wr_rst0,
      i_wr_en         => wr_tmp0,
      i_wr_din        => wr_data_tmp0,
      o_wr_full       => open,
      o_wr_prog_full  => wr_prog_full0,
      o_wr_rst_busy   => open,
      ---------------------------------------------------------------------
      -- read side
      ---------------------------------------------------------------------
      i_rd_en         => rd1,
      o_rd_dout_valid => data_valid1,
      o_rd_dout       => data_tmp1,
      o_rd_empty      => empty1,
      o_rd_rst_busy   => open,
      ---------------------------------------------------------------------
      -- resynchronized errors/ empty status
      ---------------------------------------------------------------------
      o_errors_sync   => errors_sync1,
      o_empty_sync    => empty_sync1
      );


---------------------------------------------------------------------
-- science_ddr3_ctrl
---------------------------------------------------------------------

  inst_science_ddr3_ctrl : entity work.science_ddr3_ctrl
    port map(
      -- clock
      i_clk                         => i_clk,
      -- reset
      i_rst                         => i_rst,
      ---------------------------------------------------------------------
      -- DDR status
      ---------------------------------------------------------------------
      -- DDR calibration is done
      i_calib_done                  => i_init_calib_complete,
      ---------------------------------------------------------------------
      -- input FIFO
      ---------------------------------------------------------------------
      -- FIFO input read
      o_pipe_in_read                => rd1,
      -- input FIFO data
      i_pipe_in_data                => data_tmp1,
      -- input FIFO data valid
      i_pipe_in_valid               => data_valid1,
      -- input FIFO data empty
      i_pipe_in_empty               => empty1,
      -- input FIFO data prog full
      i_prog_full                   => wr_prog_full0,
      ---------------------------------------------------------------------
      -- output FIFO
      ---------------------------------------------------------------------
      -- output FIFO write enable
      o_pipe_out_write              => data_valid2,
      -- output FIFO write data
      o_pipe_out_data               => data2,
      -- output FIFO full
      i_pipe_out_full               => wr_prog_full2,
      ---------------------------------------------------------------------
      -- DDR data
      ---------------------------------------------------------------------
      -- indicates that the UI is ready to accept commands.
      i_app_rdy                     => i_app_rdy,
      -- active-High strobe for the app_addr[], app_cmd[2:0], app_sz, and app_hi_pri inputs
      o_app_en                      => o_app_en,
      -- selects the command for the current request.
      o_app_cmd                     => o_app_cmd,
      -- address of the current request
      o_app_addr                    => o_app_addr,
      -- data from read commands
      i_app_rd_data                 => i_app_rd_data,
      -- indicates app_rd_data is valid
      i_app_rd_data_valid           => i_app_rd_data_valid,
      -- indicates that the write data FIFO is ready to receive data
      i_app_wdf_rdy                 => i_app_wdf_rdy,
      -- active-High strobe for app_wdf_data
      o_app_wdf_wren                => o_app_wdf_wren,
      -- data for write commands.
      o_app_wdf_data                => o_app_wdf_data,
      -- indicates that the current clock cycle is the last cycle of input data on app_wdf_data[
      o_app_wdf_end                 => o_app_wdf_end,
      -- mask for app_wdf_data
      o_app_wdf_mask                => o_app_wdf_mask,
      ---------------------------------------------------------------------
      -- Status
      ---------------------------------------------------------------------
      -- wr address (expressed in bytes)
      o_buffer_new_cmd_byte_addr_wr => buffer_new_cmd_byte_addr_wr,
      -- rd address (expressed in bytes)
      o_buffer_new_cmd_byte_addr_rd => buffer_new_cmd_byte_addr_rd
      );

---------------------------------------------------------------------
-- output FIFO: 128 bits -> 32 bits
---------------------------------------------------------------------
  wr_rst2 <= i_rst;
  wr_tmp2 <= data_valid2;

  ---------------------------------------------------------------------
  -- 32 bit word: Reordering:
  -- The data2 input has the following structure:
  --   data2 = dat0 & dat1 & dat2 & dat3 with datx: a 32 bit word
  -- with wr_data_tmp2 = data2, the output FIFO reading order is:
  --        0. out0 = wr_data_tmp2(127 downto 96) <=> dat3
  --        1. out1 = wr_data_tmp2(95 downto 64)  <=> dat2
  --        2. out2 = wr_data_tmp2(63 downto 32)  <=> dat1
  --        3. out3 = wr_data_tmp2(31 downto 0)   <=> dat0
  -- To get the following output FIFO,
  --        0. out0 = wr_data_tmp2(127 downto 96)  <=> dat0
  --        1. out1 = wr_data_tmp2(95 downto 64)   <=> dat1
  --        2. out2 = wr_data_tmp2(63 downto 32)   <=> dat2
  --        3. out3 = wr_data_tmp2(31 downto 0)    <=> dat3
  -- The FIFO 32 bit input words must be swapped as below:
  ---------------------------------------------------------------------
  wr_data_tmp2(127 downto 96) <= data2(31 downto 0);
  wr_data_tmp2(95 downto 64)  <= data2(63 downto 32);
  wr_data_tmp2(63 downto 32)  <= data2(95 downto 64);
  wr_data_tmp2(31 downto 0)   <= data2(127 downto 96);

  inst_fifo_sync_with_error_prog_full : entity work.fifo_sync_with_error_prog_full
    generic map(
      g_FIFO_MEMORY_TYPE  => "block",
      g_FIFO_READ_LATENCY => 1,
      g_FIFO_WRITE_DEPTH  => c_FIFO_DEPTH2,
      g_PROG_FULL_THRESH  => c_FIFO_PROG_FULL2,
      g_READ_DATA_WIDTH   => data_tmp3'length,
      g_READ_MODE         => "std",
      g_WRITE_DATA_WIDTH  => wr_data_tmp2'length

      )
    port map(
      ---------------------------------------------------------------------
      -- write side
      ---------------------------------------------------------------------
      i_wr_clk        => i_clk,
      i_wr_rst        => wr_rst2,
      i_wr_en         => wr_tmp2,
      i_wr_din        => wr_data_tmp2,
      o_wr_full       => open,
      o_wr_prog_full  => wr_prog_full2,
      o_wr_rst_busy   => open,
      ---------------------------------------------------------------------
      -- read side
      ---------------------------------------------------------------------
      i_rd_en         => rd3,
      o_rd_dout_valid => data_valid3,
      o_rd_dout       => data_tmp3,
      o_rd_empty      => empty3,
      o_rd_rst_busy   => rd_rst_busy3,
---------------------------------------------------------------------
      -- errors/status
      ---------------------------------------------------------------------
      o_errors_sync   => errors_sync3,
      o_empty_sync    => empty_sync3
      );
  -- auto-read the FIFO
  rd3               <= '1' when empty3 = '0' and rd_rst_busy3 = '0' and i_fifo_prog_full = '0' else '0';
  data3             <= data_tmp3;
---------------------------------------------------------------------
-- output
---------------------------------------------------------------------
  o_fifo_data_valid <= data_valid3;
  o_fifo_data       <= data3;

---------------------------------------------------------------------
-- science_ddr3_stamp
---------------------------------------------------------------------
  inst_science_ddr3_stamp : entity work.science_ddr3_stamp
    port map(
      --  clock
      i_clk                         => i_clk,
      ---------------------------------------------------------------------
      -- input
      ---------------------------------------------------------------------
      -- data ddr write count
      i_buffer_new_cmd_byte_addr_wr => buffer_new_cmd_byte_addr_wr,
      -- data ddr read count
      i_buffer_new_cmd_byte_addr_rd => buffer_new_cmd_byte_addr_rd,
      ---------------------------------------------------------------------
      -- output
      ---------------------------------------------------------------------
      o_subtraction_addr_wr_addr_rd => o_ddr_stamp
      );


---------------------------------------------------------------------
-- errors/status
---------------------------------------------------------------------
  error_tmp(5) <= errors_sync3(2) or errors_sync3(3);  -- fifo rst error
  error_tmp(4) <= errors_sync3(1);                     -- fifo rd empty error
  error_tmp(3) <= errors_sync3(0);                     -- fifo wr full error
  error_tmp(2) <= errors_sync1(2) or errors_sync1(3);  -- fifo rst error
  error_tmp(1) <= errors_sync1(1);                     -- fifo rd empty error
  error_tmp(0) <= errors_sync1(0);                     -- fifo wr full error
  gen_errors_latch : for i in error_tmp'range generate
    inst_one_error_latch : entity work.one_error_latch
      port map(
        i_clk         => i_clk,
        i_rst         => i_rst_status,
        i_debug_pulse => i_debug_pulse,
        i_error       => error_tmp(i),
        o_error       => error_tmp_bis(i)
        );
  end generate gen_errors_latch;

  o_errors(15 downto 8) <= (others => '0');
  o_errors(7)           <= '0';
  o_errors(6)           <= error_tmp_bis(5);
  o_errors(5)           <= error_tmp_bis(4);
  o_errors(4)           <= error_tmp_bis(3);
  o_errors(3)           <= '0';
  o_errors(2)           <= error_tmp_bis(2);
  o_errors(1)           <= error_tmp_bis(1);
  o_errors(0)           <= error_tmp_bis(0);

  o_status(7 downto 2) <= (others => '0');
  o_status(1)          <= empty_sync3;
  o_status(0)          <= empty_sync1;

  ---------------------------------------------------------------------
  -- for simulation only
  ---------------------------------------------------------------------
  assert not (error_tmp_bis(5) = '1') report "[science_ddr3] => FIFO2 is used before the end of the initialization " severity error;
  assert not (error_tmp_bis(4) = '1') report "[science_ddr3] => FIFO2 read an empty FIFO" severity error;
  assert not (error_tmp_bis(3) = '1') report "[science_ddr3] => FIFO2 write a full FIFO" severity error;

  assert not (error_tmp_bis(2) = '1') report "[science_ddr3] => FIFO0 is used before the end of the initialization " severity error;
  assert not (error_tmp_bis(1) = '1') report "[science_ddr3] => FIFO0 read an empty FIFO" severity error;
  assert not (error_tmp_bis(0) = '1') report "[science_ddr3] => FIFO0 write a full FIFO" severity error;



end architecture RTL;
