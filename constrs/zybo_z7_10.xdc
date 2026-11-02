## Zybo Z7-10 constraints for zybo_top
## Pin names follow the Digilent Zybo Z7 master XDC.

## 125 MHz system clock
set_property -dict { PACKAGE_PIN K17 IOSTANDARD LVCMOS33 } [get_ports sysclk]
create_clock -period 8.000 -name sys_clk_pin -waveform {0.000 4.000} [get_ports sysclk]

## BTN0 = reset
set_property -dict { PACKAGE_PIN K18 IOSTANDARD LVCMOS33 } [get_ports btn0]

## UART on Pmod JE (JE1 = rx, JE2 = tx)
set_property -dict { PACKAGE_PIN V12 IOSTANDARD LVCMOS33 } [get_ports uart_rx]
set_property -dict { PACKAGE_PIN W16 IOSTANDARD LVCMOS33 } [get_ports uart_tx]

## Status LEDs
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN M15 IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN G14 IOSTANDARD LVCMOS33 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN D18 IOSTANDARD LVCMOS33 } [get_ports {led[3]}]

## Asynchronous I/O
## The button and the UART rx line are not related to sysclk. Each one goes
## through a 2-flop synchronizer (ASYNC_REG) inside the design, so the path
## from the pin to the first flop is not a real timing path.
set_false_path -from [get_ports {btn0 uart_rx}]
## UART tx is read by an async receiver at 9600 baud and the LEDs are read
## by a person, so there is no clock relationship to time against.
set_false_path -to [get_ports {uart_tx led[*]}]
