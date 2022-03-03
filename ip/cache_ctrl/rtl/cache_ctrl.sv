`ifdef VERILATOR_LINT
    `default_nettype none
`endif

module cache_ctrl(
    input   wire clk,
    input   wire reset,
    //
    input   wire        p0_uvld_i,
    output  wire        p0_urdy_o,
    input   wire[31:0]  p0_addr_i,
    input   wire        p0_web_i,
    input   wire[31:0]  p0_wdat_i,
    input   wire[ 3:0]  p0_wmask_i,
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
    input   wire[ 3:0]  scan_web_cache_i
);
    parameter NUM_WAYS = 4;
    parameter USE_SCAN_CLK = 0;

    ////////////////////////////////////////////////////////////////////////////

    wire scan_clk;
    generate
        // TODO: Allow generating clkmux instance
        if(USE_SCAN_CLK) begin
            assign scan_clk = scan_enb_i ? clk : scan_clk_i;
        end
    endgenerate

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

    logic[6:0]  dpipe_tag_sram_addr;
    logic[8:0]  dpipe_cache_sram_addr;
    logic[31:0] dpipe_cache_sram_wdat;
    logic[3:0]  dpipe_cache_sram_web;
    logic[3:0]  dpipe_cache_sram_wmask;
    logic[31:0] dpipe_ddat;
    logic[31:0] dpipe_addr;
    logic dpipe_dvld, dpipe_drdy, dpipe_hit, dpipe_we;

    ////////////////////////////////////////////////////////////////////////////

    tag_sram_rw     p0_tag_sram;
    cache_sram_rw   p0_cache_sram;

    // Scan generation (input MUX)
    // TODO: Change tiedowns when FSM is designed
    always @(*) begin
        if(scan_enb_i) begin
            p0_tag_sram.addr    = { 1'b0, dpipe_tag_sram_addr };
            p0_tag_sram.wdat    = 32'b0;
            p0_tag_sram.web     = 4'b1111;
            p0_tag_sram.wmask   = 4'b1111;

            p0_cache_sram.addr  = dpipe_we ? dpipe_addr[8:0] : dpipe_cache_sram_addr;
            p0_cache_sram.wdat  = dpipe_cache_sram_wdat;
            p0_cache_sram.web   = dpipe_cache_sram_web | {4{!dpipe_dvld}};
            p0_cache_sram.wmask = dpipe_cache_sram_wmask;
        end else begin
            p0_tag_sram.addr    = scan_addr_i[7:0];
            p0_tag_sram.wdat    = scan_data_i;
            p0_tag_sram.web     = scan_web_tag_i;
            p0_tag_sram.wmask   = 4'b1111;

            p0_cache_sram.addr  = scan_addr_i;
            p0_cache_sram.wdat  = scan_data_i;
            p0_cache_sram.web   = scan_web_cache_i;
            p0_cache_sram.wmask = 4'b1111;
        end
    end

    ////////////////////////////////////////////////////////////////////////////

    generate
        // TODO: Allow generation of generic SRAM models
        genvar i;
        for(i = 0; i < NUM_WAYS; i++) begin: gen_tag_sram
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
        end
        for(i = 0; i < NUM_WAYS; i++) begin: gen_cache_sram
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
        end
    endgenerate

    ////////////////////////////////////////////////////////////////////////////

    assign p0_dvld_o = dpipe_hit & dpipe_dvld & !dpipe_we;
    assign p0_ddat_o = dpipe_ddat;
    cache_ctrl_pipeline #(
        
    ) d_pipeline (
        .clk, .reset,
        //
        .b1_us_vld_i    (p0_uvld_i),
        .b1_us_rdy_o    (p0_urdy_o),
        .b1_us_addr_i   (p0_addr_i),
        .b1_us_web_i    (p0_web_i),
        .b1_us_wmask_i  (p0_wmask_i),
        .b1_us_wdat_i   (p0_wdat_i),
        .b1_us_cache_addr_o(dpipe_cache_sram_addr),
        .b1_us_tag_addr_o(dpipe_tag_sram_addr),
        //
        .b1_ds_data_i   (p0_cache_sram.rdat),
        .b1_ds_tag_i    (p0_tag_sram.rdat),
        //
        .dvld_o         (dpipe_dvld),
        .hit_o          (dpipe_hit),
        .drdy_i         (dpipe_drdy & p0_drdy_i),
        .ddat_o         (dpipe_ddat),
        .addr_o         (dpipe_addr),
        .we_o           (dpipe_we),
        .cache_web_o    (dpipe_cache_sram_web),
        .wmask_o        (dpipe_cache_sram_wmask),
        .wdat_o         (dpipe_cache_sram_wdat)
    );

    cache_ctrl_fsm #(

    ) dpipe_fsm (
        .clk, .reset,
        // 
        .urdy_o   (dpipe_drdy),
        .uvld_i   (dpipe_dvld),
        .hit_i    (dpipe_hit),
        .addr_i   (dpipe_addr),
        .ack_i    (p0_fsm_ack_i)
    );
    
endmodule
