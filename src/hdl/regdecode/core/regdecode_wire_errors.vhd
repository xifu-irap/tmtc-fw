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
--    @file                   regdecode_wire_errors.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--   @details
--
--   This module synchronizes the input errors/status from the i_out_clk source clock domain to the i_clk destination clock domain.
--
--
--   The architecture is as follows:
--
--   i_data ---------> resync register -------> o_data
--
--   Note:
--     The signals shouldn't often change. So, to save ressources, no FIFO will be used.
--     Instead, we'll use registers (be aware bus bits may not be aligned) during few clock cycles.
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg_regdecode.all;
use work.pkg_utils.all;

entity regdecode_wire_errors is
  generic(
    g_ERROR_SEL_WIDTH : integer := 4  -- define the width of the error selection
    );
  port(
    ---------------------------------------------------------------------
    -- input @i_out_clk
    ---------------------------------------------------------------------
    i_out_clk          : in std_logic;  -- clock
    -- errors
    i_reg_wire_errors1 : in std_logic_vector(31 downto 0);  -- errors value
    i_reg_wire_errors0 : in std_logic_vector(31 downto 0);  -- errors value
    -- status
    i_reg_wire_status1 : in std_logic_vector(31 downto 0);  -- status value
    i_reg_wire_status0 : in std_logic_vector(31 downto 0);  -- status value

    ---------------------------------------------------------------------
    -- input @i_clk
    ---------------------------------------------------------------------
    i_clk             : in  std_logic;  -- clock
    i_error_sel       : in  std_logic_vector(g_ERROR_SEL_WIDTH - 1 downto 0);  -- select the errors/status to output
    -- errors
    i_usb_reg_errors2 : in  std_logic_vector(31 downto 0);  -- errors value
    i_usb_reg_errors1 : in  std_logic_vector(31 downto 0);  -- errors value
    i_usb_reg_errors0 : in  std_logic_vector(31 downto 0);  -- errors value
    -- status
    i_usb_reg_status2 : in  std_logic_vector(31 downto 0);  -- status value
    i_usb_reg_status1 : in  std_logic_vector(31 downto 0);  -- status value
    i_usb_reg_status0 : in  std_logic_vector(31 downto 0);  -- status value
    ---------------------------------------------------------------------
    -- output @ i_clk
    ---------------------------------------------------------------------
    o_wire_errors     : out std_logic_vector(31 downto 0);  -- output errors
    o_wire_status     : out std_logic_vector(31 downto 0)   -- output status
    );
end entity regdecode_wire_errors;

architecture RTL of regdecode_wire_errors is

-- define the number of wire @i_clk_out
  constant c_NB_WIRE : integer := 2;

-- define the number total of selectable wire
  constant c_NB_WIRE_TOT : integer := 5;

-- define the type: array of wire
  type t_wire_array is array (natural range <>) of std_logic_vector(31 downto 0);

---------------------------------------------------------------------
-- cross clock domain: i_clk_out -> i_clk
---------------------------------------------------------------------
-- temporary input pipe: error
  signal error_array_tmp0        : t_wire_array(c_NB_WIRE - 1 downto 0);
-- temporary output pipe: error
  signal error_array_tmp1        : t_wire_array(c_NB_WIRE - 1 downto 0);
-- resynchonized temporary output pipe : error
  signal resync_error_array_tmp2 : t_wire_array(c_NB_WIRE - 1 downto 0);

-- temporary input pipe: status
  signal status_array_tmp0        : t_wire_array(c_NB_WIRE - 1 downto 0);
-- temporary output pipe: status
  signal status_array_tmp1        : t_wire_array(c_NB_WIRE - 1 downto 0);
-- resynchonized temporary output pipe : status
  signal resync_status_array_tmp2 : t_wire_array(c_NB_WIRE - 1 downto 0);


  ---------------------------------------------------------------------
  -- errors/status selection
  ---------------------------------------------------------------------
  -- array of selectable errors
  signal errors_array_tmp : t_wire_array(c_NB_WIRE_TOT - 1 downto 0);
  -- array of selectable status
  signal status_array_tmp : t_wire_array(c_NB_WIRE_TOT - 1 downto 0);
  -- selected errors
  signal errors_r1        : std_logic_vector(31 downto 0);
  -- selected status
  signal status_r1        : std_logic_vector(31 downto 0);



begin

---------------------------------------------------------------------
-- errors cross clock domaine: i_out_clk -> i_clk
---------------------------------------------------------------------
  error_array_tmp0(1) <= i_reg_wire_errors1;
  error_array_tmp0(0) <= i_reg_wire_errors0;
  gen_resync_wire_error : for i in error_array_tmp0'range generate
  begin
-- add input pipe
    inst_pipeliner_with_init : entity work.pipeliner_with_init
      generic map(
        -- register init value
        g_INIT       => '0',
        -- number of consecutives registers. Possibles values: [0, integer max value[
        g_NB_PIPES   => 1,
        -- width of the input/output data.  Possibles values: [1, integer max value[
        g_DATA_WIDTH => error_array_tmp0(i)'length
        )
      port map(
        -- clock
        i_clk  => i_out_clk,
        -- input data
        i_data => error_array_tmp0(i),
        -- output data with/without delay
        o_data => error_array_tmp1(i)
        );

    inst_synchronizer : entity work.synchronizer
      generic map(
        -- Initial value of synchronizer registers upon startup, 1'b0 or 1'b1.
        g_INIT            => '0',
        -- Integer value. Number of synchronizing registers, must be 2 or higher
        g_SYNC_STAGES     => 2,
        -- Integer value. Number of registers at the output of the synchronizer for the purpose of improving performance. Possible values: [1; integer max value [
        g_PIPELINE_STAGES => 1,
        -- data width expressed in bits
        g_DATA_WIDTH      => error_array_tmp1(i)'length
        )
      port map(
        ---------------------------------------------------------------------
        -- input
        ---------------------------------------------------------------------
        -- async input
        i_async_data => error_array_tmp1(i),
        ---------------------------------------------------------------------
        -- output
        ---------------------------------------------------------------------
        -- output clock
        i_clk        => i_clk,
        -- output data with/without delay
        o_data       => resync_error_array_tmp2(i)
        );

  end generate gen_resync_wire_error;

---------------------------------------------------------------------
-- status cross clock domaine: i_out_clk -> i_clk
---------------------------------------------------------------------
  status_array_tmp0(1) <= i_reg_wire_status1;
  status_array_tmp0(0) <= i_reg_wire_status0;
  gen_resync_wire_status : for i in error_array_tmp0'range generate
  begin
-- add input pipe
    inst_pipeliner_with_init : entity work.pipeliner_with_init
      generic map(
        -- register init value
        g_INIT       => '0',
        -- number of consecutives registers. Possibles values: [0, integer max value[
        g_NB_PIPES   => 1,
        -- width of the input/output data.  Possibles values: [1, integer max value[
        g_DATA_WIDTH => status_array_tmp0(i)'length
        )
      port map(
        -- clock
        i_clk  => i_out_clk,
        -- input data
        i_data => status_array_tmp0(i),
        -- output data with/without delay
        o_data => status_array_tmp1(i)
        );

    inst_synchronizer : entity work.synchronizer
      generic map(
        -- Initial value of synchronizer registers upon startup, 1'b0 or 1'b1.
        g_INIT            => '0',
        -- Integer value. Number of synchronizing registers, must be 2 or higher
        g_SYNC_STAGES     => 2,
        -- Integer value. Number of registers at the output of the synchronizer for the purpose of improving performance. Possible values: [1; integer max value [
        g_PIPELINE_STAGES => 1,
        -- data width expressed in bits
        g_DATA_WIDTH      => status_array_tmp1(i)'length
        )
      port map(
        ---------------------------------------------------------------------
        -- input
        ---------------------------------------------------------------------
        -- async input
        i_async_data => status_array_tmp1(i),
        ---------------------------------------------------------------------
        -- output
        ---------------------------------------------------------------------
        -- output clock
        i_clk        => i_clk,
        -- output data with/without delay
        o_data       => resync_status_array_tmp2(i)
        );

  end generate gen_resync_wire_status;

-----------------------------------------------------------------
  -- select output errors and
  -- for each error word, generate an associated trig bit if the error value is different of 0
  -----------------------------------------------------------------
  errors_array_tmp(4) <= resync_error_array_tmp2(1);
  errors_array_tmp(3) <= resync_error_array_tmp2(0);
  errors_array_tmp(2) <= i_usb_reg_errors2;
  errors_array_tmp(1) <= i_usb_reg_errors1;
  errors_array_tmp(0) <= i_usb_reg_errors0;


  status_array_tmp(4) <= resync_status_array_tmp2(1);
  status_array_tmp(3) <= resync_status_array_tmp2(0);
  status_array_tmp(2) <= i_usb_reg_status2;
  status_array_tmp(1) <= i_usb_reg_status1;
  status_array_tmp(0) <= i_usb_reg_status0;

  ---------------------------------------------------------------------
  -- Select the error/status value
  ---------------------------------------------------------------------
  p_select_error_status : process(i_clk) is
  begin
    if rising_edge(i_clk) then
      case i_error_sel is
        when "000" =>
          errors_r1 <= errors_array_tmp(0);
          status_r1 <= status_array_tmp(0);
        when "001" =>
          errors_r1 <= errors_array_tmp(1);
          status_r1 <= status_array_tmp(1);
        when "010" =>
          errors_r1 <= errors_array_tmp(2);
          status_r1 <= status_array_tmp(2);
        when "011" =>
          errors_r1 <= errors_array_tmp(3);
          status_r1 <= status_array_tmp(3);
        when others =>
          errors_r1 <= errors_array_tmp(4);
          status_r1 <= status_array_tmp(4);
      end case;
    end if;
  end process p_select_error_status;

  ---------------------------------------------------------------------
  -- output
  ---------------------------------------------------------------------
  o_wire_errors <= errors_r1;
  o_wire_status <= status_r1;


end architecture RTL;
