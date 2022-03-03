`ifdef VERILATOR_LINT
    `default_nettype none
    `define CACHE_CTRL_TB
`endif

module tb();
    parameter simcycles = 50;
    parameter rstcycles = 1;

    top #(rstcycles) u();
    tb_monitor #(.SIMCYCLES(simcycles), .TEST_ID(2)) m(u.clk);

    initial begin
        $dumpfile({ "dump.fst" });
    	$dumpvars(0, u);
    end

    always @(u.EventDownstreamBeat) m.doevent();

    ////////////////////////////////////////////////////////////////////////////
    
    integer i;
    initial begin
        // Clear cacheline
        u.clear_cacheline(32'h000001F0);
        u.fill_cacheline(
            32'h0AA001F0,
            { 32'h00FF00FF, 32'h00FFFF00, 32'hF0F0F0F0, 32'hFF0000FF },
            4'b1011
        );
        // Ungate reset
        @(posedge u.clk) u.reset_gate <= 0;
        $display("Reset ungated");
    end
    initial begin
        // Read from cache line
        u.q.push_back(lib::get_read_pkt(32'h011001F0));
        u.q.push_back(lib::get_read_pkt(32'h022001F0));
        u.q.push_back(lib::get_read_pkt(32'h0AA001F0)); // Hit
        u.q.push_back(lib::get_read_pkt(32'h033001F0));
        u.q.push_back(lib::get_read_pkt(32'h044001F0));
        u.q.push_back(lib::get_read_pkt(32'h055001F0));
        u.q.push_back(lib::get_read_pkt(32'h066001F0));
        u.q.push_back(lib::get_null_pkt(0));
    end

    initial begin
        @(u.EventDownstreamBeat) m.check(u.resp_data == 32'hFF0000FF);
        @(posedge u.clk);
        m.endsim();
    end
endmodule
