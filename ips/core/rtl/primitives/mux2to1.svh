`ifndef MUX2TO1_SVH
`define MUX2TO1_SVH

`ifdef VERILATOR_LINT
    `default_nettype none
`endif

module mux2to1 (
    input wire a0,
    input wire a1,
    input wire sel,
    output wire b
);
    assign b = sel == 1'b0 ? a0 : a1;
endmodule

`endif
