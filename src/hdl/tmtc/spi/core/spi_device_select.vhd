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
--    @file                   spi_device_select.vhd
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


entity spi_device_select is
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
    i_spi_cmd_select  : in std_logic;
    -- command valid
    i_spi_cmd_valid   : in std_logic;
    -- data to write
    i_spi_cmd_wr_data : in std_logic_vector(31 downto 0);

    -- output
    -- read data valid
    o_spi_rd_data_valid : out std_logic;
    -- read data (device spi register value).
    o_spi_rd_data       : out std_logic_vector(31 downto 0);
    -- 1: all spi links are ready,0: one of the spi link is busy
    o_spi_ready         : out std_logic;

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
end entity spi_device_select;

architecture RTL of spi_device_select is

  ---------------------------------------------------------------------
  -- input FIFO
  ---------------------------------------------------------------------
  -- index0: low
  constant c_IDX0_L : integer := 0;
  -- index0: high
  constant c_IDX0_H : integer := c_IDX0_L + i_spi_cmd_wr_data'length - 1;

  -- FIFO depth (expressed in number of words)
  constant c_FIFO_DEPTH        : integer := 256;
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
  type t_state is (E_RST, E_WAIT_CMD, E_RUN_SPI);

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




  -- read_valid
  signal rd_data_valid_next : std_logic;
  -- read_valid (registered)
  signal rd_data_valid_r1   : std_logic := '0';

  -- read data
  signal rd_data_next : std_logic_vector(o_spi_rd_data'range);
  -- read data (registered)
  signal rd_data_r1   : std_logic_vector(o_spi_rd_data'range) := (others => '0');

  -- ready flag
  signal ready_next : std_logic;
  -- ready flag (registered)
  signal ready_r1   : std_logic := '0';

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
  signal spi_cs_n_en       : std_logic;
  -- SPI MOSI
  signal spi_mosi          : std_logic;

  ---------------------------------------------------------------------
  -- select spi link
  ---------------------------------------------------------------------
  -- spi: clock (registered)
  signal spi_clk_r1   : std_logic := '0';
  -- spi: mosi (registered)
  signal spi_mosi_r1   : std_logic := '0';
  -- spi cs_n (registered)
  signal spi_cs_n_r1   : std_logic_vector(o_spi_cs_n'range);

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

  wr_tmp0                             <= i_spi_cmd_valid;
  data_tmp0(c_IDX0_H downto c_IDX0_L) <= i_spi_cmd_wr_data;

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
  p_decode_state : process (empty1, i_spi_cmd_select, rd_data_r1, ready_r1,
                            sm_state_r1, spi_finish,
                            spi_ras_select_r1, spi_rd_data, spi_rd_data_valid,
                            spi_ready) is
  begin
    rd_next             <= '0';
    spi_ras_select_next <= spi_ras_select_r1;
    rd_data_valid_next  <= '0';
    rd_data_next        <= rd_data_r1;
    ready_next          <= ready_r1;

    case sm_state_r1 is
      when E_RST =>
        ready_next    <= '0';
        sm_state_next <= E_WAIT_CMD;

      when E_WAIT_CMD =>
        spi_ras_select_next <= i_spi_cmd_select;

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

        rd_data_valid_next <= spi_rd_data_valid;
        rd_data_next       <= spi_rd_data;

        -- wait the end of the spi transaction
        if spi_finish = '1' then
          sm_state_next <= E_WAIT_CMD;
        else
          sm_state_next <= E_RUN_SPI;
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
      rd_data_valid_r1  <= rd_data_valid_next;
      rd_data_r1        <= rd_data_next;
      ready_r1          <= ready_next;

    end if;
  end process p_state;

  o_spi_ready <= ready_r1;

  -- to the regdecode
  o_spi_rd_data_valid <= rd_data_valid_r1;
  o_spi_rd_data       <= rd_data_r1;


---------------------------------------------------------------------
-- SPI engine
---------------------------------------------------------------------
  inst_spi_master_engine0 : entity work.spi_master
    generic map(
      g_CPOL                 => pkg_SPI_CPOL,        -- clock polarity
      g_CPHA                 => pkg_SPI_CPHA,        -- clock phase
      g_SYSTEM_FREQUENCY_HZ  => pkg_SPI_SYSTEM_FREQUENCY_HZ,  -- input system clock frequency  (expressed in Hz). The range is ]2*g_SPI_FREQUENCY_MAX_HZ: max_integer_value]
      g_SPI_FREQUENCY_MAX_HZ => pkg_SPI_SPI_FREQUENCY_MAX_HZ,  -- output max spi clock frequency (expressed in Hz)
      g_MOSI_DELAY           => pkg_SPI_MOSI_DELAY,  -- Number of clock period for mosi signal delay from state machine to the output
      g_MISO_DELAY           => pkg_SPI_MISO_DELAY,  -- Number of clock period for miso signal delay from spi pin input to spi master input
      g_DATA_WIDTH           => data1'length         -- Data bus size
      )
    port map(
      i_clk           => i_clk,         -- Clock
      i_rst           => i_rst,         -- Reset
      -- write side
      i_wr_rd         => '0',  -- 1:wr , 0:rd (generate a reading response)
      i_tx_msb_first  => '1',  -- 1: MSB bits sent first, 0: LSB bits sent first
      i_tx_data_valid => data_valid_tmp1,  -- Start transmit ('0' = Inactive, '1' = Active)
      i_tx_data       => data1,         -- Data to transmit (stall on MSB)
      o_ready         => spi_ready,  -- Transmit link busy ('0' = Busy, '1' = Not Busy)
      o_finish        => spi_finish,  -- pulse on finish (end of spi transaction: wr or rd)
      -- rd side
      o_rx_data_valid => spi_rd_data_valid,          -- received data valid
      o_rx_data       => spi_rd_data,  -- received data (device spi register value)
      ---------------------------------------------------------------------
      -- spi interface
      ---------------------------------------------------------------------
      i_miso          => i_spi_miso,  -- SPI MISO (Master Input - Slave Output)
      o_sclk          => spi_clk,       -- SPI Serial Clock
      o_cs_n          => spi_cs_n_en,  -- SPI Chip Select ('0' = Active, '1' = Inactive)
      o_mosi          => spi_mosi    -- SPI MOSI (Master Output - Slave Input)
      );


  ---------------------------------------------------------------------
  -- Select the spi link
  ---------------------------------------------------------------------
  p_select_spi_link: process (i_clk) is
  begin
    if rising_edge(i_clk) then
      spi_clk_r1  <= spi_clk;
      spi_mosi_r1 <= spi_mosi;

      -- select the SPI device
        if spi_ras_select_r1 = '1' then
          -- select the RAS device
          spi_cs_n_r1(1) <= '1';
          spi_cs_n_r1(0) <= spi_cs_n_en;
        else
          -- select the DEMUX device
          spi_cs_n_r1(1) <= spi_cs_n_en;
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
  assert not (error_tmp_bis(2) = '1') report "[spi_device_select] => fifo is used before the end of the initialization " severity error;
  assert not (error_tmp_bis(1) = '1') report "[spi_device_select] => fifo read an empty FIFO" severity error;
  assert not (error_tmp_bis(0) = '1') report "[spi_device_select] => fifo write a full FIFO" severity error;


end architecture RTL;
