-- -------------------------------------------------------------------------------------------------------------
--                            Copyright (C) 2023-2030 Ken-ji de la Rosa, IRAP Toulouse.
-- -------------------------------------------------------------------------------------------------------------
--                            This file is part of the ATHENA X-IFU DRE Telemetry and Telecommand Firmware.
--
--                            tmtc-fw is free software: you can redistribute it and/or modifyheral Public License as published by
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
--    @file                   leds_top.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This module manages the leds
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity leds_top is
  port (

    ---------------------------------------------------------------------
    -- input @i_clk
    ---------------------------------------------------------------------
    -- clock
    i_clk : in std_logic;
    -- reset  @i_clk
    i_rst : in std_logic;

    ---------------------------------------------------------------------
    -- from DDR controller @i_clk
    ---------------------------------------------------------------------
    -- PHY asserts init_calib_complete when calibration is finished
    i_init_calib_complete : in std_logic;

    ---------------------------------------------------------------------
    -- from science @i_clk
    ---------------------------------------------------------------------
    -- data valid (serialized bit)
    i_science_data_valid : in std_logic;
    -- detect the last bit of the synchro word
    i_science_sync       : in  std_logic;

    ---------------------------------------------------------------------
    -- output @i_clk
    ---------------------------------------------------------------------
    -- FPGA board: status leds
    o_leds : out std_logic_vector(3 downto 0);
    -- FMC firmware led
    o_led_fw: out std_logic;
    -- FMC PLL lock led
    o_led_pll_lock : out std_logic

    );
end entity leds_top;

architecture RTL of leds_top is

  -- counter max value
  constant c_CNT_MAX : unsigned(31 downto 0) := to_unsigned(10_000_000, 32);
  -- counter: tempo
  signal cpt0_r1     : unsigned(31 downto 0);
  -- counter: tempo
  signal cpt1_r1     : unsigned(31 downto 0);
  -- count the number of science frame
  signal start_r1    : unsigned(3 downto 0);
  -- leds (registered)
  signal leds_r1     : std_logic;

  -- led: count clock cycle
  signal cnt_r1 : unsigned(26 downto 0) := (others => '0');
  -- led: change state
  signal trig   : std_logic;

begin

-- generate the o_leds[0] and o_leds[1]
  p_clock_science_link0 : process (i_clk)
  begin

    if rising_edge(i_clk) then
      if i_rst = '1' then
        cpt0_r1    <= (others => '0');
        leds_r1 <= '1';
      else
        -- compute change only when a new bit is received
        if i_science_data_valid = '1' then
          cpt0_r1 <= cpt0_r1 + 1;
          if i_science_sync = '1' then
            -- count the number of frame
            start_r1 <= start_r1 +'1';
          end if;

          if cpt0_r1 = c_CNT_MAX then
            if start_r1 = "0000" then
              leds_r1 <= '0';
            else
              leds_r1 <= '1';
            end if;
            cpt0_r1    <= (others => '0');
          end if;
        end if;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------
  -- detect @clk alive
  ---------------------------------------------------------------------
  p_blink : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      cnt_r1 <= cnt_r1 + 1;
    end if;
  end process p_blink;

  trig <= cnt_r1(cnt_r1'high);


  ---------------------------------------------------------------------
  -- output
  ---------------------------------------------------------------------
  o_leds(0) <= not('1');
  o_leds(1) <= not(i_init_calib_complete);
  o_leds(2) <= leds_r1;
  o_leds(3) <= trig;

  o_led_fw       <= '1';
  o_led_pll_lock <= i_init_calib_complete;

end architecture RTL;
