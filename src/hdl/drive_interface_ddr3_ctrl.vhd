----------------------------------------------------------------------------------
-- Company  : IRAP CNRS
-- Engineer : Bernard Bertrand
--
-- Create Date:    07/09/2015
-- Design Name:    usb_to_fmc
-- Module Name:    drive_interface_ddr3_ctrl - RTL
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


entity drive_interface_ddr3_ctrl is
  port(

    clk   : in std_logic;
    reset : in std_logic;

    calib_done        : in  std_logic;
--  //DDR Input Buffer (ib_)
    pipe_in_read      : out std_logic;
    pipe_in_data      : in  std_logic_vector(127 downto 0);
    pipe_in_rd_count  : in  std_logic_vector(7 downto 0);
    pipe_in_valid     : in  std_logic;
    pipe_in_empty     : in  std_logic;
--  //DDR Output Buffer (ob_)
    pipe_out_write    : out std_logic;
    pipe_out_data     : out std_logic_vector(127 downto 0);
    pipe_out_wr_count : in  std_logic_vector(7 downto 0);
    pipe_out_full     : in  std_logic;

    app_rdy  : in  std_logic;
    app_en   : out std_logic;
    app_cmd  : out std_logic_vector(2 downto 0);
    app_addr : out std_logic_vector(28 downto 0);

    app_rd_data       : in std_logic_vector(127 downto 0);
    app_rd_data_end   : in std_logic;
    app_rd_data_valid : in std_logic;

    app_wdf_rdy  : in  std_logic;
    app_wdf_wren : out std_logic;
    app_wdf_data : out std_logic_vector(127 downto 0);
    app_wdf_end  : out std_logic;
    app_wdf_mask : out std_logic_vector(15 downto 0);

    prog_empty : in std_logic;

    load_ep_wire         : out std_logic;
    fifo_filled          : in  std_logic;
    counter_BL_read_DRR3 : out std_logic_vector(31 downto 0);

    SYNC_OUT_3 : in std_logic_vector(31 downto 0);

    ddr3_stamp : out std_logic_vector(28 downto 0);

    buffer_new_cmd_byte_addr_wr : out std_logic_vector(54 downto 0);
    buffer_new_cmd_byte_addr_rd : out std_logic_vector(54 downto 0)

    );
end entity;

architecture RTL of drive_interface_ddr3_ctrl is

--  fsm manager
  type FSM_State_manager is (idle, write_ddr3, read_ddr3, wait_restart);
  signal state_manager : FSM_State_manager;

--  fsm_interface
  constant FIFO_SIZE           : integer := 256;
  constant BURST_UI_WORD_COUNT : integer := 2;  --'d1; //(WORD_SIZE*BURST_MODE/UI_SIZE) = BURST_UI_WORD_COUNT : 16*8/128 = 1

  constant ADDRESS_INCREMENT : std_logic_vector(4 downto 0) := b"01000";  --'d8; // UI Address is a word address. BL8 Burst Mode = 8.  Memory Width = 16.

  signal cmd_byte_addr_wr : std_logic_vector(57 downto 0);

  signal new_cmd_byte_addr_wr : std_logic_vector(54 downto 0);

  signal new_cmd_byte_addr_rd : std_logic_vector(54 downto 0);
  signal cmd_byte_addr_rd     : std_logic_vector(57 downto 0);

  signal write_mode     : std_logic;
  signal ack_write_mode : std_logic;
  signal read_mode      : std_logic;
  signal ack_read_mode  : std_logic;

  type FSM_State is (s_idle, s_write_0, s_write_1, s_write_2, s_write_3, s_write_4, s_read_0, s_read_1, s_read_2, s_read_3);
  signal state : FSM_State;

--  manage ep wire
  signal max_readed_rest : std_logic_vector(3 downto 0);
  signal cnt_readed_rest : std_logic_vector(3 downto 0);

  signal signal_app_en       : std_logic;
  signal signal_load_ep_wire : std_logic;

  signal counter_wait_dump_ddr3 : integer;

begin

  app_wdf_mask <= x"0000";

  app_en                      <= signal_app_en;
  buffer_new_cmd_byte_addr_wr <= new_cmd_byte_addr_wr;
  buffer_new_cmd_byte_addr_rd <= new_cmd_byte_addr_rd;


----------------------------------------
--  fsm_fsm_manager
-----------------------------------------
  p_fsm_manager : process(reset, clk)
  begin
    if reset = '1' then
      state_manager   <= idle;
      write_mode      <= '0';
      read_mode       <= '0';
      max_readed_rest <= (others => '0');
    else
      if clk = '1' and clk'event then

        signal_load_ep_wire <= '0';

        case state_manager is

          when idle =>
            if calib_done = '1' then
              if prog_empty = '1' and (new_cmd_byte_addr_wr /= new_cmd_byte_addr_rd) and pipe_out_full = '0' then
                state_manager <= read_ddr3;
              else
                state_manager <= write_ddr3;
              end if;
            end if;

          when write_ddr3 =>

            if write_mode = '0' then
              if (prog_empty = '0' or (new_cmd_byte_addr_wr = new_cmd_byte_addr_rd) or pipe_out_full = '1') and pipe_in_empty = '0' then
                read_mode  <= '0';
                write_mode <= '1';          --  remote write in ddr3
              else
                state_manager <= idle;      -- write ddr3 not needed
              end if;
            else
              state_manager <= write_ddr3;  --   wait last ack before idle
            end if;

            if ack_write_mode = '1' and write_mode = '1' then  --  ack data writed in ddr3
              write_mode <= '0';
              read_mode  <= '0';
            end if;

          when read_ddr3 =>

            if read_mode = '0' then
              if prog_empty = '1' and pipe_out_full = '0' then
                read_mode  <= '1';
                write_mode <= '0';
                if (new_cmd_byte_addr_wr = new_cmd_byte_addr_rd) then
                  --  write and read adress is same
                  max_readed_rest <= (others => '0');
                  state_manager   <= idle;
                  read_mode       <= '0';
                else
                  if (new_cmd_byte_addr_wr - new_cmd_byte_addr_rd) < x"4" then
                    --  write and read adress is almost same
                    max_readed_rest <= new_cmd_byte_addr_wr(3 downto 0) - new_cmd_byte_addr_rd(3 downto 0);
                  else
                    --  default mode read
                    max_readed_rest <= x"4";
                  end if;
                end if;
              else
                state_manager <= idle;     -- read ddr3 not needed
              end if;
            else
              state_manager <= read_ddr3;  --  wait last ack read before idle
            end if;

            --  ack data readed in ddr3
            if ack_read_mode = '1' and read_mode = '1' then
              read_mode  <= '0';
              write_mode <= '0';
            end if;

          when others =>

        end case;
      end if;
    end if;
  end process p_fsm_manager;

--------------------------------------------
--  fsm_interface
---------------------------------------------
  p_fsm_interface : process(reset, clk)
  begin
    if reset = '1' then
      state            <= s_idle;
      cmd_byte_addr_wr <= (others => '0');
      cmd_byte_addr_rd <= (others => '0');
      signal_app_en    <= '0';
      app_cmd          <= b"000";
      app_addr         <= (others => '0');
      app_wdf_wren     <= '0';
      app_wdf_end      <= '0';
      ack_write_mode   <= '0';
      ack_read_mode    <= '0';
      pipe_in_read     <= '0';
      pipe_out_write   <= '0';
      pipe_out_data    <= (others => '0');
      app_wdf_data     <= (others => '0');

      new_cmd_byte_addr_rd <= (others => '0');

      new_cmd_byte_addr_wr <= (others => '0');
      cnt_readed_rest      <= (others => '0');

    else
      if clk = '1' and clk'event then
        signal_app_en  <= '0';
        app_wdf_wren   <= '0';
        app_wdf_end    <= '0';
        pipe_in_read   <= '0';
        pipe_out_write <= '0';
        ack_write_mode <= '0';
        ack_read_mode  <= '0';

        case state is

          when s_idle =>
            if (calib_done = '1' and write_mode = '1') then  -- read data in pipe_in and write ddr3
              app_addr <= cmd_byte_addr_wr(28 downto 0);  -- boundary ddr3 adress on 11 bits
              state    <= s_write_0;
            else
              if (calib_done = '1' and read_mode = '1') then  --read data in ddr3 and write in pipe out
                app_addr <= cmd_byte_addr_rd(28 downto 0);  -- boundary ddr3 adress on 11 bits
                state    <= s_read_0;
              end if;
            end if;

          when s_write_0 =>
            state        <= s_write_1;  -- read data in pipe in
            pipe_in_read <= '1';

          when s_write_1 =>

            if pipe_in_valid = '1' then  --   transfer data on ddr3 bus
              app_wdf_data <= pipe_in_data;
              state        <= s_write_2;
            end if;

          when s_write_2 =>

            if app_wdf_rdy = '1' then
              state <= s_write_3;
            end if;

          when s_write_3 =>             -- write data in ddr3

            app_wdf_wren <= '1';
            app_wdf_end  <= '1';

            if (app_wdf_rdy = '1') then  --  acknowledge data is writed in ddr3
              signal_app_en  <= '1';
              app_cmd        <= b"000";
              state          <= s_write_4;
              ack_write_mode <= '1';     -- disable remote write
            end if;

          when s_write_4 =>             -- increment address

            if (app_rdy = '1') then
              cmd_byte_addr_wr     <= cmd_byte_addr_wr + ADDRESS_INCREMENT;  --  set address data for next remote write
              new_cmd_byte_addr_wr <= cmd_byte_addr_wr(57 downto 3) + 1;
              state                <= s_idle;
            else
              signal_app_en <= '1';
              app_cmd       <= b"000";
            end if;

          when s_read_0 =>              -- read data in ddr3

            signal_app_en   <= '1';     -- launch first read
            app_cmd         <= b"001";
            state           <= s_read_1;
            cnt_readed_rest <= (others => '0');

          when s_read_1 =>

            if app_rdy = '0' and signal_app_en = '1' then  --  previous read data don't work, relaunch read
              signal_app_en <= '1';
            else
              if cnt_readed_rest < max_readed_rest-1 then
                if (app_rdy = '1') then                    -- launch one read
                  app_addr         <= cmd_byte_addr_rd(28 downto 0) + ADDRESS_INCREMENT;  -- boundary ddr3 adress on 11 bits
                  cmd_byte_addr_rd <= cmd_byte_addr_rd + ADDRESS_INCREMENT;
                  signal_app_en    <= '1';
                  cnt_readed_rest  <= cnt_readed_rest + 1;
                else
                  signal_app_en <= '1';
                  app_cmd       <= b"001";
                end if;
              else
                cmd_byte_addr_rd     <= cmd_byte_addr_rd + ADDRESS_INCREMENT;  --  set address data for next remote read
                new_cmd_byte_addr_rd <= cmd_byte_addr_rd(57 downto 3) + 1;
                state                <= s_read_2;
                cnt_readed_rest      <= (others => '0');
              end if;
            end if;

          when s_read_2 =>
            if cnt_readed_rest <= max_readed_rest-1 then
              if (app_rd_data_valid = '1') then  --  incoming valid data
                pipe_out_data   <= app_rd_data;
                pipe_out_write  <= '1';          --  write data pipe out
                cnt_readed_rest <= cnt_readed_rest + 1;
              end if;
            else
              state           <= s_read_3;
              cnt_readed_rest <= (others => '0');
              ack_read_mode   <= '1';            -- disable remote read

            end if;

          when s_read_3 =>
            state <= s_idle;

          when others =>

        end case;

      end if;
    end if;
  end process p_fsm_interface;


end RTL;
