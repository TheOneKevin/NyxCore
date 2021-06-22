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
    output  wire [3:0]  wp_addr_o,
    output  wire [31:0] wp_data_o,
    output  wire        wp_we1_o,
    output  wire        wp_we2_o,

    // Pipeline data packets
    input   hs32_s2pkt  data_i,
    output  hs32_s3pkt  data_o,

    // Pipeline controls
    output  wire[3:0]   rd3_o
);
    assign wp_addr_o    = data_i.rd;
    assign wp_we1_o     = data_i.we1 & valid_i;
    assign wp_we2_o     = data_i.we2 & valid_i;

    // Calculate data packet
    assign data_o.d     = wp_data_o;
    
    // Calculate data stall signals
    assign rd3_o        = data_i.rd;

    hs32_alu u0 (
        .clk(clk), .reset(reset),
        .a_i(data_i.d1), .b_i(data_i.d2),
        .ctl_i(data_i.ctl),
        .flags_o(), .out(wp_data_o)
    );
    
endmodule
