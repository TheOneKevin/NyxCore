`ifdef VERILATOR_LINT
    `default_nettype none
    `include "hs32_alu.sv"
    `include "include/utils.svh"
    `include "include/types.svh"
`endif

module hs32_execute #(
    parameter USE_TECHMAP = 1
) (
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
    output  hs32_stall  s3_o,
    input   hs32_stall  l1_i,
    input   hs32_stall  l2_i,
    output  wire        stall_o
);
    assign rp_addr_o    = data_i.rd;
    assign wp_addr_o    = data_i.rd;
    assign wp_we1_o     = data_i.we1 & valid_i;
    assign wp_we2_o     = data_i.we2 & valid_i;

    // Forwarded data
    wire[31:0] d1       = data_i.fwd  ? fwd_i : data_i.d1;
    wire[31:0] d2       = data_i.fwd2 ? fwd_i : data_i.d2;

    wire op_isldr       = data_i.isldr;
    wire op_isstr       = data_i.isstr;
    wire op_islsu       = data_i.isldr || data_i.isstr;

    // Calculate data packet
    assign data_o.rd    = data_i.rd;
    assign data_o.std   = rp_data_i;
    assign data_o.res   = wp_data_o;
    assign data_o.memwe = op_isstr;
    assign data_o.regwe = op_isldr;
    assign data_o.islsu = op_islsu;
    
    // Calculate data stall signals
    assign s3_o.rd      = data_i.rd;
    assign s3_o.vld     = valid_i && !op_isstr;
    assign s3_o.lsu     = op_islsu;
    assign stall_o      = !op_islsu && (l1_i.vld || l2_i.vld);

    wire[3:0] flags;
    hs32_alu #(
        .USE_TECHMAP(USE_TECHMAP)
    ) u0 (
        .clk(clk), .reset(reset),
        .valid_i(valid_i),
        .a_i(d1), .b_i(d2),
        .ctl_i(data_i.ctl),
        .flags_o(flags), .out(wp_data_o)
    );
endmodule
