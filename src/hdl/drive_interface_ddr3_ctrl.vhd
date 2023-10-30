-- -------------------------------------------------------------------------------------------------------------
--                            Copyright (C) 2023-2030 Ken-ji de la ROSA, IRAP Toulouse.
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
--!   @file                   drive_interface_ddr3_ctrl.vhd
--    reference design        Bernard Bertrand (IRAP Toulouse)
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--!   @details
--
--            Manage the DDR user interface
--
-- -------------------------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


entity drive_interface_ddr3_ctrl is
  port(

    i_clk : in std_logic;
    i_rst : in std_logic;

    i_calib_done   : in  std_logic;
--  //DDR Input Buffer (ib_)
    o_pipe_in_read : out std_logic;
    i_pipe_in_data : in  std_logic_vector(127 downto 0);

    i_pipe_in_valid  : in  std_logic;
    i_pipe_in_empty  : in  std_logic;
--  //DDR Output Buffer (ob_)
    o_pipe_out_write : out std_logic;
    o_pipe_out_data  : out std_logic_vector(127 downto 0);
    i_pipe_out_full  : in  std_logic;

    i_app_rdy  : in  std_logic;
    o_app_en   : out std_logic;
    o_app_cmd  : out std_logic_vector(2 downto 0);
    o_app_addr : out std_logic_vector(28 downto 0);

    i_app_rd_data       : in std_logic_vector(127 downto 0);
    i_app_rd_data_valid : in std_logic;

    i_app_wdf_rdy  : in  std_logic;
    o_app_wdf_wren : out std_logic;
    o_app_wdf_data : out std_logic_vector(127 downto 0);
    o_app_wdf_end  : out std_logic;
    o_app_wdf_mask : out std_logic_vector(15 downto 0);

    i_prog_empty : in std_logic;

    o_buffer_new_cmd_byte_addr_wr : out std_logic_vector(54 downto 0);
    o_buffer_new_cmd_byte_addr_rd : out std_logic_vector(54 downto 0)

    );
end entity;

architecture RTL of drive_interface_ddr3_ctrl is

--  fsm manager
  type t_fsm_state_manager is (E_IDLE, E_WRITE_DDR3, E_READ_DDR3, E_WAIT_RESTART);
  signal sm_state_manager_r1 : t_fsm_state_manager;

--  fsm_interface

  constant c_ADDRESS_INCREMENT : std_logic_vector(4 downto 0) := b"01000";  --'d8; // UI Address is a word address. BL8 Burst Mode = 8.  Memory Width = 16.

  signal cmd_byte_addr_wr_r1 : std_logic_vector(57 downto 0);

  signal new_cmd_byte_addr_wr_r1 : std_logic_vector(54 downto 0);

  signal new_cmd_byte_addr_rd_r1 : std_logic_vector(54 downto 0);
  signal cmd_byte_addr_rd_r1     : std_logic_vector(57 downto 0);

  signal write_mode_r1     : std_logic;
  signal ack_write_mode_r1 : std_logic;
  signal read_mode_r1      : std_logic;
  signal ack_read_mode_r1  : std_logic;

  type t_fsm_state is (E_IDLE, E_WRITE0, E_WRITE1, E_WRITE2, E_WRITE3, E_WRITE4, E_READ0, E_READ1, E_READ2, E_READ3);
  signal sm_state_r1 : t_fsm_state;

--  manage ep wire
  signal max_readed_rest_r1 : std_logic_vector(3 downto 0);
  signal cnt_readed_rest_r1 : std_logic_vector(3 downto 0);

  signal signal_app_en_r1 : std_logic;


begin

  o_app_wdf_mask <= x"0000";

  o_app_en                      <= signal_app_en_r1;
  o_buffer_new_cmd_byte_addr_wr <= new_cmd_byte_addr_wr_r1;
  o_buffer_new_cmd_byte_addr_rd <= new_cmd_byte_addr_rd_r1;


----------------------------------------
--  fsm_fsm_manager
-----------------------------------------
  p_fsm_manager : process(i_rst, i_clk)
  begin
    if i_rst = '1' then
      sm_state_manager_r1 <= E_IDLE;
      write_mode_r1       <= '0';
      read_mode_r1        <= '0';
      max_readed_rest_r1  <= (others => '0');
    else
      if i_clk = '1' and i_clk'event then

        case sm_state_manager_r1 is

          when E_IDLE =>
            if i_calib_done = '1' then
              if i_prog_empty = '1' and (new_cmd_byte_addr_wr_r1 /= new_cmd_byte_addr_rd_r1) and i_pipe_out_full = '0' then
                sm_state_manager_r1 <= E_READ_DDR3;
              else
                sm_state_manager_r1 <= E_WRITE_DDR3;
              end if;
            end if;

          when E_WRITE_DDR3 =>

            if write_mode_r1 = '0' then
              if (i_prog_empty = '0' or (new_cmd_byte_addr_wr_r1 = new_cmd_byte_addr_rd_r1) or i_pipe_out_full = '1') and i_pipe_in_empty = '0' then
                read_mode_r1  <= '0';
                write_mode_r1 <= '1';   --  remote write in ddr3
              else
                sm_state_manager_r1 <= E_IDLE;      -- write ddr3 not needed
              end if;
            else
              sm_state_manager_r1 <= E_WRITE_DDR3;  --   wait last ack before idle
            end if;

            if ack_write_mode_r1 = '1' and write_mode_r1 = '1' then  --  ack data writed in ddr3
              write_mode_r1 <= '0';
              read_mode_r1  <= '0';
            end if;

          when E_READ_DDR3 =>

            if read_mode_r1 = '0' then
              if i_prog_empty = '1' and i_pipe_out_full = '0' then
                read_mode_r1  <= '1';
                write_mode_r1 <= '0';
                if (new_cmd_byte_addr_wr_r1 = new_cmd_byte_addr_rd_r1) then
                  --  write and read adress is same
                  max_readed_rest_r1  <= (others => '0');
                  sm_state_manager_r1 <= E_IDLE;
                  read_mode_r1        <= '0';
                else
                  if (new_cmd_byte_addr_wr_r1 - new_cmd_byte_addr_rd_r1) < x"4" then
                    --  write and read adress is almost same
                    max_readed_rest_r1 <= new_cmd_byte_addr_wr_r1(3 downto 0) - new_cmd_byte_addr_rd_r1(3 downto 0);
                  else
                    --  default mode read
                    max_readed_rest_r1 <= x"4";
                  end if;
                end if;
              else
                sm_state_manager_r1 <= E_IDLE;     -- read ddr3 not needed
              end if;
            else
              sm_state_manager_r1 <= E_READ_DDR3;  --  wait last ack read before idle
            end if;

            --  ack data readed in ddr3
            if ack_read_mode_r1 = '1' and read_mode_r1 = '1' then
              read_mode_r1  <= '0';
              write_mode_r1 <= '0';
            end if;

          when others =>

        end case;
      end if;
    end if;
  end process p_fsm_manager;

--------------------------------------------
--  fsm_interface
---------------------------------------------
  p_fsm_interface : process(i_rst, i_clk)
  begin
    if i_rst = '1' then
      sm_state_r1         <= E_IDLE;
      cmd_byte_addr_wr_r1 <= (others => '0');
      cmd_byte_addr_rd_r1 <= (others => '0');
      signal_app_en_r1    <= '0';
      o_app_cmd           <= b"000";
      o_app_addr          <= (others => '0');
      o_app_wdf_wren      <= '0';
      o_app_wdf_end       <= '0';
      ack_write_mode_r1   <= '0';
      ack_read_mode_r1    <= '0';
      o_pipe_in_read      <= '0';
      o_pipe_out_write    <= '0';
      o_pipe_out_data     <= (others => '0');
      o_app_wdf_data      <= (others => '0');

      new_cmd_byte_addr_rd_r1 <= (others => '0');

      new_cmd_byte_addr_wr_r1 <= (others => '0');
      cnt_readed_rest_r1      <= (others => '0');

    else
      if i_clk = '1' and i_clk'event then
        signal_app_en_r1  <= '0';
        o_app_wdf_wren    <= '0';
        o_app_wdf_end     <= '0';
        o_pipe_in_read    <= '0';
        o_pipe_out_write  <= '0';
        ack_write_mode_r1 <= '0';
        ack_read_mode_r1  <= '0';

        case sm_state_r1 is

          when E_IDLE =>
            if (i_calib_done = '1' and write_mode_r1 = '1') then  -- read data in pipe_in and write ddr3
              o_app_addr  <= cmd_byte_addr_wr_r1(28 downto 0);  -- boundary ddr3 adress on 11 bits
              sm_state_r1 <= E_WRITE0;
            else
              if (i_calib_done = '1' and read_mode_r1 = '1') then  --read data in ddr3 and write in pipe out
                o_app_addr  <= cmd_byte_addr_rd_r1(28 downto 0);  -- boundary ddr3 adress on 11 bits
                sm_state_r1 <= E_READ0;
              end if;
            end if;

          when E_WRITE0 =>
            sm_state_r1    <= E_WRITE1;  -- read data in pipe in
            o_pipe_in_read <= '1';

          when E_WRITE1 =>

            if i_pipe_in_valid = '1' then  --   transfer data on ddr3 bus
              o_app_wdf_data <= i_pipe_in_data;
              sm_state_r1    <= E_WRITE2;
            end if;

          when E_WRITE2 =>

            if i_app_wdf_rdy = '1' then
              sm_state_r1 <= E_WRITE3;
            end if;

          when E_WRITE3 =>              -- write data in ddr3

            o_app_wdf_wren <= '1';
            o_app_wdf_end  <= '1';

            if (i_app_wdf_rdy = '1') then  --  acknowledge data is writed in ddr3
              signal_app_en_r1  <= '1';
              o_app_cmd         <= b"000";
              sm_state_r1       <= E_WRITE4;
              ack_write_mode_r1 <= '1';    -- disable remote write
            end if;

          when E_WRITE4 =>              -- increment address

            if (i_app_rdy = '1') then
              cmd_byte_addr_wr_r1     <= cmd_byte_addr_wr_r1 + c_ADDRESS_INCREMENT;  --  set address data for next remote write
              new_cmd_byte_addr_wr_r1 <= cmd_byte_addr_wr_r1(57 downto 3) + 1;
              sm_state_r1             <= E_IDLE;
            else
              signal_app_en_r1 <= '1';
              o_app_cmd        <= b"000";
            end if;

          when E_READ0 =>               -- read data in ddr3

            signal_app_en_r1   <= '1';  -- launch first read
            o_app_cmd          <= b"001";
            sm_state_r1        <= E_READ1;
            cnt_readed_rest_r1 <= (others => '0');

          when E_READ1 =>

            if i_app_rdy = '0' and signal_app_en_r1 = '1' then  --  previous read data don't work, relaunch read
              signal_app_en_r1 <= '1';
            else
              if cnt_readed_rest_r1 < max_readed_rest_r1-1 then
                if (i_app_rdy = '1') then  -- launch one read
                  o_app_addr          <= cmd_byte_addr_rd_r1(28 downto 0) + c_ADDRESS_INCREMENT;  -- boundary ddr3 adress on 11 bits
                  cmd_byte_addr_rd_r1 <= cmd_byte_addr_rd_r1 + c_ADDRESS_INCREMENT;
                  signal_app_en_r1    <= '1';
                  cnt_readed_rest_r1  <= cnt_readed_rest_r1 + 1;
                else
                  signal_app_en_r1 <= '1';
                  o_app_cmd        <= b"001";
                end if;
              else
                cmd_byte_addr_rd_r1     <= cmd_byte_addr_rd_r1 + c_ADDRESS_INCREMENT;  --  set address data for next remote read
                new_cmd_byte_addr_rd_r1 <= cmd_byte_addr_rd_r1(57 downto 3) + 1;
                sm_state_r1             <= E_READ2;
                cnt_readed_rest_r1      <= (others => '0');
              end if;
            end if;

          when E_READ2 =>
            if cnt_readed_rest_r1 <= max_readed_rest_r1-1 then
              if (i_app_rd_data_valid = '1') then  --  incoming valid data
                o_pipe_out_data    <= i_app_rd_data;
                o_pipe_out_write   <= '1';         --  write data pipe out
                cnt_readed_rest_r1 <= cnt_readed_rest_r1 + 1;
              end if;
            else
              sm_state_r1        <= E_READ3;
              cnt_readed_rest_r1 <= (others => '0');
              ack_read_mode_r1   <= '1';           -- disable remote read

            end if;

          when E_READ3 =>
            sm_state_r1 <= E_IDLE;

          when others =>

        end case;

      end if;
    end if;
  end process p_fsm_interface;


end RTL;
