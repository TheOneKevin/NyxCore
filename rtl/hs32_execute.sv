`ifdef VERILATOR_LINT
    `default_nettype none
    `include "hs32_alu.sv"
    `include "include/utils.svh"
    `include "include/types.svh"
`endif

module hs32_execute (
    input   wire clk,
    input   wire reset,
    input   wire valid_i,

    // Regfile read port
    output  wire[3:0]   rp_addr_o,
    input   wire[31:0]  rp_data_i,

    // Regfile write port
    output  wire [3:0]  wp_addr_o,
    output  wire [31:0] wp_data_o,
    output  wire        wp_we1_o,
    output  wire        wp_we2_o,

    // Pipeline data packets
    input   hs32_s2pkt  data_i,
    output  hs32_s3pkt  data_o,
    input   wire[31:0]  fwd_i,

    // Pipeline controls
    output  wire[3:0]   rd3_o
);
    assign rp_addr_o    = data_i.rd;
    assign wp_addr_o    = data_i.rd;
    assign wp_we1_o     = data_i.we1 & valid_i;
    assign wp_we2_o     = data_i.we2 & valid_i;

    // Forwarded data
    wire[31:0] d1       = data_i.fwd ? fwd_i : data_i.d1;

    // Calculate data packet
    assign data_o.std   = rp_data_i;
    assign data_o.res   = wp_data_o;
    
    // Calculate data stall signals
    assign rd3_o        = data_i.rd;

    wire[3:0] flags;
    hs32_alu u0 (
        .clk(clk), .reset(reset),
        .valid_i(valid_i),
        .a_i(d1), .b_i(data_i.d2),
        .ctl_i(data_i.ctl),
        .flags_o(flags), .out(wp_data_o)
    );
endmodule
