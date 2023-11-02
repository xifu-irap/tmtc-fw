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
--!   @file                   fmc_to_usb.vhd
--    reference design        Paul MARBEAU (IRAP Toulouse)
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--!   @details
--
--            Top of the TMTC firmware.
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.FRONTPANEL.all;
use work.science_data_rx_package.all;
use work.pkg_func_math.all;
use work.pkg_project_ok.all;
use work.pkg_project.all;

library unisim;
use unisim.VComponents.all;

use work.pkg_ram.all;

library xpm;
use xpm.vcomponents.all;

entity fmc_to_usb is
  generic (
    -- enable debug
    g_DEBUG : boolean := true
    );
  port(
    ---------------------------------------------------------------------
    -- Opal Kelly inouts
    ---------------------------------------------------------------------
    -- usb interface signal
    i_okUH  : in    std_logic_vector(4 downto 0);
    -- usb interface signal
    o_okHU  : out   std_logic_vector(2 downto 0);
    -- usb interface signal
    b_okUHU : inout std_logic_vector(31 downto 0);
    -- usb interface signal
    b_okAA  : inout std_logic;

    ---------------------------------------------------------------------
    -- DDR
    ---------------------------------------------------------------------
    -- DDR input differential_p clock
    i_sys_clkp : in std_logic;
    -- DDR input differential_n clock
    i_sys_clkn : in std_logic;

    -- inout  wire [DQ_WIDTH-1:0]  ddr3_dq,  //16
    ddr3_dq      : inout std_logic_vector (pkg_DQ_WIDTH-1 downto 0);
    -- output wire [ROW_WIDTH-1:0] ddr3_addr,  //15
    ddr3_addr    : out   std_logic_vector (pkg_ROW_WIDTH-1 downto 0);
    -- output wire [BANK_WIDTH-1:0] ddr3_ba,    //3
    ddr3_ba      : out   std_logic_vector (pkg_BANK_WIDTH-1 downto 0);
    -- output wire [CK_WIDTH-1:0] ddr3_ck_p,  //1
    ddr3_ck_p    : out   std_logic_vector (pkg_CK_WIDTH-1 downto 0);
    -- output wire [CK_WIDTH-1:0] ddr3_ck_n,
    ddr3_ck_n    : out   std_logic_vector (pkg_CK_WIDTH-1 downto 0);
    -- output wire [CKE_WIDTH-1:0] ddr3_cke,  //1
    ddr3_cke     : out   std_logic_vector (pkg_CKE_WIDTH-1 downto 0);
    -- output wire [(CS_WIDTH*nCS_PER_RANK)-1:0]  ddr3_cs_n,
    ddr3_cs_n    : out   std_logic_vector ((pkg_CS_WIDTH*pkg_nCS_PER_RANK)-1 downto 0);
    -- output wire ddr3_cas_n,
    ddr3_cas_n   : out   std_logic;
    -- output wire ddr3_ras_n,
    ddr3_ras_n   : out   std_logic;
    -- output wire ddr3_we_n,
    ddr3_we_n    : out   std_logic;
    -- output wire [(CS_WIDTH*nCS_PER_RANK)-1:0]  ddr3_odt,
    ddr3_odt     : out   std_logic_vector ((pkg_CS_WIDTH*pkg_nCS_PER_RANK)-1 downto 0);
    -- output wire [DM_WIDTH-1:0] ddr3_dm,  //2
    ddr3_dm      : out   std_logic_vector (pkg_DM_WIDTH-1 downto 0);
    -- inout wire [DQS_WIDTH-1:0]ddr3_dqs_p,  //2
    ddr3_dqs_p   : inout std_logic_vector (pkg_DQS_WIDTH-1 downto 0);
    -- inout wire [DQS_WIDTH-1:0]ddr3_dqs_n,
    ddr3_dqs_n   : inout std_logic_vector (pkg_DQS_WIDTH-1 downto 0);
    -- output wire ddr3_reset_n
    ddr3_reset_n : out   std_logic;

    ---------------------------------------------------------------------
    -- DEMUX
    ---------------------------------------------------------------------
    --  from DEMUX
    -- diffential_p science clock
    i_clk_science_p : in std_logic_vector(pkg_LINK_NUMBER-1 downto 0);
    -- diffential_n science clock
    i_clk_science_n : in std_logic_vector(pkg_LINK_NUMBER-1 downto 0);

    -- diffential_p control science
    i_science_ctrl_p : in std_logic_vector(pkg_LINK_NUMBER-1 downto 0);
    -- diffential_n control science
    i_science_ctrl_n : in std_logic_vector(pkg_LINK_NUMBER-1 downto 0);

    -- diffential_p data science
    i_science_data_p : in std_logic_vector(pkg_LINE_NUMBER-1 downto 0);
    -- diffential_n data science
    i_science_data_n : in std_logic_vector(pkg_LINE_NUMBER-1 downto 0);

    -- to DEMUX: SPI link
    -- Shared SPI MISO
    i_miso : in  std_logic;
    -- Shared SPI MOSI
    o_mosi : out std_logic;
    -- Shared SPI clock line
    o_sclk : out std_logic;
    -- SPI chip select
    o_cs_n : out std_logic_vector(1 downto 0);

    ---------------------------------------------------------------------
    -- LEDS
    ---------------------------------------------------------------------
    -- FMC 105 LEDS
    o_leds_fmc : out std_logic_vector(3 downto 0);
    -- Opal Kelly LEDs
    o_leds     : out std_logic_vector(3 downto 0);

    ---------------------------------------------------------------------
    -- ICU
    ---------------------------------------------------------------------
    -- ICU selection : 0 for main, 1 for redundant
    o_sel_main_n : out std_logic
    );
end entity;

architecture RTL of fmc_to_usb is
  -- ddr clock (user side)
  signal clk            : std_logic;
  -- ddr reset @clk (user side)
  signal ddr_rst        : std_logic;
  -- reset @usb_clk
  signal usb_rst        : std_logic;
  -- science reset
  signal rst_science0   : std_logic;

  --  usb_clk
  signal ok_clk : std_logic;
  -- usb interface signal
  signal okHE  : std_logic_vector(112 downto 0);
  -- usb interface signal
  signal okEH  : std_logic_vector(64 downto 0);
  -- usb interface signal
  signal okEHx : std_logic_vector(65*12-1 downto 0);

  ---------------------------------------------------------------------
  -- FIFO instrument
  ---------------------------------------------------------------------
  -- fifo instrument read enable
  signal read_instrument       : std_logic;
  -- fifo instrument empty
  signal empty_fifo_instrument : std_logic;

  -- fifo instrument full
  signal full_fifo_instrument       : std_logic;
  -- delayed fifo instrument full
  signal full_fifo_instrument_r1    : std_logic;
  -- delayed fifo instrument full
  signal full_fifo_instrument_r2    : std_logic;
  -- fifo instrument prog full
  signal prog_empty_fifo_instrument : std_logic;

  -- fifo instrument data valid
  signal valid_fifo_instrument : std_logic;
  -- fifo instrument input data
  signal dataout_instrument    : std_logic_vector(127 downto 0);
  -- fifo instrument write enable
  signal write_instrument      : std_logic;
  -- fifo instrument output data
  signal data_instrument       : std_logic_vector(127 downto 0);

  ---------------------------------------------------------------------
  -- FIFO fifo_r32_256_w32_256
  ---------------------------------------------------------------------
  -- fifo write enable
  signal pi0_ep_write   : std_logic;
  -- fifo input data
  signal pi0_ep_dataout : std_logic_vector(31 downto 0);
  -- fifo read enable
  signal pipe_in_read   : std_logic;
  -- fifo read data
  signal pipe_in_data   : std_logic_vector(31 downto 0);
  -- fifo empty
  signal pipe_in_empty  : std_logic;

  ---------------------------------------------------------------------
  -- FIFO fifo_r32_131068_w128_32728
  ---------------------------------------------------------------------
  -- fifo read enable
  signal po0_ep_read    : std_logic;
  -- fifo data output
  signal po0_ep_datain  : std_logic_vector(31 downto 0);
  -- fifo write enable
  signal pipe_out_write : std_logic;
  -- fifo input data
  signal pipe_out_data  : std_logic_vector(127 downto 0);
  -- fifo prog full
  signal pipe_out_full  : std_logic;
  -- fifo empty
  signal empty          : std_logic;
  -- fifo write data count
  signal wr_data_count  : std_logic_vector(14 downto 0);
  -- fifo read data count
  signal rd_data_count  : std_logic_vector(16 downto 0);

  --  wire
  -- wire in00
  signal ep00wire : std_logic_vector(31 downto 0);
  -- wire in01
  signal ep01wire : std_logic_vector(31 downto 0);
  -- wire in02
  signal ep02wire : std_logic_vector(31 downto 0);
  -- wire out00
  signal ep20wire : std_logic_vector(31 downto 0);
  -- wire out02
  signal ep22wire : std_logic_vector(31 downto 0);
  -- wire out03
  signal ep23wire : std_logic_vector(31 downto 0);
  -- wire out05
  signal ep25wire : std_logic_vector(31 downto 0);
  -- wire out06
  signal ep26wire : std_logic_vector(31 downto 0);
  -- wire out07
  signal ep27wire : std_logic_vector(31 downto 0);
  -- wire out30
  signal ep3Ewire : std_logic_vector(31 downto 0);
  -- wire out31
  signal ep3Fwire : std_logic_vector(31 downto 0);

  -- delayed wire out03
  signal ep23wire_r1 : std_logic_vector(31 downto 0);
  -- delayed wire out03
  signal ep23wire_r2 : std_logic_vector(31 downto 0);

  -- delayed wire out02
  signal ep22wire_r1 : std_logic_vector(31 downto 0);
  -- delayed wire out02
  signal ep22wire_r2 : std_logic_vector(31 downto 0);

  -- delayed wire out05
  signal ep25wire_r1 : std_logic_vector(31 downto 0);
  -- delayed wire out05
  signal ep25wire_r2 : std_logic_vector(31 downto 0);

  -- delayed wire out07
  signal ep27wire_r1 : std_logic_vector(31 downto 0);
  -- delayed wire out07
  signal ep27wire_r2 : std_logic_vector(31 downto 0);

  --  ddr3: read address (expressed in byte)
  signal buffer_new_cmd_byte_addr_rd : std_logic_vector(54 downto 0);
  --  ddr3: write address (expressed in byte)
  signal buffer_new_cmd_byte_addr_wr : std_logic_vector(54 downto 0);
  --  ddr3: computed delta between the write address and the read address
  signal Subtraction_addr_wr_addr_rd : std_logic_vector(54 downto 0);


-- Ajout d'un signal spi_chipselect_ras qui vient du XIFU Studio par l'USB pour definir
-- la valeur des chip select DEMUX et RAS de la prochaine commande SPI.
  signal spi_chipselect_ras : std_logic;

  -- DDR calibration is done
  signal init_calib_complete      : std_logic;
  -- DDR calibration is done (resynchronized)
  signal init_calib_complete_sync : std_logic;
  -- DDR input reset
  signal sys_rst_r1               : std_logic;
  -- DDR input reset counter
  signal rst_cnt_r1               : unsigned(4 downto 0) := (others => '0');

  -- address of the current request
  signal app_addr          : std_logic_vector (pkg_ADDR_WIDTH-1 downto 0);
  -- selects the command for the current request.
  signal app_cmd           : std_logic_vector (2 downto 0);
  -- This is the active-High strobe for the app_addr[], app_cmd[2:0], app_sz, and app_hi_pri inputs
  signal app_en            : std_logic;
  --  indicates that the UI is ready to accept commands.
  signal app_rdy           : std_logic;
  -- data from read commands
  signal app_rd_data       : std_logic_vector (pkg_APP_DATA_WIDTH-1 downto 0);
  -- indicates app_rd_data is valid
  signal app_rd_data_valid : std_logic;
  -- data for write commands.
  signal app_wdf_data      : std_logic_vector (pkg_APP_DATA_WIDTH-1 downto 0);
  -- indicates that the current clock cycle is the last cycle of input data on app_wdf_data[
  signal app_wdf_end       : std_logic;
  -- mask for app_wdf_data
  signal app_wdf_mask      : std_logic_vector (pkg_APP_MASK_WIDTH-1 downto 0);
  -- indicates that the write data FIFO is ready to receive data
  signal app_wdf_rdy       : std_logic;
  -- active-High strobe for app_wdf_data
  signal app_wdf_wren      : std_logic;

  ---------------------------------------------------------------------
  -- leds
  ---------------------------------------------------------------------
  -- counter for the blinked led
  signal cpt0_r1  : integer;
  -- count the number of science synchro word
  signal start_r1 : unsigned(3 downto 0);
  -- blinked led @science_clk
  signal led_r1   : std_logic;


  -- count the numbers of read science word
  signal rd_piper_out_r1 : unsigned(31 downto 0);

  --  HK output data
  signal pipe_out_data_hk  : std_logic_vector(31 downto 0);
  --  HK write enable
  signal pipe_out_write_hk : std_logic;

  ---------------------------------------------------------------------
  -- HK okPipeOut
  ---------------------------------------------------------------------
  -- HK read enable
  signal po0_ep_read_hk   : std_logic;
  -- HK input data
  signal po0_ep_datain_hk : std_logic_vector(31 downto 0);
  ---------------------------------------------------------------------
  -- HK wire_out
  ---------------------------------------------------------------------
  -- HK data count
  signal rd_data_count_hk : std_logic_vector(9 downto 0);

  ---------------------------------------------------------------------
  -- science
  ---------------------------------------------------------------------
  -- science data valid
  signal data_rate_enable : std_logic;

  -- science control (serialized)
  signal science_ctrl   : std_logic_vector(pkg_LINK_NUMBER - 1 downto 0);
  -- science clock
  signal clk_science    : std_logic_vector(pkg_LINK_NUMBER - 1 downto 0);
  -- science data (serialized)
  signal science_data   : std_logic_vector(pkg_LINE_NUMBER - 1 downto 0);
  -- detect the science synchro words
  signal start_detected : std_logic_vector(pkg_LINK_NUMBER-1 downto 0);

  -- endianess: swap bytes
  signal pipe_in_data_big_endian : std_logic_vector(31 downto 0);

  -- shared SPI chip select
  signal sync_n        : std_logic;
  -- Shared SPI MISO
  signal miso          : std_logic;
  -- Shared SPI MOSI
  signal mosi          : std_logic;
  -- Shared SPI clock line
  signal sclk          : std_logic;
  -- SPI chip select
  signal cs_n          : std_logic_vector(o_cs_n'range);
  -- ICU selection
  signal sel_main_n_r1 : std_logic;

  -- fpga specific attribute: force to use registers (very close)
  attribute ASYNC_REG                : string;
  -- apply attribute on ep23wire_r1
  attribute ASYNC_REG of ep23wire_r1 : signal is "TRUE";
  -- apply attribute on ep23wire_r2
  attribute ASYNC_REG of ep23wire_r2 : signal is "TRUE";

  -- apply attribute on ep22wire_r1
  attribute ASYNC_REG of ep22wire_r1 : signal is "TRUE";
  -- apply attribute on ep22wire_r2
  attribute ASYNC_REG of ep22wire_r2 : signal is "TRUE";

  -- apply attribute on ep25wire_r1
  attribute ASYNC_REG of ep25wire_r1 : signal is "TRUE";
  -- apply attribute on ep25wire_r2
  attribute ASYNC_REG of ep25wire_r2 : signal is "TRUE";

  -- apply attribute on ep27wire_r1
  attribute ASYNC_REG of ep27wire_r1 : signal is "TRUE";
  -- apply attribute on ep27wire_r2
  attribute ASYNC_REG of ep27wire_r2 : signal is "TRUE";

  -- led: count clock cycle
  signal cnt_r1 : unsigned(26 downto 0) := (others => '0');
  -- led: change state
  signal trig   : std_logic;

begin

  gen_IBUFDS_science_data : for i in 0 to pkg_LINE_NUMBER - 1 generate
    inst_IBUFDS_i : IBUFDS
      generic map (
        DIFF_TERM    => true,           -- Differential Termination
        IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
        IOSTANDARD   => "DEFAULT")
      port map (
        O  => science_data(i),          -- Buffer output
        I  => i_science_data_p(i),  -- Diff_p buffer input (connect directly to top-level port)
        IB => i_science_data_n(i)  -- Diff_n buffer input (connect directly to top-level port)
        );
  end generate;

  gen_IBUFDS_science_ctrl : for i in 0 to pkg_LINK_NUMBER - 1 generate
    inst_IBUFDS_science_ctrl : IBUFDS
      generic map (
        DIFF_TERM    => true,           -- Differential Termination
        IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
        IOSTANDARD   => "DEFAULT")
      port map (
        O  => science_ctrl(i),          -- Buffer output
        I  => i_science_ctrl_p(i),  -- Diff_p buffer input (connect directly to top-level port)
        IB => i_science_ctrl_n(i)  -- Diff_n buffer input (connect directly to top-level port)
        );
  end generate;

  gen_IBUFDS_clk_science : for i in 0 to pkg_LINK_NUMBER - 1 generate
    inst_IBUFDS_clk_science : IBUFDS
      generic map (
        DIFF_TERM    => true,           -- Differential Termination
        IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
        IOSTANDARD   => "DEFAULT")
      port map (
        O  => clk_science(i),           -- Buffer output
        I  => i_clk_science_p(i),  -- Diff_p buffer input (connect directly to top-level port)
        IB => i_clk_science_n(i)  -- Diff_n buffer input (connect directly to top-level port)
        );
  end generate;

-- Gestion de o_cs_n sur 2 bits
-- le spi_chipselect_ras est utilise pour "orienter" le o_sync_n vers le DEMUX ou le RAS
-- si spi_chipselect_ras = 1 on selectionne le RAS

----------------------------------------------------
--  SPI
----------------------------------------------------

  inst_spi_mgt : entity work.spi_mgt
    port map(
      i_rst         => ddr_rst,
      i_clk         => clk,
      i_spi_data_tx => pipe_in_data_big_endian,
      i_miso        => miso,
      i_fifo_empty  => pipe_in_empty,

      o_read_en    => pipe_in_read,
      o_data_ready => pipe_out_write_hk,
      o_data       => pipe_out_data_hk,
      o_mosi       => mosi,
      o_sclk       => sclk,
      o_sync_n     => sync_n
      );

  cs_n(0) <= sync_n when spi_chipselect_ras = '1' else '1';  -- Chip select _n for RAS
  cs_n(1) <= sync_n when spi_chipselect_ras = '0' else '1';  -- Chip select _n for DEMUX (in the future, maybe there will be more DEMUX)

  -- endianess: swap bytes
  pipe_in_data_big_endian <= pipe_in_data(7 downto 0) & pipe_in_data(15 downto 8) & pipe_in_data(23 downto 16) & pipe_in_data(31 downto 24);

  ---------------------------------------------------------------------
  -- SPI_IO
  ---------------------------------------------------------------------
  inst_io_spi : entity work.io_spi
    generic map(
      g_SPI_CS_N_WIDTH => cs_n'length
      )
    port map(
      ---------------------------------------------------------------------
      -- from/to FPGA io: spi @i_sys_spi_clk
      ---------------------------------------------------------------------
      i_sys_spi_clk => clk,             -- system spi clock
      -- SPI --
      i_spi_miso    => i_miso,          -- Shared SPI MISO
      o_spi_mosi    => o_mosi,          -- Shared SPI MOSI
      o_spi_sclk    => o_sclk,          -- Shared SPI clock line
      o_spi_cs_n    => o_cs_n,          -- SPI chip select
      ---------------------------------------------------------------------
      -- to user: spi interface @i_sys_spi_clk
      ---------------------------------------------------------------------
      -- SPI --
      o_ui_spi_miso => miso,            -- Shared SPI MISO
      i_ui_spi_mosi => mosi,            -- Shared SPI MOSI
      i_ui_spi_sclk => sclk,            -- Shared SPI clock line
      i_ui_spi_cs_n => cs_n             -- SPI chip select
      );

----------------------------------------------------
--  OPAL KELLY LEDs
--    inversed logical:
--      led off: led <= '1';
--      led on:  led <= '0';
----------------------------------------------------
  p_clock_science_link0 : process (clk_science(0))
  begin

    if rising_edge(clk_science(0)) then
      if rst_science0 = '1' then
        cpt0_r1 <= 0;
        led_r1  <= '1';
      else
        cpt0_r1 <= cpt0_r1 + 1;
        if start_detected(0) = '1' then
          start_r1 <= start_r1 + 1;
        end if;
        if cpt0_r1 = 1000000 then
          if start_r1 = "0000" then
            led_r1 <= '0';
          else
            led_r1 <= '1';
          end if;
          cpt0_r1 <= 0;
        end if;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------
  -- detect @clk alive
  ---------------------------------------------------------------------
  p_blink : process (clk) is
  begin
    if rising_edge(clk) then
      cnt_r1 <= cnt_r1 + 1;
    end if;
  end process p_blink;

  trig <= cnt_r1(cnt_r1'high);

  -- leds
  o_leds(0) <= not('1');
  o_leds(1) <= not(init_calib_complete);
  o_leds(2) <= led_r1;
  o_leds(3) <= trig;
----------------------------------------------------
--  RESET
----------------------------------------------------
  usb_rst   <= ep00wire(0);

----------------------------------------------------
--  FMC 105 LEDs
----------------------------------------------------
  p_leds : process (ok_clk)
  begin
    if rising_edge(ok_clk)then
      o_leds_fmc(0) <= '1';
      o_leds_fmc(1) <= cs_n(0);
      o_leds_fmc(2) <= cs_n(1);
      o_leds_fmc(3) <= sel_main_n_r1;
    end if;
  end process;

----------------------------------------------------
--  Controller DDR3
----------------------------------------------------
  inst_ddr3_256_16 : entity work.ddr3_256_16
    port map (
--// Memory interface ports
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
--// Application interface ports
      app_addr          => app_addr,
      app_cmd           => app_cmd,
      app_en            => app_en,
      app_wdf_data      => app_wdf_data,
      app_wdf_end       => app_wdf_end,
      app_wdf_wren      => app_wdf_wren,
      app_rd_data       => app_rd_data,
      app_rd_data_end   => open,
      app_rd_data_valid => app_rd_data_valid,
      app_rdy           => app_rdy,
      app_wdf_rdy       => app_wdf_rdy,
      app_sr_req        => '0',
      app_sr_active     => open,
      app_ref_req       => '0',
      app_ref_ack       => open,
      app_zq_req        => '0',
      app_zq_ack        => open,
      ui_clk            => clk,
      ui_clk_sync_rst   => ddr_rst,

      app_wdf_mask => app_wdf_mask,

--// System Clock Ports
      sys_clk_p => i_sys_clkp,
      sys_clk_n => i_sys_clkn,

      device_temp => open,

      sys_rst => sys_rst_r1

      );

  --//MIG Infrastructure Reset
  p_reset_mig : process (ok_clk)
  begin

    if rising_edge(ok_clk) then
      if usb_rst = '1' then
        rst_cnt_r1 <= (others => '0');
        sys_rst_r1 <= '1';
      else
        if(rst_cnt_r1 < "1000") then
          rst_cnt_r1 <= rst_cnt_r1 + 1;
          sys_rst_r1 <= '1';
        else
          sys_rst_r1 <= '0';
        end if;
      end if;
    end if;
  end process p_reset_mig;

----------------------------------------------------
--  Controller DDR3
----------------------------------------------------
  inst_drive_interface_ddr3_ctrl : entity work.drive_interface_ddr3_ctrl
    port map (

      i_clk => clk,
      i_rst => ddr_rst,

      ---------------------------------------------------------------------
      -- DDR status
      ---------------------------------------------------------------------
      i_calib_done => init_calib_complete,

      ---------------------------------------------------------------------
      -- input FIFO
      ---------------------------------------------------------------------
      o_pipe_in_read => read_instrument,
      i_pipe_in_data => data_instrument,

      i_pipe_in_valid => valid_fifo_instrument,
      i_pipe_in_empty => empty_fifo_instrument,
      i_prog_empty    => prog_empty_fifo_instrument,

      ---------------------------------------------------------------------
      -- output FIFO
      ---------------------------------------------------------------------
      o_pipe_out_write => pipe_out_write,
      o_pipe_out_data  => pipe_out_data,
      i_pipe_out_full  => pipe_out_full,

      ---------------------------------------------------------------------
      -- DDR data
      ---------------------------------------------------------------------
      i_app_rdy  => app_rdy,            --: STD_LOGIC;
      o_app_en   => app_en,             --: STD_LOGIC
      o_app_cmd  => app_cmd,            --: STD_LOGIC_VECTOR  (2 downto 0);
      o_app_addr => app_addr,  --: STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0); --ADDR_WIDTH            : integer := 29;

      i_app_rd_data       => app_rd_data,  --: STD_LOGIC_VECTOR  (APP_DATA_WIDTH-1 downto 0);  --constant APP_DATA_WIDTH        :  integer := 128;
      i_app_rd_data_valid => app_rd_data_valid,  --: STD_LOGIC;

      i_app_wdf_rdy  => app_wdf_rdy,    --: STD_LOGIC;
      o_app_wdf_wren => app_wdf_wren,   --: STD_LOGIC;
      o_app_wdf_data => app_wdf_data,  --: STD_LOGIC_VECTOR  (APP_DATA_WIDTH-1 downto 0);  --constant APP_DATA_WIDTH        :  integer := 128;
      o_app_wdf_end  => app_wdf_end,    --: STD_LOGIC;
      o_app_wdf_mask => app_wdf_mask,  --: STD_LOGIC_VECTOR  (APP_MASK_WIDTH-1 downto 0);  --constant APP_DATA_WIDTH        :  integer := 128;


      ---------------------------------------------------------------------
      -- status
      ---------------------------------------------------------------------
      o_buffer_new_cmd_byte_addr_wr => buffer_new_cmd_byte_addr_wr,
      o_buffer_new_cmd_byte_addr_rd => buffer_new_cmd_byte_addr_rd

      );

----------------------------------------------------
--  Controller DDR3
----------------------------------------------------
  inst_ddr_stamp : entity work.ddr_stamp
    port map (

      --  global
      i_clk => clk,
      i_rst => ddr_rst,

      --  input
      i_buffer_new_cmd_byte_addr_wr => buffer_new_cmd_byte_addr_wr,
      i_buffer_new_cmd_byte_addr_rd => buffer_new_cmd_byte_addr_rd,

      --  output
      o_sub_addr_wr_addr_rd => Subtraction_addr_wr_addr_rd
      );

  ep23wire <= Subtraction_addr_wr_addr_rd(31 downto 0);

-- ----------------------------------------------------
-- manage ep20wire
-- ----------------------------------------------------
  inst_manaage_pipe_out : entity work.manage_pipe_out
    port map (
      --  global
      i_ok_clk => ok_clk,
      i_rst    => usb_rst,

      --  fifo interface
      i_rd_data_count => rd_data_count,

      --  ctrl interface

      o_result => ep20wire

      );

-- ----------------------------------------------------
-- meta wire out
-- ----------------------------------------------------
-- resynchronized register
  p_synchronized_register : process (ok_clk)
  begin

    if rising_edge (ok_clk) then
      ep23wire_r1 <= ep23wire;
      ep23wire_r2 <= ep23wire_r1;

      ep22wire_r1 <= ep22wire;
      ep22wire_r2 <= ep22wire_r1;

      ep25wire_r1 <= ep25wire;
      ep25wire_r2 <= ep25wire_r1;

      ep27wire_r1 <= ep27wire;
      ep27wire_r2 <= ep27wire_r1;
    end if;
  end process p_synchronized_register;

----------------------------------------------------
--  ok wire host
----------------------------------------------------
  inst_okHost : okHost
    port map(

      okUH   => i_okUH,
      okHU   => o_okHU,
      okUHU  => b_okUHU,
      okAA   => b_okAA,  --//temp removed for SIMULATION replace Core
      ok_clk => ok_clk,                   --out
      okHE   => okHE,
      okEH   => okEH

      );

----------------------------------------------------
--  ok wire OR
----------------------------------------------------
  inst_okWireOR : okWireOR generic map (N => 12)
    port map (
      okEH  => okEH,
      okEHx => okEHx
      );

----------------------------------------------------
--  ok wire in
----------------------------------------------------
  inst_okWireIn : okWireIn
    port map (
      okHE       => okHE,
      ep_addr    => x"00",
      ep_dataout => ep00wire
      );


-- Le signal spi_chipselect_ras est recu sur le wire x"01"
-- La valeur au reset est fixee a: spi_chipselect_ras = '1'
-- Relecture du spi_chipselect_ras sur le wire x"24"
  inst_okWireIn_chipselect : okWireIn
    port map (
      okHE       => okHE,
      ep_addr    => x"01",
      ep_dataout => ep01wire
      );

  inst_okWireIn_icu_main : okWireIn
    port map (
      okHE       => okHE,
      ep_addr    => x"02",
      ep_dataout => ep02wire
      );

  -- add an output register to the sel_main_n signal
  p_pipe : process (ok_clk)
  begin
    if rising_edge(ok_clk)then
      sel_main_n_r1 <= ep02wire(0);
    end if;
  end process p_pipe;

  o_sel_main_n <= sel_main_n_r1;

  ---------------------------------------------------------------------
  -- resynchronize shi
  ---------------------------------------------------------------------
  gen_spi_chipselect_ras : if true generate
    -- temporary input pipe signal
    signal data_tmp0 : std_logic_vector(0 downto 0);
    -- temporary output pipe signal
    signal data_tmp1 : std_logic_vector(0 downto 0);
  begin
    data_tmp0(0) <= ep01wire(0);
    inst_synchronizer_spi_chipselect_ras : entity work.synchronizer
      generic map(
        g_INIT            => '0',  -- Initial value of synchronizer registers upon startup, 1'b0 or 1'b1.
        g_SYNC_STAGES     => 2,  -- Integer value for number of synchronizing registers, must be 2 or higher
        g_PIPELINE_STAGES => 1,  -- Integer value for number of registers on the output of the synchronizer for the purpose of improving performance. Possible values: [1; integer max value [
        g_DATA_WIDTH      => data_tmp0'length  -- data width expressed in bits
        )
      port map(
        i_async_data => data_tmp0,      -- async input
        i_clk        => clk,            -- output clock signal
        o_data       => data_tmp1       -- output data with/without delay
        );
    spi_chipselect_ras <= data_tmp1(0);
  end generate gen_spi_chipselect_ras;


----------------------------------------------------
--  ok wire out
----------------------------------------------------
  inst_okWireOut_spi_chipselect_ras : okWireOut
    port map (
      okHE      => okHE,
      okEH      => okEHx(1*65-1 downto 0*65),
      ep_addr   => x"24",
      ep_datain => ep01wire
      );


----------------------------------------------------
--  ok pipe out
----------------------------------------------------
  inst_okPipeOut : okPipeOut            --okBTPipeOut
    port map (
      okHE    => okHE,
      okEH    => okEHx(2*65-1 downto 1*65),
      ep_addr => x"A0",
      ep_read => po0_ep_read,

      ep_datain => po0_ep_datain

      );

----------------------------------------------------
--  ok wire out full flag
----------------------------------------------------
  inst_okWireOut_full : okWireOut
    port map (
      okHE      => okHE,
      okEH      => okEHx(3*65-1 downto 2*65),
      ep_addr   => x"22",
      ep_datain => ep22wire_r2
      );

----------------------------------------------------
--  ok wire out ddr3 stamp lsb
----------------------------------------------------
  inst_okWireOut_ddr3_stamp_lsb : okWireOut
    port map (
      okHE      => okHE,
      okEH      => okEHx(4*65-1 downto 3*65),
      ep_addr   => x"23",
      ep_datain => ep23wire_r2
      );

----------------------------------------------------
--  ok wire out ddr3 stamp msb
----------------------------------------------------
  inst_okWireOut_ddr3_stamp_msb : okWireOut
    port map (
      okHE      => okHE,
      okEH      => okEHx(5*65-1 downto 4*65),
      ep_addr   => x"21",
      ep_datain => ep20wire
      );

----------------------------------------------------
--  ok wire out debug
----------------------------------------------------
  inst_okWireOut_debug : okWireOut
    port map (
      okHE      => okHE,
      okEH      => okEHx(6*65-1 downto 5*65),
      ep_addr   => x"25",
      ep_datain => ep25wire_r2
      );

----------------------------------------------------
--  ok wire out HK
----------------------------------------------------
  inst_okWireOut_hk : okWireOut
    port map (
      okHE      => okHE,
      okEH      => okEHx(7*65-1 downto 6*65),
      ep_addr   => x"26",
      ep_datain => ep26wire
      );

----------------------------------------------------
--  ok wire debug
----------------------------------------------------
  inst_okWireOut_debug1 : okWireOut
    port map (
      okHE      => okHE,
      okEH      => okEHx(8*65-1 downto 7*65),
      ep_addr   => x"27",
      ep_datain => ep27wire_r2
      );

----------------------------------------------------
--  ok wire firmware_name
----------------------------------------------------
-- Ajout de la gestion du firmware name
  ep3Ewire <= x"544D5443";              -- TMTC: hex ASCII CODE

  inst_okWireOut_fw_name : okWireOut
    port map (
      okHE      => okHE,
      okEH      => okEHx(9*65-1 downto 8*65),
      ep_addr   => x"3E",
      ep_datain => ep3Ewire
      );


----------------------------------------------------
--  ok wire firmware_id
----------------------------------------------------
-- Ajout de la gestion du firmware id
  ep3Fwire <= std_logic_vector(to_unsigned(16#11#, ep3Fwire'length));  -- 0x11

  inst_okWireOut_fw_id : okWireOut
    port map (
      okHE      => okHE,
      okEH      => okEHx(10*65-1 downto 9*65),
      ep_addr   => x"3F",
      ep_datain => ep3Fwire
      );


----------------------------------------------------
--  ok pipe out hk
----------------------------------------------------
  inst_okPipeOut_hk : okPipeOut         --okBTPipeOut
    port map (
      okHE      => okHE,
      okEH      => okEHx(11*65-1 downto 10*65),
      ep_addr   => x"A1",
      ep_read   => po0_ep_read_hk,
      ep_datain => po0_ep_datain_hk
      );

----------------------------------------------------
--  ok pipe in
----------------------------------------------------
  inst_okPipeIn : okPipeIn              --okBTPipeIn
    port map (
      okHE       => okHE,
      okEH       => okEHx(12*65-1 downto 11*65),
      ep_addr    => x"80",
      ep_write   => pi0_ep_write,
      ep_dataout => pi0_ep_dataout
      );

  ---------------------------------------------------------------------
  -- FIFO status
  ---------------------------------------------------------------------
  -- register: get the FIFO status
  p_status_fifo : process (clk)
  begin


    if rising_edge (clk) then
      --  meta
      full_fifo_instrument_r1 <= full_fifo_instrument;
      full_fifo_instrument_r2 <= full_fifo_instrument_r1;

      ep22wire(2) <= '0';
      ep22wire(3) <= '0';
      ep22wire(4) <= empty;
      ep22wire(5) <= empty_fifo_instrument;
      ep22wire(6) <= '0';

      --  detect error
      if pipe_out_full = '1' and full_fifo_instrument_r2 = '0' then
        ep22wire(0) <= '1';
      else
        if pipe_out_full = '0' and full_fifo_instrument_r2 = '1' then
          ep22wire(1) <= '1';
        else
          if pipe_out_full = '1' and full_fifo_instrument_r2 = '1' then
            ep22wire(1) <= '1';
            ep22wire(0) <= '1';
          end if;
        end if;
      end if;

    end if;
  end process p_status_fifo;

---------------------------------------------------------------------
-- MIG lock
---------------------------------------------------------------------
-- resynchronized the init_calib_complete
  inst_xpm_cdc_single_init_calib_complete : xpm_cdc_single
    generic map (
      DEST_SYNC_FF   => 3,              -- DECIMAL; range: 2-10
      INIT_SYNC_FF   => 0,  -- DECIMAL; 0=disable simulation init values, 1=enable simulation init values
      SIM_ASSERT_CHK => 0,  -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      SRC_INPUT_REG  => 1  -- DECIMAL; 0=do not register input, 1=register input
      )
    port map (
      dest_out => init_calib_complete_sync,  -- 1-bit output: src_in synchronized to the destination clock domain. This output
      -- is registered.

      dest_clk => clk_science(0),  -- 1-bit input: Clock signal for the destination clock domain.
      src_clk  => clk,  -- 1-bit input: optional; required when SRC_INPUT_REG = 1
      src_in   => init_calib_complete  -- 1-bit input: Input signal to be synchronized to dest_clk domain.
      );

---------------------------------------------------------------
--      instrument fifo
---------------------------------------------------------------
  inst_instrument_fifo_in : entity work.fifo_w32_131068_r128_32728
    port map (
      rst           => rst_science0,
      wr_clk        => clk_science(0),
      rd_clk        => clk,
      din           => dataout_instrument,  --  pi0_ep_dataout  for test with pipe in (small packet)
      wr_en         => write_instrument,  --  pi0_ep_write  for test with pipe in (small packet)
      rd_en         => read_instrument,
      dout          => data_instrument,   --// Bus [127 : 0]
      full          => full_fifo_instrument,
      empty         => empty_fifo_instrument,
      valid         => valid_fifo_instrument,
      rd_data_count => open,            --// Bus [7 : 0]
      wr_data_count => open,            --// Bus [9 : 0]
      prog_empty    => prog_empty_fifo_instrument


      );

  rst_science0_n <= init_calib_complete_sync;


---------------------------------------------------------------
--   RX - Top level
---------------------------------------------------------------
  inst_science_data_rx : entity work.science_data_rx port map
    (

      i_rst         => rst_science0,
      i_clk_science => clk_science,

      -- Link

      o_start_detected => start_detected,

      i_science_ctrl => science_ctrl,
      i_science_data => science_data,
      i_data_rate_en => data_rate_enable,

      --  fifo
      o_data_instrument => dataout_instrument,
      o_wr_instrument   => write_instrument

      );

  data_rate_enable <= '1';


---------------------------------------------------------------
--  Pipe out fifo
---------------------------------------------------------------
  inst_okPipeOut_fifo : entity work.fifo_r32_131068_w128_32728
    port map (
      rst           => ddr_rst,
      wr_clk        => clk,
      rd_clk        => ok_clk,
      din           => pipe_out_data,   --// Bus [127 : 0]
      wr_en         => pipe_out_write,
      rd_en         => po0_ep_read,
      dout          => po0_ep_datain,   --// Bus [31 : 0]
      full          => open,
      empty         => empty,
      valid         => open,
      rd_data_count => rd_data_count,   --// Bus [9 : 0]
      wr_data_count => wr_data_count,   --// Bus [7 : 0]
      prog_full     => pipe_out_full
      );

  ep27wire <= "00000000000000000"&wr_data_count;

---------------------------------------------------------------
--  Pipe out fifo  hk
---------------------------------------------------------------
  inst_okPipeOut_fifo_hk : entity work.fifo_r32_256_w32_256_hk
    port map (
      rst           => ddr_rst,
      wr_clk        => clk,
      rd_clk        => ok_clk,
      din           => pipe_out_data_hk,  --// Bus [127 : 0]
      wr_en         => pipe_out_write_hk,
      rd_en         => po0_ep_read_hk,
      dout          => po0_ep_datain_hk,  --// Bus [31 : 0]
      full          => open,
      empty         => open,
      rd_data_count => rd_data_count_hk,  --// Bus [9 : 0]
      wr_rst_busy   => open,
      rd_rst_busy   => open
      );

  inst_hk_pattern : entity work.hk_pattern
    port map (

      i_okClk => ok_clk,
      i_rst   => usb_rst,

      i_rd_data_count_hk => rd_data_count_hk,

      o_result => ep26wire

      );

  ---------------------------------------------------------------------
  -- register: get the number of read science words
  ---------------------------------------------------------------------
  -- count the number of read science words.
  p_nb_science_read_word : process (ok_clk)
  begin

    if rising_edge (ok_clk) then
      if usb_rst = '1' then
        ep25wire        <= (others => '0');
        rd_piper_out_r1 <= (others => '0');
      else
        if po0_ep_read = '1' then
          rd_piper_out_r1 <= rd_piper_out_r1 + 1;
          ep25wire        <= std_logic_vector(rd_piper_out_r1);
        else
          if empty = '1' then
            ep25wire        <= (others => '0');
            rd_piper_out_r1 <= (others => '0');
          end if;
        end if;
      end if;
    end if;
  end process p_nb_science_read_word;

---------------------------------------------------------------
--  Pipe in
---------------------------------------------------------------
  inst_okPipein_fifo : entity work.fifo_r32_256_w32_256
    port map (
      rst         => usb_rst,
      wr_clk      => ok_clk,
      rd_clk      => clk,
      din         => pi0_ep_dataout,    --// Bus [31 : 0]
      wr_en       => pi0_ep_write,
      rd_en       => pipe_in_read,
      dout        => pipe_in_data,      --// Bus [127 : 0]
      full        => open,
      empty       => pipe_in_empty,
      valid       => open,
      wr_rst_busy => open,
      rd_rst_busy => open
      );

---------------------------------------------------------------------
-- ILA debugging
---------------------------------------------------------------------
  gen_ILAs : if g_DEBUG generate
  begin
    inst_ila_usb : entity work.ila_usb
      port map (
        clk => ok_clk,

        -- probe3
        probe2(2) => ep02wire(0),
        probe2(1) => ep01wire(0),
        probe2(0) => usb_rst,
        -- probe1
        probe1(2) => po0_ep_read,
        probe1(1) => po0_ep_read_hk,
        probe1(0) => pi0_ep_write,

        -- probe0
        probe0(95 downto 64) => po0_ep_datain,
        probe0(63 downto 32) => po0_ep_datain_hk,
        probe0(31 downto 0)  => pi0_ep_dataout
        );
  end generate gen_ILAs;
end RTL;
