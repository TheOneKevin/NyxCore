// Temporary file

module cache_ctrl_top (
    input wire clk,
    input wire reset,
    //
    input   wire        p0_uvld_i,
    output  wire        p0_urdy_o,
    input   wire[29:0]  p0_addr_i,
    input   wire        p0_web_i,
    input   wire[31:0]  p0_wdat_i,
    input   wire[3:0]   p0_wmask_i,
    //
    output  wire        p0_dvld_o,
    input   wire        p0_drdy_i,
    output  wire[31:0]  p0_ddat_o,
    //
    input   wire        p0_fsm_ack_i,
    //
    input   wire        scan_clk_i,
    input   wire        scan_enb_i,
    input   wire[ 8:0]  scan_addr_i,
    input   wire[31:0]  scan_data_i,
    input   wire[ 3:0]  scan_web_tag_i,
    input   wire[ 3:0]  scan_web_cache_i,
    input   wire        scan_web_meta_i,
    //
    input   wire        phy_req_i
);
    localparam NUM_WAYS = 4;
    localparam USE_SCAN_CLK = 0;

    ////////////////////////////////////////////////////////////////////////////

    logic[6:0]              p0_tag_addr;
    logic[22*NUM_WAYS-1:0]  p0_tag_rdat;
    logic[21:0]             p0_tag_wdat;
    logic[NUM_WAYS-1:0]     p0_tag_web;
    logic[NUM_WAYS-1:0]     meta_wmask;
    logic                   meta_web;
    logic[31:0]             meta_rdat;
    logic[31:0]             meta_wdat;

    assign p0_tag_web = 4'b1111;
    assign p0_tag_wdat = 0;

    logic[8:0]              p0_cache_addr;
    logic[32*NUM_WAYS-1:0]  p0_cache_rdat;
    logic[3:0]              p0_cache_wmask;
    logic[31:0]             p0_cache_wdat;
    logic[NUM_WAYS-1:0]     p0_cache_web;

    cache_ctrl #(
        .ADDR_WIDTH(30)
    ) cache (
        .*
    );

    ////////////////////////////////////////////////////////////////////////////

    logic scan_clk;
    assign scan_clk = clk;

    typedef struct packed {
        logic[7:0] addr;
        logic[32*NUM_WAYS-1:0] rdat;
        logic[3:0] wmask;
        logic[31:0] wdat;
        logic[NUM_WAYS-1:0] web;
    } tag_sram_rw;

    typedef struct packed {
        logic[8:0] addr;
        logic[32*NUM_WAYS-1:0] rdat;
        logic[3:0] wmask;
        logic[31:0] wdat;
        logic[NUM_WAYS-1:0] web;
    } cache_sram_rw;

    tag_sram_rw     p0_tag_sram;
    cache_sram_rw   p0_cache_sram;

    logic[7:0]  meta_sram_addr;
    logic[31:0] meta_sram_rdat, meta_sram_wdat;
    logic[3:0]  meta_sram_wmask;
    logic       meta_sram_web;
    
    always @(*) begin
        if(scan_enb_i) begin
            p0_tag_sram.addr    = { 1'b0, p0_tag_addr };
            p0_tag_sram.wdat    = { p0_tag_wdat[21], 10'b0, p0_tag_wdat[20:0] };
            p0_tag_sram.web     = p0_tag_web;
            p0_tag_sram.wmask   = 4'b1111;

            p0_cache_sram.addr  = p0_cache_addr;
            p0_cache_sram.wdat  = p0_cache_wdat;
            p0_cache_sram.web   = p0_cache_web;
            p0_cache_sram.wmask = p0_cache_wmask;

            meta_sram_addr      = { 1'b0, p0_tag_addr };
            meta_sram_wdat      = meta_wdat;
            meta_sram_wmask     = meta_wmask;
            meta_sram_web       = meta_web;
        end else begin
            p0_tag_sram.addr    = scan_addr_i[7:0];
            p0_tag_sram.wdat    = scan_data_i;
            p0_tag_sram.web     = scan_web_tag_i;
            p0_tag_sram.wmask   = 4'b1111;

            p0_cache_sram.addr  = scan_addr_i;
            p0_cache_sram.wdat  = scan_data_i;
            p0_cache_sram.web   = scan_web_cache_i;
            p0_cache_sram.wmask = 4'b1111;

            meta_sram_addr      = scan_addr_i[7:0];
            meta_sram_wdat      = scan_data_i;
            meta_sram_wmask     = 4'b1111;
            meta_sram_web       = scan_web_meta_i;
        end
    end
    
    genvar i;
    generate
        for(i = 0; i < NUM_WAYS; i++) begin
            always @(*)
            p0_tag_rdat[22*i+:22] = {
                p0_tag_sram.rdat[i*32+31+:1],
                p0_tag_sram.rdat[i*32+:21]
            };
        end
        assign p0_cache_rdat = p0_cache_sram.rdat;
        assign meta_rdat = meta_sram_rdat;
    endgenerate

    generate
        for(i = 0; i < NUM_WAYS; i++) begin: gen_sram
            // verilator lint_off PINCONNECTEMPTY
            sky130_sram_1kbyte_1rw1r_32x256_8 #(
                .VERBOSE(0), .T_HOLD(0)
            ) tag_sram (
                // Port 0: RW
                .clk0   (USE_SCAN_CLK ? scan_clk : clk),
                .csb0   (1'b0),
                .web0   (p0_tag_sram.web[i]),
                .wmask0 (p0_tag_sram.wmask),
                .addr0  (p0_tag_sram.addr),
                .din0   (p0_tag_sram.wdat),
                .dout0  (p0_tag_sram.rdat[32*i+:32]),
                // Port 1: R
                .clk1(clk),
                .csb1(1'b0),
                .addr1(),
                .dout1()
            );
            sky130_sram_2kbyte_1rw1r_32x512_8 #(
                .VERBOSE(0), .T_HOLD(0)
            ) cache_sram (
                // Port 0: RW
                .clk0   (USE_SCAN_CLK ? scan_clk : clk),
                .csb0   (1'b0),
                .web0   (p0_cache_sram.web[i]),
                .wmask0 (p0_cache_sram.wmask),
                .addr0  (p0_cache_sram.addr),
                .din0   (p0_cache_sram.wdat),
                .dout0  (p0_cache_sram.rdat[32*i+:32]),
                // Port 1: R
                .clk1(clk),
                .csb1(1'b0),
                .addr1(),
                .dout1()
            );
            // verilator lint_on PINCONNECTEMPTY
        end
        // verilator lint_off UNUSED
        wire unused;
        // verilator lint_on UNUSED
        sky130_sram_1kbyte_1rw_32x256_8 #(
            .VERBOSE(0), .T_HOLD(0), .ADDR_WIDTH(8)
        ) meta_sram (
            // Port 0: RW
            .clk0   (USE_SCAN_CLK ? scan_clk : clk),
            .csb0   (1'b0),
            .web0   (meta_sram_web),
            .wmask0 (meta_sram_wmask),
            .addr0  (meta_sram_addr),
            .din0   ({ 1'b0, meta_sram_wdat }),
            .dout0  ({ unused, meta_sram_rdat }),
            .spare_wen0(1'b0)
        );
    endgenerate
endmodule
