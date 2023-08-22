# FrontPanelUSB (v5.2.5) library for the Opal Kelly XEM7350-K160T board

Those following files must be compatible with Vivado 2022.1

## VHDL simulation files

The "Front_panel_XEM7350-K160T/simu" directory contains VHDL simulation files for the FrontPanelUSB (Opal Kelly USB IP).

The simulations files are listed below:
- mappings.vhd
- okBTPipeIn.vhd
- okBTPipeOut.vhd
- okDualHost.vhd
- okHost.vhd
- okLibrary_sim.vhd
- okPipeIn.vhd
- okPipeOut.vhd
- okRegisterBridge.vhd
- okTriggerIn.vhd
- okTriggerOut.vhd
- okWireIn.vhd
- okWireOR.vhd
- okWireOut.vhd
- parameters.vhd

## Vivado synthetized files (compatible with Vivado 2022.1)

The "Front_panel_XEM7350-K160T/syn" directory contains encrypted synthetized files (compiled) of the USB IP provided by the Opal Kelly vendor.

The synthetized files are listed below:
- okBTPipeIn.v
- okBTPipeOut.v
- okCoreHarness.v
- okLibrary.v
- okLibrary.vhd
- okPipeIn.v
- okPipeOut.v
- okRegisterBridge.v
- okTriggerIn.v
- okTriggerOut.v
- okWireIn.v
- okWireOut.v

**Note**:
> The encrypted files must be compatible with Vivado 2022.1. The time between the currently vivado version and the vivado version used by the vendor to encrypt their VHDL files must be inferior to 5 years. Otherwise, the currently vivado version can't uncrypt those files.