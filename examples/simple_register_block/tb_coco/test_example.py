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
from cocotb.triggers import Timer, RisingEdge, ReadOnly
from cocotb.clock import Clock
from tb import TestBench

@cocotb.test(timeout_time = 1000, timeout_unit='ns')
async def test_example(dut):
    """
    A test that enables the counter and waits for an active high interrupt
    to be set.  It polls the status register until this is set and then
    lets the sim end.
    """

    clk = dut.pclk_i
    rst = dut.preset_ni
    tb  = TestBench(dut, clk, rst)
    log = dut._log


    def get_field_lsb(reg_name, field_name):
        """ Avoid hard coding bit positions in the test 
        when we can get them from the regmodel.
        """
        reg = tb.regmodel.get_reg_by_name(reg_name)
        field = reg.get_field_by_name(field_name)
        return field.get_lsb_pos()


    # Define some bit positions of the control/status bits
    CONTROL_EN     = get_field_lsb('control', 'en'    )
    CONTROL_IRQ_EN = get_field_lsb('control', 'irq_en')
    STATUS_ACTIVE  = get_field_lsb('status' , 'active')
    STATUS_IRQ     = get_field_lsb('status' , 'irq')


    clock = Clock(clk, 5, 'ns')
    cocotb.fork(clock.start())


    # Reset the DUT
    await tb.reset()


    # Enable the counter and interrupt generation.
    value  = 1 << CONTROL_EN 
    value |= 1 << CONTROL_IRQ_EN
    await tb.regmodel.write_reg_by_name(name='control', data=value)


    # Now read the status register to check if the counter is active
    value = await tb.regmodel.read_reg_by_name('status')
    if ( ((value >> STATUS_ACTIVE) & 1) ):
        log.info("Counter is active")


    # Now poll the status register to check the interrupt request bit
    log.info("Polling for IRQ status")
    while( not ((value >> STATUS_IRQ) & 1) ):
        log.info("...waiting")
        await Timer(100, 'ns')
        await RisingEdge(clk)
        value = await tb.regmodel.read_reg_by_name('status')
    log.info("IRQ has been set!")


    await RisingEdge(clk)
    log.info("Finished test")