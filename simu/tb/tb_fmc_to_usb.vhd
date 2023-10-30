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
--    @file                   tb_fmc_to_usb.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--   @details
--
--   Testbench of the spi_top module.
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.science_data_rx_package.all;


entity tb_fmc_to_usb is

end tb_fmc_to_usb;

architecture Simulation of tb_fmc_to_usb is

  constant BANK_WIDTH     : integer := 3;  -- --// # of memory Bank Address bits.
  constant CK_WIDTH       : integer := 1;
  constant CS_WIDTH       : integer := 1;
  constant nCS_PER_RANK   : integer := 1;
  constant CKE_WIDTH      : integer := 1;
  constant DM_WIDTH       : integer := 2;
  constant DQ_WIDTH       : integer := 16;
  constant DQS_WIDTH      : integer := 2;
--constant ODT_WIDTH             :  integer := 1;
  constant ROW_WIDTH      : integer := 15;
  constant ADDR_WIDTH     : integer := 29;
  constant nCK_PER_CLK    : integer := 4;
--constant PAYLOAD_WIDTH         :  integer := 16;
  constant APP_DATA_WIDTH : integer := 128;  -- 2 * nCK_PER_CLK * PAYLOAD_WIDTH;
  constant APP_MASK_WIDTH : integer := 16;   -- APP_DATA_WIDTH / 8;

  constant MEMORY_WIDTH : integer := 16;
  constant NUM_COMP     : integer := DQ_WIDTH/MEMORY_WIDTH;

  --  global
  signal i_okUH           : std_logic_vector(4 downto 0);
  signal o_okHU           : std_logic_vector(2 downto 0);
  signal b_okUHU          : std_logic_vector(31 downto 0);
  signal b_okAA           : std_logic;
  signal i_sys_clkp       : std_logic;
  signal i_sys_clkn       : std_logic;
  --sys_clk           : in    STD_LOGIC;
  signal o_leds_fmc       : std_logic_vector(3 downto 0);
  signal o_leds           : std_logic_vector(3 downto 0);
  signal ddr3_dq          : std_logic_vector (DQ_WIDTH-1 downto 0);
  signal ddr3_addr        : std_logic_vector (ROW_WIDTH-1 downto 0);
  signal ddr3_ba          : std_logic_vector (BANK_WIDTH-1 downto 0);
  signal ddr3_ck_p        : std_logic_vector (CK_WIDTH-1 downto 0);
  signal ddr3_ck_n        : std_logic_vector (CK_WIDTH-1 downto 0);
  signal ddr3_cke         : std_logic_vector (CKE_WIDTH-1 downto 0);
  signal ddr3_cs_n        : std_logic_vector ((CS_WIDTH*nCS_PER_RANK)-1 downto 0);
  signal ddr3_cas_n       : std_logic;
  signal ddr3_ras_n       : std_logic;
  signal ddr3_we_n        : std_logic;
  signal ddr3_odt         : std_logic_vector ((CS_WIDTH*nCS_PER_RANK)-1 downto 0);
  signal ddr3_dm          : std_logic_vector (DM_WIDTH-1 downto 0);
  signal ddr3_dqs_p       : std_logic_vector (DQS_WIDTH-1 downto 0);
  signal ddr3_dqs_n       : std_logic_vector (DQS_WIDTH-1 downto 0);
  signal tdqs_n           : std_logic_vector (DQS_WIDTH-1 downto 0);  -- not used
  signal ddr3_reset_n     : std_logic;
  --  from NG-LARGE
  signal i_clk_science_p  : std_logic_vector(pkg_LINK_NUMBER-1 downto 0);
  signal i_clk_science_n  : std_logic_vector(pkg_LINK_NUMBER-1 downto 0);
  signal i_science_ctrl_p : std_logic_vector(pkg_LINK_NUMBER-1 downto 0);
  signal i_science_ctrl_n : std_logic_vector(pkg_LINK_NUMBER-1 downto 0);
  signal i_science_data_p : std_logic_vector(pkg_LINE_NUMBER-1 downto 0);
  signal i_science_data_n : std_logic_vector(pkg_LINE_NUMBER-1 downto 0);
  -- Paul Test --
  signal i_miso           : std_logic;
  signal o_mosi           : std_logic;
  signal o_sclk           : std_logic;
  signal o_cs_n           : std_logic_vector(1 downto 0);
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

  i_sys_clkp <= sys_clk;
  i_sys_clkn <= not(sys_clk);


  -- science clock
  p_clk1_gen : process is
  begin
    clk_science <= '0';
    wait for c_CLK_PERIOD1 / 2;
    clk_science <= '1';
    wait for c_CLK_PERIOD1 / 2;
  end process p_clk1_gen;

  i_clk_science_p(0) <= clk_science;
  i_clk_science_n(0) <= not(clk_science);

  i_clk_science_p(1) <= clk_science;
  i_clk_science_n(1) <= not(clk_science);

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
  begin
    science_data <= not(science_data);
    wait for c_CLK_PERIOD1;
  end process p_science_data;

  i_science_data_p <= science_data;
  i_science_data_n <= not(science_data);


---------------------------------------------------------------------
-- DUT
---------------------------------------------------------------------

  i_okUH(0) <= usb_clk;

  inst_fmc_to_usb : entity work.fmc_to_usb
    port map(
      --  global
      i_okUH     => i_okUH,
      o_okHU     => o_okHU,
      b_okUHU    => b_okUHU,
      b_okAA     => b_okAA,
      i_sys_clkp => i_sys_clkp,
      i_sys_clkn => i_sys_clkn,
      --sys_clk           : in    STD_LOGIC;
      o_leds_fmc => o_leds_fmc,
      o_leds     => o_leds,

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
      --  from NG-LARGE
      i_clk_science_p  => i_clk_science_p,
      i_clk_science_n  => i_clk_science_n,
      i_science_ctrl_p => i_science_ctrl_p,
      i_science_ctrl_n => i_science_ctrl_n,
      i_science_data_p => i_science_data_p,
      i_science_data_n => i_science_data_n,
      -- Paul Test --
      i_miso           => i_miso,
      o_mosi           => o_mosi,
      o_sclk           => o_sclk,
      o_cs_n           => o_cs_n,
      o_sel_main_n     => o_sel_main_n
      );


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
