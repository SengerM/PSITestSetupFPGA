# FPGA source code for PSI test setup

This repository contains the source code to program the FPGA in the "PSI chip design test setup".

## Simulating Verilog modules in Linux

It is possible to simulate modules written in Verilog using [Icarus Verilog](http://iverilog.icarus.com/) and then view the results using [GTKWave](http://gtkwave.sourceforge.net/). To see how to do proceed just look into the simulation files in this repository as an example. To install these programs just run:

```
sudo apt install iverilog
sudo apt install gtkwave
```

## How to use Terasic USB Blaster in Linux

I was not able to make it work. Once I thought it was working but after I restarted the computer it stopped working. I give up with the Terasic USB Blaster.
