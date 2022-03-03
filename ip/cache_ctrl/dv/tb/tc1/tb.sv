`ifdef VERILATOR_LINT
    `default_nettype none
    `define CACHE_CTRL_TB
`endif

module tb();
    parameter simcycles = 100;
    parameter rstcycles = 1;

    top #(rstcycles) u();
    tb_monitor #(.SIMCYCLES(simcycles), .TEST_ID(1)) m(u.clk);

    initial begin
        $dumpfile({ "dump.fst" });
    	$dumpvars(0, u);
    end

    always @(u.EventDownstreamBeat) m.doevent();

    ////////////////////////////////////////////////////////////////////////////
    
    integer i;
    initial begin
        // Write to cacheline, fill all 4 ways
        u.fill_cacheline(
            32'h0FF001F0,
            { 32'h00FF00FF, 32'h00FFFF00, 32'hF0F0F0F0, 32'hFF0000FF },
            4'b1101
        );
        u.fill_cacheline(
            32'h0AA001F0,
            { 32'hEEFFEEFF, 32'h00000000, 32'hAAAAAAAA, 32'h11111111 },
            4'b1110
        );
        u.fill_cacheline(
            32'h0BB001F0,
            { 32'h00000000, 32'hAAAAAAAA, 32'hBBBBBBBB, 32'h33333333 },
            4'b1011
        );
        u.fill_cacheline(
            32'h000001F0,
            { 32'h11111111, 32'hF0F0F0F0, 32'h10000001, 32'h11110000 },
            4'b0111
        );
        // Ungate reset
        @(posedge u.clk) u.reset_gate <= 0;
        $display("Reset ungated");
    end

    initial begin
        // Read from cache line
        for(i = 0; i < 4; i++) begin
            u.q.push_back(lib::get_read_pkt(32'h0FF001F0 + i));
            u.q.push_back(lib::get_read_pkt(32'h0AA001F0 + i));
            u.q.push_back(lib::get_read_pkt(32'h0BB001F0 + i));
            u.q.push_back(lib::get_read_pkt(32'h000001F0 + i));
        end
        u.q.push_back(lib::get_null_pkt(0));
    end

    initial begin
        @(u.EventDownstreamBeat) m.check(u.resp_data == 32'hFF0000FF);
        @(u.EventDownstreamBeat) m.check(u.resp_data == 32'h11111111);
        @(u.EventDownstreamBeat) m.check(u.resp_data == 32'h33333333);
        @(u.EventDownstreamBeat) m.check(u.resp_data == 32'h11110000);
        @(u.EventDownstreamBeat) m.check(u.resp_data == 32'hF0F0F0F0);
        @(u.EventDownstreamBeat) m.check(u.resp_data == 32'hAAAAAAAA);
        @(u.EventDownstreamBeat) m.check(u.resp_data == 32'hBBBBBBBB);
        @(u.EventDownstreamBeat) m.check(u.resp_data == 32'h10000001);
        @(u.EventDownstreamBeat) m.check(u.resp_data == 32'h00FFFF00);
        @(u.EventDownstreamBeat) m.check(u.resp_data == 32'h00000000);
        @(u.EventDownstreamBeat) m.check(u.resp_data == 32'hAAAAAAAA);
        @(u.EventDownstreamBeat) m.check(u.resp_data == 32'hF0F0F0F0);
        @(u.EventDownstreamBeat) m.check(u.resp_data == 32'h00FF00FF);
        @(u.EventDownstreamBeat) m.check(u.resp_data == 32'hEEFFEEFF);
        @(u.EventDownstreamBeat) m.check(u.resp_data == 32'h00000000);
        @(u.EventDownstreamBeat) m.check(u.resp_data == 32'h11111111);
        @(posedge u.clk);
        m.endsim();
    end
endmodule
