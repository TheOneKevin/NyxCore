`ifdef VERILATOR_LINT
    `default_nettype none
`endif

module opi_phy #(
    parameter ADDR_WIDTH        = 32,
    parameter NUM_WAYS          = 4,
    parameter TAG_ADDR_WIDTH    = 8,
    parameter CACHE_ADDR_WIDTH  = 9
) (
    clk, reset, clk50, clk50p90,
    pmc_vld_i, pmc_rdy_o, pmc_cmd_i, pmc_ack_o,
    pmc_tag_clk_o,
    pmc_tag_web_o,
    pmc_tag_addr_o,
    pmc_tag_d_o,
    pmc_tag_d_i,
    pmc_cache_clk_o,
    pmc_cache_web_o,
    pmc_cache_addr_o,
    pmc_cache_d_o,
    pmc_cache_d_i,
    pad_ck_o, pad_csn_o, pad_dq_i, pad_dq_o, pad_rwds_i, pad_rwds_o
);
    // TODO: Figure out a better way to determine size of this signal
    localparam phycmdWidth = ADDR_WIDTH+NUM_WAYS+1;

    typedef struct packed {
        logic flush;
        logic[NUM_WAYS-1:0] way;
        logic[ADDR_WIDTH-1:0] addr;
    } ds_pkt;

    ////////////////////////////////////////////////////////////////////////////

    input   wire                    reset;
    input   wire                    clk;
    input   wire                    clk50;
    input   wire                    clk50p90;

    input   wire                    pmc_vld_i;
    output  wire                    pmc_rdy_o;
    input   wire[phycmdWidth-1:0]   pmc_cmd_i;
    output  wire                    pmc_ack_o;

    output  wire                    pmc_tag_clk_o;
    output  wire                    pmc_tag_web_o;
    output  wire[TAG_ADDR_WIDTH-1:0] pmc_tag_addr_o;
    output  wire[31:0]              pmc_tag_d_o;
    input   wire[31:0]              pmc_tag_d_i;

    output  wire                    pmc_cache_clk_o;
    output  wire                    pmc_cache_web_o;
    output  wire[CACHE_ADDR_WIDTH-1:0] pmc_cache_addr_o;
    output  wire[31:0]              pmc_cache_d_o;
    input   wire[31:0]              pmc_cache_d_i;

    output  wire                    pad_ck_o;
    output  wire                    pad_csn_o;
    input   wire[7:0]               pad_dq_i;
    output  wire[7:0]               pad_dq_o;
    input   wire                    pad_rwds_i;
    output  wire                    pad_rwds_o;

    ////////////////////////////////////////////////////////////////////////////

    assign pmc_cache_clk_o = clk50p90;
    assign pmc_tag_clk_o = clk50p90;

    

endmodule
