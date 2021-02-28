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

from uvm.reg.uvm_reg_map import UVMRegMap, UVM_VERB_MEM_MAP
from uvm.reg.uvm_reg_item import UVMRegItem, UVMRegBusOp
from uvm.reg.uvm_reg_model import *
from uvm.macros.uvm_object_defines import uvm_object_utils
from uvm.base.uvm_debug import uvm_debug
from uvm.base.sv import sv
from uvm.macros.uvm_message_defines import uvm_info, uvm_error, uvm_fatal

class DVRegMap(UVMRegMap):
    """
    Extends UVMRegMap to override all read/write methods.  UVM expects sequence items to be
    passed to the driver via a sequencer but we want to connect directly to the driver.
    """

    def set_driver(self, driver, adapter=None):
        """
        Function: set_driver(driver, adapter)

            Set the bus driver associated with this map.  This method must be called
            before calling any read/write methods.

        Args:
            driver: the Cocotb BusDriver to use
            adapter: the UVMRegAdapter
        """
        if driver is None:
            uvm_error("DVRegMap::NO_DRIVER", "set_driver() called with driver of 'None'")

        if adapter is None:
            uvm_info("DVRegMap::NO_ADAPTER", "set_driver() called with adapter of 'None'")

        self.m_driver  = driver
        self.m_adapter = adapter


    def get_driver(self, hier=UVM_HIER):
        """
        Function: get_driver

            Gets the driver for the bus associated with this map. If `hier` is
            set to `UVM_HIER`, gets the driver for the bus at the system-level.
            See `set_driver`.

        Args:
            hier: UVM_HIER or UVM_NO_HIER
        Returns:
        """
        if (hier == UVM_NO_HIER or self.m_parent_map is None):
            return self.m_driver
        return self.m_parent_map.get_driver(hier)


    async def do_write(self, rw):
        """
        Function: do_write(rw)

            Perform a write operation.

        Args:
            rw (UVMRegItem): Register item for the write op.
        """
        system_map = self.get_root_map()
        adapter    = system_map.get_adapter()
        driver     = system_map.get_driver()

        if adapter is None:
            uvm_fatal(self.get_type_name(), "adapter is None")
        elif driver is None:
            uvm_fatal(self.get_type_name(), "driver is None")
        else:
            await self.do_bus_write(rw, driver, adapter)


    async def do_read(self, rw):
        """
        Function: do_read(rw)

            Perform a read operation.

        Args:
            rw (UVMRegItem): Register item for the write op.
        """
        system_map = self.get_root_map()
        adapter    = system_map.get_adapter()
        driver     = system_map.get_driver()

        if adapter is None:
            uvm_fatal(self.get_type_name(), "adapter is None")
        elif driver is None:
            uvm_fatal(self.get_type_name(), "driver is None")
        else:
            await self.do_bus_read(rw, driver, adapter)


    async def do_bus_write(self, rw, driver, adapter):
        """
        Function: do_bus_write()

            Perform a bus write operation

        Args:
            rw (UVMRegItem): the item to be driven
            driver (BusDriver): the Cocotb driver to use
            adapter (DVRegAdapter): the bus adapter to use
        """

        addrs = []
        system_map = self.get_root_map()
        bus_width = self.get_n_bytes()
        byte_en = int(''.join(['1' for bit in range(bus_width)]),2)
        map_info = None
        n_bits = 0
        lsb = 0
        skip = 0
        curr_byte = 0
        n_access_extra = 0
        n_access = 0
        n_bits_init = 0

        [map_info, n_bits_init, lsb, skip] = self.Xget_bus_infoX(rw, map_info, n_bits_init, lsb, skip)
        addrs = map_info.addr.copy()

        # if a memory, adjust addresses based on offset
        if rw.element_kind == UVM_MEM:
            for i in range(len(addrs)):
                addrs[i] = addrs[i] + map_info.mem_range.stride * rw.offset

        for val_idx in range(len(rw.value)):
            value = rw.value[val_idx]

            # /* calculate byte_enables */
            if rw.element_kind == UVM_FIELD:
                temp_be = 0
                idx = 0
                n_access_extra = lsb % (bus_width*8)
                n_access = n_access_extra + n_bits_init
                temp_be = n_access_extra
                value = value << n_access_extra
                while temp_be >= 8:
                    byte_en = sv.clear_bit(byte_en, idx)
                    idx += 1
                    temp_be -= 8

                temp_be += n_bits_init
                while temp_be > 0:
                    byte_en = sv.set_bit(byte_en, idx)
                    # byte_en[idx] = 1
                    idx += 1
                    temp_be -= 8
                byte_en &= (1 << idx)-1
                for i in range(skip):
                    addrs.pop_front()
                while len(addrs) > (int(n_bits_init/(bus_width*8)) + 1):
                    addrs.pop_back()
            curr_byte = 0
            n_bits = n_bits_init

            accesses = []
            for i in range(len(addrs)):
                rw_access = UVMRegBusOp()
                data = (value >> (curr_byte*8)) & ((1 << (bus_width * 8))-1)

                uvm_debug(self.get_type_name(),
                   sv.sformatf("Writing 0x%0h at 0x%0h via map %s...",
                        data, addrs[i], rw.map.get_full_name()), UVM_VERB_MEM_MAP)

                if rw.element_kind == UVM_FIELD:
                    for z in range(bus_width):
                        bit_val = sv.get_bit(byte_en, curr_byte + z)
                        # rw_access.byte_en[z] = byte_en[curr_byte+z]
                        rw_access.byte_en = sv.set_bit(rw_access.byte_en, z, bit_val)

                rw_access.kind    = rw.kind
                rw_access.addr    = addrs[i]
                rw_access.data    = data
                #rw_access.n_bits  = (n_bits > bus_width*8) ? bus_width*8 : n_bits
                rw_access.n_bits = n_bits
                if (n_bits > bus_width*8):
                    rw_access.n_bits = bus_width*8
                rw_access.byte_en = byte_en

                accesses.append(rw_access)

                curr_byte += bus_width
                n_bits -= bus_width * 8

            # if set utilize the order policy
            if (self.policy is not None):
                self.policy.order(accesses)

            # perform accesses
            for i in range(len(accesses)):
                rw_access = accesses[i]  # uvm_reg_bus_op
                bus_req = None  # uvm_sequence_item

                adapter.m_set_item(rw)
                bus_req = adapter.reg2bus(rw_access)
                adapter.m_set_item(None)

                if bus_req is None:
                    uvm_fatal("RegMem",
                        "adapter [" + adapter.get_name() + "] didnt return a bus transaction")

                # Drive the transaction
                await self.m_driver.busy_send(bus_req)

                if adapter.provides_responses:
                    bus_rsp = None  # uvm_sequence_item
                    op = None  # uvm_access_e
                    # TODO: need to test for right trans type, if not put back in q
                    await rw.parent.get_base_response(bus_rsp)
                    rw_access = adapter.bus2reg(bus_rsp, rw_access)
                else:
                    rw_access = adapter.bus2reg(bus_req, rw_access)
                    if rw_access is None:
                        uvm_error("ADAPTER_BUS2REG_NONE", sv.sformatf("Adapter %s"
                            + " returned None for RW item %s",
                            adapter.get_name(),
                            bus_req.convert2string())
                        )

                rw.status = rw_access.status

                uvm_debug(self.get_type_name(),
                   sv.sformatf("Wrote 0x%0h at 0x%0h via map %s: %s...",
                      rw_access.data, addrs[i], rw.map.get_full_name(), rw.status), UVM_VERB_MEM_MAP)

                if rw.status == UVM_NOT_OK:
                    break

            for i in range(len(addrs)):
                addrs[i] = addrs[i] + map_info.mem_range.stride


    async def do_bus_read(self, rw, driver, adapter):
        """
         Function: do_bus_read()

            Perform a bus read operation

        Args:
            rw (UVMRegItem): the item to be driven
            driver (BusDriver): the Cocotb driver to use
            adapter (DVRegAdapter): the bus adapter to use
        """
        addrs = []  # uvm_reg_addr_t[$]
        system_map = self.get_root_map()
        bus_width = self.get_n_bytes()
        byte_en = int(''.join(['1' for bit in range(bus_width)]))
        map_info = None
        size = 0
        n_bits = 0
        skip = 0
        lsb = 0
        curr_byte = 0
        n_access_extra = 0
        n_access = 0
        n_bits_init = 0
        accesses = []  # uvm_reg_bus_op[$]

        [map_info, n_bits_init, lsb, skip] = self.Xget_bus_infoX(rw, map_info, n_bits_init, lsb, skip)
        # Need a copy as this will be modified later
        addrs = map_info.addr.copy()

        # if a memory, adjust addresses based on offset
        if (rw.element_kind == UVM_MEM):
            for i in range(len(addrs)):
                addrs[i] = addrs[i] + map_info.mem_range.stride * rw.offset

        for val_idx in range(len(rw.value)):
            rw.value[val_idx] = 0

            # /* calculate byte_enables */
            if (rw.element_kind == UVM_FIELD):
                temp_be = 0
                ii = 0
                n_access_extra = lsb % (bus_width*8)
                n_access = n_access_extra + n_bits_init
                temp_be = n_access_extra
                while (temp_be >= 8):
                    # byte_en[ii] = 0
                    byte_en = sv.clear_bit(byte_en, ii)
                    ii += 1
                    temp_be -= 8

                temp_be += n_bits_init
                while(temp_be > 0):
                    # byte_en[ii] = 1
                    byte_en = sv.set_bit(byte_en, ii)
                    ii += 1
                    temp_be -= 8
                byte_en &= (1 << ii) - 1
                for i in range(skip):
                    addrs.pop_front()
                while addrs.size() > (int(n_bits_init/(bus_width*8)) + 1):
                    addrs.pop_back()
            #end
            curr_byte = 0
            n_bits = n_bits_init

            accesses = []
            for i in range(len(addrs)):
                rw_access = UVMRegBusOp()

                uvm_debug(self.get_type_name(),
                   sv.sformatf("Reading address 'h%0h via map \"%s\"...",
                             addrs[i], self.get_full_name()), UVM_VERB_MEM_MAP)

                if (rw.element_kind == UVM_FIELD):
                    #for (int z=0;z<bus_width;z++)
                    for z in range(bus_width):
                        # rw_access.byte_en[z] = byte_en[curr_byte+z]
                        bit_val = sv.get_bit(byte_en, curr_byte + z)
                        rw_access.byte_en = sv.set_bit(rw_access.byte_en, z, bit_val)

                rw_access.kind = rw.kind
                rw_access.addr = addrs[i]
                rw_access.data = curr_byte
                rw_access.byte_en = byte_en
                rw_access.n_bits = n_bits
                if (n_bits > bus_width*8):
                    rw_access.n_bits = bus_width*8

                accesses.append(rw_access)

                curr_byte += bus_width
                n_bits -= bus_width * 8

            # if set utilize the order policy
            if(self.policy is not None):
                self.policy.order(accesses)

            # perform accesses
            for i in range(len(accesses)):
                rw_access = accesses[i]  # uvm_reg_bus_op
                bus_req = None  # uvm_sequence_item

                data       = 0  # uvm_reg_data_logic_t
                curr_byte_ = 0

                curr_byte_     = rw_access.data
                rw_access.data = 0

                adapter.m_set_item(rw)
                bus_req = adapter.reg2bus(rw_access)
                adapter.m_set_item(None)

                if bus_req is None:
                    uvm_fatal("RegMem","adapter [" + adapter.get_name() + "] didnt return a bus transaction")

                # Call the driver, must stall
                await self.m_driver.busy_send(bus_req)

                if adapter.provides_responses:
                    bus_rsp = None  # uvm_sequence_item
                    op = 0  # uvm_access_e
                    # TODO: need to test for right trans type, if not put back in q
                    await rw.parent.get_base_response(bus_rsp)
                    rw_access = adapter.bus2reg(bus_rsp,rw_access)
                else:
                    adapter.bus2reg(bus_req,rw_access)

                data = rw_access.data & ((1 << bus_width*8)-1)  # mask the upper bits
                rw.status = rw_access.status

                # TODO
                #if (rw.status == UVM_IS_OK && (^data) === 1'bx):

                uvm_debug(self.get_type_name(),
                   sv.sformatf("Read 0x%h at 0x%h via map %s: %s...", data,
                       addrs[i], self.get_full_name(), str(rw.status)), UVM_VERB_MEM_MAP)

                if (rw.status == UVM_NOT_OK):
                    break

                rw.value[val_idx] |= data << curr_byte_*8

            for i in range(len(addrs)):
                addrs[i] = addrs[i] + map_info.mem_range.stride

            if (rw.element_kind == UVM_FIELD):
                rw.value[val_idx] = (rw.value[val_idx] >> (n_access_extra)) & ((1<<size)-1)


uvm_object_utils(DVRegMap)

