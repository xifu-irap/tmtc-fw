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
--    @file                   io_science.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This module has the following functionnalities:
--       . convert the input differential signal into singled-ended
--       . pass data through the cross clock domain FIFO
--
--    The architecture is as follows:
--
--    i_science_ctrl_p/n ---> IO ---> fifo async --> o_science_ctrl
--    i_science_data_p/n ---> IO ---> fifo async --> o_science_data
--
--
--    LIMITATION:
--       . the input clocks must respect the following formula: i_science_clk <= i_sys_clk.
--         Otherwise, FIFO overflow
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.VComponents.all;

use work.pkg_system_tmtc.all;

entity io_science is
  generic (
    -- output FIFO depth
     g_FIFO_DEPTH_OUT : integer := pkg_IO_SCIENCE_FIFO_DEPTH
     );
  port (
    ---------------------------------------------------------------------
    -- from DEMUX: science interface @i_science_clk
    ---------------------------------------------------------------------
    -- differential_p science clock @62.5M
    i_science_clk_p : in std_logic;
    -- differential_n science clock @62.5M
    i_science_clk_n : in std_logic;

    -- Differential_p ctrl signal
    i_science_ctrl_p : in std_logic;
    -- Differential_n ctrl signal
    i_science_ctrl_n : in std_logic;

    -- Differential_p data
    i_science_data_p : in std_logic_vector(pkg_SC_LIGN_NUMBER_BY_COL - 1 downto 0);
    -- Differential_n data
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
    o_science_data       : out std_logic_vector(pkg_SC_LIGN_NUMBER_BY_COL - 1 downto 0)

    );
end entity io_science;

architecture RTL of io_science is

  ---------------------------------------------------------------------
  --  Xilinx IO
  ---------------------------------------------------------------------
  -- science ctrl signal
  signal science_ctrl : std_logic;
  -- science clock signal
  signal science_clk  : std_logic;
  -- science data signal
  signal science_data : std_logic_vector(i_science_data_p'range);

  ---------------------------------------------------------------------
  -- optional input delay
  ---------------------------------------------------------------------
  -- delayed science control signal
  signal science_ctrl_rx : std_logic;
  -- delayed science data signal
  signal science_data_rx : std_logic_vector(i_science_data_p'range);


  ---------------------------------------------------------------------
  -- output FIFO
  ---------------------------------------------------------------------
  -- index0: low
  constant c_IDX0_L : integer := 0;
  --index0: high
  constant c_IDX0_H : integer := c_IDX0_L + o_science_data'length - 1;

  -- index1: low
  constant c_IDX1_L : integer := c_IDX0_H + 1;
  --index1: high
  constant c_IDX1_H : integer := c_IDX1_L + 1 - 1;

  -- FIFO depth (expressed in number of words)
  constant c_FIFO_DEPTH        : integer := g_FIFO_DEPTH_OUT;
  -- FIFO width (expressed in bits)
  constant c_FIFO_WIDTH        : integer := c_IDX1_H + 1;
  -- FIFO latency (in reading)
  constant c_FIFO_READ_LATENCY : integer := 2;

  -- fifo write side
  -- fifo reset
  signal wr_rst_tmp0  : std_logic;
  -- fifo write
  signal wr_tmp0      : std_logic;
  -- fifo data_in
  signal data_tmp0    : std_logic_vector(c_FIFO_WIDTH - 1 downto 0);
  -- fifo full flag
  --signal full0        : std_logic;
  -- fifo rst_busy flag
  -- signal wr_rst_busy0 : std_logic;      -- not used

  -- fifo read side
  -- fifo read
  signal rd1          : std_logic;
  -- fifo data_out
  signal data_tmp1    : std_logic_vector(c_FIFO_WIDTH - 1 downto 0);
  -- fifo empty flag
  signal empty1       : std_logic;
  -- fifo rst_busy flag
  signal rd_rst_busy1 : std_logic;

  -- temporary data valid
  signal data_valid_tmp1 : std_logic;
  -- fifo data out
  signal data1           : std_logic_vector(c_FIFO_WIDTH - 1 downto 0);

  -- resynchronized science control
  signal science_ctrl1 : std_logic;
  -- resynchronized science data
  signal science_data1 : std_logic_vector(o_science_data'range);

begin

---------------------------------------------------------------------
-- Xilinx IO
---------------------------------------------------------------------

  inst_IBUFDS_science_clk : IBUFDS
    generic map (
      DIFF_TERM    => true,             -- Differential Termination
      IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD   => "DEFAULT")
    port map (
      O  => science_clk,                -- Buffer output
      I  => i_science_clk_p,  -- Diff_p buffer input (connect directly to top-level port)
      IB => i_science_clk_n  -- Diff_n buffer input (connect directly to top-level port)
      );

  inst_IBUFDS_science_ctrl : IBUFDS
    generic map (
      DIFF_TERM    => true,             -- Differential Termination
      IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD   => "DEFAULT")
    port map (
      O  => science_ctrl,               -- Buffer output
      I  => i_science_ctrl_p,  -- Diff_p buffer input (connect directly to top-level port)
      IB => i_science_ctrl_n  -- Diff_n buffer input (connect directly to top-level port)
      );


  GEN_IBUFDS_science_data : for i in 0 to i_science_data_p'length - 1 generate
    inst_IBUFDS_clk_science : IBUFDS
      generic map (
        DIFF_TERM    => true,           -- Differential Termination
        IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
        IOSTANDARD   => "DEFAULT")
      port map (
        O  => science_data(i),          -- Buffer output
        I  => i_science_data_p(i),  -- Diff_p buffer input (connect directly to top-level port)
        IB => i_science_data_n(i)  -- Diff_n buffer input (connect directly to top-level port)
        );
  end generate GEN_IBUFDS_science_data;

  ---------------------------------------------------------------------
  -- add optional input pipeliner
  ---------------------------------------------------------------------
  gen_pipeline : if true generate
    -- science ctrl temporary input pipe
    signal science_ctrl_tmp0 : std_logic_vector(0 downto 0);
    -- science ctrl temporary ouptut pipe
    signal science_ctrl_tmp1 : std_logic_vector(0 downto 0);
  begin

    science_ctrl_tmp0(0) <= science_ctrl;

    inst_pipeliner_with_init_science_ctrl : entity work.pipeliner_with_init
      generic map(
        g_INIT       => '0',
        g_NB_PIPES   => pkg_IO_SCIENCE_DELAY,
        g_DATA_WIDTH => science_ctrl_tmp0'length
        )
      port map(
        i_clk  => science_clk,
        i_data => science_ctrl_tmp0,
        o_data => science_ctrl_tmp1
        );
    science_ctrl_rx <= science_ctrl_tmp1(0);

    inst_pipeliner_with_init_science_data : entity work.pipeliner_with_init
      generic map(
        g_INIT       => '0',
        g_NB_PIPES   => pkg_IO_SCIENCE_DELAY,
        g_DATA_WIDTH => science_data'length
        )
      port map(
        i_clk  => science_clk,
        i_data => science_data,
        o_data => science_data_rx
        );

  end generate gen_pipeline;


  ---------------------------------------------------------------------
  -- output FIFO
  --  cross clock domain: @science_clk -> i_sys_clk
  ---------------------------------------------------------------------
  wr_rst_tmp0                         <= '0';
  wr_tmp0                             <= '1' when wr_rst_tmp0 = '0' else '0';
  data_tmp0(c_IDX1_H)                 <= science_ctrl_rx;
  data_tmp0(c_IDX0_H downto c_IDX0_L) <= science_data_rx;

  inst_fifo_async : entity work.fifo_async
    generic map(
      g_CDC_SYNC_STAGES   => 2,
      g_FIFO_MEMORY_TYPE  => "auto",
      g_FIFO_READ_LATENCY => c_FIFO_READ_LATENCY,
      g_FIFO_WRITE_DEPTH  => c_FIFO_DEPTH,
      g_READ_DATA_WIDTH   => data_tmp0'length,
      g_READ_MODE         => "std",
      g_RELATED_CLOCKS    => 0,
      g_WRITE_DATA_WIDTH  => data_tmp0'length
      )
    port map(
      ---------------------------------------------------------------------
      -- write side
      ---------------------------------------------------------------------
      i_wr_clk        => science_clk,
      i_wr_rst        => wr_rst_tmp0,
      i_wr_en         => wr_tmp0,
      i_wr_din        => data_tmp0,
      o_wr_full       => open,
      o_wr_rst_busy   => open,
      ---------------------------------------------------------------------
      -- read side
      ---------------------------------------------------------------------
      i_rd_clk        => i_sys_clk,
      i_rd_en         => rd1,
      o_rd_dout_valid => data_valid_tmp1,
      o_rd_dout       => data_tmp1,
      o_rd_empty      => empty1,
      o_rd_rst_busy   => rd_rst_busy1
      );

  rd1           <= '1' when empty1 = '0' and rd_rst_busy1 = '0' else '0';
  science_ctrl1 <= data_tmp1(c_IDX1_H);
  science_data1 <= data_tmp1(c_IDX0_H downto c_IDX0_L);

  ---------------------------------------------------------------------
  -- output
  ---------------------------------------------------------------------
  o_science_data_valid <= data_valid_tmp1;
  o_science_ctrl       <= science_ctrl1;
  o_science_data       <= science_data1;


end architecture RTL;
