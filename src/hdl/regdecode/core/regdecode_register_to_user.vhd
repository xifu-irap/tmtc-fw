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
--    @file                   regdecode_register_to_user.vhd
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
--   i_data ---------> async_fifo -------> o_fifo_data
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity regdecode_register_to_user is
  generic (
    -- data width
    g_DATA_WIDTH     : integer := 32;
    -- output FIFO DEPTH
    g_FIFO_DEPTH_OUT : integer := 16
    );
  port(
    ---------------------------------------------------------------------
    -- from usb:  @i_clk
    ---------------------------------------------------------------------
    -- input clock
    i_clk         : in std_logic;
    -- reset
    i_rst         : in std_logic;
    -- reset error flag(s)
    i_rst_status  : in std_logic;
    -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s)
    i_debug_pulse : in std_logic;

    -- input
    -- data
    i_data : in std_logic_vector(g_DATA_WIDTH - 1 downto 0);

    ---------------------------------------------------------------------
    -- to the user: @i_out_clk
    ---------------------------------------------------------------------
    -- output clock
    i_out_clk : in std_logic;

    -- fifo data valid
    o_fifo_data_valid : out std_logic;
    -- fifo data
    o_fifo_data       : out std_logic_vector(g_DATA_WIDTH - 1 downto 0);

    ---------------------------------------------------------------------
    -- errors/status @ i_clk
    ---------------------------------------------------------------------
    -- output errors
    o_errors : out std_logic_vector(15 downto 0);
    -- output status
    o_status : out std_logic_vector(7 downto 0)
    );
end entity regdecode_register_to_user;

architecture RTL of regdecode_register_to_user is
  ---------------------------------------------------------------------
  -- detect value change
  ---------------------------------------------------------------------
  -- auto-generated data valid
  signal data_valid_r1 : std_logic;
  -- delayed data
  signal data_r1       : std_logic_vector(i_data'range);

  ---------------------------------------------------------------------
  -- fifo cross clock domain
  ---------------------------------------------------------------------
  -- index0: low
  constant c_FIFO_IDX0_L : integer := 0;
  -- index0: high
  constant c_FIFO_IDX0_H : integer := c_FIFO_IDX0_L + i_data'length - 1;

  -- FIFO depth (expressed in number of words)
  constant c_FIFO_DEPTH0 : integer := g_FIFO_DEPTH_OUT;
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
  -- error latching
  ---------------------------------------------------------------------
  -- define the width of the temporary errors signals
  constant c_NB_ERRORS : integer := 3;
  -- temporary input errors
  signal error_tmp     : std_logic_vector(c_NB_ERRORS - 1 downto 0);
  -- temporary output errors
  signal error_tmp_bis : std_logic_vector(c_NB_ERRORS - 1 downto 0);

begin

-- detect a change on the input data value
  p_detect_value_change : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      data_r1 <= i_data;
      if data_r1 /= i_data then
        data_valid_r1 <= '1';
      else
        data_valid_r1 <= '0';
      end if;
    end if;
  end process p_detect_value_change;

---------------------------------------------------------------------
-- clock cross domain : @i_clk -> i_out_clk
---------------------------------------------------------------------
  wr_rst0                                          <= i_rst;
  wr_tmp0                                          <= data_valid_r1;
  wr_data_tmp0(c_FIFO_IDX0_H downto c_FIFO_IDX0_L) <= data_r1;

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
      g_SYNC_SIDE         => "wr"  -- define the clock side where status/errors is resynchronised. Possible value "wr" or "rd"
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
      o_wr_rst_busy   => open,
      ---------------------------------------------------------------------
      -- read side
      ---------------------------------------------------------------------
      i_rd_clk        => i_out_clk,
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

-- auto read when data is present in the fifo
  rd1 <= '1' when empty1 = '0' and rd_rst_busy1 = '0' else '0';

---------------------------------------------------------------------
-- output
---------------------------------------------------------------------
  o_fifo_data_valid <= data_valid1;
  o_fifo_data       <= data_tmp1;

---------------------------------------------------------------------
-- errors/status
---------------------------------------------------------------------
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

  o_errors(15 downto 4) <= (others => '0');
  o_errors(3)           <= '0';
  o_errors(2)           <= error_tmp_bis(2);
  o_errors(1)           <= error_tmp_bis(1);
  o_errors(0)           <= error_tmp_bis(0);

  o_status(7 downto 1) <= (others => '0');
  o_status(0)          <= empty_sync1;

  ---------------------------------------------------------------------
  -- for simulation only
  ---------------------------------------------------------------------
  assert not (error_tmp_bis(2) = '1') report "[regdecode_register_to_user] => FIFO0 is used before the end of the initialization " severity error;
  assert not (error_tmp_bis(1) = '1') report "[regdecode_register_to_user] => FIFO0 read an empty FIFO" severity error;
  assert not (error_tmp_bis(0) = '1') report "[regdecode_register_to_user] => FIFO0 write a full FIFO" severity error;

end architecture RTL;
