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
--    @file                   tc_hk_spi_device_select.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This module distributes spi commands to the different devices of the FMC150 board (abaco system)
--    In particular, it manages the shared spi links (o_spi_sclk and o_spi_sdata) between the different devices.
--
--    Note:
--     . For the different devices, the user must build the corresponding full SPI words (typically: addr + data).
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg_system_tmtc.all;
use work.pkg_utils.all;


entity tc_hk_spi_device_select is
  generic (
    -- input FIFO DEPTH
    g_FIFO_DEPTH_IN : integer := 16;
    -- true: Enable the DEBUG TOOL (ILA, etc.), false: otherwise
    g_DEBUG         : boolean := false
    );
  port (
    -- clock
    i_clk         : in std_logic;
    -- reset
    i_rst         : in std_logic;
    -- reset error flag(s)
    i_rst_status  : in std_logic;
    -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s)
    i_debug_pulse : in std_logic;

    ---------------------------------------------------------------------
    -- command
    ---------------------------------------------------------------------
    -- input
    -- select the SPI chip
    i_spi_select : in std_logic;
    -- tc write data enable
    i_tc_valid   : in std_logic;
    -- tc write data
    i_tc         : in std_logic_vector(31 downto 0);

    -- output
    -- hk read data valid
    o_hk_valid : out std_logic;
    -- hk read data (device spi register value).
    o_hk       : out std_logic_vector(31 downto 0);
    -- 1: all spi links are ready,0: one of the spi link is busy
    o_ready    : out std_logic;

    ---------------------------------------------------------------------
    -- errors/status
    ---------------------------------------------------------------------
    -- errors
    o_errors : out std_logic_vector(15 downto 0);
    -- status
    o_status : out std_logic_vector(7 downto 0);

    ---------------------------------------------------------------------
    -- from/to the IOs
    ---------------------------------------------------------------------
    ---------------------------------------------------------------------
    -- from/to io: spi @i_clk
    ---------------------------------------------------------------------
    -- SPI --
    -- Shared SPI MISO
    i_spi_miso : in  std_logic;
    -- Shared SPI MOSI
    o_spi_mosi : out std_logic;
    -- Shared SPI clock line
    o_spi_sclk : out std_logic;
    -- SPI chip select
    o_spi_cs_n : out std_logic_vector(1 downto 0)

    );
end entity tc_hk_spi_device_select;

architecture RTL of tc_hk_spi_device_select is

  -- define the number of clock cycle between  SPI frame
  constant c_INTER_FRAME_TEMPO : integer := pkg_SPI_PAUSE;

  --! SPI: Serial word size vector bus size
  constant c_SPI_SER_WD_S_V_S : integer := work.pkg_utils.pkg_width_from_value(i_value => pkg_SPI_SER_WD_S) + 1;
  --! SPI: Serial word size vector
  constant c_SPI_SER_WD_S_V   : std_logic_vector(c_SPI_SER_WD_S_V_S-1 downto 0) :=
    std_logic_vector(to_unsigned(pkg_SPI_SER_WD_S, c_SPI_SER_WD_S_V_S));


  -- counter width
  constant c_CNT_WIDTH : integer := work.pkg_utils.pkg_width_from_value(i_value => c_INTER_FRAME_TEMPO);

  -- counter max value
  constant c_CNT_MAX : unsigned(c_CNT_WIDTH - 1 downto 0) := to_unsigned(c_INTER_FRAME_TEMPO - 1, c_CNT_WIDTH);

  ---------------------------------------------------------------------
  -- input FIFO
  ---------------------------------------------------------------------
  -- index0: low
  constant c_IDX0_L : integer := 0;
  -- index0: high
  constant c_IDX0_H : integer := c_IDX0_L + i_tc'length - 1;

  -- FIFO depth (expressed in number of words)
  constant c_FIFO_DEPTH        : integer := g_FIFO_DEPTH_IN;
  -- FIFO width (expressed in bits)
  constant c_FIFO_WIDTH        : integer := c_IDX0_H + 1;
  -- FIFO latency (in reading)
  constant c_FIFO_READ_LATENCY : integer := 2;


  -- fifo write side
  -- fifo: reset
  signal wr_rst_tmp0 : std_logic;
  -- fifo: write
  signal wr_tmp0     : std_logic;
  -- fifo: data_in
  signal data_tmp0   : std_logic_vector(c_FIFO_WIDTH - 1 downto 0);
  -- fifo: full flag
  --signal full0        : std_logic;
  -- fifo: rst_busy flag
  -- signal wr_rst_busy0 : std_logic; -- not used

  -- fifo read side
  -- fifo: read
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

  -- fifo resynchronized errors
  signal errors_sync1 : std_logic_vector(3 downto 0);
  -- fifo resynchronized empty flag
  signal empty_sync1  : std_logic;

---------------------------------------------------------------------
-- state machine
---------------------------------------------------------------------
  -- fsm type declaration
  type t_state is (E_RST, E_WAIT_CMD, E_RUN_SPI, E_INTER_FRAME_TEMPO);

  -- state
  signal sm_state_next : t_state;
  -- state (registered)
  signal sm_state_r1   : t_state := E_RST;

  -- input fifo read enable
  signal rd_next : std_logic;
  -- input fifo read enable (registered)
  signal rd_r1   : std_logic;

  -- select the SPI chip select
  signal spi_ras_select_next : std_logic;
  -- select the SPI chip select (registered)
  signal spi_ras_select_r1   : std_logic;

  -- hk read_valid
  signal rd_hk_valid_next : std_logic;
  -- hk read_valid (registered)
  signal rd_hk_valid_r1   : std_logic := '0';

  -- hk read data
  signal rd_hk_next : std_logic_vector(o_hk'range);
  -- hk read data (registered)
  signal rd_hk_r1   : std_logic_vector(o_hk'range) := (others => '0');

  -- ready flag
  signal ready_next : std_logic;
  -- ready flag (registered)
  signal ready_r1   : std_logic := '0';

  -- count the number of inter frame sample
  signal cnt_tempo_next : unsigned(c_CNT_WIDTH - 1 downto 0);
  -- count the number of inter frame sample (delayed)
  signal cnt_tempo_r1   : unsigned(c_CNT_WIDTH - 1 downto 0);

  ---------------------------------------------------------------------
  -- spi engine
  ---------------------------------------------------------------------
  -- cmd
  -- cdce spi bridge: read data valid
  signal spi_rd_data_valid : std_logic;
  -- cdce spi bridge: read data
  signal spi_rd_data       : std_logic_vector(31 downto 0);
  -- cdce spi bridge: ready
  signal spi_ready         : std_logic;
  -- cdce spi bridge: finish
  signal spi_finish        : std_logic;
  -- spi
  -- SPI clock
  signal spi_clk           : std_logic;
  -- SPI chip select
  signal spi_cs_n          : std_logic;
  -- SPI MOSI
  signal spi_mosi          : std_logic;

  ---------------------------------------------------------------------
  -- select spi link
  ---------------------------------------------------------------------
  -- spi: clock (registered)
  signal spi_clk_r1  : std_logic := '0';
  -- spi: mosi (registered)
  signal spi_mosi_r1 : std_logic := '0';
  -- spi cs_n (registered)
  signal spi_cs_n_r1 : std_logic_vector(o_spi_cs_n'range);

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

  ---------------------------------------------------------------------
  -- input FIFO
  ---------------------------------------------------------------------
  wr_rst_tmp0 <= i_rst;

  wr_tmp0                             <= i_tc_valid;
  data_tmp0(c_IDX0_H downto c_IDX0_L) <= i_tc;

  inst_fifo_sync_with_error : entity work.fifo_sync_with_error
    generic map(
      g_FIFO_MEMORY_TYPE  => "auto",
      g_FIFO_READ_LATENCY => c_FIFO_READ_LATENCY,
      g_FIFO_WRITE_DEPTH  => c_FIFO_DEPTH,
      g_READ_DATA_WIDTH   => data_tmp0'length,
      g_READ_MODE         => "std",
      g_WRITE_DATA_WIDTH  => data_tmp0'length
      )
    port map(
      ---------------------------------------------------------------------
      -- write side
      ---------------------------------------------------------------------
      i_wr_clk        => i_clk,
      i_wr_rst        => wr_rst_tmp0,
      i_wr_en         => wr_tmp0,
      i_wr_din        => data_tmp0,
      o_wr_full       => open,          -- not connected
      o_wr_rst_busy   => open,
      ---------------------------------------------------------------------
      -- read side
      ---------------------------------------------------------------------
      i_rd_en         => rd1,
      o_rd_dout_valid => data_valid_tmp1,
      o_rd_dout       => data_tmp1,
      o_rd_empty      => empty1,
      o_rd_rst_busy   => rd_rst_busy1,  -- not connected
      ---------------------------------------------------------------------
      -- resynchronized errors/status
      ---------------------------------------------------------------------
      o_errors_sync   => errors_sync1,
      o_empty_sync    => empty_sync1
      );

  rd1   <= '1' when rd_r1 = '1' and rd_rst_busy1 = '0' else '0';
  data1 <= data_tmp1(c_IDX0_H downto c_IDX0_L);


---------------------------------------------------------------------
-- state machine
--  It manages 2 steps:
--   1. read an input command
--   2. wait the spi engine response (reading)
---------------------------------------------------------------------
  p_decode_state : process (empty1, i_spi_select, rd_hk_r1, ready_r1,
                            sm_state_r1, spi_finish,
                            spi_ras_select_r1, spi_rd_data, spi_rd_data_valid,
                            spi_ready, cnt_tempo_r1) is
  begin
    rd_next             <= '0';
    spi_ras_select_next <= spi_ras_select_r1;
    rd_hk_valid_next    <= '0';
    rd_hk_next          <= rd_hk_r1;
    ready_next          <= ready_r1;
    cnt_tempo_next      <= cnt_tempo_r1;

    case sm_state_r1 is
      when E_RST =>
        ready_next    <= '0';
        sm_state_next <= E_WAIT_CMD;

      when E_WAIT_CMD =>
        spi_ras_select_next <= i_spi_select;
        cnt_tempo_next      <= (others => '0');

        if empty1 = '0' and spi_ready = '1' then
          -- read one input command
          rd_next       <= '1';
          ready_next    <= '0';
          sm_state_next <= E_RUN_SPI;
        else
          ready_next    <= '1';
          sm_state_next <= E_WAIT_CMD;

        end if;

      when E_RUN_SPI =>

        rd_hk_valid_next <= spi_rd_data_valid;
        rd_hk_next       <= spi_rd_data;

        -- wait the end of the spi transaction
        if spi_rd_data_valid = '1' then
          sm_state_next <= E_INTER_FRAME_TEMPO;
        else
          sm_state_next <= E_RUN_SPI;
        end if;

      when E_INTER_FRAME_TEMPO =>

        cnt_tempo_next <= cnt_tempo_r1 + 1;

        if cnt_tempo_r1 = c_CNT_MAX then
          sm_state_next <= E_WAIT_CMD;
        else
          sm_state_next <= E_INTER_FRAME_TEMPO;
        end if;

      when others =>
        sm_state_next <= E_RST;
    end case;
  end process p_decode_state;

  ---------------------------------------------------------------------
  -- State process : register signals
  ---------------------------------------------------------------------
  -- registered FSM signals
  p_state : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      if i_rst = '1' then
        sm_state_r1 <= E_RST;
      else
        sm_state_r1 <= sm_state_next;
      end if;
      -- to input fifo
      rd_r1             <= rd_next;
      -- others
      spi_ras_select_r1 <= spi_ras_select_next;
      -- to regdecode
      rd_hk_valid_r1    <= rd_hk_valid_next;
      rd_hk_r1          <= rd_hk_next;
      ready_r1          <= ready_next;
      cnt_tempo_r1      <= cnt_tempo_next;

    end if;
  end process p_state;

  o_ready <= ready_r1;

  -- to the regdecode
  o_hk_valid <= rd_hk_valid_r1;
  o_hk       <= rd_hk_r1;


---------------------------------------------------------------------
-- SPI engine
---------------------------------------------------------------------
  inst_spi_master_engine0 : entity work.spi_master
    generic map(
      g_CPOL               => pkg_SPI_CPOL,    --! Clock polarity
      g_CPHA               => pkg_SPI_CPHA,    --! Clock phase
      g_N_CLK_PER_SCLK_L   => pkg_SPI_SCLK_L,  --! Number of clock period for elaborating SPI Serial Clock low  level
      g_N_CLK_PER_SCLK_H   => pkg_SPI_SCLK_H,  --! Number of clock period for elaborating SPI Serial Clock high level
      g_N_CLK_PER_MISO_DEL => pkg_IO_SPI_MISO_LATENCY,  --! Number of clock period for miso signal delay from spi pin input to spi master input
      g_DATA_S             => pkg_SPI_SER_WD_S     --! Data bus size
      )
    port map(
      i_rst         => i_rst,  --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
      i_clk         => i_clk,           --! Clock
      i_start       => data_valid_tmp1,  --! Start transmit ('0' = Inactive, '1' = Active)
      i_ser_wd_s    => c_SPI_SER_WD_S_V,   --! Serial word size
      i_data_tx     => data1,           --! Data to transmit (stall on MSB)
      o_tx_busy_n   => spi_ready,  --! Transmit link busy ('0' = Busy, '1' = Not Busy)
      o_data_rx     => spi_rd_data,     --! Receipted data (stall on LSB)
      o_data_rx_rdy => spi_rd_data_valid,  --! Receipted data ready ('0' = Not ready, '1' = Ready)
      i_miso        => i_spi_miso,      --! SPI Master Input Slave Output
      o_mosi        => spi_mosi,        --! SPI Master Output Slave Input
      o_sclk        => spi_clk,         --! SPI Serial Clock
      o_cs_n        => spi_cs_n  --! SPI Chip Select ('0' = Active, '1' = Inactive)
      );


  ---------------------------------------------------------------------
  -- Select the spi link
  ---------------------------------------------------------------------
  p_select_spi_link : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      spi_clk_r1  <= spi_clk;
      spi_mosi_r1 <= spi_mosi;

      -- select the SPI device
      if spi_ras_select_r1 = '1' then
        -- select the RAS device
        spi_cs_n_r1(1) <= '1';
        spi_cs_n_r1(0) <= spi_cs_n;
      else
        -- select the DEMUX device
        spi_cs_n_r1(1) <= spi_cs_n;
        spi_cs_n_r1(0) <= '1';
      end if;
    end if;
  end process p_select_spi_link;
  ---------------------------------------------------------------------
  -- output
  ---------------------------------------------------------------------
  -- common: shared link between the spi
  o_spi_sclk <= spi_clk_r1;
  o_spi_mosi <= spi_mosi_r1;
  o_spi_cs_n <= spi_cs_n_r1;


  ---------------------------------------------------------------------
  -- Error latching
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

  o_errors(15 downto 3) <= (others => '0');
  o_errors(2)           <= error_tmp_bis(2);  -- fifo rst error
  o_errors(1)           <= error_tmp_bis(1);  -- fifo rd empty error
  o_errors(0)           <= error_tmp_bis(0);  -- fifo wr full error

  o_status(7 downto 1) <= (others => '0');
  o_status(0)          <= empty_sync1;  -- fifo empty

  ---------------------------------------------------------------------
  -- for simulation only
  ---------------------------------------------------------------------
  assert not (error_tmp_bis(2) = '1') report "[tc_hk_spi_device_select] => fifo is used before the end of the initialization " severity error;
  assert not (error_tmp_bis(1) = '1') report "[tc_hk_spi_device_select] => fifo read an empty FIFO" severity error;
  assert not (error_tmp_bis(0) = '1') report "[tc_hk_spi_device_select] => fifo write a full FIFO" severity error;

---------------------------------------------------------------------
-- debug
---------------------------------------------------------------------
  gen_debug : if g_DEBUG generate
  begin

    inst_ila_spi_select_top : entity work.ila_spi_select_top
      port map (
        clk => i_clk,

        -- probe0
        probe0(8) => i_rst,
        probe0(7) => i_rst_status,
        probe0(6) => i_debug_pulse,
        probe0(5) => rd_r1,
        probe0(4) => ready_r1,
        probe0(3) => spi_ready,
        probe0(2) => data_valid_tmp1,
        probe0(1) => rd_hk_valid_r1,
        probe0(0) => spi_ras_select_r1,

        -- probe1
        probe1(4)          => i_spi_miso,
        probe1(3)          => spi_mosi_r1,
        probe1(2)          => spi_clk_r1,
        probe1(1 downto 0) => spi_cs_n_r1,

        -- probe2
        probe2(63 downto 32) => data1,
        probe2(31 downto 0)  => rd_hk_r1,

        -- probe 3
        probe3(3)          => empty_sync1,
        probe3(2 downto 0) => error_tmp_bis
        );


  end generate gen_debug;


end architecture RTL;
