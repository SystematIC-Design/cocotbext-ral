// MIT License
//
// Copyright (c) 2021 SystematIC Design BV
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

module example
  import apb_pkg::*;
  (
   input logic pclk_i,
   input logic preset_ni,

   input       apb_h2d_t apb_h2d_i, // The APB naming must follow this style
   output      apb_d2h_t apb_d2h_o  // or pass signals[] to APBMasterDriver.
   );


  localparam COUNT_MAX = 32'd100;

  // --------------------------------------------------------------------------------
  // Logic Declarations
  // --------------------------------------------------------------------------------

  example_reg_pkg::example_reg2hw_t reg2hw;
  example_reg_pkg::example_hw2reg_t hw2reg;

  logic [31:0] count_q, count_d;
  logic count_en;
  logic irq_en;

  // --------------------------------------------------------------------------------
  // Register Block
  // --------------------------------------------------------------------------------

  /**
   * This is the top level instance of the register file. It is important that the
   * instance name is "u_reg" in order to match up with the UVM auto-generated hier
   * naming convension.  If you change this, then make sure to update the auto-
   * generated Python classes. But just don't do it.  Ok.
   */
  example_reg_top
    u_reg (.clk_i     (pclk_i),
           .rst_ni    (preset_ni),
           .apb_i     (apb_h2d_i),
           .apb_o     (apb_d2h_o),
           .reg2hw    (reg2hw),
           .hw2reg    (hw2reg),
           .devmode_i ('1)
           );

  assign count_en = reg2hw.control.en.q;
  assign irq_en   = reg2hw.control.irq_en.q;


  // --------------------------------------------------------------------------------
  // Dummy Logic
  // --------------------------------------------------------------------------------

  /**
   * Simple incrementing counter that fires an interrupt when it hits a count value.
   */
  assign count_d = (count_en && (count_q < COUNT_MAX)) ? count_q + 1 : count_q;

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      count_q <= '0;
    end else begin
      count_q <= count_d;
    end
  end

  assign hw2reg.status.active.d  = count_en && (count_q < COUNT_MAX);
  assign hw2reg.status.active.de = 1'b1;
  assign hw2reg.status.irq.d     = count_en && (count_q == COUNT_MAX) && irq_en;
  assign hw2reg.status.irq.de    = 1'b1;

endmodule
