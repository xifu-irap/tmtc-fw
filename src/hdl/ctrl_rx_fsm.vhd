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
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--!   @details
--
--    This module deserialized the input science control bit in order to build the output science control word
--    by checking the science ctrl synchro bits.
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ctrl_rx_fsm is
  port (
    -- reset
    i_rst         : in std_logic;
    -- science clock
    i_clk_science : in std_logic;

    -- science control data valid
    i_data_rate_en : in std_logic;

    -- science control bit
    i_science_ctrl : in std_logic;

    -- detect the science synchro words
    o_start_detected : out std_logic;

    ---------------------------------------------------------------------
    -- deserialization
    ---------------------------------------------------------------------
    -- science control word
    o_ctrl       : out std_logic_vector(7 downto 0);
    -- detection control word complete
    o_data_ready : out std_logic

    );

end ctrl_rx_fsm;

architecture Behavioral of ctrl_rx_fsm is

  -- fsm type declaration
  type t_rx_state is (E_WAIT1_START, E_WAIT2_START, E_WAIT3_START, E_DECODE);
  -- state (registered)
  signal sm_state_rx_r1 : t_rx_state;

  -- bit counter (all bits excepts synchro bits)
  signal N_r1 : integer range 0 to 5;

  -- delayed science ctrl bit (step1)
  signal science_ctrl_r1 : std_logic;
  -- delayed science ctrl bit (step2)
  signal science_ctrl_r2 : std_logic;
  -- delayed science ctrl bit (step3)
  signal science_ctrl_r3 : std_logic;

  -- fpga specific attribute: force to use registers (very close)
  attribute ASYNC_REG                    : string;
  -- apply attribute on science_ctrl_r1
  attribute ASYNC_REG of science_ctrl_r1 : signal is "TRUE";
  -- apply attribute on science_ctrl_r2
  attribute ASYNC_REG of science_ctrl_r2 : signal is "TRUE";

begin

-------------------------------------------------------------------------------------------------
-- Metastability protect on CTRL
-------------------------------------------------------------------------------------------------
  -- pipe for the Metastability
  p_meta_ctrl : process(i_clk_science)
  begin
    if rising_edge(i_clk_science) then
      science_ctrl_r1 <= i_science_ctrl;
      science_ctrl_r2 <= science_ctrl_r1;
    end if;
  end process p_meta_ctrl;

-------------------------------------------------------------------------------------------------
-- Data rate protect on DATA
-------------------------------------------------------------------------------------------------
  -- latch data
  p_data_rate : process(i_clk_science)
  begin
    if rising_edge(i_clk_science) then
      if i_rst = '1' then
        science_ctrl_r3 <= '0';
      else
        if i_data_rate_en = '1' then
          science_ctrl_r3 <= science_ctrl_r2;
        end if;
      end if;
    end if;
  end process p_data_rate;


-------------------------------------------------------------------------------------------------
-- Decode characters
-------------------------------------------------------------------------------------------------
  -- deserialized the input frame by detecting synchro word
  p_FSM : process(i_clk_science)
  begin
    if rising_edge(i_clk_science) then
      if i_rst = '1' then
        sm_state_rx_r1   <= E_WAIT1_START;
        N_r1             <= 0;
        o_start_detected <= '0';
        o_data_ready     <= '0';
        o_ctrl           <= (others => '0');
      else
        o_data_ready <= '0';

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
              o_ctrl(7)      <= science_ctrl_r3;
            else
              sm_state_rx_r1 <= E_WAIT2_START;
            end if;

          when E_WAIT3_START =>
            if science_ctrl_r3 = '1' then
              sm_state_rx_r1   <= E_DECODE;
              o_ctrl(6)        <= science_ctrl_r3;
              N_r1             <= 5;
              o_start_detected <= '1';
            else
              sm_state_rx_r1 <= E_WAIT2_START;
            end if;

          when E_DECODE =>
            if N_r1 = 0 then
              o_start_detected <= '0';
              o_data_ready     <= '1';
              o_ctrl(N_r1)     <= science_ctrl_r3;
              if science_ctrl_r3 = '0' then
                sm_state_rx_r1 <= E_WAIT2_START;
              else
                sm_state_rx_r1 <= E_WAIT1_START;
              end if;
            else
              o_ctrl(N_r1) <= science_ctrl_r3;
              N_r1         <= N_r1-1;
            end if;

          when others =>

        end case;
      end if;
    end if;
  end process p_FSM;

end Behavioral;
