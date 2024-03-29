# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# UVM Registers auto-generated by `reggen` containing data structure
# Do Not Edit directly

from uvm.macros import uvm_object_utils
from uvm.reg.uvm_reg_model import *

from cocotbext.ral.dv_reg import DVReg
from cocotbext.ral.dv_reg_field import DVRegField
from cocotbext.ral.dv_reg_block import DVRegBlock
from cocotbext.ral.dv_reg_map import DVRegMap
from cocotbext.ral.dv_reg_adapter import DVRegApbAdapter

# UVM Registers auto-generated by `reggen` containing data structure
# Do Not Edit directly

# Block: example

# Class: example_reg_control
class example_reg_control(DVReg):
    def __init__(self, name="example_reg_control"):
        super().__init__(name, 32)
        # fields
        self.en = None
        self.irq_en = None

    def build(self):
        # create fields
        self.en = DVRegField.type_id.create("en")
        self.en.configure(
            parent=self,
            size=1,
            lsb_pos=0,
            access="RW",
            volatile=0,
            reset=0,
            has_reset=1,
            is_rand=1,
            individually_accessible=1
        )
        self.add_hdl_path_slice("u_reg.u_control_en.q", 0, 1, 0, "BkdrRegPathRtl");

        self.irq_en = DVRegField.type_id.create("irq_en")
        self.irq_en.configure(
            parent=self,
            size=1,
            lsb_pos=1,
            access="RW",
            volatile=0,
            reset=0,
            has_reset=1,
            is_rand=1,
            individually_accessible=1
        )
        self.add_hdl_path_slice("u_reg.u_control_irq_en.q", 1, 1, 0, "BkdrRegPathRtl");


uvm_object_utils(example_reg_control)

# Class: example_reg_status
class example_reg_status(DVReg):
    def __init__(self, name="example_reg_status"):
        super().__init__(name, 32)
        # fields
        self.active = None
        self.irq = None

    def build(self):
        # create fields
        self.active = DVRegField.type_id.create("active")
        self.active.configure(
            parent=self,
            size=1,
            lsb_pos=0,
            access="RO",
            volatile=1,
            reset=0,
            has_reset=1,
            is_rand=1,
            individually_accessible=1
        )
        self.add_hdl_path_slice("u_reg.u_status_active.q", 0, 1, 0, "BkdrRegPathRtl");

        self.irq = DVRegField.type_id.create("irq")
        self.irq.configure(
            parent=self,
            size=1,
            lsb_pos=8,
            access="RO",
            volatile=1,
            reset=0,
            has_reset=1,
            is_rand=1,
            individually_accessible=1
        )
        self.add_hdl_path_slice("u_reg.u_status_irq.q", 8, 1, 0, "BkdrRegPathRtl");


uvm_object_utils(example_reg_status)


# Class: example_reg_block
class example_reg_block(DVRegBlock):
    def __init__(self, name="example_reg_block"):
        super().__init__(name)
        # registers
        self.control = None
        self.status = None

    def build(self, base_addr=0):
        # create default map
        self.default_map = self.create_map(
            name="default_map",
            base_addr=base_addr,
            n_bytes=4,
            endian=UVM_LITTLE_ENDIAN
        )

        self.set_hdl_path_root("tb.dut", "BkdrRegPathRtl");
        self.set_hdl_path_root("tb.dut", "BkdrRegPathRtlCommitted");
        self.set_hdl_path_root("tb.dut", "BkdrRegPathRtlShadow");

        # create registers
        self.control = example_reg_control.type_id.create("control")
        self.control.configure(blk_parent=self)
        self.control.build()
        self.default_map.add_reg(rg=self.control,
                                offset=0,
                                rights="RW")
        self.status = example_reg_status.type_id.create("status")
        self.status.configure(blk_parent=self)
        self.status.build()
        self.default_map.add_reg(rg=self.status,
                                offset=4,
                                rights="RO")

    def set_driver(self, driver, adapter):
        """
        Connect the bus specific driver/adapter pair to the memory map.
        """
        self.default_map.set_driver(driver, adapter)

uvm_object_utils(example_reg_block)

