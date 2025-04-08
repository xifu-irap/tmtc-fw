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
-- -------------------------------------------------------------------------------------------------------------
--    email                   kenji.delarosa@alten.com
--    @file                   tb_system_tmtc_top.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--   @details
--
--   Testbench of the system_tmtc_top module.
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.pkg_system_tmtc.all;


entity tb_system_tmtc_top is

end tb_system_tmtc_top;

architecture Simulation of tb_system_tmtc_top is

  --  Opal Kelly inouts --
  -- usb interface signal
  signal i_okUH           : std_logic_vector(4 downto 0);
  -- usb interface signal
  signal o_okHU           : std_logic_vector(2 downto 0);
  -- usb interface signal
  signal b_okUHU          : std_logic_vector(31 downto 0);
  -- usb interface signal
  signal b_okAA           : std_logic;
  ---------------------------------------------------------------------
  -- On board
  ---------------------------------------------------------------------
  -- hardware id register (reading)
  --i_hardware_id : in std_logic_vector(31 downto 0);
  -- Opal Kelly LEDs
  signal o_leds           : std_logic_vector(3 downto 0);
  ---------------------------------------------------------------------
  -- DDR input clock
  ---------------------------------------------------------------------
  -- Differential_p input DDR clock @200M
  signal i_sys_clk_p      : std_logic;
  -- Differential_n input DDR clock @200M
  signal i_sys_clk_n      : std_logic;
  ---------------------------------------------------------------------
  -- DDR interface
  ---------------------------------------------------------------------
  signal ddr3_dq          : std_logic_vector (pkg_DQ_WIDTH-1 downto 0);
  signal ddr3_addr        : std_logic_vector (pkg_ROW_WIDTH-1 downto 0);
  signal ddr3_ba          : std_logic_vector (pkg_BANK_WIDTH-1 downto 0);
  signal ddr3_ck_p        : std_logic_vector (pkg_CK_WIDTH-1 downto 0);
  signal ddr3_ck_n        : std_logic_vector (pkg_CK_WIDTH-1 downto 0);
  signal ddr3_cke         : std_logic_vector (pkg_CKE_WIDTH-1 downto 0);
  signal ddr3_cs_n        : std_logic_vector ((pkg_CS_WIDTH*pkg_nCS_PER_RANK)-1 downto 0);
  signal ddr3_cas_n       : std_logic;
  signal ddr3_ras_n       : std_logic;
  signal ddr3_we_n        : std_logic;
  signal ddr3_odt         : std_logic_vector ((pkg_CS_WIDTH*pkg_nCS_PER_RANK)-1 downto 0);
  signal ddr3_dm          : std_logic_vector (pkg_DM_WIDTH-1 downto 0);
  signal ddr3_dqs_p       : std_logic_vector (pkg_DQS_WIDTH-1 downto 0);
  signal ddr3_dqs_n       : std_logic_vector (pkg_DQS_WIDTH-1 downto 0);
  signal tdqs_n           : std_logic_vector (pkg_DQS_WIDTH-1 downto 0);  -- not used
  signal ddr3_reset_n     : std_logic;
  ---------------------------------------------------------------------
  -- DEMUX: science interface
  ---------------------------------------------------------------------
  -- differential_p science clock
  signal i_science_clk_p  : std_logic_vector(1 downto 0);  --  bit1, not used
  -- differential_n science clock
  signal i_science_clk_n  : std_logic_vector(1 downto 0);  --  bit1, not used
  -- Differential_p science ctrl
  signal i_science_ctrl_p : std_logic_vector(1 downto 0);  --  bit1, not used
  -- Differential_n science ctrl
  signal i_science_ctrl_n : std_logic_vector(1 downto 0);  --  bit1, not used
  -- Differential_p science data
  signal i_science_data_p : std_logic_vector(pkg_SC_LIGN_NUMBER_BY_COL - 1 downto 0);
  -- Differential_n science data
  signal i_science_data_n : std_logic_vector(pkg_SC_LIGN_NUMBER_BY_COL - 1 downto 0);
  ---------------------------------------------------------------------
  -- DEMUX: SPI interface
  ---------------------------------------------------------------------
  -- SPI --
  -- Shared SPI MISO
  signal i_spi_miso       : std_logic;
  -- Shared SPI MOSI
  signal o_spi_mosi       : std_logic;
  -- Shared SPI clock
  signal o_spi_sclk       : std_logic;
  -- SPI chip select
  signal o_spi_cs_n       : std_logic_vector(1 downto 0);
  ---------------------------------------------------------------------
  -- ICU: Selection
  ---------------------------------------------------------------------
  -- ICU selection : 0 for main, 1 for redundant
  signal o_sel_main_n     : std_logic;


  ---------------------------------------------------------------------
  -- Clock definition
  ---------------------------------------------------------------------
  -- clock period duration
  constant c_CLK_PERIOD0 : time := 5 ns;     -- 200M
  constant c_CLK_PERIOD1 : time := 16 ns;    -- 62.5M
  constant c_CLK_PERIOD2 : time := 9.92 ns;  -- 100M

  signal usb_clk           : std_logic                    := '0';
  signal sys_clk           : std_logic                    := '0';
  signal clk_science       : std_logic                    := '0';
  signal science_ctrl_vect : std_logic_vector(7 downto 0) := "01100000";
  signal science_data      : std_logic_vector(7 downto 0) := "10010110";


  signal cnt_value : unsigned(7 downto 0);
  signal cnt_bit : integer;
  signal data0 : std_logic_vector(7 downto 0);
  signal data1 : std_logic_vector(7 downto 0);
  signal data2 : std_logic_vector(7 downto 0);
  signal data3 : std_logic_vector(7 downto 0);
  signal data4 : std_logic_vector(7 downto 0);
  signal data5 : std_logic_vector(7 downto 0);
  signal data6 : std_logic_vector(7 downto 0);
  signal data7 : std_logic_vector(7 downto 0);

begin

  ---------------------------------------------------------------------
  -- Clock generation
  ---------------------------------------------------------------------
  -- sys clock (input dddr)
  p_clk0_gen : process is
  begin
    sys_clk <= '0';
    wait for c_CLK_PERIOD0 / 2;
    sys_clk <= '1';
    wait for c_CLK_PERIOD0 / 2;
  end process p_clk0_gen;

  i_sys_clk_p <= sys_clk;
  i_sys_clk_n <= not(sys_clk);


  -- science clock
  p_clk1_gen : process is
  begin
    clk_science <= '0';
    wait for c_CLK_PERIOD1 / 2;
    clk_science <= '1';
    wait for c_CLK_PERIOD1 / 2;
  end process p_clk1_gen;

  i_science_clk_p(0) <= clk_science;
  i_science_clk_n(0) <= not(clk_science);

  i_science_clk_p(1) <= clk_science;
  i_science_clk_n(1) <= not(clk_science);

  -- usb clock
  p_clk2_gen : process is
  begin
    usb_clk <= '0';
    wait for c_CLK_PERIOD2 / 2;
    usb_clk <= '1';
    wait for c_CLK_PERIOD2 / 2;
  end process p_clk2_gen;

  ---------------------------------------------------------------------
  -- generate science control
  ---------------------------------------------------------------------
  -- loop on valid science ctrl signal
  p_science_ctrl : process is
  begin
    science_ctrl_vect <= science_ctrl_vect(science_ctrl_vect'high - 1 downto 0) & science_ctrl_vect(science_ctrl_vect'high);
    wait for c_CLK_PERIOD1;
  end process p_science_ctrl;

  i_science_ctrl_p(0) <= science_ctrl_vect(science_ctrl_vect'high);
  i_science_ctrl_n(0) <= not(science_ctrl_vect(science_ctrl_vect'high));

  i_science_ctrl_p(1) <= science_ctrl_vect(science_ctrl_vect'high);
  i_science_ctrl_n(1) <= not(science_ctrl_vect(science_ctrl_vect'high));

---------------------------------------------------------------------
-- generate science data
---------------------------------------------------------------------
  p_science_data : process is
    constant c_DATA_WIDTH : integer := 8;
    -- count the number of bits by words
    variable v_cnt_bit: integer := 8;
    -- counter value
    variable v_cnt_value : unsigned(c_DATA_WIDTH - 1 downto 0) := to_unsigned(0,c_DATA_WIDTH);
    -- shift register
    variable v_data0 : std_logic_vector(c_DATA_WIDTH - 1 downto 0):= std_logic_vector(to_unsigned(0,c_DATA_WIDTH));
    variable v_data1 : std_logic_vector(c_DATA_WIDTH - 1 downto 0):= std_logic_vector(to_unsigned(1,c_DATA_WIDTH));
    variable v_data2 : std_logic_vector(c_DATA_WIDTH - 1 downto 0):= std_logic_vector(to_unsigned(2,c_DATA_WIDTH));
    variable v_data3 : std_logic_vector(c_DATA_WIDTH - 1 downto 0):= std_logic_vector(to_unsigned(3,c_DATA_WIDTH));
    variable v_data4 : std_logic_vector(c_DATA_WIDTH - 1 downto 0):= std_logic_vector(to_unsigned(4,c_DATA_WIDTH));
    variable v_data5 : std_logic_vector(c_DATA_WIDTH - 1 downto 0):= std_logic_vector(to_unsigned(5,c_DATA_WIDTH));
    variable v_data6 : std_logic_vector(c_DATA_WIDTH - 1 downto 0):= std_logic_vector(to_unsigned(6,c_DATA_WIDTH));
    variable v_data7 : std_logic_vector(c_DATA_WIDTH - 1 downto 0):= std_logic_vector(to_unsigned(7,c_DATA_WIDTH));


  begin
    if v_cnt_bit = 8 then
      v_cnt_bit := 1;

      -- load the shift register
      v_data0 := std_logic_vector(v_cnt_value + 0);
      v_data1 := std_logic_vector(v_cnt_value + 1);
      v_data2 := std_logic_vector(v_cnt_value + 2);
      v_data3 := std_logic_vector(v_cnt_value + 3);
      v_data4 := std_logic_vector(v_cnt_value + 4);
      v_data5 := std_logic_vector(v_cnt_value + 5);
      v_data6 := std_logic_vector(v_cnt_value + 6);
      v_data7 := std_logic_vector(v_cnt_value + 7);
      v_cnt_value := v_cnt_value + 8;

    else
       v_cnt_bit    := v_cnt_bit + 1;
       v_data0 := v_data0(v_data0'high - 1 downto 0) & '0';
       v_data1 := v_data1(v_data1'high - 1 downto 0) & '0';
       v_data2 := v_data2(v_data2'high - 1 downto 0) & '0';
       v_data3 := v_data3(v_data3'high - 1 downto 0) & '0';
       v_data4 := v_data4(v_data4'high - 1 downto 0) & '0';
       v_data5 := v_data5(v_data5'high - 1 downto 0) & '0';
       v_data6 := v_data6(v_data6'high - 1 downto 0) & '0';
       v_data7 := v_data7(v_data7'high - 1 downto 0) & '0';
    end if;
    science_data(0) <= v_data0(v_data0'high);
    science_data(1) <= v_data1(v_data1'high);
    science_data(2) <= v_data2(v_data2'high);
    science_data(3) <= v_data3(v_data3'high);
    science_data(4) <= v_data4(v_data4'high);
    science_data(5) <= v_data5(v_data5'high);
    science_data(6) <= v_data6(v_data6'high);
    science_data(7) <= v_data7(v_data7'high);
    cnt_value <= v_cnt_value;
    cnt_bit   <= v_cnt_bit;
    data0     <= v_data0;
    data1     <= v_data1;
    data2     <= v_data2;
    data3     <= v_data3;
    data4     <= v_data4;
    data5     <= v_data5;
    data6     <= v_data6;
    data7     <= v_data7;
    wait for c_CLK_PERIOD1;
  end process p_science_data;

  i_science_data_p <= science_data;
  i_science_data_n <= not(science_data);


---------------------------------------------------------------------
-- DUT
---------------------------------------------------------------------

  i_okUH(4 downto 1) <= (others => '0');
  i_okUH(0)          <= usb_clk;

  inst_system_tmtc_top : entity work.system_tmtc_top
    port map(
      --  Opal Kelly inouts --
      -- usb interface signal
      i_okUH           => i_okUH,
      -- usb interface signal
      o_okHU           => o_okHU,
      -- usb interface signal
      b_okUHU          => b_okUHU,
      -- usb interface signal
      b_okAA           => b_okAA,
      ---------------------------------------------------------------------
      -- On board
      ---------------------------------------------------------------------
      -- hardware id register (reading)
      --i_hardware_id : in std_logic_vector(31 downto 0);
      -- Opal Kelly LEDs
      o_leds           => o_leds,
      ---------------------------------------------------------------------
      -- DDR input clock
      ---------------------------------------------------------------------
      -- Differential_p input DDR clock @200M
      i_sys_clk_p      => i_sys_clk_p,
      -- Differential_n input DDR clock @200M
      i_sys_clk_n      => i_sys_clk_n,
      ---------------------------------------------------------------------
      -- DDR interface
      ---------------------------------------------------------------------
      ddr3_dq          => ddr3_dq,
      ddr3_addr        => ddr3_addr,
      ddr3_ba          => ddr3_ba,
      ddr3_ck_p        => ddr3_ck_p,
      ddr3_ck_n        => ddr3_ck_n,
      ddr3_cke         => ddr3_cke,
      ddr3_cs_n        => ddr3_cs_n,
      ddr3_cas_n       => ddr3_cas_n,
      ddr3_ras_n       => ddr3_ras_n,
      ddr3_we_n        => ddr3_we_n,
      ddr3_odt         => ddr3_odt,
      ddr3_dm          => ddr3_dm,
      ddr3_dqs_p       => ddr3_dqs_p,
      ddr3_dqs_n       => ddr3_dqs_n,
      ddr3_reset_n     => ddr3_reset_n,
      ---------------------------------------------------------------------
      -- DEMUX: science interface
      ---------------------------------------------------------------------
      -- differential_p science clock
      i_science_clk_p  => i_science_clk_p,   -- bit1, not used
      -- differential_n science clock
      i_science_clk_n  => i_science_clk_n,   -- bit1, not used
      -- Differential_p science ctrl
      i_science_ctrl_p => i_science_ctrl_p,  -- bit1, not used
      -- Differential_n science ctrl
      i_science_ctrl_n => i_science_ctrl_n,  -- bit1, not used
      -- Differential_p science data
      i_science_data_p => i_science_data_p,
      -- Differential_n science data
      i_science_data_n => i_science_data_n,
      ---------------------------------------------------------------------
      -- DEMUX: SPI interface
      ---------------------------------------------------------------------
      -- SPI --
      -- Shared SPI MISO
      i_spi_miso       => i_spi_miso,
      -- Shared SPI MOSI
      o_spi_mosi       => o_spi_mosi,
      -- Shared SPI clock
      o_spi_sclk       => o_spi_sclk,
      -- SPI chip select
      o_spi_cs_n       => o_spi_cs_n,
      ---------------------------------------------------------------------
      -- ICU: Selection
      ---------------------------------------------------------------------
      -- ICU selection : 0 for main, 1 for redundant
      o_sel_main_n     => o_sel_main_n
      );


---------------------------------------------------------------------
-- DDR model
---------------------------------------------------------------------
  inst_ddr3_model : entity work.ddr3_model
    port map(
      rst_n   => ddr3_reset_n,
      ck      => ddr3_ck_p,
      ck_n    => ddr3_ck_n,
      cke     => ddr3_cke,
      cs_n    => ddr3_cs_n,
      ras_n   => ddr3_ras_n,
      cas_n   => ddr3_cas_n,
      we_n    => ddr3_we_n,
      dm_tdqs => ddr3_dm,
      ba      => ddr3_ba,               -- attention calcul particulier
      addr    => ddr3_addr,             -- attentin calcul particulier
      dq      => ddr3_dq,
      dqs     => ddr3_dqs_p,
      dqs_n   => ddr3_dqs_n,
      tdqs_n  => tdqs_n,
      odt     => ddr3_odt

      );



end Simulation;
