module monitor(input logic clk);
    parameter SIMCYCLES = 0;
    parameter TEST_ID = 0;

    integer events, covered;
    byte mm = 8'd27;
    initial events = 0;
    initial covered = 0;

    // Monitor and logging
    logic finish = 0;
    initial begin
        repeat (SIMCYCLES) @(posedge clk);
        $display("=== SIMULATION COMPLETE ===");
        $display("Event coverage %0d/%0d", covered, events);
        if(events == 0) begin
            $warning("%c[1;33mNo event coverage (no events registered)%c[0m", mm, mm);
            $finish(0);
        end else if(covered != events) begin
            $warning("%c[1;33mThere are uncovered events (or too many covered)%c[0m", mm, mm);
            $finish(0);
        end else if(finish != 1) begin
            $error("%c[1;31mReached the end of sim without calling endsim()%c[0m", mm, mm);
            $fatal;
        end else begin
            $display("%c[1;32mTest %0d: Passed all cases%c[0m", mm, TEST_ID, mm);
    		$finish(0);
        end
    end

    // Regular asssert but with return
    function void checkv(input x, string y = "");
        assert(x) else begin
            if(y.len() == 0) begin
                $error("%c[1;31mAssertation failed in %m %c[0m", mm, mm);
            end else begin
                $error("%c[1;31mAssertation failed in %m: %s %c[0m", mm, y, mm);
            end
            $fatal;
        end
    endfunction

    // Call to register an event
    function void doevent();
        checkv(finish != 1, "Uncovered event!");
        events = events + 1;
    endfunction

    // Behaves like checkv, but with event coverage
    function void check(input x, string y = "");
        checkv(x, y);
        covered = covered + 1;
    endfunction

    // Marks the end of simulation
    function void endsim();
        finish = 1;
    endfunction
endmodule
