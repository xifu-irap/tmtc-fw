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
--    @file                   science_rx_deserializer.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg_utils;

entity science_rx_deserializer is
  generic (
    -- define the number of links (input data width)
    g_DATA_WIDTH         : integer := 8;
    -- define the number of bits by links in order to build word
    g_DATA_WIDTH_BY_LINK : integer := 8
    );
  port (

    -- input clock
    i_clk : in std_logic;
    --  input reset
    i_rst : in std_logic;

    ---------------------------------------------------------------------
    -- input
    ---------------------------------------------------------------------
    -- science data valid
    i_science_data_valid : in std_logic;
    -- science ctrl (serialized)
    i_science_ctrl       : in std_logic;
    -- science data (serialized)
    i_science_data       : in std_logic_vector(g_DATA_WIDTH - 1 downto 0);

    ---------------------------------------------------------------------
    -- output
    ---------------------------------------------------------------------
    -- detect the last bit of the synchro word
    o_sync_word_eof : out std_logic;
    -- valid deserialized word
    o_data_valid    : out std_logic;
    -- deserialized control word
    o_ctrl_word     : out std_logic_vector(g_DATA_WIDTH_BY_LINK - 1 downto 0);
    -- deserialized data words
    o_data_words    : out std_logic_vector(g_DATA_WIDTH*g_DATA_WIDTH_BY_LINK - 1 downto 0)

    );
end entity science_rx_deserializer;

architecture RTL of science_rx_deserializer is

  -- auto-computed the number of output words
  constant c_NB_WORDS : integer := i_science_data'length;
  -- define the counter width (for the bits)
  constant c_CNT_BIT_WIDTH : integer := work.pkg_utils.pkg_width_from_value(i_value=> g_DATA_WIDTH_BY_LINK);

  -- max bit counter value:
  constant c_CNT_MAX : unsigned(c_CNT_BIT_WIDTH - 1 downto 0):= to_unsigned(g_DATA_WIDTH_BY_LINK - 1,c_CNT_BIT_WIDTH);

  -- array of data
  type t_array_data is array (g_DATA_WIDTH_BY_LINK - 1 downto 0) of std_logic_vector(c_NB_WORDS - 1 downto 0);

-- fsm type declaration
  type t_state is (E_RST, E_WAIT_HEADER0, E_WAIT_HEADER1, E_WAIT_HEADER2, E_DECODE);

  -- state
  signal sm_state_next : t_state;
  -- state (registered)
  signal sm_state_r1   : t_state := E_RST;

  -- generate a data valid when words are built
  signal data_valid_next : std_logic;
  -- data valid (registered)
  signal data_valid_r1   : std_logic;

  -- detect the end of the synchro word (0-1-1)
  signal sync_word_eof_next : std_logic;
  -- detect the end of the synchro word (0-1-1) registered
  signal sync_word_eof_r1   : std_logic;

  -- bit counter
  signal cnt_bit_next : unsigned(c_CNT_BIT_WIDTH - 1 downto 0);
  -- bit counter registered
  signal cnt_bit_r1   : unsigned(c_CNT_BIT_WIDTH - 1 downto 0);

  -- data shift register
  signal data_array_next : t_array_data;
  -- data shift register (registered)
  signal data_array_r1   : t_array_data;

  -- ctrl shift register
  signal ctrl_array_next : std_logic_vector(o_ctrl_word'range);
  -- ctrl shift register (registered)
  signal ctrl_array_r1   : std_logic_vector(o_ctrl_word'range);


begin

-- this FSM deserializes the input data stream (ctrl,data) by decoding the control bits
  p_decode_state : process (ctrl_array_r1, data_array_r1, i_science_ctrl, i_science_data,
                            i_science_data_valid,
                            sm_state_r1,cnt_bit_r1) is
  begin
    data_valid_next      <= '0';
    sync_word_eof_next   <= '0';
    data_array_next      <= data_array_r1;
    ctrl_array_next      <= ctrl_array_r1;
    cnt_bit_next         <= cnt_bit_r1;

    case sm_state_r1 is
      when E_RST =>
        cnt_bit_next      <= (others => '0');
        sm_state_next <= E_WAIT_HEADER0;

      when E_WAIT_HEADER0 =>
        if i_science_ctrl = '0' and i_science_data_valid = '1' then
          sm_state_next <= E_WAIT_HEADER1;
        else
          sm_state_next <= E_WAIT_HEADER0;
        end if;

      when E_WAIT_HEADER1 =>
        if i_science_ctrl = '1' and i_science_data_valid = '1' then
          cnt_bit_next     <= cnt_bit_r1 + 1;
          ctrl_array_next  <= ctrl_array_r1(ctrl_array_r1'high - 1 downto 0) & i_science_ctrl;
          data_array_next  <= data_array_r1(data_array_r1'high - 1 downto 0) & i_science_data;
          sm_state_next <= E_WAIT_HEADER2;
        else
          sm_state_next <= E_WAIT_HEADER1;
        end if;

      when E_WAIT_HEADER2 =>

        if i_science_ctrl = '1' and i_science_data_valid = '1' then
          cnt_bit_next <= cnt_bit_r1 + 1;
          ctrl_array_next  <= ctrl_array_r1(ctrl_array_r1'high - 1 downto 0) & i_science_ctrl;
          data_array_next  <= data_array_r1(data_array_r1'high - 1 downto 0) & i_science_data;
          -- detect sync_word
          sync_word_eof_next <= '1';

          sm_state_next <= E_DECODE;
        else
          sm_state_next <= E_WAIT_HEADER2;
        end if;

      when E_DECODE =>
        if i_science_data_valid = '1' then
          cnt_bit_next     <= cnt_bit_r1 + 1;
          ctrl_array_next  <= ctrl_array_r1(ctrl_array_r1'high - 1 downto 0) & i_science_ctrl;
          data_array_next  <= data_array_r1(data_array_r1'high - 1 downto 0) & i_science_data;

          if cnt_bit_r1 = c_CNT_MAX then
            data_valid_next <= '1';
            cnt_bit_next    <= (others => '0');
            if i_science_ctrl = '0' then
              sm_state_next   <= E_WAIT_HEADER1;
            else
              sm_state_next   <= E_WAIT_HEADER0;
            end if;
          else
            sm_state_next <= E_DECODE;
          end if;
        else
          sm_state_next <= E_DECODE;
        end if;

      when others =>
        sm_state_next <= E_RST;
    end case;
  end process p_decode_state;

-- registered state signals
  p_state : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      if i_rst = '1' then
        sm_state_r1 <= E_RST;
      else
        sm_state_r1 <= sm_state_next;
      end if;
      data_valid_r1      <= data_valid_next;
      sync_word_eof_r1   <= sync_word_eof_next;
      data_array_r1      <= data_array_next;
      ctrl_array_r1      <= ctrl_array_next;
      cnt_bit_r1         <= cnt_bit_next;

      --if i_science_data_valid = '1' then
      --  ctrl_array_r1  <= ctrl_array_r1(ctrl_array_r1'high - 1 downto 0) & i_science_ctrl;
      --  data_array_r1  <= data_array_r1(data_array_r1'high - 1 downto 0) & i_science_data;
      --end if;

    end if;
  end process p_state;

---------------------------------------------------------------------
-- output
---------------------------------------------------------------------
  o_sync_word_eof <= sync_word_eof_r1;
  o_data_valid    <= data_valid_r1;
  o_ctrl_word     <= ctrl_array_r1;

  gen_extracted_word : for i in data_array_next'range generate
    o_data_words(g_DATA_WIDTH_BY_LINK*(i+1)-1 downto g_DATA_WIDTH_BY_LINK*i) <= data_array_r1(i)(7 downto 0);
  end generate gen_extracted_word;




end architecture RTL;
