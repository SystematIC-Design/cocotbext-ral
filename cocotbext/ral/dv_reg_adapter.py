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

from uvm.reg.uvm_reg_adapter import UVMRegAdapter
from uvm.reg.uvm_reg_item import UVMRegItem, UVMRegBusOp
from uvm.reg.uvm_reg_model import UVM_NOT_OK, UVM_IS_OK, UVM_READ

from cocotbext.apb import APBTransaction

class DVRegApbAdapter(UVMRegAdapter):
    """
    Extends the UVMRegAdapter base class to provide APB specifc translation methods.

    This class must be used when connecting to the cocotbext-apb bus driver.
    """

    def reg2bus(self, rw: UVMRegBusOp):
        """
        Method to translate from the generic UVMRegBusOp to an APB specific transaction class.

        There is currently no checking that the bus widths match.
        """
        strobe = [ True if (rw.byte_en & (1<<idx)) else False for idx in range(int(rw.n_bits/8)) ]
        direction = 'READ' if rw.kind == UVM_READ else 'WRITE'

        return APBTransaction(rw.addr, rw.data, direction=direction, strobe=strobe)


    def bus2reg(self, bus_item: APBTransaction, rw: UVMRegBusOp):
        """
        Method to translate from an APB bus specific transaction to the generic UVMRegBusOp.

        Any read data is populated along with the status of the transaction.
        """
        rw.data = bus_item.data
        rw.status = UVM_NOT_OK if bus_item.error else UVM_IS_OK

        return rw

