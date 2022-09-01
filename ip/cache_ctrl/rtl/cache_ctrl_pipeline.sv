`ifdef VERILATOR_LINT
    `default_nettype none
`endif

module cache_ctrl_pipeline #(
    // TODO: Specify parameter constraints
    parameter ADDR_WIDTH        = 32,
    parameter CLINE_SIZE_WORD   = 4,  // Cache line size in words
    parameter CLINE_ADDR_WIDTH  = 7,  // Num. bits to address 1 word
    parameter CLINE_WORD_WIDTH  = 32, // Cache line word size (bits)
    parameter NUM_WAYS          = 4,  // Number of cache ways
    parameter WMASK_WIDTH       = 4   // Number of bytes in 1 word
) (
    clk, reset,
    //
    b1_us_vld_i, b1_us_rdy_o,
    b1_us_addr_i, b1_us_web_i, b1_us_wmask_i, b1_us_wdat_i,
    b1_us_cache_addr_o, b1_us_tag_addr_o,
    //
    b1_ds_data_i, b1_ds_tag_i, b1_ds_meta_i,
    //
    dvld_o, drdy_i, hit_o, ddat_o, addr_o,
    cache_web_o, wmask_o, wdat_o, we_o, tag_o, meta_o,
    //
    phy_req_i
);
    localparam dataWidth    = CLINE_WORD_WIDTH;
    localparam clineOffset  = $clog2(CLINE_SIZE_WORD);
    localparam caWidth      = CLINE_ADDR_WIDTH + clineOffset;
    localparam tagWidth     = ADDR_WIDTH - caWidth + 1;
    localparam metaWidth    = 8;

    ////////////////////////////////////////////////////////////////////////////

    input wire clk;
    input wire reset;

    // Stage 1 buffer us
    input   wire                        b1_us_vld_i;
    output  wire                        b1_us_rdy_o;
    input   wire[ADDR_WIDTH-1:0]        b1_us_addr_i;
    input   wire                        b1_us_web_i;
    input   wire[WMASK_WIDTH-1:0]       b1_us_wmask_i;
    input   wire[dataWidth-1:0]         b1_us_wdat_i;
    output  wire[caWidth-1:0]           b1_us_cache_addr_o;
    output  wire[CLINE_ADDR_WIDTH-1:0]  b1_us_tag_addr_o;

    // Stage 1 buffer ds
    input  wire[dataWidth*NUM_WAYS-1:0] b1_ds_data_i;
    input  wire[tagWidth*NUM_WAYS-1:0]  b1_ds_tag_i;
    input  wire[metaWidth*NUM_WAYS-1:0] b1_ds_meta_i;

    // Output
    output  wire                        dvld_o;
    input   wire                        drdy_i;
    output  wire                        hit_o;
    output  wire                        we_o;
    output  wire[dataWidth-1:0]         ddat_o;
    output  wire[ADDR_WIDTH-1:0]        addr_o;
    output  wire[dataWidth-1:0]         wdat_o;
    output  wire[NUM_WAYS-1:0]          cache_web_o;
    output  wire[WMASK_WIDTH-1:0]       wmask_o;
    output  wire[tagWidth-1:0]          tag_o;
    output  reg[metaWidth*NUM_WAYS-1:0] meta_o;

    // PHY request override
    input wire phy_req_i;

    ////////////////////////////////////////////////////////////////////////////

    assign b1_us_cache_addr_o = b1_us_addr_i[0+:caWidth];
    assign b1_us_tag_addr_o = b1_us_addr_i[clineOffset+:CLINE_ADDR_WIDTH];

    typedef struct packed {
        logic we;
        logic[ADDR_WIDTH-1:0] addr;
        logic[tagWidth*NUM_WAYS-1:0] tag;
        logic[dataWidth*NUM_WAYS-1:0] data;
        logic[WMASK_WIDTH-1:0] wmask;
        logic[dataWidth-1:0] wdata;
        logic[metaWidth*NUM_WAYS-1:0] meta;
    } ca_pkt;
    
    ca_pkt b1_ds, b2_ds;
    logic wstall;
    logic b1uvld, b1urdy, b1dvld, b1drdy;
    logic b2uvld, b2urdy, b2dvld, b2drdy;

    logic b2mvld;
    ca_pkt b2mdat;

    prim_stall b1_ustall (
        .stall_i(wstall),
        .urdy_o(b1_us_rdy_o),
        .uvld_i(b1_us_vld_i),
        .drdy_i(b1urdy),
        .dvld_o(b1uvld)
    );

    prim_skidbuf #(
        .WIDTH($bits({
            b1_us_addr_i, b1_us_web_i, b1_us_wmask_i, b1_us_wdat_i
        }))
    ) B1 (
        .clk, .reset,
        //
        .urdy_o(b1urdy),
        .uvld_i(b1uvld),
        .udat_i({~b1_us_web_i, b1_us_addr_i, b1_us_wmask_i, b1_us_wdat_i}),
        //
        .drdy_i(b1drdy),
        .dvld_o(b1dvld),
        .ddat_o({ b1_ds.we, b1_ds.addr, b1_ds.wmask, b1_ds.wdata })
    );
    assign b1_ds.tag = b1_ds_tag_i;
    assign b1_ds.data = b1_ds_data_i;
    assign b1_ds.meta = b1_ds_meta_i;
    
    prim_stall b1_dstall (
        .stall_i(phy_req_i),
        .urdy_o(b1drdy),
        .uvld_i(b1dvld),
        .drdy_i(b2urdy),
        .dvld_o(b2uvld)
    );

    ////////////////////////////////////////////////////////////////////////////
    
    logic[NUM_WAYS-1:0] way_miss, way_hit;
    assign way_miss = ~way_hit;

    prim_fifo2 #(
        .WIDTH($bits(b1_ds))
    ) B2 (
        .clk, .reset,
        //
        .urdy_o(b2urdy),
        .uvld_i(b2uvld),
        .udat_i(b1_ds),
        //
        .drdy_i(b2drdy),
        .dvld_o(b2dvld),
        .ddat_o(b2_ds),
        //
        .inner_vld_o(b2mvld),
        .inner_dat_o(b2mdat)
    );

    cache_tag_waysel #(
        .NUM_WAYS(NUM_WAYS),
        .ADDR_WIDTH(ADDR_WIDTH), 
        .DATA_WIDTH(dataWidth),
        .CLINE_SIZE_WORD(CLINE_SIZE_WORD),
        .CLINE_ADDR_WIDTH(CLINE_ADDR_WIDTH)
    ) CD (
        .addr_i(b2_ds.addr),
        .tagways_i(b2_ds.tag),
        .dataways_i(b2_ds.data),
        .data_o(ddat_o),
        .hit_o(hit_o),
        .way_hit_o(way_hit)
    );

    prim_stall b2_dstall (
        .stall_i(1'b0),
        .urdy_o(b2drdy),
        .uvld_i(b2dvld),
        .drdy_i(drdy_i),
        .dvld_o(dvld_o)
    );

    assign we_o = b2_ds.we;
    assign wmask_o = b2_ds.wmask;
    assign wdat_o = b2_ds.wdata;
    assign cache_web_o = way_miss | {4{ ~b2_ds.we }};
    assign addr_o = b2_ds.addr;

    // TODO: Revise metadata generation and LRU algorithm
    generate
        genvar i;
        for(i = 0; i < NUM_WAYS; i++) begin: gen_meta
            always @(*)
            meta_o[metaWidth*i+:metaWidth] =
                b2_ds.meta[metaWidth*i+:metaWidth]
            |   { 7'b0, way_hit[i] };
        end
    endgenerate

    // Output hit tag
    logic[tagWidth-1:0] current_tag;
    prim_muxonehot #(
        .DATA_COUNT(NUM_WAYS),
        .DATA_WIDTH(tagWidth),
        .OPERATION("OR")
    ) tagmux (
        .mask_i(way_hit),
        .data_i(b2_ds.tag),
        .data_o(current_tag)
    );
    assign tag_o = { we_o, current_tag[tagWidth-2:0] };
    
    // Stall when:
    // (b1_us is NOT write) AND (there are in-flight write(s) downstream)
    assign wstall =
        b1_us_web_i & (
            b1dvld & b1_ds.we |
            b2mvld & b2mdat.we |
            b2dvld & b2_ds.we
        );
    
endmodule
