// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Register Package auto-generated by `reggen` containing data structure

<%
  num_wins = len(block.wins)
  num_wins_width = ((num_wins+1).bit_length()) - 1
  num_dsp  = num_wins + 1
  max_regs_char = len("{}".format(block.get_n_regs_flat()-1))
  regs_flat = block.get_regs_flat()
%>
`include "prim_assert.sv"

module ${block.name}_reg_top (
  input clk_i,
  input rst_ni,

  // Below Regster interface can be changed
% if block.bus_device == "apb":
  input  apb_pkg::apb_h2d_t apb_i,
  output apb_pkg::apb_d2h_t apb_o,
% else:
  input  ahb_pkg::ahb_h2d_t ahb_i,
  output ahb_pkg::ahb_d2h_t ahb_o,
%endif
% if num_wins != 0:

  // Output port for window
  output apb_pkg::apb_h2d_t apb_win_o  [${num_wins}],
  input  apb_pkg::apb_d2h_t apb_win_i  [${num_wins}],

% endif
  // To HW
% if block.get_n_bits(["q","qe","re"]):
  output ${block.name}_reg_pkg::${block.name}_reg2hw_t reg2hw, // Write
% endif
% if block.get_n_bits(["d","de"]):
  input  ${block.name}_reg_pkg::${block.name}_hw2reg_t hw2reg, // Read
% endif

  // Config
  input devmode_i // If 1, explicit error return for unmapped register access
);

  import ${block.name}_reg_pkg::* ;

  localparam int AW = ${block.addr_width};
  localparam int DW = ${block.width};
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

% if block.bus_device == "apb":
  apb_pkg::apb_h2d_t apb_reg_h2d;
  apb_pkg::apb_d2h_t apb_reg_d2h;
% else:
  ahb_pkg::ahb_h2d_t ahb_reg_h2d;
  ahb_pkg::ahb_d2h_t ahb_reg_d2h;
% endif

% if num_wins == 0:
% if block.bus_device == "apb":
  assign apb_reg_h2d = apb_i;
  assign apb_o       = apb_reg_d2h;
% else:
  assign ahb_reg_h2d = ahb_i;
  assign ahb_o       = ahb_reg_d2h;
% endif
% else:
  tlul_pkg::tl_h2d_t tl_socket_h2d [${num_dsp}];
  tlul_pkg::tl_d2h_t tl_socket_d2h [${num_dsp}];

  logic [${num_wins_width}:0] reg_steer;

  // socket_1n connection
  assign tl_reg_h2d = tl_socket_h2d[${num_wins}];
  assign tl_socket_d2h[${num_wins}] = tl_reg_d2h;

  % for i,t in enumerate(block.wins):
  assign tl_win_o[${i}] = tl_socket_h2d[${i}];
  assign tl_socket_d2h[${i}] = tl_win_i[${i}];
  % endfor

  // Create Socket_1n
  tlul_socket_1n #(
    .N          (${num_dsp}),
    .HReqPass   (1'b1),
    .HRspPass   (1'b1),
    .DReqPass   ({${num_dsp}{1'b1}}),
    .DRspPass   ({${num_dsp}{1'b1}}),
    .HReqDepth  (4'h0),
    .HRspDepth  (4'h0),
    .DReqDepth  ({${num_dsp}{4'h0}}),
    .DRspDepth  ({${num_dsp}{4'h0}})
  ) u_socket (
    .clk_i,
    .rst_ni,
    .tl_h_i (tl_i),
    .tl_h_o (tl_o),
    .tl_d_o (tl_socket_h2d),
    .tl_d_i (tl_socket_d2h),
    .dev_select_i (reg_steer)
  );

  // Create steering logic
  always_comb begin
    reg_steer = ${num_dsp-1};       // Default set to register

    // TODO: Can below codes be unique case () inside ?
  % for i,w in enumerate(block.wins):
      % if w.limit_addr == 2**block.addr_width:
    if (tl_i.a_address[AW-1:0] >= ${w.base_addr}) begin
      // Exceed or meet the address range. Removed the comparison of limit addr ${"'h %x" % w.limit_addr}
      % else:
    if (tl_i.a_address[AW-1:0] >= ${w.base_addr} && tl_i.a_address[AW-1:0] < ${w.limit_addr}) begin
      % endif
      reg_steer = ${i};
    end
  % endfor
  end
% endif

% if block.bus_device == "apb":
  apb_adapter_reg #(
% else:
  ahb_adapter_reg #(
% endif
    .RegAw(AW),
    .RegDw(DW)
  ) u_reg_if (
    .clk_i,
    .rst_ni,

% if block.bus_device == "apb":
    .apb_i (apb_reg_h2d),
    .apb_o (apb_reg_d2h),
% else:
    .ahb_i (ahb_reg_h2d),
    .ahb_o (ahb_reg_d2h),
% endif

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
  % for r in regs_flat:
    % if len(r.fields) == 1:
<%
      msb = r.fields[0].msb
      lsb = r.fields[0].lsb
      sig_name = r.name
      f = r.fields[0]
      swwraccess = f.swwraccess
      swrdaccess = f.swrdaccess
      hwext = r.hwext
      regwen = r.regwen
      shadowed = r.shadowed
%>\
${sig_gen(msb, lsb, sig_name, swwraccess, swrdaccess, hwext, regwen, shadowed)}\
    % else:
      % for f in r.fields:
<%
      msb = f.msb
      lsb = f.lsb
      sig_name = r.name + "_" + f.name
      swwraccess = f.swwraccess
      swrdaccess = f.swrdaccess
      hwext = r.hwext
      regwen = r.regwen
      shadowed = r.shadowed
%>\
${sig_gen(msb, lsb, sig_name, swwraccess, swrdaccess, hwext, regwen, shadowed)}\
      % endfor
    % endif
  % endfor

  // Register instances
  % for r in block.regs:
  ######################## multiregister ###########################
    % if r.is_multi_reg():
<%
      mreg_flat = r.get_regs_flat()
      k = 0
%>
      % for sr in mreg_flat:
  // Subregister ${k} of Multireg ${r.name}
  // R[${sr.name}]: V(${str(sr.hwext)})
        % if len(sr.fields) == 1:
<%
          f = sr.fields[0]
          finst_name = sr.name
          fsig_name = r.name + "[%d]" % k
          msb = f.msb
          lsb = f.lsb
          swaccess = f.swaccess
          swrdaccess = f.swrdaccess
          swwraccess = f.swwraccess
          hwaccess = f.hwaccess
          hwqe = f.hwqe
          hwre = f.hwre
          hwext = sr.hwext
          resval = f.resval
          regwen = sr.regwen
          shadowed = sr.shadowed
          k = k + 1
%>
${finst_gen(finst_name, fsig_name, msb, lsb, swaccess, swrdaccess, swwraccess, hwaccess, hwqe, hwre, hwext, resval, regwen, shadowed)}
        % else:
          % for f in sr.fields:
<%
            finst_name = sr.name + "_" + f.name
            if r.ishomog:
              fsig_name = r.name + "[%d]" % k
              k = k + 1
            else:
              fsig_name = r.name + "[%d]" % k + "." + f.get_basename()
            msb = f.msb
            lsb = f.lsb
            swaccess = f.swaccess
            swrdaccess = f.swrdaccess
            swwraccess = f.swwraccess
            hwaccess = f.hwaccess
            hwqe = f.hwqe
            hwre = f.hwre
            hwext = sr.hwext
            resval = f.resval
            regwen = sr.regwen
            shadowed = sr.shadowed
%>
  // F[${f.name}]: ${f.msb}:${f.lsb}
${finst_gen(finst_name, fsig_name, msb, lsb, swaccess, swrdaccess, swwraccess, hwaccess, hwqe, hwre, hwext, resval, regwen, shadowed)}
          % endfor
<%
          if not r.ishomog:
            k += 1
%>
        % endif
      ## for: mreg_flat
      % endfor
######################## register with single field ###########################
    % elif len(r.fields) == 1:
  // R[${r.name}]: V(${str(r.hwext)})
<%
        f = r.fields[0]
        finst_name = r.name
        fsig_name = r.name
        msb = f.msb
        lsb = f.lsb
        swaccess = f.swaccess
        swrdaccess = f.swrdaccess
        swwraccess = f.swwraccess
        hwaccess = f.hwaccess
        hwqe = f.hwqe
        hwre = f.hwre
        hwext = r.hwext
        resval = f.resval
        regwen = r.regwen
        shadowed = r.shadowed
%>
${finst_gen(finst_name, fsig_name, msb, lsb, swaccess, swrdaccess, swwraccess, hwaccess, hwqe, hwre, hwext, resval, regwen, shadowed)}
######################## register with multiple fields ###########################
    % else:
  // R[${r.name}]: V(${str(r.hwext)})
      % for f in r.fields:
<%
        finst_name = r.name + "_" + f.name
        fsig_name = r.name + "." + f.name
        msb = f.msb
        lsb = f.lsb
        swaccess = f.swaccess
        swrdaccess = f.swrdaccess
        swwraccess = f.swwraccess
        hwaccess = f.hwaccess
        hwqe = f.hwqe
        hwre = f.hwre
        hwext = r.hwext
        resval = f.resval
        regwen = r.regwen
        shadowed = r.shadowed
%>
  //   F[${f.name}]: ${f.msb}:${f.lsb}
${finst_gen(finst_name, fsig_name, msb, lsb, swaccess, swrdaccess, swwraccess, hwaccess, hwqe, hwre, hwext, resval, regwen, shadowed)}
      % endfor
    % endif

  ## for: block.regs
  % endfor


  logic [${len(regs_flat)-1}:0] addr_hit;
  always_comb begin
    addr_hit = '0;
    % for i,r in enumerate(regs_flat):
    addr_hit[${"{}".format(i).rjust(max_regs_char)}] = (reg_addr == ${block.name.upper()}_${r.name.upper()}_OFFSET);
    % endfor
  end

  assign addrmiss = (reg_re || reg_we) ? ~|addr_hit : 1'b0 ;

  // Check sub-word write is permitted
  always_comb begin
    wr_err = 1'b0;
    % for i,r in enumerate(regs_flat):
<% index_str = "{}".format(i).rjust(max_regs_char) %>\
    if (addr_hit[${index_str}] && reg_we && (${block.name.upper()}_PERMIT[${index_str}] != (${block.name.upper()}_PERMIT[${index_str}] & reg_wstrb))) wr_err = 1'b1 ;
    % endfor
  end
  % for i, r in enumerate(regs_flat):
    % if len(r.fields) == 1:
<%
      f = r.fields[0]
      sig_name = r.name
      inst_name = r.name
      msb = f.msb
      lsb = f.lsb
      swrdaccess = f.swrdaccess
      swwraccess = f.swwraccess
      hwext = r.hwext
      shadowed = r.shadowed
%>
${we_gen(sig_name, msb, lsb, swrdaccess, swwraccess, hwext, shadowed, i)}\
    % else:
      % for f in r.fields:
<%
      sig_name = r.name + "_" + f.name
      inst_name = r.name + "." + f.name
      msb = f.msb
      lsb = f.lsb
      swrdaccess = f.swrdaccess
      swwraccess = f.swwraccess
      hwext = r.hwext
      shadowed = r.shadowed
%>
${we_gen(sig_name, msb, lsb, swrdaccess, swwraccess, hwext, shadowed, i)}\
      % endfor
    % endif
  % endfor

  // Read data return
  always_comb begin
    reg_rdata_next = '0;
    unique case (1'b1)
      % for i, r in enumerate(regs_flat):
        % if len(r.fields) == 1:
<%
          f = r.fields[0]
          sig_name = r.name
          inst_name = r.name
          msb = f.msb
          lsb = f.lsb
          swrdaccess = f.swrdaccess
%>\
      addr_hit[${i}]: begin
${rdata_gen(sig_name, msb, lsb, swrdaccess)}\
      end

        % else:
      addr_hit[${i}]: begin
          % for f in r.fields:
<%
          sig_name = r.name + "_" + f.name
          inst_name = r.name + "." + f.name
          msb = f.msb
          lsb = f.lsb
          swrdaccess = f.swrdaccess
%>\
${rdata_gen(sig_name, msb, lsb, swrdaccess)}\
          % endfor
      end

        % endif
      % endfor
      default: begin
        reg_rdata_next = '1;
      end
    endcase
  end

  // Assertions for Register Interface
  // REVISIT: add AHB Assertions

endmodule
<%def name="str_bits_sv(msb, lsb)">\
% if msb != lsb:
${msb}:${lsb}\
% else:
${msb}\
% endif
</%def>\
<%def name="str_arr_sv(msb, lsb)">\
% if msb != lsb:
[${msb-lsb}:0] \
% endif
</%def>\
<%def name="sig_gen(msb, lsb, sig_name, swwraccess, swrdaccess, hwext, regwen, shadowed)">\
  % if swrdaccess != SwRdAccess.NONE:
  logic ${str_arr_sv(msb, lsb)}${sig_name}_qs;
  % endif
  % if swwraccess != SwWrAccess.NONE:
  logic ${str_arr_sv(msb, lsb)}${sig_name}_wd;
  logic ${sig_name}_we;
  % endif
  % if (swrdaccess != SwRdAccess.NONE and hwext) or shadowed:
  logic ${sig_name}_re;
  % endif
</%def>\
<%def name="finst_gen(finst_name, fsig_name, msb, lsb, swaccess, swrdaccess, swwraccess, hwaccess, hwqe, hwre, hwext, resval, regwen, shadowed)">\
  % if hwext:       ## if hwext, instantiate prim_subreg_ext
  prim_subreg_ext #(
    .DW    (${msb - lsb + 1})
  ) u_${finst_name} (
    % if swrdaccess != SwRdAccess.NONE:
    .re     (${finst_name}_re),
    % else:
    .re     (1'b0),
    % endif
    % if swwraccess != SwWrAccess.NONE:
      % if regwen:
    // qualified with register enable
    .we     (${finst_name}_we & ${regwen}_qs),
      % else:
    .we     (${finst_name}_we),
      % endif
    .wd     (${finst_name}_wd),
    % else:
    .we     (1'b0),
    .wd     ('0),
    % endif
    % if hwaccess == HwAccess.HRO:
    .d      ('0),
    % else:
    .d      (hw2reg.${fsig_name}.d),
    % endif
    % if hwre or shadowed:
    .qre    (reg2hw.${fsig_name}.re),
    % else:
    .qre    (),
    % endif
    % if hwaccess == HwAccess.HWO:
    .qe     (),
    .q      (),
    % else:
      % if hwqe:
    .qe     (reg2hw.${fsig_name}.qe),
      % else:
    .qe     (),
      % endif
    .q      (reg2hw.${fsig_name}.q ),
    % endif
    % if swrdaccess != SwRdAccess.NONE:
    .qs     (${finst_name}_qs)
    % else:
    .qs     ()
    % endif
  );
  % else:       ## if not hwext, instantiate prim_subreg, prim_subreg_shadow or constant assign
    % if hwaccess == HwAccess.NONE and swrdaccess == SwRdAccess.RD and swwraccess == SwWrAccess.NONE:
  // constant-only read
  assign ${finst_name}_qs = ${msb-lsb+1}'h${"%x" % resval};
    % else:     ## not hwext not constant
      % if not shadowed:
  prim_subreg #(
      % else:
  prim_subreg_shadow #(
      % endif
    .DW      (${msb - lsb + 1}),
    .SWACCESS("${swaccess.name}"),
    .RESVAL  (${msb-lsb+1}'h${"%x" % resval})
  ) u_${finst_name} (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

      % if shadowed:
    .re     (${finst_name}_re),
      % endif
      % if swwraccess != SwWrAccess.NONE: ## non-RO types
        % if regwen:
    // from register interface (qualified with register enable)
    .we     (${finst_name}_we & ${regwen}_qs),
        % else:
    // from register interface
    .we     (${finst_name}_we),
        % endif
    .wd     (${finst_name}_wd),
      % else:                             ## RO types
    .we     (1'b0),
    .wd     ('0  ),
      % endif

    // from internal hardware
      % if hwaccess == HwAccess.HRO or hwaccess == HwAccess.NONE:
    .de     (1'b0),
    .d      ('0  ),
      % else:
    .de     (hw2reg.${fsig_name}.de),
    .d      (hw2reg.${fsig_name}.d ),
      % endif

    // to internal hardware
      % if hwaccess == HwAccess.HWO or hwaccess == HwAccess.NONE:
    .qe     (),
    .q      (),
      % else:
        % if hwqe:
    .qe     (reg2hw.${fsig_name}.qe),
        % else:
    .qe     (),
        % endif
    .q      (reg2hw.${fsig_name}.q ),
      % endif

      % if not shadowed:
        % if swrdaccess != SwRdAccess.NONE:
    // to register interface (read)
    .qs     (${finst_name}_qs)
        % else:
    .qs     ()
        % endif
      % else:
        % if swrdaccess != SwRdAccess.NONE:
    // to register interface (read)
    .qs     (${finst_name}_qs),
        % else:
    .qs     (),
        % endif

    // Shadow register error conditions
    .err_update  (reg2hw.${fsig_name}.err_update ),
    .err_storage (reg2hw.${fsig_name}.err_storage)
      % endif
  );
    % endif  ## end non-constant prim_subreg
  % endif
</%def>\
<%def name="we_gen(sig_name, msb, lsb, swrdaccess, swwraccess, hwext, shadowed, idx)">\
% if swwraccess != SwWrAccess.NONE:
  % if swrdaccess != SwRdAccess.RC:
  assign ${sig_name}_we = addr_hit[${idx}] & reg_we & ~wr_err;
  assign ${sig_name}_wd = reg_wdata[${str_bits_sv(msb,lsb)}];
  % else:
  ## Generate WE based on read request, read should clear
  assign ${sig_name}_we = addr_hit[${idx}] & reg_re;
  assign ${sig_name}_wd = '1;
  % endif
% endif
% if (swrdaccess != SwRdAccess.NONE and hwext) or shadowed:
  assign ${sig_name}_re = addr_hit[${idx}] && reg_re;
% endif
</%def>\
<%def name="rdata_gen(sig_name, msb, lsb, swrdaccess)">\
% if swrdaccess != SwRdAccess.NONE:
        reg_rdata_next[${str_bits_sv(msb,lsb)}] = ${sig_name}_qs;
% else:
        reg_rdata_next[${str_bits_sv(msb,lsb)}] = '0;
% endif
</%def>\
