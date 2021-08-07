`default_nettype none

// !! Order is important !!

`include "rtl/include/utils.svh"
`include "rtl/include/types.svh"
`include "rtl/include/amba3.svh"

`include "primitives/mux2to1.svh"
`include "primitives/mux4to1.svh"
`include "primitives/skid_buffer.svh"
`include "primitives/shift_right.svh"

`include "rtl/hs32_regfile4r1w.sv"
`include "rtl/hs32_lcu.sv"
`include "rtl/hs32_adder.sv"
`include "rtl/hs32_alu.sv"
`include "rtl/hs32_decode1.sv"
`include "rtl/hs32_decode2.sv"
`include "rtl/hs32_execute.sv"
`include "rtl/hs32_lsu.sv"
`include "rtl/hs32_pipeline.sv"
