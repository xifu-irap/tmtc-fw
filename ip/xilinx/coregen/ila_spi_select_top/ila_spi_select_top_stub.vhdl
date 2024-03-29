-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2022.1 (win64) Build 3526262 Mon Apr 18 15:48:16 MDT 2022
-- Date        : Tue Nov 21 11:54:34 2023
-- Host        : PC-PAUL running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               d:/tmtc-fw-hardware/tmtc-fw/ip/xilinx/coregen/ila_spi_select_top/ila_spi_select_top_stub.vhdl
-- Design      : ila_spi_select_top
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7k160tffg676-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ila_spi_select_top is
  Port ( 
    clk : in STD_LOGIC;
    probe0 : in STD_LOGIC_VECTOR ( 8 downto 0 );
    probe1 : in STD_LOGIC_VECTOR ( 4 downto 0 );
    probe2 : in STD_LOGIC_VECTOR ( 63 downto 0 );
    probe3 : in STD_LOGIC_VECTOR ( 3 downto 0 )
  );

end ila_spi_select_top;

architecture stub of ila_spi_select_top is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk,probe0[8:0],probe1[4:0],probe2[63:0],probe3[3:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "ila,Vivado 2022.1";
begin
end;
