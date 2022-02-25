`ifdef VERILATOR_LINT
    `include "../top.sv"
`endif

module tb();
    parameter simcycles = 50;
    parameter rstcycles = 1;

    top #(rstcycles) u();
    monitor #(.SIMCYCLES(simcycles), .TEST_ID(2)) m(u.clk);

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
        // Read from cache line
        u.read_addr(32'h011001F0);
        u.read_addr(32'h022001F0);
        u.read_addr(32'h0AA001F0); // Hit
        u.read_addr(32'h0EE001F0);
        u.read_addr(32'h0FF001F0);
        @(u.EventUpstreamReady) u.uvld <= 0;
    end

    initial begin
        @(u.EventDownstreamBeat) m.check(u.resp_data == 32'hFF0000FF);
        @(posedge u.clk);
        m.endsim();
    end
endmodule
