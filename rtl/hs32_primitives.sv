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

module skid_buffer #(
    parameter WIDTH = 32
) (
    input wire clk,
    input wire reset,

    input wire stall_i,

    output wire rdy_o,
    input wire val_i,
    input wire[WIDTH-1:0] d_i,

    input wire rdy_i,
    output wire val_o,
    output reg[WIDTH-1:0] d_o
);
    reg val_r;
    assign rdy_o = (rdy_i | !val_o) & !stall_i;
    assign val_o = val_r & !stall_i;

    // Drives: d_o
    always @(posedge clk)
    if(reset) begin
        d_o <= 0;
    end else if(rdy_o) begin
        d_o <= d_i;
    end

    // Drives: val_o
    always @(posedge clk)
    if(reset) begin
        val_r <= 0;
    end else if(rdy_o) begin
        val_r <= val_i;
    end
endmodule