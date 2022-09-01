`ifdef VERILATOR_LINT
    `default_nettype none
`endif
`ifdef CACHE_CTRL_TB

module top();
    parameter RSTCYCLES = 1;
    parameter DATA_COUNT = 1;
    import lib::*;

    logic clk, reset, reset_gate;
    initial reset_gate = 1;
    tb_por #(10, RSTCYCLES) por (.clk, .reset, .reset_gate);

    logic scan_enb;
    logic[8:0] scan_addr;
    logic[31:0] scan_data;
    logic[3:0] scan_web_tag, scan_web_cache;
    logic scan_web_meta;

    initial scan_enb = 1'b1;
    initial scan_web_tag = 4'b1111;
    initial scan_web_cache = 4'b1111;
    initial scan_web_meta = 1'b1;

    logic urdy, uvld, drdy, dvld;
    logic[31:0] resp_data;
    bit[$bits(cache_pkt)-1:0] q[$];
    cache_pkt pkt;

    initial pkt = lib::get_null_pkt(0);
    initial drdy = 1;
    assign uvld = !reset & pkt.valid;

    always @(posedge clk)
    if(!reset && urdy && q.size > 0) begin
        pkt = q.pop_front();
    end

    cache_ctrl_top dut (
        .clk, .reset,

        .p0_uvld_i(uvld),
        .p0_urdy_o(urdy),
        .p0_addr_i(pkt.addr),
        .p0_wdat_i(pkt.wdat),
        .p0_web_i(!pkt.we),
        .p0_wmask_i(4'b1111),

        .p0_dvld_o(dvld),
        .p0_drdy_i(drdy),
        .p0_ddat_o(resp_data),

        .scan_clk_i(clk),
        .scan_enb_i(scan_enb),
        .scan_addr_i(scan_addr),
        .scan_data_i(scan_data),
        .scan_web_tag_i(scan_web_tag),
        .scan_web_cache_i(scan_web_cache),
        .scan_web_meta_i(scan_web_meta),

        // TODO: Connect to real PHY
        .phy_vld_o(),
        .phy_rdy_i(1'b1),
        .phy_cmd_o(),
        .phy_ack_i(1'b1)
    );

    ////////////////////////////////////////////////////////////////////////////

    event EventUpstreamReady;
    always @(posedge clk)
    if(!reset && urdy) -> EventUpstreamReady;

    event EventUpstreamBeat;
    always @(posedge clk)
    if(!reset && urdy && uvld) -> EventUpstreamBeat;

    event EventDownstreamBeat;
    always @(posedge clk)
    if(!reset && drdy && dvld) begin
        -> EventDownstreamBeat;
        $display($time, " TOP read: 0x%X", resp_data);
    end

    event EventCacheMiss;
    always @(posedge clk)
    if(!reset && dut.cache.dpipe_fsm.ubeat && !dut.cache.dpipe_fsm.hit_i) begin
        -> EventCacheMiss;
    end

    task clear_cacheline(input [31:0] addr);
        $display("Invalidating cache line at %X", addr);
        @(posedge clk) begin
            scan_addr <= { 2'b00, addr[8:2] };
            scan_enb <= 0;
            scan_data <= 32'b0;
            scan_web_cache <= 4'b1111;
            scan_web_tag <= 4'b0000;
        end
        repeat (2) @(posedge clk) scan_enb <= 1;
        // Repeat twice to allow sram writes, this gives us better logs :)
    endtask

    task fill_cacheline(
        input [ 31:0] addr,
        input [127:0] data,
        input [  3:0] mask
    );
        reg[1:0] i;
        i = 0;
        $display("Filling cache line at %X", addr);
        repeat(4) @(posedge clk) begin
            scan_enb <= 0;
            scan_addr <= { addr[8:2], i[1:0] };
            scan_data <= data[32*i+:32];
            scan_web_cache <= mask;
            scan_web_tag <= 4'b1111;
            i = i + 1;
        end
        @(posedge clk) begin
            scan_addr <= { 2'b00, addr[8:2] };
            scan_data <= 32'b0;
            scan_web_meta <= 1'b0;
            scan_web_cache <= 4'b1111;
        end
        @(posedge clk) begin
            scan_addr <= { 2'b00, addr[8:2] };
            scan_data <= { 1'b1, 8'b0, addr[31:9] };
            scan_web_tag <= mask;
            scan_web_meta <= 1'b1;
        end
        repeat (2) @(posedge clk) scan_enb <= 1;
        // Repeat twice to allow sram writes, this gives us better logs :)
    endtask
endmodule

`endif
