module top();
    parameter RSTCYCLES = 1;

    logic clk, reset, reset_gate;
    initial reset_gate = 1;
    power_on_reset #(10, RSTCYCLES) por (.clk, .reset, .reset_gate);

    logic urdy, uvld, drdy, dvld;
    initial drdy = 1;
    initial uvld = 0;

    logic scan_enb;
    logic[8:0] scan_addr;
    logic[31:0] scan_data;
    logic[3:0] scan_web_tag, scan_web_cache;
    initial scan_enb = 1'b1;
    initial scan_web_tag = 4'b1111;
    initial scan_web_cache = 4'b1111;

    logic[31:0] req_addr, resp_data;
    initial req_addr = 0;

    cache_ctrl dut (
        .clk, .reset,

        .p0_uvld_i(uvld),
        .p0_urdy_o(urdy),
        .p0_addr_i(req_addr),
        .p0_web_i(1'b1),
        .p0_wmask_i(4'b1111),

        .p0_dvld_o(dvld),
        .p0_drdy_i(drdy),
        .p0_ddat_o(resp_data),

        .scan_enb_i(scan_enb),
        .scan_addr_i(scan_addr),
        .scan_data_i(scan_data),
        .scan_web_tag_i(scan_web_tag),
        .scan_web_cache_i(scan_web_cache)
    );

    ////////////////////////////////////////////////////////////////////////////

    event EventUpstreamReady;
    always @(posedge clk)
    if(!reset && urdy) -> EventUpstreamReady;

    event EventDownstreamBeat;
    always @(posedge clk)
    if(!reset && drdy && dvld) begin
        -> EventDownstreamBeat;
        $display($time, " TOP read: 0x%X", resp_data);
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
            scan_data <= { 1'b1, 8'b0, addr[31:9] };
            scan_web_cache <= 4'b1111;
            scan_web_tag <= mask;
        end
        repeat (2) @(posedge clk) scan_enb <= 1;
        // Repeat twice to allow sram writes, this gives us better logs :)
    endtask

    task read_addr (input [ 31:0] addr);
        @(EventUpstreamReady) begin
            uvld <= 1;
            req_addr <= addr;
            $display($time, " TOP read_addr at %X", addr);
        end
    endtask
endmodule
