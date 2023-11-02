-- -------------------------------------------------------------------------------------------------------------
--                            Copyright (C) 2023-2030 Ken-ji de la ROSA, IRAP Toulouse.
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
--!   @file                   spi_mgt.vhd
--    reference design        Paul MARBEAU (IRAP Toulouse)
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--!   @details
--
--             Management of the SPI Link
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg_func_math.all;
use work.pkg_project.all;

entity spi_mgt is
  port(
    i_rst         : in std_logic;  --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
    i_clk         : in std_logic;  --! System Clock
    i_spi_data_tx : in std_logic_vector(pkg_DAC_SPI_SER_WD_S-1 downto 0);  --! Data to transmit
    i_miso        : in std_logic;  --! Serial data Master in Slave Out
    i_fifo_empty  : in std_logic;  --! Fifo State (Empty = '1', not Empty ='0')

    o_read_en    : out std_logic; --! Read Fifo next value
    o_data_ready : out std_logic; --! Receipted data ready ('0' = Not ready, '1' = Ready)
    o_data       : out std_logic_vector(pkg_DAC_SPI_SER_WD_S-1 downto 0);
    o_mosi       : out std_logic; --! DAC - Serial Data
    o_sclk       : out std_logic; --! Serial Clock
    o_sync_n     : out std_logic  --! Frame Synchronization ('0' = Active, '1' = Inactive)
    );
end entity spi_mgt;

architecture RTL of spi_mgt is
  constant c_SPI_SER_WD_S_V_S   : integer := log2_ceil(pkg_DAC_SPI_SER_WD_S+1);  --! DAC SPI: Serial word size vector bus size
  constant c_DAC_SPI_SER_WD_S_V : std_logic_vector(c_SPI_SER_WD_S_V_S-1 downto 0) :=
    std_logic_vector(to_unsigned(pkg_DAC_SPI_SER_WD_S, c_SPI_SER_WD_S_V_S));  --! DAC SPI: Serial word size vector

  signal spi_start_ry        : std_logic;  -- Starts SPI link (Active = '1', Inactive ='0')
  signal spi_tx_busy_n       : std_logic;  -- SPI link state (Not Busy = '1', Busy = '0')
  signal miso_r1             : std_logic;  -- Used to synchronize  i_miso
  signal miso_r2             : std_logic;  -- Used to synchronize  i_miso
  signal read_en_rx          : std_logic_vector(pkg_SPI_PAUSE-2 downto 0);  -- Used to create the delay between two communications.
  signal trig_first_value_r1 : std_logic;  -- Used to send only correct values to the EGSE
  signal data_ready          : std_logic;  -- data ready to be used from SPI point of view

begin

  -- ------------------------------------------------------------------------------------------------------
  --!   SPI master
  --    @Req :
  -- ------------------------------------------------------------------------------------------------------
  inst_dac_spi_master : entity work.spi_master
    generic map(
      g_CPOL               => pkg_DAC_SPI_CPOL,  -- Clock polarity
      g_CPHA               => pkg_DAC_SPI_CPHA,  -- Clock phase
      g_N_CLK_PER_SCLK_L   => pkg_DAC_SPI_SCLK_L,  -- Number of clock period for elaborating SPI Serial Clock low  level
      g_N_CLK_PER_SCLK_H   => pkg_DAC_SPI_SCLK_H,  -- Number of clock period for elaborating SPI Serial Clock high level
      g_N_CLK_PER_MISO_DEL => 2,  -- Number of clock period for miso signal delay from spi pin input to spi master input
      g_DATA_S             => pkg_DAC_SPI_SER_WD_S  -- Data bus size
      )
    port map(
      i_rst => i_rst,  -- Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
      i_clk => i_clk,  -- Clock

      i_start     => spi_start_ry,  -- Start transmit ('0' = Inactive, '1' = Active)
      i_ser_wd_s  => c_DAC_SPI_SER_WD_S_V,  -- Serial word size
      i_data_tx   => i_spi_data_tx,  -- Data to transmit (stall on MSB)
      o_tx_busy_n => spi_tx_busy_n,  -- Transmit link busy ('0' = Busy, '1' = Not Busy)

      o_data_rx     => o_data,  -- Receipted data (stall on LSB)
      o_data_rx_rdy => data_ready,  -- Receipted data ready ('0' = Not ready, '1' = Ready)

      i_miso => miso_r2,  -- SPI Master Input Slave Output
      o_mosi => o_mosi,  -- SPI Master Output Slave Input
      o_sclk => o_sclk,  -- SPI Serial Clock
      o_cs_n => o_sync_n  -- SPI Chip Select ('0' = Active, '1' = Inactive)
      );

  -- add a read tempo
  p_read_tempo : process (i_clk)
  begin

    if rising_edge(i_clk) then
      if i_rst = '1' then
        -- Initialisation
        read_en_rx          <= (others => '0');
        spi_start_ry        <= '0';
        miso_r1             <= '0';
        miso_r2             <= '0';
        trig_first_value_r1 <= '0';
      else
        if spi_tx_busy_n = '1' and read_en_rx = (read_en_rx'range => '0') and i_fifo_empty = '0'  -- Read one value with the appropriate delay
        then
          read_en_rx <= read_en_rx(read_en_rx'high -1 downto 0) & '1';
        else
          read_en_rx <= read_en_rx(read_en_rx'high -1 downto 0) & '0';
        end if;
        if read_en_rx(read_en_rx'high) = '1'
        then
          trig_first_value_r1 <= '1';
        end if;
        spi_start_ry <= read_en_rx(read_en_rx'high-1);  -- Start SPI communication
        miso_r2      <= miso_r1;        -- Synchronize  i_miso
        miso_r1      <= i_miso;
      end if;
    end if;
  end process p_read_tempo;

  o_read_en    <= read_en_rx(read_en_rx'high-1);  -- Buffer
  o_data_ready <= data_ready and trig_first_value_r1;

end architecture RTL;
