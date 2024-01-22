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
--    @file                   science_check_header_w32.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This module checks the periodicity of the science pattern (provided by the DDR manager)
--    The periodic science patterns has the following structure:
--        1. 32 bit word0: header - ...
--        2. 32 bit word1: data0
--        3. 32 bit word2: data1
--    In particular, en error (one by words) is generated and counted if the header is not found every 3 words.
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity science_check_header_w32 is
  port (
    -- input clock
    i_clk : in std_logic;
    ---------------------------------------------------------------------
    -- from DEMUX: science interface @i_science_clk
    ---------------------------------------------------------------------
    -- input science data valid
    i_science_valid : in std_logic;
    -- input science data
    i_science_data  : in std_logic_vector(31 downto 0);

    ---------------------------------------------------------------------
    -- to user: science interface @i_sys_clk
    ---------------------------------------------------------------------
    -- delayed science data valid
    o_science_data_valid  : out std_logic;
    -- delayed science data
    o_science_data        : out std_logic_vector(31 downto 0);
    -- science error cnt valid
    o_science_error_valid : out std_logic;
    -- science error count: count the number of pattern error
    o_science_error_cnt   : out std_logic_vector(15 downto 0)

    );
end entity science_check_header_w32;

architecture RTL of science_check_header_w32 is

  -- defined the header value
  constant c_HEADER : std_logic_vector(15 downto 0) := x"AAAA";

  -- fsm type declaration
  type t_state is (E_RST, E_WAIT, E_RUN0, E_RUN1);

  signal sm_state_r1   : t_state := E_RST;  -- state
  signal sm_state_next : t_state;           -- state (registered)

  signal data_valid_next : std_logic;         -- data_valid
  signal data_valid_r1   : std_logic := '0';  -- data_valid (registered)

  signal data_valid_error_next : std_logic;  -- detect an error
  signal data_valid_error_r1   : std_logic;  -- detect an error

  -- data (registered)
  signal data_r1 : std_logic_vector(i_science_data'range);

  signal cnt_error_next : unsigned(o_science_error_cnt'range);  -- count the rst duration
  signal cnt_error_r1   : unsigned(o_science_error_cnt'range);  -- count the rst duration (registered)


begin

---------------------------------------------------------------------
-- FSM
---------------------------------------------------------------------
-- This process check the periodicity of the science pattern: header -> data0 -> data1
  p_decode_state : process (cnt_error_r1, i_science_data(31 downto 16),
                            i_science_valid, sm_state_r1) is
  begin
    data_valid_next       <= '0';
    data_valid_error_next <= '0';
    cnt_error_next        <= cnt_error_r1;
    case sm_state_r1 is
      when E_RST =>
        cnt_error_next <= (others => '0');
        sm_state_next  <= E_WAIT;

      when E_WAIT =>
        if i_science_valid = '1' then
          data_valid_next <= i_science_valid;
          if i_science_data(31 downto 16) = c_HEADER then
            sm_state_next <= E_RUN0;
          else
            data_valid_error_next <= '1';
            cnt_error_next        <= cnt_error_r1 + 1;

            sm_state_next <= E_WAIT;
          end if;
        else
          sm_state_next <= E_WAIT;
        end if;

      when E_RUN0 =>
        if i_science_valid = '1' then
          data_valid_next <= i_science_valid;
          sm_state_next   <= E_RUN1;
        else
          sm_state_next <= E_RUN0;
        end if;

      when E_RUN1 =>
        if i_science_valid = '1' then
          data_valid_next <= i_science_valid;
          sm_state_next   <= E_WAIT;
        else
          sm_state_next <= E_RUN1;
        end if;

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
      sm_state_r1         <= sm_state_next;
      data_valid_r1       <= data_valid_next;
      data_valid_error_r1 <= data_valid_error_next;
      cnt_error_r1        <= cnt_error_next;

      -- pipe
      data_r1             <= i_science_data;

    end if;
  end process p_state;

---------------------------------------------------------------------
-- output
---------------------------------------------------------------------
  o_science_data_valid <= data_valid_r1;
  o_science_data       <= data_r1;

  o_science_error_valid <= data_valid_error_r1;
  o_science_error_cnt   <= std_logic_vector(cnt_error_r1);


end architecture RTL;
