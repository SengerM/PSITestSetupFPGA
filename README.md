# FPGA source code for PSI test setup

This repository contains the source code to program the FPGA in the "PSI chip design test setup".

## Simulating Verilog modules in Linux

It is possible to simulate modules written in Verilog using [Icarus Verilog](http://iverilog.icarus.com/) and then view the results using [GTKWave](http://gtkwave.sourceforge.net/). To see how to do proceed just look into the simulation files in this repository as an example. To install these programs just run:

```
sudo apt install iverilog
sudo apt install gtkwave
```

## How to use Terasic USB Blaster in Linux

I acquired a [Terasic USB Blaster](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=46) and I was not able to program using Quartus. It was a long story so I don't exactly remember the problem, but the symptoms were basically that the blue LED in the USB blaster turned on after clicking on the `start` button in the "Programmer" window in Quartus, and after a while this LED turned back off and the "Progress" bar in Quartus said "Failed". To solve this I tried many things with no success untill I did the first thing that is explained in [this link](http://fpgacpu.ca/fpga/debian.html). Basically I created the file `/etc/udev/rules.d/51-altera-usb-blaster.rules` with the following content
```
# USB-Blaster
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6001", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6002", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6003", MODE="0666"
# USB-Blaster II
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6010", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6810", MODE="0666"
```
After this I "reloaded that file using udevadm":

```
sudo udevadm control --reload
```
Then I restarted Quartus and this was finally working!
