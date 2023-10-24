-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            Copyright (C) 2021-2030 Paul Marbeau, IRAP Toulouse.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    email                   paul.marbeau@alten.com
--!   @file                   fmc_to_usb.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details
--
--            Top of the TMTC firmware.
--
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;


use ieee.numeric_std.all;


--use work.okLibrary.all;
library work;
use work.FRONTPANEL.all;
use work.science_data_rx_package.all;
use work.pkg_func_math.all;
use work.pkg_project_ok.all;
use work.pkg_project.all;

library unisim;
use unisim.VComponents.all;

use work.Ramtest_pack.all;

library xpm;
use xpm.vcomponents.all;

entity fmc_to_usb is

  port(

    --  global

    okUH  : in    std_logic_vector(4 downto 0);
    okHU  : out   std_logic_vector(2 downto 0);
    okUHU : inout std_logic_vector(31 downto 0);
    okAA  : inout std_logic;

    sys_clkp : in std_logic;            -- input    wire         sys_clkp,
    sys_clkn : in std_logic;            -- input  wire         sys_clkn,


    led : out std_logic_vector(3 downto 0);

    ddr3_dq      : inout std_logic_vector (DQ_WIDTH-1 downto 0);  -- inout  wire [DQ_WIDTH-1:0]                 ddr3_dq,  //16
    ddr3_addr    : out   std_logic_vector (ROW_WIDTH-1 downto 0);  -- output wire [ROW_WIDTH-1:0]                ddr3_addr,  //15
    ddr3_ba      : out   std_logic_vector (BANK_WIDTH-1 downto 0);  -- output wire [BANK_WIDTH-1:0]               ddr3_ba,    //3
    ddr3_ck_p    : out   std_logic_vector (CK_WIDTH-1 downto 0);  -- output wire [CK_WIDTH-1:0]                 ddr3_ck_p,  //1
    ddr3_ck_n    : out   std_logic_vector (CK_WIDTH-1 downto 0);  -- output wire [CK_WIDTH-1:0]                 ddr3_ck_n,
    ddr3_cke     : out   std_logic_vector (CKE_WIDTH-1 downto 0);  -- output wire [CKE_WIDTH-1:0]                ddr3_cke,  //1
    ddr3_cs_n    : out   std_logic_vector ((CS_WIDTH*nCS_PER_RANK)-1 downto 0);  -- output wire [(CS_WIDTH*nCS_PER_RANK)-1:0]  ddr3_cs_n,
    ddr3_cas_n   : out   std_logic;  -- output wire                                ddr3_cas_n,
    ddr3_ras_n   : out   std_logic;  -- output wire                                ddr3_ras_n,
    ddr3_we_n    : out   std_logic;  -- output wire                                ddr3_we_n,
    ddr3_odt     : out   std_logic_vector ((CS_WIDTH*nCS_PER_RANK)-1 downto 0);  -- output wire [(CS_WIDTH*nCS_PER_RANK)-1:0]  ddr3_odt,
    ddr3_dm      : out   std_logic_vector (DM_WIDTH-1 downto 0);  -- output wire [DM_WIDTH-1:0]                 ddr3_dm,  //2
    ddr3_dqs_p   : inout std_logic_vector (DQS_WIDTH-1 downto 0);  -- inout  wire [DQS_WIDTH-1:0]                ddr3_dqs_p,  //2
    ddr3_dqs_n   : inout std_logic_vector (DQS_WIDTH-1 downto 0);  -- inout  wire [DQS_WIDTH-1:0]                ddr3_dqs_n,
    ddr3_reset_n : out   std_logic;  -- output wire                                ddr3_reset_n

    --  from NG-LARGE
    clk_science_p : in std_logic_vector(LinkNumber-1 downto 0);
    clk_science_n : in std_logic_vector(LinkNumber-1 downto 0);

    i_science_ctrl_p : in std_logic_vector(LinkNumber-1 downto 0);
    i_science_ctrl_n : in std_logic_vector(LinkNumber-1 downto 0);

    i_science_data_p : in std_logic_vector(LignNumber-1 downto 0);
    i_science_data_n : in std_logic_vector(LignNumber-1 downto 0);

    -- Paul Test --
    i_miso   : in  std_logic;
    o_mosi   : out std_logic;
    o_sclk   : out std_logic;
    o_sync_n : out std_logic

    );
end entity;

architecture RTL of fmc_to_usb is

  signal Clk            : std_logic;
  signal rst            : std_logic;
  signal usb_rst        : std_logic;
  signal ddr_rst        : std_logic;
  signal rst_science0   : std_logic;
  signal rst_science0_n : std_logic;
  signal rst_meta       : std_logic;
  signal rst_a          : std_logic;

  --  okHost
  signal okClk : std_logic;

  signal okHE : std_logic_vector(112 downto 0);
  signal okEH : std_logic_vector(64 downto 0);

  --  okWireOR
  signal okEHx : std_logic_vector(65*11-1 downto 0);

  -- fifo instrument
  signal read_instrument       : std_logic;
  signal empty_fifo_instrument : std_logic;

  signal full_fifo_instrument   : std_logic;
  signal full_fifo_instrument_1 : std_logic;
  signal full_fifo_instrument_2 : std_logic;
  signal enable_debug           : std_logic;

  signal valid_fifo_instrument   : std_logic;
  signal dataout_instrument      : std_logic_vector(127 downto 0);
  signal dataout_instrument_wire : std_logic_vector(15 downto 0);
  signal write_instrument        : std_logic;
  signal load_MSB                : std_logic;

  signal data_instrument : std_logic_vector(127 downto 0);

  signal din   : std_logic_vector(31 downto 0);
  signal wr_en : std_logic;

  --  okPipeIn_fifo
  signal read_sended      : std_logic;
  signal pi0_ep_write     : std_logic;
  signal pi0_ep_dataout   : std_logic_vector(31 downto 0);
  signal pipe_in_read     : std_logic;
  signal pipe_in_data     : std_logic_vector(31 downto 0);
  signal pipe_in_data_use : std_logic_vector(31 downto 0);
  signal pipe_in_rd_count : std_logic_vector(7 downto 0);
  signal pipe_in_wr_count : std_logic_vector(9 downto 0);
  signal pipe_in_empty    : std_logic;
  signal pipe_in_full     : std_logic;
  signal pipe_in_valid    : std_logic;

  --  okPipeOut_fifo
  signal po0_ep_read       : std_logic;
  signal po0_ep_datain     : std_logic_vector(31 downto 0);
  signal pipe_out_write    : std_logic;
  signal pipe_out_data     : std_logic_vector(127 downto 0);
  signal pipe_out_rd_count : std_logic_vector(9 downto 0);
  signal pipe_out_wr_count : std_logic_vector(7 downto 0);
  signal pipe_out_full     : std_logic;
  signal pipe_out_empty    : std_logic;
  signal empty             : std_logic;
  signal wr_data_count     : std_logic_vector(14 downto 0);
  signal rd_data_count     : std_logic_vector(16 downto 0);

  --  wire
  signal ep00wire : std_logic_vector(31 downto 0);
  signal ep20wire : std_logic_vector(31 downto 0);
  signal ep22wire : std_logic_vector(31 downto 0);
  signal ep25wire : std_logic_vector(31 downto 0);
  signal ep26wire : std_logic_vector(31 downto 0);
  signal ep27wire : std_logic_vector(31 downto 0);
  signal ep28wire : std_logic_vector(31 downto 0);

  signal ep20wire_one   : std_logic_vector(31 downto 0);
  signal ep20wire_two   : std_logic_vector(31 downto 0);
  signal ep20wire_three : std_logic_vector(31 downto 0);
  signal ep23wire_one   : std_logic_vector(31 downto 0);
  signal ep23wire_two   : std_logic_vector(31 downto 0);
  signal ep22wire_one   : std_logic_vector(31 downto 0);
  signal ep22wire_two   : std_logic_vector(31 downto 0);
  signal ep24wire_one   : std_logic_vector(31 downto 0);
  signal ep24wire_two   : std_logic_vector(31 downto 0);
  signal ep25wire_one   : std_logic_vector(31 downto 0);
  signal ep25wire_two   : std_logic_vector(31 downto 0);
  signal ep26wire_one   : std_logic_vector(31 downto 0);
  signal ep26wire_two   : std_logic_vector(31 downto 0);
  signal ep27wire_one   : std_logic_vector(31 downto 0);
  signal ep27wire_two   : std_logic_vector(31 downto 0);
  signal ep28wire_one   : std_logic_vector(31 downto 0);
  signal ep28wire_two   : std_logic_vector(31 downto 0);

  --  ddr3 stamp
  signal ep23wire                    : std_logic_vector(31 downto 0);
  signal ep24wire                    : std_logic_vector(31 downto 0);
  signal buffer_new_cmd_byte_addr_rd : std_logic_vector(54 downto 0);
  signal buffer_new_cmd_byte_addr_wr : std_logic_vector(54 downto 0);
  signal Subtraction_addr_wr_addr_rd : std_logic_vector(54 downto 0);

  --  ddr3 interconnect
  signal init_calib_complete      : std_logic;
  signal init_calib_complete_sync : std_logic;
  signal sys_rst                  : std_logic;
  signal rst_cnt                  : unsigned(4 downto 0) := (others => '0');

  signal app_ecc_multiple_err : std_logic_vector(2*nCK_PER_CLK-1 downto 0);
  signal app_addr             : std_logic_vector (ADDR_WIDTH-1 downto 0);
  signal app_cmd              : std_logic_vector (2 downto 0);
  signal app_en               : std_logic;
  signal app_rdy              : std_logic;
  signal app_rd_data          : std_logic_vector (APP_DATA_WIDTH-1 downto 0);
  signal app_rd_data_end      : std_logic;
  signal app_rd_data_valid    : std_logic;
  signal app_wdf_data         : std_logic_vector (APP_DATA_WIDTH-1 downto 0);
  signal app_wdf_end          : std_logic;
  signal app_wdf_mask         : std_logic_vector (APP_MASK_WIDTH-1 downto 0);
  signal app_wdf_rdy          : std_logic;
  signal app_wdf_wren         : std_logic;

  --  led
  signal cpt0        : integer;
  signal cpt1        : integer;
  signal start_temp0 : unsigned(3 downto 0);
  signal start_temp1 : std_logic_vector(3 downto 0);
  signal led_temp    : std_logic_vector(3 downto 0);

  --  icon et ila
  signal CONTROL0 : std_logic_vector(35 downto 0);
  signal CONTROL1 : std_logic_vector(35 downto 0);
  signal CONTROL2 : std_logic_vector(35 downto 0);

  signal DATA              : std_logic_vector(1 downto 0);
  signal SYNC_OUT          : std_logic_vector(31 downto 0);
  signal SYNC_OUT_one      : std_logic_vector(31 downto 0);
  signal SYNC_OUT_fast     : std_logic_vector(31 downto 0);
  signal start_stop_fast   : std_logic;
  signal start_stop_one    : std_logic;
  signal SYNC_OUT_3        : std_logic_vector(31 downto 0);
  signal tREFI_std         : std_logic_vector(31 downto 0);
  signal counter_tREFI_std : std_logic_vector(31 downto 0);

  --  refresh process
  signal tREFI                : integer;
  signal app_ref_req          : std_logic;
  signal app_ref_ack          : std_logic;
  signal app_ref_ack_received : std_logic;

  -- simulate data rate by counter
  signal simulate_data_instrument : std_logic_vector(31 downto 0);
  signal timer_instrument         : integer range 0 to 10002;

  signal first_data : std_logic;

  -- manage ep20wire
  signal counter_BL_read_DRR3 : std_logic_vector(31 downto 0);
  signal load_ep_wire         : std_logic;
  signal fifo_filled          : std_logic;
  signal signal_empty_fast    : std_logic;

  signal prog_full  : std_logic;
  signal prog_empty : std_logic;

  signal before_prog_full  : std_logic;
  signal before_prog_empty : std_logic;

  --  output
  signal ack_time_out : std_logic;
  signal time_out     : std_logic;

  signal clk_slow : std_logic;

  signal signal_read_piper_out : unsigned(31 downto 0);

  --  HK
  signal pipe_out_data_hk  : std_logic_vector(31 downto 0);
  signal pipe_out_write_hk : std_logic;
  signal empty_hk          : std_logic;
  signal pipe_out_full_hk  : std_logic;

  signal po0_ep_read_hk   : std_logic;
  signal po0_ep_datain_hk : std_logic_vector(31 downto 0);
  signal rd_data_count_hk : std_logic_vector(9 downto 0);

  --
  signal init_calib_complete_one  : std_logic;
  signal init_calib_complete_fast : std_logic;

  signal ep00wire_one  : std_logic;
  signal ep00wire_fast : std_logic;

  signal start      : std_logic;
  signal start_one  : std_logic;
  signal start_fast : std_logic;

  -- NG-LARGE
  signal start_data_rate : std_logic;
  signal clk_ng_large    : std_logic;
  signal clk_ng_large_n  : std_logic;
  signal ok_pattern      : t_sc_data_w(0 to c_DMX_NB_COL*c_SC_DATA_SER_NB);

  signal i_science_data_tx_ena : std_logic;
  signal start_pattern         : std_logic;
  signal data_rate_enable      : std_logic;

  -- Paul Part --
  signal i_science_ctrl : std_logic_vector(LinkNumber - 1 downto 0);

  signal clk_science    : std_logic_vector(LinkNumber - 1 downto 0);
  signal i_science_data : std_logic_vector(LignNumber - 1 downto 0);
  signal start_detected : std_logic_vector(LinkNumber-1 downto 0);

  constant c_SPI_SER_WD_S_V_S   : integer := log2_ceil(c_DAC_SPI_SER_WD_S + 1);  --! DAC SPI: Serial word size vector bus size
  constant c_DAC_SPI_SER_WD_S_V : std_logic_vector(c_SPI_SER_WD_S_V_S-1 downto 0) :=
    std_logic_vector(to_unsigned(c_DAC_SPI_SER_WD_S, c_SPI_SER_WD_S_V_S));  --! DAC SPI: Serial word size vector
  signal pipe_in_data_big_endian : std_logic_vector(31 downto 0);


  attribute ASYNC_REG                 : string;
  attribute ASYNC_REG of ep23wire_one : signal is "TRUE";
  attribute ASYNC_REG of ep23wire_two : signal is "TRUE";

  attribute ASYNC_REG of ep22wire_one : signal is "TRUE";
  attribute ASYNC_REG of ep22wire_two : signal is "TRUE";

  attribute ASYNC_REG of ep24wire_one : signal is "TRUE";
  attribute ASYNC_REG of ep24wire_two : signal is "TRUE";

  attribute ASYNC_REG of ep25wire_one : signal is "TRUE";
  attribute ASYNC_REG of ep25wire_two : signal is "TRUE";

  attribute ASYNC_REG of ep27wire_one : signal is "TRUE";
  attribute ASYNC_REG of ep27wire_two : signal is "TRUE";

  attribute ASYNC_REG of ep28wire_one : signal is "TRUE";
  attribute ASYNC_REG of ep28wire_two : signal is "TRUE";



  signal cnt_r1 : unsigned(26 downto 0) := (others => '0');
  signal trig   : std_logic;

begin

  gen_IBUFDS_science_data : for i in 0 to LignNumber - 1 generate
    IBUFDS_i : IBUFDS
      generic map (
        DIFF_TERM    => true,           -- Differential Termination
        IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
        IOSTANDARD   => "DEFAULT")
      port map (
        O  => i_science_data(i),        -- Buffer output
        I  => i_science_data_p(i),  -- Diff_p buffer input (connect directly to top-level port)
        IB => i_science_data_n(i)  -- Diff_n buffer input (connect directly to top-level port)
        );
  end generate;

  gen_IBUFDS_science_ctrl : for i in 0 to LinkNumber - 1 generate
    IBUFDS_science_ctrl : IBUFDS
      generic map (
        DIFF_TERM    => true,           -- Differential Termination
        IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
        IOSTANDARD   => "DEFAULT")
      port map (
        O  => i_science_ctrl(i),        -- Buffer output
        I  => i_science_ctrl_p(i),  -- Diff_p buffer input (connect directly to top-level port)
        IB => i_science_ctrl_n(i)  -- Diff_n buffer input (connect directly to top-level port)
        );
  end generate;

  gen_IBUFDS_clk_science : for i in 0 to LinkNumber - 1 generate
    IBUFDS_clk_science : IBUFDS
      generic map (
        DIFF_TERM    => true,           -- Differential Termination
        IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
        IOSTANDARD   => "DEFAULT")
      port map (
        O  => clk_science(i),           -- Buffer output
        I  => clk_science_p(i),  -- Diff_p buffer input (connect directly to top-level port)
        IB => clk_science_n(i)  -- Diff_n buffer input (connect directly to top-level port)
        );
  end generate;

  inst_spi_mgt : entity work.spi_mgt
    port map(
      i_rst         => ddr_rst,
      i_clk         => clk,
      i_spi_data_tx => pipe_in_data_big_endian,
      i_miso        => i_miso,
      i_fifo_empty  => pipe_in_empty,

      o_read_en    => pipe_in_read,
      o_data_ready => pipe_out_write_hk,
      o_data       => pipe_out_data_hk,
      o_mosi       => o_mosi,
      o_sclk       => o_sclk,
      o_sync_n     => o_sync_n
      );

  -- endianess: swap bytes
  pipe_in_data_big_endian <= pipe_in_data(7 downto 0)&pipe_in_data(15 downto 8)&pipe_in_data(23 downto 16)&pipe_in_data(31 downto 24);

----------------------------------------------------
--  LED
--    inversed logical:
--      led off: led <= '1';
--      led on:  led <= '0';
----------------------------------------------------
  p_clock_science_link0 : process (clk_science(0), rst_science0)
  begin
    if rst_science0 = '1' then
      cpt0        <= 0;
      led_temp(0) <= '1';
      led_temp(1) <= '1';
    elsif rising_edge(clk_science(0)) then
      cpt0 <= cpt0 + 1;
      if start_detected(0) = '1' then
        start_temp0 <= start_temp0 + 1;
      end if;
      if cpt0 = 10000000 then
        if start_temp0 = "0000" then
          led_temp(1) <= '0';
        else
          led_temp(1) <= '1';
        end if;
        led_temp(0) <= not led_temp(0);
        cpt0        <= 0;
      end if;
    end if;
  end process;

  -- leds
  led(0) <= not('1');
  led(1) <= led_temp(1);

  p_clock_science_link1 : process (clk_science(1), rst_science0)
  begin
    if rst_science0 = '1' then
      cpt1        <= 0;
      led_temp(2) <= '1';
      led_temp(3) <= '1';
    elsif rising_edge(clk_science(1))then
      cpt1 <= cpt1 + 1;
      if cpt1 = 10000000 then
        if start_detected(1) = '0' then
          led_temp(3) <= '1';
        else
          led_temp(3) <= '0';
        end if;
        led_temp(2) <= not led_temp(2);
        cpt1        <= 0;
      end if;
    end if;
  end process;

  --led(2) <= led_temp(2);
  --led(3) <= led_temp(3);

  p_blink : process (clk) is
  begin
    if rising_edge(clk) then
      cnt_r1 <= cnt_r1 + 1;
    end if;
  end process p_blink;
  trig <= cnt_r1(cnt_r1'high);

  led(2)  <= not(init_calib_complete);
  led(3)  <= trig;
----------------------------------------------------
--  RESET
----------------------------------------------------
  usb_rst <= ep00wire(0);

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
      app_rd_data_end   => app_rd_data_end,
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
      sys_clk_p => sys_clkp,
      sys_clk_n => sys_clkn,

      sys_rst => sys_rst
      );

  --//MIG Infrastructure Reset
  p_reset_mig : process (okClk, usb_rst)
  begin
    if usb_rst = '1' then
      rst_cnt <= (others => '0');
      sys_rst <= '1';
    elsif rising_edge(okClk) then
      if(rst_cnt < "1000") then
        rst_cnt <= rst_cnt + 1;
        sys_rst <= '1';
      else
        sys_rst <= '0';
      end if;
    end if;
  end process p_reset_mig;

----------------------------------------------------
--  Controller DDR3
----------------------------------------------------
  inst_drive_interface_ddr3_ctrl : entity work.drive_interface_ddr3_ctrl
    port map (

      clk   => clk,
      reset => ddr_rst,

      calib_done => init_calib_complete,

      pipe_in_read     => read_instrument,
      pipe_in_data     => data_instrument,
      pipe_in_rd_count => x"00",
      pipe_in_valid    => valid_fifo_instrument,
      pipe_in_empty    => empty_fifo_instrument,

      pipe_out_write    => pipe_out_write,
      pipe_out_data     => pipe_out_data,
      pipe_out_wr_count => pipe_out_wr_count,
      pipe_out_full     => pipe_out_full,

      app_rdy  => app_rdy,              --: STD_LOGIC;
      app_en   => app_en,               --: STD_LOGIC
      app_cmd  => app_cmd,              --: STD_LOGIC_VECTOR  (2 downto 0);
      app_addr => app_addr,  --: STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0); --ADDR_WIDTH            : integer := 29;

      app_rd_data       => app_rd_data,  --: STD_LOGIC_VECTOR  (APP_DATA_WIDTH-1 downto 0);  --constant APP_DATA_WIDTH        :  integer := 128;
      app_rd_data_end   => app_rd_data_end,    --: STD_LOGIC;
      app_rd_data_valid => app_rd_data_valid,  --: STD_LOGIC;

      app_wdf_rdy  => app_wdf_rdy,      --: STD_LOGIC;
      app_wdf_wren => app_wdf_wren,     --: STD_LOGIC;
      app_wdf_data => app_wdf_data,  --: STD_LOGIC_VECTOR  (APP_DATA_WIDTH-1 downto 0);  --constant APP_DATA_WIDTH        :  integer := 128;
      app_wdf_end  => app_wdf_end,      --: STD_LOGIC;
      app_wdf_mask => app_wdf_mask,  --: STD_LOGIC_VECTOR  (APP_MASK_WIDTH-1 downto 0);  --constant APP_DATA_WIDTH        :  integer := 128;

      prog_empty => prog_empty,

      load_ep_wire         => load_ep_wire,
      fifo_filled          => fifo_filled,
      counter_BL_read_DRR3 => counter_BL_read_DRR3,

      SYNC_OUT_3 => SYNC_OUT_3,

      buffer_new_cmd_byte_addr_wr => buffer_new_cmd_byte_addr_wr,
      buffer_new_cmd_byte_addr_rd => buffer_new_cmd_byte_addr_rd

      );

----------------------------------------------------
--  Controller DDR3
----------------------------------------------------
  inst_ddr_stamp : entity work.ddr_stamp
    port map (

      --  global
      clk   => clk,
      reset => ddr_rst,

      --  input
      buffer_new_cmd_byte_addr_wr => buffer_new_cmd_byte_addr_wr,
      buffer_new_cmd_byte_addr_rd => buffer_new_cmd_byte_addr_rd,

      --  output
      Subtraction_addr_wr_addr_rd => Subtraction_addr_wr_addr_rd
      );

  ep23wire <= Subtraction_addr_wr_addr_rd (31 downto 0);

-- ----------------------------------------------------
-- manage ep20wire
-- ----------------------------------------------------
  inst_manaage_pipe_out : entity work.manage_pipe_out
    port map (
      --  global
      clk   => clk,
      okClk => okClk,
      reset => usb_rst,

      --  fifo interface
      rd_data_count => rd_data_count,

      --  ctrl interface
      ep20wire_three => ep20wire_three

      );

-- ----------------------------------------------------
-- meta wire out
-- ----------------------------------------------------
  p_synchronized_register : process (okClk, usb_rst)
  begin
    if usb_rst = '1' then

      ep23wire_one <= (others => '0');
      ep23wire_two <= (others => '0');
      ep22wire_one <= (others => '0');
      ep22wire_two <= (others => '0');
      ep24wire_one <= (others => '0');
      ep24wire_two <= (others => '0');
      ep25wire_one <= (others => '0');
      ep25wire_two <= (others => '0');
      ep27wire_one <= (others => '0');
      ep27wire_two <= (others => '0');
      ep28wire_one <= (others => '0');
      ep28wire_two <= (others => '0');

    else
      if rising_edge (okClk) then

        ep23wire_one <= ep23wire;
        ep23wire_two <= ep23wire_one;

        ep22wire_one <= ep22wire;
        ep22wire_two <= ep22wire_one;

        ep24wire_one <= ep24wire;
        ep24wire_two <= ep24wire_one;

        ep25wire_one <= ep25wire;
        ep25wire_two <= ep25wire_one;

        ep27wire_one <= ep27wire;
        ep27wire_two <= ep27wire_one;

        ep28wire_one <= ep28wire;
        ep28wire_two <= ep28wire_one;

      end if;
    end if;
  end process p_synchronized_register;

----------------------------------------------------
--  ok wire host
----------------------------------------------------
  inst_okHost : okHost
    port map(

      okUH  => okUH,
      okHU  => okHU,
      okUHU => okUHU,
      okAA  => okAA,   --//temp removed for SIMULATION replace Core
      okClk => okClk,                   --out
      okHE  => okHE,
      okEH  => okEH

      );

----------------------------------------------------
--  ok wire OR
----------------------------------------------------
  inst_okWireOR : okWireOR generic map (N => 11)
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

----------------------------------------------------
--  ok wire out
----------------------------------------------------
  inst_okWireOut : okWireOut
    port map (
      okHE      => okHE,
      okEH      => okEHx(1*65-1 downto 0*65),
      ep_addr   => x"24",
      ep_datain => ep24wire_two
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
      ep_datain => ep22wire_two
      );

----------------------------------------------------
--  ok wire out ddr3 stamp lsb
----------------------------------------------------
  inst_okWireOut_ddr3_stamp_lsb : okWireOut
    port map (
      okHE      => okHE,
      okEH      => okEHx(4*65-1 downto 3*65),
      ep_addr   => x"23",
      ep_datain => ep23wire_two
      );

----------------------------------------------------
--  ok wire out ddr3 stamp msb
----------------------------------------------------
  inst_okWireOut_ddr3_stamp_msb : okWireOut
    port map (
      okHE      => okHE,
      okEH      => okEHx(5*65-1 downto 4*65),
      ep_addr   => x"21",
      ep_datain => ep20wire_three
      );

----------------------------------------------------
--  ok wire out ddr3 stamp msb
----------------------------------------------------
  inst_okWireOut_debug : okWireOut
    port map (
      okHE      => okHE,
      okEH      => okEHx(6*65-1 downto 5*65),
      ep_addr   => x"25",
      ep_datain => ep25wire_two
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
      ep_datain => ep27wire_two
      );

----------------------------------------------------
--  ok wire debug
----------------------------------------------------
  inst_okWireOut_debug2 : okWireOut
    port map (
      okHE      => okHE,
      okEH      => okEHx(9*65-1 downto 8*65),
      ep_addr   => x"28",
      ep_datain => ep28wire_two
      );

----------------------------------------------------
--  ok pipe out hk
----------------------------------------------------
  inst_okPipeOut_hk : okPipeOut         --okBTPipeOut
    port map (
      okHE      => okHE,
      okEH      => okEHx(10*65-1 downto 9*65),
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
      okEH       => okEHx(11*65-1 downto 10*65),
      ep_addr    => x"80",
      ep_write   => pi0_ep_write,
      ep_dataout => pi0_ep_dataout
      );

  ---------------------------------------------------------------------
  -- FIFO status
  ---------------------------------------------------------------------
  -- register: get the FIFO status
  p_status_fifo : process (clk, ddr_rst)
  begin
    if ddr_rst = '1' then
      ep22wire     <= (others => '0');
      enable_debug <= '0';
    else

      if rising_edge (clk) then
        --  meta
        full_fifo_instrument_1 <= full_fifo_instrument;
        full_fifo_instrument_2 <= full_fifo_instrument_1;

        ep22wire(2) <= load_ep_wire;
        ep22wire(3) <= fifo_filled;
        ep22wire(4) <= empty;
        ep22wire(5) <= empty_fifo_instrument;
        ep22wire(6) <= enable_debug;

        --  detect error
        if pipe_out_full = '1' and full_fifo_instrument_2 = '0' and enable_debug = '1' then
          ep22wire(0) <= '1';
        else
          if pipe_out_full = '0' and full_fifo_instrument_2 = '1' and enable_debug = '1' then
            ep22wire(1) <= '1';
          else
            if pipe_out_full = '1' and full_fifo_instrument_2 = '1' and enable_debug = '1' then
              ep22wire(1) <= '1';
              ep22wire(0) <= '1';
            end if;
          end if;
        end if;

        if load_ep_wire = '1' then  --  enable full flag after first gse read
          enable_debug <= '1';
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
--  prog_full     =>  prog_full,
      prog_empty    => prog_empty


      );

  rst_science0   <= not(init_calib_complete_sync);
  rst_science0_n <= init_calib_complete_sync;


---------------------------------------------------------------
--   RX - Top level
---------------------------------------------------------------
  inst_science_data_rx : entity work.science_data_rx port map
    (

      reset_n       => rst_science0_n,
      i_clk_science => clk_science,

      -- Link

      start_detected => start_detected,

      i_science_ctrl   => i_science_ctrl,
      i_science_data   => i_science_data,
      data_rate_enable => data_rate_enable,

      --  fifo
      dataout_instrument => dataout_instrument,
      write_instrument   => write_instrument

      );

  data_rate_enable <= '1';


---------------------------------------------------------------
--  Pipe out fifo
---------------------------------------------------------------
  inst_okPipeOut_fifo : entity work.fifo_r32_131068_w128_32728
    port map (
      rst           => ddr_rst,
      wr_clk        => clk,
      rd_clk        => okClk,
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
  ep28wire <= "0000000000000000"&dataout_instrument_wire;

---------------------------------------------------------------
--  Pipe out fifo  hk
---------------------------------------------------------------
  isnt_okPipeOut_fifo_hk : entity work.fifo_r32_256_w32_256_hk
    port map (
      rst           => ddr_rst,
      wr_clk        => Clk,
      rd_clk        => okClk,
      din           => pipe_out_data_hk,  --// Bus [127 : 0]
      wr_en         => pipe_out_write_hk,
      rd_en         => po0_ep_read_hk,
      dout          => po0_ep_datain_hk,  --// Bus [31 : 0]
      full          => pipe_out_full_hk,
      empty         => empty_hk,
      rd_data_count => rd_data_count_hk   --// Bus [9 : 0]
      );

  inst_hk_pattern : entity work.hk_pattern
    port map (

      okClk => okClk,
      reset => usb_rst,

      rd_data_count_hk => rd_data_count_hk,

      ep26wire => ep26wire

      );

  ---------------------------------------------------------------------
  -- register: get the number of read science words
  ---------------------------------------------------------------------
  -- count the number of read science words.
  p_nb_science_read_word : process (okClk, usb_rst)
  begin
    if usb_rst = '1' then
      ep25wire              <= (others => '0');
      signal_read_piper_out <= (others => '0');
    else
      if rising_edge (okClk) then
        if po0_ep_read = '1' then
          signal_read_piper_out <= signal_read_piper_out + 1;
          ep25wire              <= std_logic_vector(signal_read_piper_out);
        else
          if empty = '1' then
            ep25wire              <= (others => '0');
            signal_read_piper_out <= (others => '0');
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
      rst    => usb_rst,
      wr_clk => okClk,
      rd_clk => Clk,
      din    => pi0_ep_dataout,         --// Bus [31 : 0]
      wr_en  => pi0_ep_write,
      rd_en  => pipe_in_read,
      dout   => pipe_in_data,           --// Bus [127 : 0]
      full   => open,
      empty  => pipe_in_empty,
      valid  => pipe_in_valid
      );

end RTL;
