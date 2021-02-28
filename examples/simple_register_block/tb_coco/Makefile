TOPLEVEL=example
MODULE=test_example
WAVES=1

SIM=questa
TOPLEVEL_LANG=verilog

COMPILE_ARGS = +libext+.v+.sv+.svh

VERILOG_INCLUDE_DIRS = \
	../src_rtl

VERILOG_SOURCES = \
	../src_rtl/prim_subreg.sv \
	../src_rtl/prim_subreg_arb.sv \
	../src_rtl/apb_pkg.sv \
	../src_rtl/apb_adapter_reg.sv \
	../src_rtl/example_reg_pkg.sv \
	../src_rtl/example_reg_top.sv \
	../src_rtl/example.sv

default: _all

include $(shell cocotb-config --makefiles)/Makefile.sim

_all: clean all