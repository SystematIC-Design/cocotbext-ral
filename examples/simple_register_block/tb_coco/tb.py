# MIT License

# Copyright (c) 2021 SystematIC Design BV

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly
from cocotb.drivers import BusDriver

# We need an adapter which converts to/from the UVM classes
# and a bus specific driver.
from cocotbext.ral.dv_reg_adapter import DVRegApbAdapter
from cocotbext.apb import APBMasterDriver

# We need some UVM specific return types
from uvm.reg.uvm_reg_model import *

from regmodel import RegModel


class TestBench(object):
    """
    A simple top level testbench class that hooks up the
    required component and implements a simple reset routine.
    """
    def __init__(self, dut, clk, rst):
        self.dut = dut
        self.clk = clk
        self.rst = rst

        # Instance the driver/adapter pair first
        self.apb_driver = APBMasterDriver(dut, 'apb', dut.pclk_i, pkg=True)
        self.apb_adapter = DVRegApbAdapter('apb_adapter')

        # Force signals to sane values to prevent X's
        self.rst.setimmediatevalue(1)

        # Build the register model
        self.regmodel = RegModel("regmodel", log=self.dut._log)
        self.regmodel.build()
        self.regmodel.set_driver(self.apb_driver, self.apb_adapter)
        self.regmodel.lock_model()


    async def reset(self):
        """
        Simple single cycle reset.
        """
        await RisingEdge(self.clk)
        self.rst <= 0
        await RisingEdge(self.clk)
        self.rst <= 1


