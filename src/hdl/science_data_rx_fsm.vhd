-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            Copyright (C) 2021-2030 Paul Marbeau, IRAP Toulouse.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    email                   paul.marbeau@alten.com
--!   @file                   science_data_rx_fsm.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Data State Machine.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

entity science_data_rx_fsm is
   port (



	-- param
	
	wd_timeout 			: in	std_logic_vector(15 downto 0);

	-- global	
	
	reset_n 			: in	std_logic;
	i_clk_science 		: in	std_logic;
	data_rate_enable	: in	std_logic;
	
		
	-- Link
	
	i_science_ctrl		: in    std_logic;
	i_science_data		: in    std_logic;
	
	-- decode
	
	CTRL				: out	std_logic_vector(7 downto 0);
	data_out 			: out	std_logic_vector(7 downto 0);
	data_ready			: out	std_logic
			
      );

end science_data_rx_fsm;

architecture Behavioral of science_data_rx_fsm is

	type 	T_Rx_State is (Wait_First_start, Wait_Second_start, Wait_Third_start, decode);
signal	Rx_State 		: T_Rx_State;

signal	N				:	integer range 0 to 5;
signal	start_detected	:	std_logic;

signal	science_ctrl_FFF	:	std_logic;
signal	i_science_ctrl_FF	:	std_logic;
signal	science_ctrl		:	std_logic;

signal	science_data_FFF	:	std_logic;
signal	i_science_data_FF	:	std_logic;
signal	science_data		:	std_logic;	

attribute ASYNC_REG : string;
attribute ASYNC_REG of i_science_ctrl_FF: signal is "TRUE";
attribute ASYNC_REG of science_ctrl_FFF: signal is "TRUE";

attribute ASYNC_REG of science_data_FFF: signal is "TRUE";
attribute ASYNC_REG of i_science_data_FF: signal is "TRUE";

begin

-------------------------------------------------------------------------------------------------
-- Metastability protect on CTRL
-------------------------------------------------------------------------------------------------
label_meta_ctrl: process(reset_n, i_clk_science)
begin
if reset_n = '0' then 
	i_science_ctrl_FF	<= '0';	
else
    if i_clk_science = '1' and i_clk_science'event then
		i_science_ctrl_FF	<=	i_science_ctrl;
		science_ctrl_FFF	<=	i_science_ctrl_FF;
    end if;
end if;
end process;

-------------------------------------------------------------------------------------------------
-- Metastability protect on DATA
-------------------------------------------------------------------------------------------------
label_meta_data: process(reset_n, i_clk_science)
begin
if reset_n = '0' then 
	i_science_data_FF	<= '0';
else
    if i_clk_science = '1' and i_clk_science'event then
		i_science_data_FF	<=	i_science_data;
		science_data_FFF	<=	i_science_data_FF;
    end if;
end if;
end process;

-------------------------------------------------------------------------------------------------
-- Data rate protect on DATA
-------------------------------------------------------------------------------------------------
label_data_rate: process(reset_n, i_clk_science)
begin
if reset_n = '0' then 
	science_ctrl		<= '0';
	science_data		<= '0';
else
    if i_clk_science = '1' and i_clk_science'event then
		if data_rate_enable = '1' then
			science_ctrl		<= science_ctrl_FFF;
			science_data		<= science_data_FFF;	
		end if;
    end if;
end if;
end process;


-------------------------------------------------------------------------------------------------
-- Decode characters
-------------------------------------------------------------------------------------------------
label_FSM: process(reset_n, i_clk_science)

begin

if reset_n = '0' then 	
	Rx_State		<= Wait_First_start; 
	N				<=	0;
	data_out		<= (others => '0');
	start_detected	<=	'0';
	data_ready		<=	'0';	
	CTRL			<= (others => '0');
else
    if i_clk_science = '1' and i_clk_science'event then
    data_ready		<=	'0';
 	
	case Rx_State is

	when Wait_First_start =>
		if science_ctrl ='0' then 
			Rx_State		<=	Wait_Second_start;
		else
			Rx_State		<=	Wait_First_start;
		end if;	

	when Wait_Second_start =>
		if science_ctrl = '1' then
			Rx_State		<=	Wait_Third_start;
			data_out(7)		<=	science_data; 
			CTRL(7)			<=	science_ctrl;	
		else 
			Rx_State		<=	Wait_Second_start;
		end if;		

	when Wait_Third_start => 	
		if science_ctrl = '1' then
			Rx_State 		<=	decode;
			data_out(6)		<=	science_data;
			CTRL(6)			<=	science_ctrl;							
			N				<=	5;
			start_detected	<=	'1';
		else
			Rx_State 		<=	Wait_Second_start;
		end if;		


	when decode =>			
		if	N	=	0	then
				start_detected	<=	'0';
				data_ready		<=	'1';
				data_out(N)	 	<=	science_data;
				CTRL(N)			<=	science_ctrl;
			if 	science_ctrl = '0'	then
				Rx_State		<= Wait_Second_start;	
			else
				Rx_State		<= Wait_First_start;	
			end if ;		
		else
			data_out(N)		 <=	science_data;
			CTRL(N)			<=	science_ctrl;
			N	<=	N-1;
		end if;
																	
	when others =>
			

	end case;

    end if;
end if;
end process;


end Behavioral;