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

    -- reset error flag(s) @i_clk
    i_rst_status  : in std_logic;
    -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s) @i_clk
    i_debug_pulse : in std_logic;

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
    -- detect the last bit of the synchro part of the ctrl word
    o_sync_word_eof : out std_logic;

    -- first ctrl bit (for debugging)
    o_sof        : out std_logic;
    -- last ctrl bit (for debugging)
    o_eof        : out std_logic;
    -- valid deserialized word
    o_data_valid : out std_logic;
    -- deserialized control word
    o_ctrl_word  : out std_logic_vector(g_DATA_WIDTH_BY_LINK - 1 downto 0);
    -- deserialized data words
    o_data_words : out std_logic_vector(g_DATA_WIDTH*g_DATA_WIDTH_BY_LINK - 1 downto 0);

    ---------------------------------------------------------------------
    -- errors/status
    ---------------------------------------------------------------------
    -- status
    o_status : out std_logic_vector(7 downto 0);
    -- errors
    o_errors : out std_logic_vector(15 downto 0)
    );
end entity science_rx_deserializer;

architecture RTL of science_rx_deserializer is

  -- array of data (registered)
  type t_array_data is array (g_DATA_WIDTH - 1 downto 0) of std_logic_vector(g_DATA_WIDTH_BY_LINK - 1 downto 0);

  -- science data valid (registered)
  signal science_data_vld_r1 : std_logic;

  -- data valid (registered)
  signal data_valid_r1   : std_logic;

  -- ctrl shift register (registered)
  signal ctrl_array_r1   : std_logic_vector(o_ctrl_word'range);

  ---------------------------------------------------------------------
  --  deserializer of the input data
  ---------------------------------------------------------------------
  -- data shift register (registered)
  signal data_array_r1       : t_array_data;
  -- delayed data valid: one by link
  signal data_valid_array_r1 : std_logic_vector(i_science_data'range);

  ---------------------------------------------------------------------
  -- output pipe
  ---------------------------------------------------------------------
  -- delayed last bit of a science ctrl bit
  signal eof_r2           : std_logic;
  -- data valid (registered)
  signal data_valid_r2    : std_logic;
  -- latched ctrl registers (registered)
  signal ctrl_array_r2    : std_logic_vector(o_ctrl_word'range);
  -- latched data registers
  signal data_array_r2    : t_array_data;

begin

-- ctrl shift register
   p_ctrl_array : process (i_clk)
   begin

      if rising_edge(i_clk) then
         if i_rst = '1' then
            ctrl_array_r1 <= (others => '0');

         elsif i_science_data_valid = '1' then
            ctrl_array_r1 <= ctrl_array_r1(ctrl_array_r1'high - 1 downto 0) & i_science_ctrl;

         end if;

      end if;

   end process p_ctrl_array;

-- science data valid (registered)
   p_sc_data_vld_r1 : process (i_clk)
   begin

      if rising_edge(i_clk) then
         if i_rst = '1' then
            science_data_vld_r1 <= '0';

         else
            science_data_vld_r1 <= i_science_data_valid;

         end if;

      end if;

   end process p_sc_data_vld_r1;

-- registered state signals
  p_state : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      data_valid_r1         <= ctrl_array_r1(ctrl_array_r1'high) and ctrl_array_r1(ctrl_array_r1'high-1) and not(ctrl_array_r1(ctrl_array_r1'high-3)) and science_data_vld_r1;

    end if;

  end process p_state;

---------------------------------------------------------------------
-- deserialize the input data: one word by line
--  Note: the latency must be equal to the fsm latency (see above)
---------------------------------------------------------------------
  gen_deserialize_data : for i in i_science_data'range generate
    inst_science_rx_deserializer_data : entity work.science_rx_deserializer_data
      generic map(
        -- define the number of bits by links in order to build word
        g_DATA_WIDTH_BY_LINK => g_DATA_WIDTH_BY_LINK
        )
      port map(
        -- input clock
        i_clk                => i_clk,
        ---------------------------------------------------------------------
        -- input
        ---------------------------------------------------------------------
        -- science data valid
        i_science_data_valid => i_science_data_valid,
        -- science data (serialized)
        i_science_data       => i_science_data(i),
        ---------------------------------------------------------------------
        -- output
        ---------------------------------------------------------------------
        -- valid deserialized word
        o_data_valid         => data_valid_array_r1(i),  -- not connected
        -- deserialized data words
        o_data               => data_array_r1(i)
        );

  end generate gen_deserialize_data;

---------------------------------------------------------------------
-- add pipe
---------------------------------------------------------------------
  p_pipe : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      eof_r2           <= data_valid_r1;
      data_valid_r2    <= data_valid_r1;
      -- add a latch to improve the readiability in simulation
      if data_valid_r1 = '1' then
        ctrl_array_r2 <= ctrl_array_r1;
        data_array_r2 <= data_array_r1;
      end if;
    end if;
  end process p_pipe;

---------------------------------------------------------------------
-- output
---------------------------------------------------------------------

  o_sync_word_eof <= '0';
  o_sof           <= '0';
  o_eof           <= eof_r2;
  o_data_valid    <= data_valid_r2;
  o_ctrl_word     <= ctrl_array_r2;

  gen_extracted_word : for i in data_array_r2'range generate
    o_data_words(g_DATA_WIDTH_BY_LINK*(i+1)-1 downto g_DATA_WIDTH_BY_LINK*i) <= data_array_r2(i);
  end generate gen_extracted_word;


  ---------------------------------------------------------------------
-- errors/status
---------------------------------------------------------------------
  o_errors(15 downto 0) <= (others => '0');

  o_status(7 downto 1) <= (others => '0');
  o_status(0)          <= data_valid_r2;


end architecture RTL;
