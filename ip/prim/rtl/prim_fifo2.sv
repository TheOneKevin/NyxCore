`ifdef VERILATOR_LINT
    `default_nettype none
`endif

module prim_fifo2 #(
    parameter WIDTH = 32
) (
    input wire clk,
    input wire reset,
    // Upstream ports
    output  logic               urdy_o,
    input   logic               uvld_i,
    input   logic[WIDTH-1:0]    udat_i,
    // Downstream ports
    input   logic               drdy_i,
    output  logic               dvld_o,
    output  logic[WIDTH-1:0]    ddat_o,
    // Expose inner buffer port
    output  logic               inner_vld_o,
    output  logic[WIDTH-1:0]    inner_dat_o
);
    reg[WIDTH:0] buf1;
    reg[WIDTH:0] buf2;

    logic drdy_r;
    assign drdy_r = drdy_i;

    always @(*)
    case(buf2[0])
        1'b0: begin
            ddat_o = buf1[WIDTH:1];
            dvld_o = buf1[0];
            inner_dat_o = buf2[WIDTH:1];
            inner_vld_o = buf2[0];
        end
        1'b1: begin
            inner_dat_o = buf1[WIDTH:1];
            inner_vld_o = buf1[0];
            ddat_o = buf2[WIDTH:1];
            dvld_o = buf2[0];
        end
    endcase

    // Upstream ready only when state != STATE_FULL
    assign urdy_o = !buf2[0];

    // Drives: buf1
    always @(posedge clk)
    if(reset) begin
        buf1 <= 0;
    end else if(urdy_o) begin
        buf1 <= { udat_i, uvld_i };
    end

    // Drives: buf2
    always @(posedge clk)
    if(reset) begin
        buf2 <= 0;
    end else begin
        // If downstream is blocked, buffer the current (possible) transaction
        if(urdy_o && !drdy_r) begin
            buf2 <= buf1;
        end
        if(drdy_r) begin
            buf2[0] <= 1'b0;
        end
    end

`ifdef SIMULATION
    event EventUpstreamBeat;
    always @(posedge clk)
    if(!reset && urdy_o && uvld_i) -> EventUpstreamBeat;
    event EventDownstreamBeat;
    always @(posedge clk)
    if(!reset && drdy_i && dvld_o) -> EventDownstreamBeat;
`endif
endmodule
