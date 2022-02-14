`ifdef VERILATOR_LINT
    `default_nettype none
    `include "include/types.svh"
    `include "include/amba3.svh"
    `include "primitives/skid_buffer.svh"
`endif

module hs32_lsu (
    input wire clk,
    input wire resetn,

    // Pipeline port
    input   wire        valid_i,
    output  wire        ready_o,
    input   hs32_s3pkt  data_i,

    // Pipeline stalls and forwarding
    output  hs32_stall  l1_o,
    output  hs32_stall  l2_o,
    output  wire[31:0]  fwd_o,

    // Regfile write port
    output  wire[3:0]   wp_addr_o,
    output  wire[31:0]  wp_data_o,
    output  wire        wp_we_o,
    
    // AHB-lite slave interface
    input   wire        HREADY_i,
    input   wire        HRESP_i,
    input   wire[31:0]  HRDATA_i,

    // AHB-lite master interface
    output  wire[31:0]  HADDR_o,
    output  wire        HWRITE_o,
    output  wire[2:0]   HSIZE_o,
    output  wire[2:0]   HBURST_o,
    output  wire[3:0]   HPROT_o,
    output  wire[1:0]   HTRANS_o,
    output  wire        HMASTLOCK_o,
    output  wire[31:0]  HWDATA_o
);
    // AHB-lite constants
    assign HSIZE_o = 2;
    assign HBURST_o = `HBURST_SINGLE;
    assign HPROT_o = `HPROT_PRIVILEGED | `HPROT_DATA;
    assign HMASTLOCK_o = 0;

    // TODO: Optimize packet size
    hs32_s3pkt l1l, l2l;
    logic l1rdy, l1vld, l2vld;
    skid_buffer #(.WIDTH($bits(data_i))) l1 (
        .clk(clk), .reset(!resetn), .stall_i(1'b0),
        .rdy_o(ready_o), .val_i(valid_i), .d_i(data_i),
        .rdy_i(l1rdy), .val_o(l1vld), .d_o(l1l)
    );
    skid_buffer #(.WIDTH($bits(l1l))) l2 (
        .clk(clk), .reset(!resetn), .stall_i(1'b0),
        .rdy_o(l1rdy), .val_i(l1vld), .d_i(l1l),
        .rdy_i(HREADY_i), .val_o(l2vld), .d_o(l2l)
    );

    assign HTRANS_o = l1vld ? `HTRANS_NOSEQ : `HTRANS_IDLE;
    assign HADDR_o = l1l.res;
    assign HWRITE_o = l1l.memwe & l1vld;
    assign HWDATA_o = l2l.std;

    assign wp_we_o      = l2l.regwe & l2vld;
    assign wp_data_o    = HRDATA_i;
    assign wp_addr_o    = l2l.rd;

    assign l1_o.vld     = l1vld;
    assign l1_o.rd      = l1l.rd;
    assign l1_o.lsu     = l1l.regwe;
    assign l2_o.vld     = l2vld;
    assign l2_o.rd      = l2l.rd;
    assign l2_o.lsu     = l2l.regwe;
    assign fwd_o        = 32'h0;
endmodule