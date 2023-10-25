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
--!   @file                   ctrl_rx_fsm.vhd
--    reference design        Paul MARBEAU (IRAP Toulouse)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details
--
--            Control State Machine.
--
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ctrl_rx_fsm is
  port (
    -- global
    reset_n          : in std_logic;
    i_clk_science    : in std_logic;
    data_rate_enable : in std_logic;

    -- Link
    i_science_ctrl : in std_logic;

    -- decode
    start_detected : out std_logic;
    CTRL           : out std_logic_vector(7 downto 0);
    data_ready     : out std_logic

    );

end ctrl_rx_fsm;

architecture Behavioral of ctrl_rx_fsm is

  type t_rx_state is (E_WAIT1_START, E_WAIT2_START, E_WAIT3_START, E_DECODE);
  signal sm_state_rx_r1 : t_rx_state;

  signal N_r1 : integer range 0 to 5;

  signal science_ctrl_r2 : std_logic;
  signal science_ctrl_r1 : std_logic;
  signal science_ctrl_r3 : std_logic;

  attribute ASYNC_REG                    : string;
  attribute ASYNC_REG of science_ctrl_r1 : signal is "TRUE";
  attribute ASYNC_REG of science_ctrl_r2 : signal is "TRUE";

begin

-------------------------------------------------------------------------------------------------
-- Metastability protect on CTRL
-------------------------------------------------------------------------------------------------
  p_meta_ctrl : process(reset_n, i_clk_science)
  begin
    if reset_n = '0' then
      science_ctrl_r1 <= '0';
      science_ctrl_r2 <= '0';
    else
      if i_clk_science = '1' and i_clk_science'event then
        science_ctrl_r1 <= i_science_ctrl;
        science_ctrl_r2 <= science_ctrl_r1;
      end if;
    end if;
  end process p_meta_ctrl;

-------------------------------------------------------------------------------------------------
-- Data rate protect on DATA
-------------------------------------------------------------------------------------------------
  p_data_rate : process(reset_n, i_clk_science)
  begin
    if reset_n = '0' then
      science_ctrl_r3 <= '0';
    else
      if i_clk_science = '1' and i_clk_science'event then
        if data_rate_enable = '1' then
          science_ctrl_r3 <= science_ctrl_r2;
        end if;
      end if;
    end if;
  end process p_data_rate;


-------------------------------------------------------------------------------------------------
-- Decode characters
-------------------------------------------------------------------------------------------------
  p_FSM : process(reset_n, i_clk_science)

  begin

    if reset_n = '0' then
      sm_state_rx_r1 <= E_WAIT1_START;
      N_r1           <= 0;
      start_detected <= '0';
      data_ready     <= '0';
      CTRL           <= (others => '0');
    else

      if i_clk_science = '1' and i_clk_science'event then
        data_ready <= '0';

        case sm_state_rx_r1 is

          when E_WAIT1_START =>
            if science_ctrl_r3 = '0' then
              sm_state_rx_r1 <= E_WAIT2_START;
            else
              sm_state_rx_r1 <= E_WAIT1_START;
            end if;

          when E_WAIT2_START =>
            if science_ctrl_r3 = '1' then
              sm_state_rx_r1 <= E_WAIT3_START;
              CTRL(7)        <= science_ctrl_r3;
            else
              sm_state_rx_r1 <= E_WAIT2_START;
            end if;

          when E_WAIT3_START =>
            if science_ctrl_r3 = '1' then
              sm_state_rx_r1 <= E_DECODE;
              CTRL(6)        <= science_ctrl_r3;
              N_r1           <= 5;
              start_detected <= '1';
            else
              sm_state_rx_r1 <= E_WAIT2_START;
            end if;

          when E_DECODE =>
            if N_r1 = 0 then
              start_detected <= '0';
              data_ready     <= '1';
              CTRL(N_r1)     <= science_ctrl_r3;
              if science_ctrl_r3 = '0' then
                sm_state_rx_r1 <= E_WAIT2_START;
              else
                sm_state_rx_r1 <= E_WAIT1_START;
              end if;
            else
              CTRL(N_r1) <= science_ctrl_r3;
              N_r1       <= N_r1-1;
            end if;

          when others =>

        end case;
      end if;
    end if;
  end process p_FSM;

end Behavioral;
