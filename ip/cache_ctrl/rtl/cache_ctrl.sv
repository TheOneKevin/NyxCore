`ifdef VERILATOR_LINT
    `default_nettype none
`endif

module cache_ctrl #(
    parameter ADDR_WIDTH        = 32,
    parameter CLINE_SIZE_WORD   = 4,  // Cache line size in words
    parameter CLINE_ADDR_WIDTH  = 7,  // Num. bits to address 1 word
    parameter CLINE_WORD_WIDTH  = 32, // Cache line word size (bits)
    parameter NUM_WAYS          = 4,  // Number of cache ways
    parameter WMASK_WIDTH       = 4   // Number of bytes in 1 word
) (
    clk,
    reset,
    // Upstream Port 0
    p0_uvld_i, p0_urdy_o,
    p0_addr_i,
    p0_web_i,
    p0_wdat_i,
    p0_wmask_i,
    // Downstream Port 0
    p0_dvld_o, p0_drdy_i,
    p0_ddat_o,
    // Tag/Cache/Meta SRAM Port 0
    p0_tag_addr,
    p0_tag_rdat,
    p0_tag_wdat,
    p0_tag_web,
    p0_cache_addr,
    p0_cache_web,
    p0_cache_wdat,
    p0_cache_wmask,
    p0_cache_rdat,
    meta_rdat,
    meta_wmask,
    meta_web,
    meta_wdat,
    // PHY/MC IF
    phy_vld_o,
    phy_rdy_i,
    phy_cmd_o,
    phy_ack_i
);
    localparam dataWidth = CLINE_WORD_WIDTH;
    localparam clineOffset = $clog2(CLINE_SIZE_WORD);
    localparam caWidth = CLINE_ADDR_WIDTH + clineOffset;
    localparam taWidth = CLINE_ADDR_WIDTH;
    localparam tagWidth = ADDR_WIDTH - caWidth + 1;
    localparam clineWidth = CLINE_SIZE_WORD * CLINE_WORD_WIDTH;
    localparam metaWidth = 8;

    // TODO: Figure out a better way to determine size of this signal
    localparam phycmdWidth = ADDR_WIDTH+NUM_WAYS+1;

    ////////////////////////////////////////////////////////////////////////////

    input   wire clk;
    input   wire reset;
    //
    input   wire                    p0_uvld_i;
    output  wire                    p0_urdy_o;
    input   wire[ADDR_WIDTH-1:0]    p0_addr_i;
    input   wire                    p0_web_i;
    input   wire[dataWidth-1:0]     p0_wdat_i;
    input   wire[WMASK_WIDTH-1:0]   p0_wmask_i;
    //
    output  reg                     p0_dvld_o;
    input   wire                    p0_drdy_i;
    output  reg[dataWidth-1:0]      p0_ddat_o;
    //
    output  wire[taWidth-1:0]       p0_tag_addr;
    output  wire[tagWidth-1:0]      p0_tag_wdat;
    output  wire[NUM_WAYS-1:0]      p0_tag_web;
    input   wire[tagWidth*NUM_WAYS-1:0] p0_tag_rdat;
    input   wire[metaWidth*NUM_WAYS-1:0] meta_rdat;
    output  wire[metaWidth*NUM_WAYS-1:0] meta_wdat;
    output  wire[NUM_WAYS-1:0]      meta_wmask;
    output  wire                    meta_web;
    //
    output  wire[caWidth-1:0]       p0_cache_addr;
    output  wire[NUM_WAYS-1:0]      p0_cache_web;
    output  wire[WMASK_WIDTH-1:0]   p0_cache_wmask;
    output  wire[dataWidth-1:0]     p0_cache_wdat;
    input   wire[clineWidth-1:0]    p0_cache_rdat;
    //
    output  wire                    phy_vld_o;
    input   wire                    phy_rdy_i;
    output  wire[phycmdWidth-1:0]   phy_cmd_o;
    input   wire                    phy_ack_i;

    ////////////////////////////////////////////////////////////////////////////

    logic[taWidth-1:0]      dpipe_tag_sram_addr;
    
    logic[caWidth-1:0]      dpipe_cache_sram_addr;
    logic[dataWidth-1:0]    dpipe_cache_sram_wdat;
    logic[NUM_WAYS-1:0]     dpipe_cache_sram_web;
    logic[WMASK_WIDTH-1:0]  dpipe_cache_sram_wmask;
    logic[tagWidth-1:0]     dpipe_cache_tag_wdat;

    logic[caWidth-1:0]      dpipe_cache_read_addr;
    logic[dataWidth-1:0]    dpipe_ddat;
    logic[ADDR_WIDTH-1:0]   dpipe_daddr;
    logic dpipe_dvld, dpipe_drdy, dpipe_hit, dpipe_we, dpipe_we_invalid;

    logic[dataWidth-1:0] dpipe_fsm_ddat;
    logic dpipe_fsm_dvld, dpipe_fsm_drdy, dpipe_fsm_scan;

    ////////////////////////////////////////////////////////////////////////////
    
    // TODO: Change tiedowns when FSM is designed
    
    assign p0_tag_addr      = dpipe_tag_sram_addr;
    assign p0_tag_wdat      = dpipe_cache_tag_wdat;
    assign p0_tag_web       = dpipe_cache_sram_web;
    assign p0_cache_addr    = dpipe_cache_sram_addr;
    assign p0_cache_wdat    = dpipe_cache_sram_wdat;
    assign p0_cache_web     = dpipe_cache_sram_web | {4{!dpipe_dvld}};
    assign p0_cache_wmask   = dpipe_cache_sram_wmask;
    assign meta_wmask       = ~p0_cache_web;
    assign meta_web         = ~dpipe_we;

    ////////////////////////////////////////////////////////////////////////////

    cache_ctrl_pipeline #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .CLINE_SIZE_WORD(CLINE_SIZE_WORD),
        .CLINE_ADDR_WIDTH(CLINE_ADDR_WIDTH),
        .CLINE_WORD_WIDTH(CLINE_WORD_WIDTH),
        .NUM_WAYS(NUM_WAYS),
        .WMASK_WIDTH(WMASK_WIDTH)
    ) d_pipeline (
        .clk, .reset,
        //
        .b1_us_vld_i        (p0_uvld_i),
        .b1_us_rdy_o        (p0_urdy_o),
        .b1_us_addr_i       (p0_addr_i),
        .b1_us_web_i        (p0_web_i),
        .b1_us_wmask_i      (p0_wmask_i),
        .b1_us_wdat_i       (p0_wdat_i),
        .b1_us_cache_addr_o (dpipe_cache_read_addr),
        .b1_us_tag_addr_o   (dpipe_tag_sram_addr),
        //
        .b1_ds_data_i       (p0_cache_rdat),
        .b1_ds_tag_i        (p0_tag_rdat),
        .b1_ds_meta_i       (meta_rdat),
        //
        .dvld_o             (dpipe_dvld),
        .hit_o              (dpipe_hit),
        .drdy_i             (dpipe_drdy & p0_drdy_i),
        .ddat_o             (dpipe_ddat),
        .addr_o             (dpipe_daddr),
        .we_o               (dpipe_we_invalid),
        .cache_web_o        (dpipe_cache_sram_web),
        .wmask_o            (dpipe_cache_sram_wmask),
        .wdat_o             (dpipe_cache_sram_wdat),
        .tag_o              (dpipe_cache_tag_wdat),
        .meta_o             (meta_wdat),
        //
        .phy_req_i(dpipe_fsm_scan)
    );

    assign dpipe_we = dpipe_we_invalid & dpipe_dvld;

    always @(*) begin: cmb_dpipe_we_mux
        if(dpipe_we) dpipe_cache_sram_addr = dpipe_daddr[8:0];
        else         dpipe_cache_sram_addr = dpipe_cache_read_addr;
    end

    always @(*) begin: cmb_dpipe_fsm_mux
        if(dpipe_fsm_scan) begin
            p0_dvld_o       = dpipe_fsm_dvld;
            p0_ddat_o       = dpipe_fsm_ddat;
            dpipe_fsm_drdy  = p0_drdy_i;
        end else begin
            p0_dvld_o       = dpipe_hit & dpipe_dvld & !dpipe_we;
            p0_ddat_o       = dpipe_ddat;
            dpipe_fsm_drdy  = 1'b1;
        end
    end

    cache_ctrl_fsm #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(dataWidth),
        .NUM_WAYS(NUM_WAYS)
    ) dpipe_fsm (
        .clk, .reset,
        // DPIPE/FSM IF
        .urdy_o   (dpipe_drdy),
        .uvld_i   (dpipe_dvld),
        .hit_i    (dpipe_hit),
        .we_i     (dpipe_we),
        .flush_i  (1'b0),
        .addr_i   (dpipe_daddr),
        // FSM/P0 DS IF
        .dvld_o   (dpipe_fsm_dvld),
        .drdy_i   (dpipe_fsm_drdy),
        .ddat_o   (dpipe_fsm_ddat),
        // PHY/MC IF
        .ack_i    (phy_ack_i),
        .scan_o   (dpipe_fsm_scan),
        .qvld_o   (phy_vld_o),
        .qrdy_i   (phy_rdy_i),
        .qdat_o   (phy_cmd_o)
    );
    
endmodule
