`ifndef MUX4TO1_SVH
`define MUX4TO1_SVH

`ifdef VERILATOR_LINT
    `default_nettype none
`endif

module mux4to1 (
    input wire a0,
    input wire a1,
    input wire a2,
    input wire a3,
    input wire[1:0] sel,
    output wire b
);
    assign b = sel == 2'b00 ? a0
             : sel == 2'b01 ? a1
             : sel == 2'b10 ? a2 : a3;
endmodule

`endif
