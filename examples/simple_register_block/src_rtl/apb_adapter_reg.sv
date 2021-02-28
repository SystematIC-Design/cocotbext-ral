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

module apb_adapter_reg
  import apb_pkg::*;
  #(
    parameter int RegAw = 8,
    parameter int RegDw = 32,
    parameter int RegBw = RegDw/8
    ) (
       input                    clk_i,
       input                    rst_ni,

       // APB interface
       input                    apb_h2d_t apb_i,
       output                   apb_d2h_t apb_o,

       // Register interface
       output logic             re_o,
       output logic             we_o,
       output logic [RegAw-1:0] addr_o,
       output logic [RegDw-1:0] wdata_o,
       output logic [RegBw-1:0] wstrb_o,
       input logic [RegDw-1:0]  rdata_i,
       input logic              error_i
       );

  // ----------------------------------------------------------------------
  // Logic Declarations
  // ----------------------------------------------------------------------

  apb_state_e apb_state;


  // ----------------------------------------------------------------------
  // APB State Decoder
  // ----------------------------------------------------------------------

  /*
   APB has three states defined by the PSEL and PENABLE signals.  Each read
   or write transaction takes two cycles, an initial SETUP phase and then an
   ACCESS phase.

   In the SETUP phase, the slave is selected by the assertion of PSEL.  The
   address bus PADDR, write enable PWRITE and write data PWDATA, must all
   remain stable throughout the SETUP and ACCESS phases.

   In the ACCESS phase, the PENABLE signal is asserted and the slave must
   complete the transfer by asserting the PREADY output.
   */

  always_comb begin : apb_state_decoder
    case({apb_i.penable, apb_i.psel})
      2'h0,
      2'h2 : apb_state = StateIdle;
      2'h1 : apb_state = StateSetup;
      2'h3 : apb_state = StateAccess;
      default : apb_state = StateUnknown;
    endcase
  end


  // ----------------------------------------------------------------------
  // Register Interface Assignments
  // ----------------------------------------------------------------------

  assign we_o    = (apb_state == StateAccess) &&  apb_i.pwrite;
  assign re_o    = (apb_state == StateAccess) && !apb_i.pwrite;
  assign addr_o  = { apb_i.paddr[RegAw-1:2], 2'b00 };
  assign wdata_o = apb_i.pwdata;
  assign wstrb_o = apb_i.pstrb;

  assign apb_o.pready  = 1'b1;     // No wait states
  assign apb_o.prdata  = rdata_i;
  assign apb_o.pslverr = error_i;


endmodule
