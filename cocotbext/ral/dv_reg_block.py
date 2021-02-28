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

from typing import Dict, Optional, List
from uvm.macros.uvm_object_defines import uvm_object_utils
from uvm.reg.uvm_reg_block import UVMRegBlock
from cocotbext.ral.dv_reg_map import DVRegMap

class DVRegBlock(UVMRegBlock):
    """
    Overrides the UVMRegBlock::create_map() method to use DVRegMap.
    """

    def create_map(self, name: str, base_addr: int, n_bytes: int, endian: int, byte_addressing=True) -> Optional[DVRegMap]:
        """
        """
        if self.locked is True:
            uvm_error("RegModel", "Cannot add map to locked model")
            return None

        _map = DVRegMap.type_id.create(name, None, self.get_full_name())
        _map.configure(self,base_addr,n_bytes,endian,byte_addressing)

        self.maps[_map] = True
        if self.maps.num() == 1:
            self.default_map = _map
        return _map

uvm_object_utils(DVRegBlock)