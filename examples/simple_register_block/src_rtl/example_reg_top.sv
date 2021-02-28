// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Register Package auto-generated by `reggen` containing data structure


`include "prim_assert.sv"

module example_reg_top (
  input clk_i,
  input rst_ni,

  // Below Regster interface can be changed
  input  apb_pkg::apb_h2d_t apb_i,
  output apb_pkg::apb_d2h_t apb_o,
  // To HW
  output example_reg_pkg::example_reg2hw_t reg2hw, // Write
  input  example_reg_pkg::example_hw2reg_t hw2reg, // Read

  // Config
  input devmode_i // If 1, explicit error return for unmapped register access
);

  import example_reg_pkg::* ;

  localparam int AW = 3;
  localparam int DW = 32;
  localparam int DBW = DW/8;                    // Byte Width

  // register signals
  logic           reg_we;
  logic           reg_re;
  logic [AW-1:0]  reg_addr;
  logic [DW-1:0]  reg_wdata;
  logic [DBW-1:0] reg_wstrb;
  logic [DW-1:0]  reg_rdata;
  logic           reg_error;

  logic          addrmiss, wr_err;

  logic [DW-1:0] reg_rdata_next;

  apb_pkg::apb_h2d_t apb_reg_h2d;
  apb_pkg::apb_d2h_t apb_reg_d2h;

  assign apb_reg_h2d = apb_i;
  assign apb_o       = apb_reg_d2h;

  apb_adapter_reg #(
    .RegAw(AW),
    .RegDw(DW)
  ) u_reg_if (
    .clk_i,
    .rst_ni,

    .apb_i (apb_reg_h2d),
    .apb_o (apb_reg_d2h),

    .we_o    (reg_we),
    .re_o    (reg_re),
    .addr_o  (reg_addr),
    .wdata_o (reg_wdata),
    .wstrb_o (reg_wstrb),
    .rdata_i (reg_rdata),
    .error_i (reg_error)
  );


  assign reg_rdata = reg_rdata_next ;
  assign reg_error = (devmode_i & addrmiss) | wr_err ;

  // Define SW related signals
  // Format: <reg>_<field>_{wd|we|qs}
  //        or <reg>_{wd|we|qs} if field == 1 or 0
  logic control_en_qs;
  logic control_en_wd;
  logic control_en_we;
  logic control_irq_en_qs;
  logic control_irq_en_wd;
  logic control_irq_en_we;
  logic status_active_qs;
  logic status_irq_qs;

  // Register instances
  // R[control]: V(False)

  //   F[en]: 0:0
  prim_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h0)
  ) u_control_en (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (control_en_we),
    .wd     (control_en_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.control.en.q ),

    // to register interface (read)
    .qs     (control_en_qs)
  );


  //   F[irq_en]: 1:1
  prim_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h0)
  ) u_control_irq_en (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (control_irq_en_we),
    .wd     (control_irq_en_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.control.irq_en.q ),

    // to register interface (read)
    .qs     (control_irq_en_qs)
  );


  // R[status]: V(False)

  //   F[active]: 0:0
  prim_subreg #(
    .DW      (1),
    .SWACCESS("RO"),
    .RESVAL  (1'h0)
  ) u_status_active (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    .we     (1'b0),
    .wd     ('0  ),

    // from internal hardware
    .de     (hw2reg.status.active.de),
    .d      (hw2reg.status.active.d ),

    // to internal hardware
    .qe     (),
    .q      (),

    // to register interface (read)
    .qs     (status_active_qs)
  );


  //   F[irq]: 8:8
  prim_subreg #(
    .DW      (1),
    .SWACCESS("RO"),
    .RESVAL  (1'h0)
  ) u_status_irq (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    .we     (1'b0),
    .wd     ('0  ),

    // from internal hardware
    .de     (hw2reg.status.irq.de),
    .d      (hw2reg.status.irq.d ),

    // to internal hardware
    .qe     (),
    .q      (),

    // to register interface (read)
    .qs     (status_irq_qs)
  );




  logic [1:0] addr_hit;
  always_comb begin
    addr_hit = '0;
    addr_hit[0] = (reg_addr == EXAMPLE_CONTROL_OFFSET);
    addr_hit[1] = (reg_addr == EXAMPLE_STATUS_OFFSET);
  end

  assign addrmiss = (reg_re || reg_we) ? ~|addr_hit : 1'b0 ;

  // Check sub-word write is permitted
  always_comb begin
    wr_err = 1'b0;
    if (addr_hit[0] && reg_we && (EXAMPLE_PERMIT[0] != (EXAMPLE_PERMIT[0] & reg_wstrb))) wr_err = 1'b1 ;
    if (addr_hit[1] && reg_we && (EXAMPLE_PERMIT[1] != (EXAMPLE_PERMIT[1] & reg_wstrb))) wr_err = 1'b1 ;
  end

  assign control_en_we = addr_hit[0] & reg_we & ~wr_err;
  assign control_en_wd = reg_wdata[0];

  assign control_irq_en_we = addr_hit[0] & reg_we & ~wr_err;
  assign control_irq_en_wd = reg_wdata[1];



  // Read data return
  always_comb begin
    reg_rdata_next = '0;
    unique case (1'b1)
      addr_hit[0]: begin
        reg_rdata_next[0] = control_en_qs;
        reg_rdata_next[1] = control_irq_en_qs;
      end

      addr_hit[1]: begin
        reg_rdata_next[0] = status_active_qs;
        reg_rdata_next[8] = status_irq_qs;
      end

      default: begin
        reg_rdata_next = '1;
      end
    endcase
  end

  // Assertions for Register Interface
  // REVISIT: add AHB Assertions

endmodule
