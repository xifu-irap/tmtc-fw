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
--    @file                   science_rx_frame.vhd
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

entity science_rx_frame is
  port (

    -- input clock
    i_clk : in std_logic;
    -- input reset
    i_rst : in std_logic;

    ---------------------------------------------------------------------
    -- input
    ---------------------------------------------------------------------
    -- valid deserialized word
    i_data_valid : in std_logic;
    -- deserialized control word
    i_ctrl_word  : in std_logic_vector(7 downto 0);
    -- deserialized data words
    i_data_words : in std_logic_vector(8*8-1 downto 0);

    ---------------------------------------------------------------------
    -- output
    ---------------------------------------------------------------------
    -- output data valid
    o_data_valid : out std_logic;
    -- output data
    o_data       : out std_logic_vector(127 downto 0)

    );
end entity science_rx_frame;

architecture RTL of science_rx_frame is

-- define the number of bits of a frame
  constant c_FRAME_SIZE : integer := 96;

--  array type declaratation (word8)
  type t_array8 is array (0 to 7) of std_logic_vector(7 downto 0);
--  array type declaratation (frame)
  type t_array_frame is array (0 to 3) of std_logic_vector(c_FRAME_SIZE - 1 downto 0);

-- define an array of 8 bit word
  signal data_array : t_array8;

-- temporary frame
  signal frame_tmp : std_logic_vector(c_FRAME_SIZE - 1 downto 0);

-- fsm type declaration
  type t_state is (E_RST, E_FRAME0, E_FRAME1, E_FRAME2, E_FRAME3);

  -- state
  signal sm_state_next : t_state;
  -- state (registered)
  signal sm_state_r1   : t_state := E_RST;

  -- array of frame
  signal frame_array_next : t_array_frame;
  -- array of frame (registered)
  signal frame_array_r1   : t_array_frame;

  -- data_valid when an output word is complete
  signal data_valid_next : std_logic;
  -- data_valid when an output word is complete (register)
  signal data_valid_r1   : std_logic;

  -- select the output word
  signal sel_next : std_logic_vector(1 downto 0);
  -- select the output word (registered)
  signal sel_r1   : std_logic_vector(1 downto 0);

  ---------------------------------------------------------------------
  -- build output word
  ---------------------------------------------------------------------
  -- delayed data valid
  signal data_valid_r2 : std_logic;
  -- delayed data
  signal data_r2       : std_logic_vector(o_data'range);


begin
-- i_data_words: word8_link7 & word8_link6 & ... & word8_link0
  gen_extracted_word : for i in data_array'range generate
    data_array(i) <= i_data_words(8*(i+1)-1 downto 8*i);
  end generate gen_extracted_word;

-- build a frame
  frame_tmp(95 downto 80) <= x"AAAA";
  frame_tmp(79 downto 72) <= i_ctrl_word;
  frame_tmp(71 downto 64) <= i_ctrl_word;
  frame_tmp(63 downto 56) <= data_array(0);
  frame_tmp(55 downto 48) <= data_array(1);
  frame_tmp(47 downto 40) <= data_array(2);
  frame_tmp(39 downto 32) <= data_array(3);
  frame_tmp(31 downto 24) <= data_array(4);
  frame_tmp(23 downto 16) <= data_array(5);
  frame_tmp(15 downto 8)  <= data_array(6);
  frame_tmp(7 downto 0)   <= data_array(7);

---------------------------------------------------------------------
-- build frame
---------------------------------------------------------------------
  p_decode_state : process (frame_array_r1, frame_tmp, i_data_valid,
                            sel_r1, sm_state_r1) is
  begin
    -- default value
    data_valid_next  <= '0';
    frame_array_next <= frame_array_r1;
    sel_next         <= sel_r1;

    case sm_state_r1 is
      when E_RST =>
        sm_state_next <= E_FRAME0;

      when E_FRAME0 =>
        if i_data_valid = '1' then
          -- store frame0
          frame_array_next(0) <= frame_tmp;
          sm_state_next       <= E_FRAME1;
        else
          sm_state_next <= E_FRAME0;
        end if;

      when E_FRAME1 =>

        if i_data_valid = '1' then
          -- store frame1
          -- and generate the output word0 (frame0 and frame1 combination)
          data_valid_next     <= '1';
          frame_array_next(1) <= frame_tmp;
          sel_next            <= "00";
          sm_state_next       <= E_FRAME2;
        else
          sm_state_next <= E_FRAME1;
        end if;

      when E_FRAME2 =>
        if i_data_valid = '1' then
          -- store frame2
          -- and generate the output word1 (frame1 and frame2 combination)
          data_valid_next     <= '1';
          frame_array_next(2) <= frame_tmp;
          sel_next            <= "01";
          sm_state_next       <= E_FRAME3;
        else
          sm_state_next <= E_FRAME2;
        end if;

      when E_FRAME3 =>
        if i_data_valid = '1' then
          -- store frame3
          -- and generate the output word2 (frame2 and frame3 combination)
          data_valid_next     <= '1';
          frame_array_next(3) <= frame_tmp;
          sel_next            <= "10";
          sm_state_next       <= E_FRAME0;
        else
          sm_state_next <= E_FRAME3;
        end if;

      when others =>
        sm_state_next <= E_RST;
    end case;
  end process p_decode_state;

-- registered fsm signals
  p_state : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      if i_rst = '1' then
        sm_state_r1 <= E_RST;
      else
        sm_state_r1 <= sm_state_next;
      end if;
      data_valid_r1  <= data_valid_next;
      frame_array_r1 <= frame_array_next;
      sel_r1         <= sel_next;

    end if;
  end process p_state;

---------------------------------------------------------------------
-- build output word
---------------------------------------------------------------------
-- build the output words
  p_build_word_out : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      data_valid_r2 <= data_valid_r1;
      case sel_r1 is
        when "00" =>
          data_r2 <= frame_array_r1(0) & frame_array_r1(1)(95 downto 64);
        when "01" =>
          data_r2 <= frame_array_r1(1)(63 downto 0) & frame_array_r1(2)(95 downto 32);
        when "10" =>
          data_r2 <= frame_array_r1(2)(31 downto 0) & frame_array_r1(3);
        when others =>
          data_r2 <= data_r2;
      end case;
    end if;
  end process p_build_word_out;

---------------------------------------------------------------------
-- output
---------------------------------------------------------------------
  o_data_valid <= data_valid_r2;
  o_data       <= data_r2;


end architecture RTL;
