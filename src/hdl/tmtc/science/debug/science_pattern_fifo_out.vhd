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
--    @file                   science_pattern_fifo_out.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    According to the i_pattern_en value, this module has 2 modes:
--       1. pattern generator (i_pattern_en=1). In this case, the input data is ignored. But the module generates
--       a science pattern at full speed for the external output FIFO. The periodic science patterns has the following structure:
--           1. 32 bit word0: c_BAD_HEADER - ...
--           2. 32 bit word1: data0
--           3. 32 bit word2: data1
--       2. bypass (i_pattern_en=0). In this case, the input data is copied on the output.
--
--    Note:
--      . To be able to differienciate the pattern generator mode of the bypass mode,
--      a c_bad_header is used (pattern generator) in order to generated errors on the test script level.
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity science_pattern_fifo_out is
  port (
    -- input clock
    i_clk        : in std_logic;
    ---------------------------------------------------------------------
    -- From the redgdecode
    ---------------------------------------------------------------------
    -- '1': Fill the output FIFO with a pre-defined pattern, '0': fill the output FIFO with data from the DDR
    i_pattern_en : in std_logic;

    ---------------------------------------------------------------------
    -- from the DDR
    ---------------------------------------------------------------------
    -- input data valid
    i_data_valid : in std_logic;
    -- input data
    i_data       : in std_logic_vector(31 downto 0);

    ---------------------------------------------------------------------
    -- output
    ---------------------------------------------------------------------
    -- ouput fifo prog full
    i_fifo_prog_full  : in  std_logic;
    -- output fifo data valid (write enable)
    o_fifo_data_valid : out std_logic;
    -- output fifo data
    o_fifo_data       : out std_logic_vector(31 downto 0)

    );
end entity science_pattern_fifo_out;

architecture RTL of science_pattern_fifo_out is

  -- bad header value
  constant c_BAD_HEADER : std_logic_vector(15 downto 0) := x"AAAB";
  -- c_DATA1
  constant c_DATA1      : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(1, 32));
  -- c_DATA2
  constant c_DATA2      : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(2, 32));

  -- fsm type declaration
  type t_state is (E_RST, E_WAIT, E_DATA0, E_DATA1);

  signal sm_state_r1   : t_state := E_RST;  -- state
  signal sm_state_next : t_state;           -- state (registered)

  signal data_valid_next : std_logic;         -- data_valid
  signal data_valid_r1   : std_logic := '0';  -- data_valid (registered)

  -- data
  signal data_next : std_logic_vector(i_data'range);
  -- data (registered)
  signal data_r1   : std_logic_vector(i_data'range);



begin

---------------------------------------------------------------------
-- FSM
---------------------------------------------------------------------
-- This FSM has 2 modes:
--   . copy the input data to the output (i_pattern_en=0)
--   . output an periodic patterns at full speeds (i_pattern_en=1)
  p_decode_state : process (data_r1, i_data, i_data_valid, i_pattern_en,
                            i_fifo_prog_full, sm_state_r1) is
  begin
    data_valid_next <= '0';
    data_next       <= data_r1;
    case sm_state_r1 is
      when E_RST =>
        sm_state_next <= E_WAIT;

      when E_WAIT =>
        if i_pattern_en = '1' and i_fifo_prog_full = '0' then
          data_valid_next         <= '1';
          data_next(31 downto 16) <= c_BAD_HEADER;
          data_next(15 downto 0)  <= (others => '0');
          sm_state_next           <= E_DATA0;
        -- generation pattern
        else
          -- copy input to output
          data_valid_next <= i_data_valid;
          data_next       <= i_data;
          sm_state_next   <= E_WAIT;
        end if;

      when E_DATA0 =>
        if i_fifo_prog_full = '0' then
          data_valid_next <= '1';
          data_next       <= c_DATA1;
          sm_state_next   <= E_DATA1;
        else
          sm_state_next <= E_DATA0;
        end if;

      when E_DATA1 =>
        if i_fifo_prog_full = '0' then
          data_valid_next <= '1';
          data_next       <= c_DATA2;
          sm_state_next   <= E_WAIT;
        else
          sm_state_next <= E_DATA1;
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
      sm_state_r1   <= sm_state_next;
      data_valid_r1 <= data_valid_next;
      data_r1       <= data_next;
    end if;
  end process p_state;

---------------------------------------------------------------------
-- output
---------------------------------------------------------------------
  o_fifo_data_valid <= data_valid_r1;
  o_fifo_data       <= data_r1;



end architecture RTL;
