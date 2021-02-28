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

package apb_pkg;

    typedef enum logic [1:0] {
        StateIdle    = 2'h0,
        StateSetup   = 2'h1,
        StateAccess  = 2'h3,
        StateUnknown = 2'bXX
    } apb_state_e;

    typedef struct packed {
        logic        psel;
        logic        pwrite;
        logic        penable;
        logic [31:0] paddr;
        logic [31:0] pwdata;
        logic [3:0]  pstrb;
    } apb_h2d_t;

    typedef struct packed {
        logic [31:0] prdata;
        logic        pready;
        logic        pslverr;
    } apb_d2h_t;

endpackage

