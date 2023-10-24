----------------------------------------------------------------------------------
-- Company  : IRAP CNRS
-- Engineer : Bernard Bertrand
--
-- Create Date:    09/03/2016
-- Design Name:    manage_pipe_out
-- Module Name:    Ram test - RTL
-- Project Name:     ATHENA XIFU
-- Target Devices: xc7k160t
-- Tool versions:  ISE 14.7
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library UNISIM;
use UNISIM.VComponents.all;

entity manage_pipe_out is
  port(
    --  global
    clk   : in std_logic;
    okClk : in std_logic;
    reset : in std_logic;

    --  fifo interface
    rd_data_count : in std_logic_vector(16 downto 0);

    --  ctrl interface
    ep20wire_three : out std_logic_vector(31 downto 0)

    );
end entity;

architecture RTL of manage_pipe_out is


begin

  p_reshape : process (okClk, reset)
  begin
    if reset = '1' then
      ep20wire_three <= (others => '0');
    else

      if rising_edge(okClk) then
        ep20wire_three <= x"0000" & '0' & (rd_data_count(16 downto 2));
      end if;
    end if;
  end process p_reshape;


end RTL;
