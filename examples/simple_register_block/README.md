# Simple Register Block Examples

## Overview

This is a minimal example showing how to read and write to a UVM register model, or RAL (Register Abstraction Layer).

The model is auto-generated from the same HJSON description of the registers used to generate the RTL.  A new switch has been added to regtool.py in order to generate this Python view instead of the usual SV RAL.

## Requirements

The Python requirements have been added to `requirements.txt` and a Make target is provided to build a virtual environment.

```console
$ make venv
$ . venv/bin/activate
```

## Directory Structure

The directory structure is shown below.

```
.
├── data
├── src_rtl
├── tb_coco
│   └── ral
└── util
    ├── reggen
    └── topgen
```

The HJSON description of the registers is in the `data` directory and the `src_rtl` and `tb_coco` directories hold the RTL and testbench code respectively.

The `util` directory contains modified versions of the lowRISC Register Tool, full documentation of which can be found [here](https://docs.opentitan.org/doc/rm/register_tool/).


## RTL Toplevel

The example toplevel, imaginatively named `src_rtl/example.sv`, contains a simple counter that sets a status bit after a timeout period.  The counter is enabled via a control field in the register bank and the resulting IRQ is captured in a status bit.

## Testbench Toplevel

The testbench, `tb_coco/tb.sv`, simply instantiates an APB driver/adapter pair along with the `RegModel` class.  This class, defined in `tb_coco/regmodel.py`, wraps the auto-generted RAL with some helper methods to ease writing tests.


## Running the Example

A Makefile has been provided where the default target runs all stages of the flow and will open up Questa to view the waves.  Run it using:

```console
cd /path/to/your/installation/of/cocotbext-ral/examples/simple_register_block
make
```

Individual targets are provided for each stage of the flow:

| Target | Description |
| :- | :- |
| rtl | Runs regtool.py with the **-r** switch to generate the RTL view |
| ral | Runs regtool.py with the **-u** switch to generate the UVM RAL view |
| sim | Runs the Cocotb simulation with WAVES=1 |
| waves | Opens up Questa and runs a dofile to add signals to the wave view |