/**
 * B1_US   B1_DS    B2_US   B2_DS    Output
 *     ┌───┐            ┌───┐
 *  ─┬►│   │◄──────────►│   │◄──────────►
 *   │ │BUF│   CA R/V   │BUF│   CD R/V
 *   │ │ 1 │  ┌────┐    │ 2 │   ┌────┐
 *   │ │   ├─►│ CA ├─┬─►│   ├──►│ CD ├──►
 *   │ └───┘  └────┘ │  └───┘   └────┘
 *   │ ┌──────┐      │
 *   └►│ SRAM ├──────┘
 *     └──────┘
 * NB: CD drives a stall signal to BUF1 to prevent write hazards
 */

`ifdef VERILATOR_LINT
    `default_nettype none
`endif

module cache_ctrl_pipeline #(
    // TODO: Specify parameter constraints
    parameter ADDR_WIDTH            = 32,
    parameter CLINE_SIZE_WORD       = 4,  // Cache line size in words
    parameter CLINE_ADDR_WIDTH      = 7,  // Num. bits to address 1 word
    parameter CLINE_WORD_WIDTH      = 32, // Cache line word size (bits)
    parameter TAG_SRAM_DATA_WIDTH   = 32,
    parameter NUM_WAYS              = 4,
    parameter WMASK_WIDTH           = 4
) (
    clk, reset,
    //
    b1_us_vld_i, b1_us_rdy_o,
    b1_us_addr_i, b1_us_web_i, b1_us_wmask_i, b1_us_wdat_i,
    b1_us_cache_addr_o, b1_us_tag_addr_o,
    //
    b1_ds_data_i, b1_ds_tag_i,
    //
    dvld_o, drdy_i, hit_o, ddat_o, addr_o,
    cache_web_o, wmask_o, wdat_o, we_o
);
    localparam DATA_WIDTH = CLINE_WORD_WIDTH;
    localparam CLINE_OFFSET = $clog2(CLINE_SIZE_WORD);
    localparam CACHE_ADDR_WIDTH = CLINE_ADDR_WIDTH + CLINE_OFFSET;

    ////////////////////////////////////////////////////////////////////////////

    input wire clk;
    input wire reset;

    // Stage 1 buffer us
    input   wire                        b1_us_vld_i;
    output  wire                        b1_us_rdy_o;
    input   wire[ADDR_WIDTH-1:0]        b1_us_addr_i;
    input   wire                        b1_us_web_i;
    input   wire[WMASK_WIDTH-1:0]       b1_us_wmask_i;
    input   wire[DATA_WIDTH-1:0]        b1_us_wdat_i;
    output  wire[CACHE_ADDR_WIDTH-1:0]  b1_us_cache_addr_o;
    output  wire[CLINE_ADDR_WIDTH-1:0]  b1_us_tag_addr_o;

    // Stage 1 buffer ds
    input  wire[DATA_WIDTH*NUM_WAYS-1:0] b1_ds_data_i;
    input  wire[TAG_SRAM_DATA_WIDTH*NUM_WAYS-1:0] b1_ds_tag_i;

    // Output
    output  wire dvld_o;
    input   wire drdy_i;
    output  wire hit_o;
    output  wire we_o;
    output  wire[DATA_WIDTH-1:0]        ddat_o;
    output  wire[ADDR_WIDTH-1:0]        addr_o;
    output  wire[DATA_WIDTH-1:0]        wdat_o;
    output  wire[NUM_WAYS-1:0]          cache_web_o;
    output  wire[WMASK_WIDTH-1:0]       wmask_o;

    ////////////////////////////////////////////////////////////////////////////

    assign b1_us_cache_addr_o = b1_us_addr_i[0+:CACHE_ADDR_WIDTH];
    assign b1_us_tag_addr_o = b1_us_addr_i[CLINE_OFFSET+:CLINE_ADDR_WIDTH];

    typedef struct packed {
        logic we;
        logic[ADDR_WIDTH-1:0] addr;
        logic[TAG_SRAM_DATA_WIDTH*NUM_WAYS-1:0] tag;
        logic[DATA_WIDTH*NUM_WAYS-1:0] data;
        logic[WMASK_WIDTH-1:0] wmask;
        logic[DATA_WIDTH-1:0] wdata;
    } ca_pkt;

    ca_pkt b1_ds, b2_ds;
    logic s1vld, s1rdy, wstall;

    prim_skidbuf #(
        .WIDTH($bits({
            b1_us_addr_i, b1_us_web_i, b1_us_wmask_i, b1_us_wdat_i
        }))
    ) B1 (
        .clk, .reset,
        //
        .urdy_o(b1_us_rdy_o),
        .uvld_i(b1_us_vld_i),
        .udat_i({~b1_us_web_i, b1_us_addr_i, b1_us_wmask_i, b1_us_wdat_i}),
        //
        .drdy_i(s1rdy),
        .dvld_o(s1vld),
        .ddat_o({ b1_ds.we, b1_ds.addr, b1_ds.wmask, b1_ds.wdata })
    );
    assign b1_ds.tag = b1_ds_tag_i;
    assign b1_ds.data = b1_ds_data_i;

    ////////////////////////////////////////////////////////////////////////////
    
    logic[3:0] way_miss;

    prim_fifo2 #(
        .WIDTH($bits(b1_ds))
    ) B2 (
        .clk, .reset,
        //
        .urdy_o(s1rdy),
        .uvld_i(s1vld),
        .udat_i(b1_ds),
        //
        .drdy_i(drdy_i),
        .dvld_o(dvld_o),
        .ddat_o(b2_ds),
        //
        .inner_vld_o(),
        .inner_dat_o()
    );

    cache_tag_waysel #(
        .NUM_WAYS(NUM_WAYS),
        .ADDR_WIDTH(ADDR_WIDTH), 
        .DATA_WIDTH(DATA_WIDTH),
        .CLINE_SIZE_WORD(CLINE_SIZE_WORD),
        .CLINE_ADDR_WIDTH(CLINE_ADDR_WIDTH),
        .TAG_SRAM_DATA_WIDTH(TAG_SRAM_DATA_WIDTH)
    ) CD (
        .addr_i(b2_ds.addr),
        .tagways_i(b2_ds.tag),
        .dataways_i(b2_ds.data),
        .data_o(ddat_o),
        .hit_o(hit_o),
        .way_miss_o(way_miss)
    );

    logic b3_buf_we, b4_buf_we;
    always @(posedge clk)
    if(reset) begin
        b3_buf_we <= 0;
        b4_buf_we <= 0;
    end else begin
        b3_buf_we <= dvld_o & b2_ds.we;
        b4_buf_we <= b3_buf_we;
    end

    assign we_o = b2_ds.we & dvld_o;
    assign wmask_o = b2_ds.wmask;
    assign wdat_o = b2_ds.wdata;
    assign cache_web_o = way_miss | {4{ ~b2_ds.we }};
    assign addr_o = b2_ds.addr;
    assign wstall = dvld_o & b2_ds.we | b3_buf_we | b4_buf_we;
    
endmodule