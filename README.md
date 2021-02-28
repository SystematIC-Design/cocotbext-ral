# cocotbext-ral

A port of the uvm-python RAL to use Cocotb's BusDrivers.

## Background

A Python port of UVM is available at [uvm-python](https://github.com/tpoikela/uvm-python) and can be used to construct UVM testbenches using Python instead of SV.  One of the components is the Register Abstraction Layer, or RAL, which allows a register file to be modelled and accessed.

However, for users who don't have a UVM background and/or don't want the complexity of a full UVM testbench with sequences, sequencers, agents, etc, this work provides a number of classes that inherrit from the UVM base, but modify the write/read methods to use a `BusDriver`.

## Register Tool   

This project makes use of a Python register file generator provided by [lowRISC](https://www.lowrisc.org/).  Full documentation is available [here](https://docs.opentitan.org/doc/rm/register_tool/).

This tool reads in a description of a register file defined in HJSON format and generates both the RTL and SV RAL model as outputs.  Modifications have been made to the scripts to enable two new outputs:

 * an APB based bus interface instead of the TileLink Uncached Lite interface
 * a Python RAL

**Note:** the Register Tool provides options for defining a number of complex structures and not all options have been tested or even implemented here for the Python port.  Straying outside of the examples will likely result in further modifications having to be made.  This is a work in progress and only the base support for registers/fields has been implemented.


## Cocotb Usage Requirements

When using this RAL within a Cocotb testbench, the user needs to provide the appropriate `BusDriver` along with an `Adapter` that inherrits from the `UVMRegAdapter` base class.  The `UVMRegAdapter` converts between the `UVMRegBusOp` transaction class and the bus specific transaction used by the `BusDriver`.

An example of an adapter is provided in `cocotbext/ral/dv_reg_adapter.py` which converts to/from an `APBTransaction`.  An example APB Cocotb Extension is provided [here](https://github.com/SystematIC-Design/cocotbext-apb) and is used is `examples/simple_register_block`.


## Example System

A very simple example is provided under `examples\simple_register_block`.  Please see the relevant README for more details.