----------------------------------------------------------------------------------
-- Company  : IRAP CNRS
-- Engineer : Bernard Bertrand
--
-- Create Date:    17:00:51 07/31/2015
-- Design Name:    Ramtester
-- Module Name:    Ramtest - RTL
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
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


---------------------------------------------------------------
--
-- PACKAGE
--
---------------------------------------------------------------
package Ramtest_pack is


  constant BANK_WIDTH   : integer := 3;  -- --// # of memory Bank Address bits.
  constant CK_WIDTH     : integer := 1;
  constant CS_WIDTH     : integer := 1;
  constant nCS_PER_RANK : integer := 1;
  constant CKE_WIDTH    : integer := 1;
  constant DM_WIDTH     : integer := 2;
  constant DQ_WIDTH     : integer := 16;
  constant DQS_WIDTH    : integer := 2;

  constant ROW_WIDTH   : integer := 15;
  constant ADDR_WIDTH  : integer := 29;
  constant nCK_PER_CLK : integer := 4;

  constant APP_DATA_WIDTH : integer := 128;  -- 2 * nCK_PER_CLK * PAYLOAD_WIDTH;
  constant APP_MASK_WIDTH : integer := 16;   -- APP_DATA_WIDTH / 8;

  -- =============================================================
  function endian64(rhs : std_logic_vector(63 downto 0)) return std_logic_vector;
  function endian32(rhs : std_logic_vector(31 downto 0)) return std_logic_vector;


end Ramtest_pack;

package body Ramtest_pack is
  -- =============================================================
  -- =============================================================
  function endian64(rhs : std_logic_vector(63 downto 0)) return std_logic_vector is
    variable x : std_logic_vector(63 downto 0);
  begin
    x(63 downto 56) := rhs(39 downto 32);
    x(55 downto 48) := rhs(47 downto 40);
    x(47 downto 40) := rhs(55 downto 48);
    x(39 downto 32) := rhs(63 downto 56);

    x(31 downto 24) := rhs(7 downto 0);
    x(23 downto 16) := rhs(15 downto 8);
    x(15 downto 8)  := rhs(23 downto 16);
    x(7 downto 0)   := rhs(31 downto 24);
    return x;
  end function endian64;
  -- =============================================================
  -- =============================================================
  function endian32(rhs : std_logic_vector(31 downto 0)) return std_logic_vector is
    variable x : std_logic_vector(31 downto 0);
  begin
    x(31 downto 24) := rhs(7 downto 0);
    x(23 downto 16) := rhs(15 downto 8);
    x(15 downto 8)  := rhs(23 downto 16);
    x(7 downto 0)   := rhs(31 downto 24);
    return x;
  end function endian32;

end Ramtest_pack;
