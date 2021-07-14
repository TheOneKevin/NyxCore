`ifndef SHIFT_RIGHT_SVH
`define SHIFT_RIGHT_SVH

`ifdef VERILATOR_LINT
    `default_nettype none
    `include "mux2to1.svh"
`endif

// Performs out = a << b with c as sign extension (0 or 1 extend)
module shift_right #(
    parameter WIDTH = 32,
    parameter DEPTH = 5
) (
    input wire[WIDTH-1:0] a,
    input wire[DEPTH-1:0] b,
    input wire c,
    output wire[WIDTH-1:0] out
);
    genvar i;
    genvar j;
    // verilator lint_off UNOPTFLAT
    generate
        wire[WIDTH-1:0] mat[DEPTH:0];
        for(j = 0; j < DEPTH; j = j+1) begin
            for(i = 0; i < WIDTH; i = i+1) begin
                mux2to1 MUX (
                    .a0(mat[j][i]),
                    .a1((i+(1<<j) < WIDTH) ? mat[j][i+(1<<j)] : c),
                    .sel(b[j]),
                    .b(mat[j+1][i])
                );
            end
        end
        assign mat[0] = a;
        assign out = mat[DEPTH];
    endgenerate
    // verilator lint_on UNOPTFLAT
endmodule

`endif
