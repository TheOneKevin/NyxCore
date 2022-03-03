`ifdef VERILATOR_LINT
    `default_nettype none
    `define CACHE_CTRL_TB
`endif

module tb();
    parameter simcycles = 50;
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
        // Clear cacheline
        u.clear_cacheline(32'h000001F0);
        u.fill_cacheline(32'h000001F0, { 128'hF100F }, 4'b1101);
        // Ungate reset
        @(posedge u.clk) u.reset_gate <= 0;
        $display("Reset ungated");
    end

    initial begin
        // 1. Test RAW hazard
        u.q.push_back(lib::get_write_pkt(32'h000001F0, 32'hDEADBEEF));
        u.q.push_back(lib::get_read_pkt(32'h000001F0));
        u.q.push_back(lib::get_write_pkt(32'h000001F1, 32'hCAFEBABE));
        u.q.push_back(lib::get_read_pkt(32'h000001F1));
        // 2. Check write pipeline
        u.q.push_back(lib::get_write_pkt(32'h000001F0, 32'hA));
        u.q.push_back(lib::get_write_pkt(32'h000001F1, 32'hB));
        u.q.push_back(lib::get_read_pkt(32'h000001F0));
        u.q.push_back(lib::get_read_pkt(32'h000001F1));
        
        u.q.push_back(lib::get_null_pkt(0));
    end

    initial begin
        // m.endsim();
    end
endmodule
