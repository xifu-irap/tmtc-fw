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
--!   @file                   science_data_rx.vhd
--    reference design        Paul MARBEAU (IRAP Toulouse)
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--!   @details
--
--             Management of the science link.
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.science_data_rx_package.all;

entity science_data_rx is
  port (
    -- reset
    i_rst         : in std_logic;
    -- science clock
    i_clk_science : in std_logic_vector(pkg_LINK_NUMBER-1 downto 0);

    -- detect the science synchro words
    o_start_detected : out std_logic_vector(pkg_LINK_NUMBER-1 downto 0);

    -- science control bit
    i_science_ctrl : in std_logic_vector((pkg_COL_NUMBER/2)-1 downto 0);
    -- science data bit
    i_science_data : in std_logic_vector(pkg_LINE_NUMBER-1 downto 0);
    -- science data valid
    i_data_rate_en : in std_logic;

    --  output data
    o_data_instrument : out std_logic_vector(127 downto 0);
    -- output data valid
    o_wr_instrument   : out std_logic

    );

end science_data_rx;

architecture RTL of science_data_rx is

  -- frame index
  signal cpt_fifo_r1   : integer;
  -- count the number of frames
  signal cpt_frame_r1  : integer;
  -- output data valid
  signal write_data_r1 : std_logic;

  -- array of data words (deserialized)
  signal data_out   : t_ARRAY8bits;
  -- array of ctrl words (deserialized)
  signal CTRL       : t_ARRAY8bits_ctrl;
  -- array of complete word
  signal data_ready : std_logic_vector((pkg_COL_NUMBER/2)-1 downto 0);

  -- array of ctrl words (deserialized)
  signal ctrl_r1       : t_ARRAY8bits_ctrl;
  -- delayed array of ctrl words (step2)
  signal ctrl_r2       : t_ARRAY8bits_ctrl;
  -- delayed array of ctrl words (step3)
  signal ctrl_r3       : t_ARRAY8bits_ctrl;
  -- array of data_ready (one by link)
  signal data_ready_r1 : std_logic_vector (pkg_LINK_NUMBER-1 downto 0);
  -- array of data words (deserialized)
  signal data_out_r1   : t_ARRAY8bits;
  -- delayed array of data words (step2)
  signal data_out_r2   : t_ARRAY8bits;
  -- delayed array of data words (step3)
  signal data_out_r3   : t_ARRAY8bits;
  -- arrays of frame
  signal frame_r4      : t_ARRAY96bits(0 to 3);
  -- delayed arrays of frame
  signal frame_fifo_r5 : t_ARRAY128bits (0 to 2);

  -- resynchronization flag
  signal start_maker_r1 : std_logic;
  -- count the clock cycle for the resynchronization
  signal cpt_synchro_r1 : std_logic_vector(1 downto 0);

  -- fpga specific attribute: force to use registers (very close)
  attribute ASYNC_REG                : string;
  -- apply attribute on reg_ctrl_r2
  attribute ASYNC_REG of ctrl_r2     : signal is "TRUE";
  -- apply attribute on reg_ctrl_r3
  attribute ASYNC_REG of ctrl_r3     : signal is "TRUE";
  -- apply attribute on reg_data_out_r2
  attribute ASYNC_REG of data_out_r2 : signal is "TRUE";
  -- apply attribute on reg_data_out_r3
  attribute ASYNC_REG of data_out_r3 : signal is "TRUE";

begin

  -- ------------------------------------------------------------------------------------------------------
  --   deserialyze data
  -- ------------------------------------------------------------------------------------------------------
  gen_science_data_rx_fsm : for I in pkg_LINK_NUMBER - 1 downto 0 generate
    gen_science_data_rx_fsm_link : for N in (pkg_LINE_NUMBER/2)-1 downto 0 generate
      inst_science_data_rx_fsm : entity work.science_data_rx_fsm
        port map (

          -- global
          i_rst          => i_rst,
          i_clk_science  => i_clk_science(I),
          i_data_rate_en => i_data_rate_en,

          -- Link
          i_science_ctrl => i_science_ctrl(I),
          i_science_data => i_science_data(4*I+N),

          -- deserialize
          o_ctrl       => open,
          o_data       => data_out(4*I+N),
          o_data_ready => open
          );
    end generate gen_science_data_rx_fsm_link;
  end generate gen_science_data_rx_fsm;

  -- ------------------------------------------------------------------------------------------------------
  --   deserialyze CTRL and generate ready
  -- ------------------------------------------------------------------------------------------------------
  gen_science_ctrl_rx_fsm : for N in pkg_LINK_NUMBER-1 downto 0 generate
    inst_ctrl_rx_fsm : entity work.ctrl_rx_fsm
      port map (
        -- global
        i_rst          => i_rst,
        i_clk_science  => i_clk_science(N),
        i_data_rate_en => i_data_rate_en,

        -- Link
        i_science_ctrl => i_science_ctrl(N),

        -- deserialize
        o_start_detected => o_start_detected(N),
        o_ctrl           => CTRL(N),
        o_data_ready     => data_ready(N)
        );
  end generate gen_science_ctrl_rx_fsm;

  -- ------------------------------------------------------------------------------------------------------
  --   Register to maintain the value
  -- ------------------------------------------------------------------------------------------------------
  gen_reg : for N in pkg_LINK_NUMBER-1 downto 0 generate
    p_ctrl_register : process (i_clk_science(N))
    begin

      if rising_edge(i_clk_science(N)) then
        if i_rst   = '1' then
          ctrl_r1(N)         <= (others => '0');
          data_ready_r1(N)   <= '0';
          data_out_r1(4*N)   <= (others => '0');
          data_out_r1(4*N+1) <= (others => '0');
          data_out_r1(4*N+2) <= (others => '0');
          data_out_r1(4*N+3) <= (others => '0');
        else
          if data_ready(N) = '1' then
            ctrl_r1(N)         <= CTRL(N);
            data_ready_r1(N)   <= data_ready(N);
            data_out_r1(4*N)   <= data_out(4*N);
            data_out_r1(4*N+1) <= data_out(4*N+1);
            data_out_r1(4*N+2) <= data_out(4*N+2);
            data_out_r1(4*N+3) <= data_out(4*N+3);
          elsif cpt_synchro_r1 = "10" then
            data_ready_r1(N) <= '0';
          end if;
        end if;
      end if;
    end process p_ctrl_register;
  end generate gen_reg;

  -- ------------------------------------------------------------------------------------------------------
  --   Resynchro
  -- ------------------------------------------------------------------------------------------------------
  -- resynchronization
  p_sync_link : process (i_clk_science(0))
  begin

    if rising_edge(i_clk_science(0)) then
      if i_rst   = '1' then
        ctrl_r2        <= (others => (others => '0'));
        ctrl_r3        <= (others => (others => '0'));
        data_out_r2    <= (others => (others => '0'));
        data_out_r3    <= (others => (others => '0'));
        start_maker_r1 <= '0';
        cpt_synchro_r1 <= (others => '0');
      else
        start_maker_r1 <= '0';
        if data_ready_r1 = (data_ready_r1'range => '1') then
          cpt_synchro_r1 <= std_logic_vector(unsigned(cpt_synchro_r1) + 1);
          ctrl_r2        <= ctrl_r1;
          ctrl_r3        <= ctrl_r2;
          data_out_r2    <= data_out_r1;
          data_out_r3    <= data_out_r2;
        end if;
        if cpt_synchro_r1 = "10" then
          start_maker_r1 <= '1';
          cpt_synchro_r1 <= (others => '0');
        end if;
      end if;
    end if;
  end process p_sync_link;

  -- build the frames
  p_frame_build : process(i_clk_science(0))
  begin

    if rising_edge(i_clk_science(0)) then
      if i_rst   = '1' then
        frame_r4          <= (others => (others => '0'));
        frame_fifo_r5     <= (others => (others => '0'));
        o_data_instrument <= (others => '0');
        o_wr_instrument   <= '0';
        write_data_r1     <= '0';
        cpt_frame_r1      <= 0;
        cpt_fifo_r1       <= 0;
      else
        if start_maker_r1 = '1' then
          cpt_frame_r1           <= cpt_frame_r1 + 1;
          frame_r4(cpt_frame_r1) <= x"AAAA" & ctrl_r3(0) & ctrl_r3(1) & data_out_r3(0) & data_out_r3(1) & data_out_r3(2) & data_out_r3(3) & data_out_r3(4) & data_out_r3(5) & data_out_r3(6) & data_out_r3(7);
        end if;
        if cpt_frame_r1 = 4 then
          cpt_frame_r1     <= 0;
          frame_fifo_r5(0) <= frame_r4(0) & frame_r4(1)(95 downto 64);
          frame_fifo_r5(1) <= frame_r4(1)(63 downto 0) & frame_r4(2)(95 downto 32);
          frame_fifo_r5(2) <= frame_r4(2)(31 downto 0) & frame_r4(3);
          write_data_r1    <= '1';
        end if;
        if write_data_r1 = '1' and cpt_fifo_r1 < 3 then
          cpt_fifo_r1       <= cpt_fifo_r1 + 1;
          o_data_instrument <= frame_fifo_r5(cpt_fifo_r1);
          o_wr_instrument   <= '1';
        end if;
        if cpt_fifo_r1 = 3 then
          write_data_r1   <= '0';
          cpt_fifo_r1     <= 0;
          o_wr_instrument <= '0';
        end if;
      end if;
    end if;
  end process p_frame_build;

end RTL;
