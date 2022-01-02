`ifdef VERILATOR_LINT
    `default_nettype none
    `include "rtl/hs32_pipeline.sv"
`endif

`include "dv/tb/ahb3_dummy.sv"

// verilator lint_off STMTDLY
`timescale 1ns/1ns

module top();

endmodule
