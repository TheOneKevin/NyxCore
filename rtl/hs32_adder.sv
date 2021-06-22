`ifdef VERILATOR_LINT
    `default_nettype none
    `include "hs32_lcu.sv"
`endif

module hs32_adder (A, B, CI, OUT, CO);
    parameter WIDTH = 32;

    input wire [WIDTH-1:0] A;
    input wire [WIDTH-1:0] B;
    input wire CI;
    output wire [WIDTH:0] OUT;
    output wire [WIDTH-1:0] CO;

    wire [WIDTH-1:0] PS = A ^ B;
    assign OUT = { 1'b0, PS } ^ { CO, CI };

    lcu #(.WIDTH(WIDTH)) u0 (.P(PS), .G(A & B), .CI(CI), .CO(CO));
endmodule