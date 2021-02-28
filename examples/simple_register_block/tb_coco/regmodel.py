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

from cocotbext.ral.dv_reg import DVReg
from ral.example_ral import example_reg_block
from uvm.reg.uvm_reg_model import *


class RegModel(example_reg_block):
    """ A wrapper around the auto-generated RAL model.

    Provides helper functions to save typing and automate tasks.
    """
    def __init__(self, *args, log=None):
        super().__init__(*args)
        self.log = log


    async def read_reg_by_name(self, name: str) -> int:
        """ Read a register by name.

        This method accepts a String |name| which is used to look up a
        matching register. An exception is thrown if it doesn't exist.
        The read value is returned to the caller.
        """
        register = self.get_reg_by_name(name)
        if register is None:
            raise RuntimeError("get_reg_by_name() failed with name=%s" % name)
        value = await self.read_reg(register)
        return value


    async def read_reg(self, register: DVReg) -> int:
        """ Read a register.

        This method calls the actual register.read() and returns a single
        integer value as the result.
        """
        value = []
        status = []

        await register.read(status, value)

        if len(status) > 1:
            raise RuntimeError("not expecting more than 1 status for read")
        if UVM_IS_OK not in status:
            self.log.error("register read to %s returned %s" % (
                register.name, uvm_status_e(status[0])))
        self.log.debug("%s.read returned %s" % (
            register.name, hex(value[0])))

        return value[0]


    async def write_reg_by_name(self, name: str, data: int)-> int:
        """ Write a register by name.

        This method accespts a String |name| which is used to look up a
        matching register. An exception is thrown if it doesn't exist.
        """
        register = self.get_reg_by_name(name)
        if register is None:
            raise RuntimeError("get_reg_by_name() failed with name=%s" % name)
        await self.write_reg(register, data)


    async def write_reg(self, register: DVReg, value: int):
        """ Write a register.

        This method calls register.write().
        """
        status = []
        await register.write(status, value)

        if len(status) > 1:
            raise RuntimeError("not expecting more than 1 status for read")
        if UVM_IS_OK not in status:
            self.log.error("register read to %s returned %s" % (
                register.name, uvm_status_e(status[0])))


    async def mirror_reg_by_name(self, name):
        """ Mirror a register

        This method accepts a String |name| which is used to look up a
        matching register.  An exception is thrown if it doesn't exist.
        """
        register = self.get_reg_by_name(name)
        if register is None:
            raise RuntimeError("get_reg_by_name() failed with name=%s" % name)
        await self.mirror_reg(register)


    async def mirror_reg(self, register, check=UVM_CHECK):
        """ Read the register and update/check its mirror value """
        status = []
        await register.mirror(status, check)


    async def mirror_all_regs(self):
        """ Read all registers and update/check thier mirror values """
        regs = []
        self.get_registers(regs)
        for reg in regs:
            await self.mirror_reg(reg)
