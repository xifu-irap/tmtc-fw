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
--    @file                   reset_ddr_controller.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This module reset the DDR controller.
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg_utils;

entity reset_ddr_controller is
  generic (
    g_RST_DURATION : integer := 1000  -- duration of the rst signal. the value range is [1;max integer value[
    );
  port (

    ---------------------------------------------------------------------
    -- input
    ---------------------------------------------------------------------
    -- clock
    i_clk : in  std_logic;
    -- reset
    i_rst : in std_logic;

    ---------------------------------------------------------------------
    -- output
    ---------------------------------------------------------------------
    -- output reset
    o_rst : out std_logic

    );
end entity reset_ddr_controller;

architecture RTL of reset_ddr_controller is

  -- compute the minimal count width to count until g_RST_DURATION - 1
  constant c_CNT_WIDTH : integer := pkg_utils.pkg_width_from_value(i_value => g_RST_DURATION);

  -- counter maximal value
  constant c_CNT_MAX : unsigned(c_CNT_WIDTH - 1 downto 0) := to_unsigned(g_RST_DURATION - 1, c_CNT_WIDTH);

  -- fsm type declaration
  type t_state is (E_RST, E_RUN, E_DONE);

  -- state
  signal sm_state_r1   : t_state := E_RST;
  -- state (registered)
  signal sm_state_next : t_state;

   -- reset
  signal rst_next : std_logic;
  -- reset (registered)
  signal rst_r1   : std_logic := '0';

  -- count the rst duration
  signal cnt_next : unsigned(c_CNT_WIDTH - 1 downto 0);
  -- count the rst duration (registered)
  signal cnt_r1   : unsigned(c_CNT_WIDTH - 1 downto 0);


begin

---------------------------------------------------------------------
-- FSM
---------------------------------------------------------------------
-- generate a long reset pulse at the startup
  p_decode_state : process (cnt_r1, sm_state_r1) is
  begin
    rst_next <= '0';
    cnt_next <= cnt_r1;
    case sm_state_r1 is
      when E_RST =>
        rst_next      <= '0';
        cnt_next      <= (others => '0');
        sm_state_next <= E_RUN;

      when E_RUN =>
        cnt_next <= cnt_r1 + 1;
        if cnt_r1 = c_CNT_MAX then
          rst_next      <= '0';
          sm_state_next <= E_DONE;
        else
          rst_next      <= '1';
          sm_state_next <= E_RUN;
        end if;

      when E_DONE =>
        rst_next      <= '0';
        sm_state_next <= E_DONE;

      when others =>
        sm_state_next <= E_RST;
    end case;
  end process p_decode_state;

---------------------------------------------------------------------
-- state process
---------------------------------------------------------------------
-- registered state/signals
  p_state : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      if i_rst = '1' then
        sm_state_r1 <= E_RST;
      else
        sm_state_r1 <= sm_state_next;
      end if;
      rst_r1      <= rst_next;
      cnt_r1      <= cnt_next;
    end if;
  end process p_state;

---------------------------------------------------------------------
-- output
---------------------------------------------------------------------
  o_rst <= rst_r1;

end architecture RTL;
