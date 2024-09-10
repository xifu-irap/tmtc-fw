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
--    @file                   endianess_change_by_generic.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    According the input generic value, change or not the input data endianess
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity endianess_change_by_generic is
  generic (
    -- False: no change, True: data byte are swapped
    g_ENDIANESS_CHANGE : boolean := false;
    -- width of the input data bus. The value must be a multiple of 8.
    g_DATA_WIDTH       : integer := 32;
    --0: no delay, 1: one tap delay and so on.
    g_OUTPUT_DELAY     : integer := 0
    );
  port (

    ---------------------------------------------------------------------
    -- input
    ---------------------------------------------------------------------
    -- clock
    i_clk        : in std_logic;
    -- input data valid
    i_data_valid : in std_logic;
    -- input data
    i_data       : in std_logic_vector(g_DATA_WIDTH - 1 downto 0);

    ---------------------------------------------------------------------
    -- output
    ---------------------------------------------------------------------
    -- output data valid
    o_data_valid : out std_logic;
    -- output data
    o_data       : out std_logic_vector(g_DATA_WIDTH - 1 downto 0)

    );
end entity endianess_change_by_generic;

architecture RTL of endianess_change_by_generic is

  -- Minimum Number of bytes to represent the input data
  constant c_NB_BYTES : integer := integer(g_DATA_WIDTH/8);

-- endianess conversion
  signal data_tmp : std_logic_vector(i_data'range);

---------------------------------------------------------------------
-- optional output delay
---------------------------------------------------------------------
  -- index0: low
  constant c_IDX0_L : integer := 0;
  -- index0: high
  constant c_IDX0_H : integer := c_IDX0_L + i_data'length - 1;

  -- index1: low
  constant c_IDX1_L : integer := c_IDX0_H + 1;
  -- index1: high
  constant c_IDX1_H : integer := c_IDX1_L + 1 - 1;

  -- temporary input pipe
  signal data_pipe_tmp0 : std_logic_vector(c_IDX1_H downto 0);
  -- temporary output pipe
  signal data_pipe_tmp1 : std_logic_vector(c_IDX1_H downto 0);

  -- data valid
  signal data_valid1 : std_logic;
  -- data
  signal data1       : std_logic_vector(i_data'range);

begin

---------------------------------------------------------------------
-- Endianess change or not
---------------------------------------------------------------------
  no_endianess_change : if g_ENDIANESS_CHANGE = false generate
    data_tmp <= i_data;
  end generate no_endianess_change;

  endianess_change : if g_ENDIANESS_CHANGE generate
    swap_byte : for i in 0 to (c_NB_BYTES - 1) generate
      data_tmp(8*(i+1) - 1 downto 8*i) <= i_data((i_data'length - 8*i - 1) downto (i_data'length - 8*(i+1)));
    end generate swap_byte;

  end generate endianess_change;

---------------------------------------------------------------------
-- optional output delay
---------------------------------------------------------------------
  data_pipe_tmp0(c_IDX1_H)                 <= i_data_valid;
  data_pipe_tmp0(c_IDX0_H downto c_IDX0_L) <= data_tmp;

  inst_pipeliner_with_init_optional_pipe : entity work.pipeliner_with_init
    generic map(
      g_INIT       => '0',
      g_NB_PIPES   => g_OUTPUT_DELAY,  -- number of consecutives registers. Possibles values: [0, integer max value[
      g_DATA_WIDTH => data_pipe_tmp0'length  -- width of the input/output data.  Possibles values: [1, integer max value[
      )
    port map(
      i_clk  => i_clk,
      i_data => data_pipe_tmp0,
      o_data => data_pipe_tmp1
      );

  data_valid1 <= data_pipe_tmp1(c_IDX1_H);
  data1       <= data_pipe_tmp1(c_IDX0_H downto c_IDX0_L);


---------------------------------------------------------------------
-- output
---------------------------------------------------------------------
o_data_valid <= data_valid1;
o_data       <=  data1;

end architecture RTL;
