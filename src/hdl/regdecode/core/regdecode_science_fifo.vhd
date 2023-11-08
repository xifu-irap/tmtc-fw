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
--    @file                   regdecode_science_fifo.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--   @details
--
--
--
--   The architecture is as follows:
--
--   i_data -> async_fifo -> fifo_sync -> o_usb_fifo_data
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg_regdecode.all;
use work.pkg_utils.all;

entity regdecode_science_fifo is
  generic (
    g_DATA_WIDTH : integer := 32
    );
  port(
    ---------------------------------------------------------------------
    -- from the user:  @i_out_clk
    ---------------------------------------------------------------------
    -- input clock
    i_out_clk : in std_logic;
    -- reset
    i_out_rst : in std_logic;

    -- input data valid
    i_data_valid : in std_logic;
    -- input data
    i_data       : in std_logic_vector(g_DATA_WIDTH - 1 downto 0);

    ---------------------------------------------------------------------
    -- to the usb: @i_clk
    ---------------------------------------------------------------------
    -- output clock
    i_clk                    : in  std_logic;
    -- reset
    i_rst                    : in  std_logic;
    -- reset error flag(s)
    i_rst_status             : in  std_logic;
    -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s)
    i_debug_pulse            : in  std_logic;
    -- data
    -- fifo read enable
    i_usb_fifo_rd            : in  std_logic;
    -- fifo data valid
    o_usb_fifo_data_valid    : out std_logic;
    -- fifo data
    o_usb_fifo_data          : out std_logic_vector(g_DATA_WIDTH - 1 downto 0);
    -- fifo empty flag
    o_usb_fifo_empty         : out std_logic;
    -- fifo write data count
    o_usb_fifo_wr_data_count : out std_logic_vector(15 downto 0);
    ---------------------------------------------------------------------
    -- errors/status @ i_clk
    ---------------------------------------------------------------------
     -- output errors
    o_errors                 : out std_logic_vector(15 downto 0);
    -- output status
    o_status                 : out std_logic_vector(7 downto 0)
    );
end entity regdecode_science_fifo;

architecture RTL of regdecode_science_fifo is

  ---------------------------------------------------------------------
  -- fifo cross clock domain
  ---------------------------------------------------------------------
  -- index0: low
  constant c_FIFO_IDX0_L : integer := 0;
  -- index0: high
  constant c_FIFO_IDX0_H : integer := c_FIFO_IDX0_L + i_data'length - 1;

  -- FIFO depth (expressed in number of words)
  constant c_FIFO_DEPTH0 : integer := 16;
  -- FIFO width (expressed in bits)
  constant c_FIFO_WIDTH0 : integer := c_FIFO_IDX0_H + 1;

  -- fifo write side
  -- fifo rst
  signal wr_rst0      : std_logic;
  -- fifo write
  signal wr_tmp0      : std_logic;
  -- fifo data_in
  signal wr_data_tmp0 : std_logic_vector(c_FIFO_WIDTH0 - 1 downto 0);
  -- fifo full flag
  -- signal wr_full0      : std_logic;
  -- fifo rst_busy flag
  -- signal wr_rst_busy0  : std_logic;

  -- fifo read side
  -- fifo read
  signal rd1          : std_logic;
  -- fifo data_valid flag
  signal data_valid1  : std_logic;
  -- fifo data_out
  signal data_tmp1    : std_logic_vector(c_FIFO_WIDTH0 - 1 downto 0);
  -- fifo empty flag
  signal empty1       : std_logic;
  -- fifo rst_busy flag
  signal rd_rst_busy1 : std_logic;

  -- fifo resynchronized errors
  signal errors_sync1 : std_logic_vector(3 downto 0);
  -- fifo resynchronized empty flag
  signal empty_sync1  : std_logic;

  ---------------------------------------------------------------------
  -- output fifo
  ---------------------------------------------------------------------
  -- FIFO depth (expressed in number of words)
  constant c_FIFO_DEPTH2          : integer := pkg_SCIENCE_FIFO_DEPTH;
  -- FIFO width (expressed in bits)
  constant c_FIFO_WIDTH2          : integer := c_FIFO_IDX0_H + 1;
  -- FIFO write data count width (expressed in bits)
  constant c_WR_DATA_COUNT_WIDTH2 : integer := pkg_width_from_value(c_FIFO_DEPTH2) + 1;

  -- fifo write side
  -- fifo rst
  signal wr_rst2        : std_logic;
  -- fifo write
  signal wr_tmp2        : std_logic;
  -- fifo data_in
  signal wr_data_tmp2   : std_logic_vector(c_FIFO_WIDTH2 - 1 downto 0);
  -- fifo write data count
  signal wr_data_count2 : std_logic_vector(c_WR_DATA_COUNT_WIDTH2 - 1 downto 0);
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
  signal data_tmp3    : std_logic_vector(c_FIFO_WIDTH2 - 1 downto 0);
  -- fifo empty flag
  signal empty3       : std_logic;
  -- fifo rst_busy flag
  signal rd_rst_busy3 : std_logic;

  -- data
  signal data3 : std_logic_vector(o_usb_fifo_data'range);

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
  wr_rst0                                          <= i_out_rst;
  wr_tmp0                                          <= i_data_valid;
  wr_data_tmp0(c_FIFO_IDX0_H downto c_FIFO_IDX0_L) <= i_data;

  inst_fifo_async_with_error : entity work.fifo_async_with_error
    generic map(
      g_CDC_SYNC_STAGES   => 2,
      g_FIFO_MEMORY_TYPE  => "auto",
      g_FIFO_READ_LATENCY => 1,
      g_FIFO_WRITE_DEPTH  => c_FIFO_DEPTH0,
      g_READ_DATA_WIDTH   => wr_data_tmp0'length,
      g_READ_MODE         => "std",
      g_RELATED_CLOCKS    => 0,
      g_WRITE_DATA_WIDTH  => wr_data_tmp0'length,
      g_SYNC_SIDE         => "rd"  -- define the clock side where status/errors is resynchronised. Possible value "wr" or "rd"
      )
    port map(
      ---------------------------------------------------------------------
      -- write side
      ---------------------------------------------------------------------
      i_wr_clk        => i_out_clk,
      i_wr_rst        => wr_rst0,
      i_wr_en         => wr_tmp0,
      i_wr_din        => wr_data_tmp0,
      o_wr_full       => open,
      o_wr_rst_busy   => open,
      ---------------------------------------------------------------------
      -- read side
      ---------------------------------------------------------------------
      i_rd_clk        => i_clk,
      i_rd_en         => rd1,
      o_rd_dout_valid => data_valid1,
      o_rd_dout       => data_tmp1,
      o_rd_empty      => empty1,
      o_rd_rst_busy   => rd_rst_busy1,
      ---------------------------------------------------------------------
      -- resynchronized errors/ empty status
      ---------------------------------------------------------------------
      o_errors_sync   => errors_sync1,
      o_empty_sync    => empty_sync1
      );

---------------------------------------------------------------------
-- output FIFO
---------------------------------------------------------------------
  rd1 <= '1' when empty1 = '0' and rd_rst_busy1 = '0' else '0';

  wr_rst2      <= i_rst;
  wr_tmp2      <= data_valid1;
  wr_data_tmp2 <= data_tmp1;

  inst_fifo_sync_with_error_wr_count : entity work.fifo_sync_with_error_wr_count
    generic map(
      g_FIFO_MEMORY_TYPE    => "auto",
      g_FIFO_READ_LATENCY   => 1,
      g_FIFO_WRITE_DEPTH    => c_FIFO_DEPTH2,
      g_READ_DATA_WIDTH     => wr_data_tmp2'length,
      g_READ_MODE           => "std",
      g_WRITE_DATA_WIDTH    => wr_data_tmp2'length,
      g_WR_DATA_COUNT_WIDTH => c_WR_DATA_COUNT_WIDTH2
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
      o_wr_data_count => wr_data_count2,
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

  rd3                      <= i_usb_fifo_rd when rd_rst_busy3 = '0' else '0';
  data3                    <= data_tmp3(c_FIFO_IDX0_H downto c_FIFO_IDX0_L);
---------------------------------------------------------------------
-- output
---------------------------------------------------------------------
  o_usb_fifo_data_valid    <= data_valid3;
  o_usb_fifo_data          <= data3;
  o_usb_fifo_empty         <= empty3;
  o_usb_fifo_wr_data_count <= std_logic_vector(resize(unsigned(wr_data_count2), o_usb_fifo_wr_data_count'length));
---------------------------------------------------------------------
-- errors/status
---------------------------------------------------------------------
  error_tmp(5)             <= errors_sync3(2) or errors_sync3(3);  -- fifo rst error
  error_tmp(4)             <= errors_sync3(1);  -- fifo rd empty error
  error_tmp(3)             <= errors_sync3(0);  -- fifo wr full error
  error_tmp(2)             <= errors_sync1(2) or errors_sync1(3);  -- fifo rst error
  error_tmp(1)             <= errors_sync1(1);  -- fifo rd empty error
  error_tmp(0)             <= errors_sync1(0);  -- fifo wr full error
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
  assert not (error_tmp_bis(5) = '1') report "[regdecode_science_fifo] => FIFO2 is used before the end of the initialization " severity error;
  assert not (error_tmp_bis(4) = '1') report "[regdecode_science_fifo] => FIFO2 read an empty FIFO" severity error;
  assert not (error_tmp_bis(3) = '1') report "[regdecode_science_fifo] => FIFO2 write a full FIFO" severity error;

  assert not (error_tmp_bis(2) = '1') report "[regdecode_science_fifo] => FIFO0 is used before the end of the initialization " severity error;
  assert not (error_tmp_bis(1) = '1') report "[regdecode_science_fifo] => FIFO0 read an empty FIFO" severity error;
  assert not (error_tmp_bis(0) = '1') report "[regdecode_science_fifo] => FIFO0 write a full FIFO" severity error;

end architecture RTL;
