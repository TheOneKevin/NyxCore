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
    // Pipeline data
    typedef struct packed {
        logic[31:0] hwdata;
        logic[3:0] rd;
        logic regwe;
        logic valid;
    } lsu_t;

    // AHB-lite constants
    assign HSIZE_o = 2;
    assign HBURST_o = `HBURST_SINGLE;
    assign HPROT_o = `HPROT_PRIVILEGED | `HPROT_DATA;
    assign HMASTLOCK_o = 0;

    // Drives: htrans
    reg[1:0] htrans;
    assign HTRANS_o = htrans;
    always @(posedge clk)
    if(!resetn) begin
        htrans <= `HTRANS_IDLE;
    end else if(HREADY_i) begin
        htrans <= valid_i ? `HTRANS_NOSEQ : `HTRANS_IDLE;
    end

    // Drives: haddr, hwrite
    reg[31:0] haddr;
    reg hwrite;
    assign HADDR_o = haddr;
    assign HWRITE_o = hwrite;
    always @(posedge clk)
    if(!resetn) begin
        haddr <= 0;
        hwrite <= 0;
    end else if(HREADY_i) begin
        haddr <= data_i.res;
        hwrite <= data_i.memwe;
    end

    // Drives: pipeline, pipeline_buf
    // TODO: Reduce switching and optimize for low power
    lsu_t pipeline_buf, pipeline;
    always @(posedge clk)
    if(!resetn) begin
        pipeline_buf <= 0;
        pipeline <= 0;
    end else if(HREADY_i) begin
        pipeline_buf.hwdata <= data_i.std;
        pipeline_buf.rd <= data_i.rd;
        pipeline_buf.regwe <= data_i.regwe;
        pipeline_buf.valid <= valid_i;
        pipeline <= pipeline_buf;
    end

    // Write port
    assign wp_we_o      = pipeline.regwe & HREADY_i;
    assign wp_data_o    = HRDATA_i;
    assign wp_addr_o    = pipeline.rd;

    // Pipeline ports
    // TODO: Don't pass in combinational path HREADY_i
    assign HWDATA_o     = pipeline.hwdata;
    assign ready_o      = HREADY_i;
    assign l1_o.rd      = pipeline_buf.rd;
    assign l1_o.vld     = pipeline_buf.regwe & pipeline_buf.valid;
    assign l2_o.rd      = pipeline.rd;
    assign l2_o.vld     = pipeline.regwe & pipeline_buf.valid & HREADY_i;
endmodule