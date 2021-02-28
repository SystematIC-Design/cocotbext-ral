// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Register Package auto-generated by `reggen` containing data structure

package example_reg_pkg;

  ////////////////////////////
  // Typedefs for registers //
  ////////////////////////////
  typedef struct packed {
    struct packed {
      logic        q;
    } en;
    struct packed {
      logic        q;
    } irq_en;
  } example_reg2hw_control_reg_t;


  typedef struct packed {
    struct packed {
      logic        d;
      logic        de;
    } active;
    struct packed {
      logic        d;
      logic        de;
    } irq;
  } example_hw2reg_status_reg_t;


  ///////////////////////////////////////
  // Register to internal design logic //
  ///////////////////////////////////////
  typedef struct packed {
    example_reg2hw_control_reg_t control; // [1:0]
  } example_reg2hw_t;

  ///////////////////////////////////////
  // Internal design logic to register //
  ///////////////////////////////////////
  typedef struct packed {
    example_hw2reg_status_reg_t status; // [3:0]
  } example_hw2reg_t;

  // Register Address
  parameter logic [2:0] EXAMPLE_CONTROL_OFFSET = 3'h 0;
  parameter logic [2:0] EXAMPLE_STATUS_OFFSET = 3'h 4;


  // Register Index
  typedef enum int {
    EXAMPLE_CONTROL,
    EXAMPLE_STATUS
  } example_id_e;

  // Register width information to check illegal writes
  parameter logic [3:0] EXAMPLE_PERMIT [2] = '{
    4'b 0001, // index[0] EXAMPLE_CONTROL
    4'b 0011  // index[1] EXAMPLE_STATUS
  };
endpackage
