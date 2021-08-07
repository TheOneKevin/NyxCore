`ifndef VERILATOR_LINT

function void check(input x, string y = "");
    assert(x) else begin
        if(y.len() == 0) begin
            $error("%c[1;31mAssertation failed in %m %c[0m", 27, 27);
        end else begin
            $error("%c[1;31mAssertation failed in %m: %s %c[0m", 27, y, 27);
        end
        $finish_and_return(1);
    end
endfunction

// Clock logic
reg clk = 1, reset = 0;
always #(clkperiod/2) clk = ~clk;
generate begin : PowerOnReset
    reg[$clog2(rstcycles):0] counter = 0;
    always @(posedge clk)
    if(counter == rstcycles - 1) begin
        reset <= 0;
    end else begin
        reset <= 1;
        counter <= counter + 1;
    end
end
endgenerate

// Monitor and logging
logic finish = 0;
initial begin
    $dumpfile("dump.fst");
	$dumpvars(0, top);
    repeat (simcycles) @(posedge clk);
    if(finish != 1) begin
        $error("%c[1;31mTest failed to complete%c[0m", 27, 27);
        $finish_and_return(1);
    end else begin
        $display("%c[1;32mTest %0d: Passed all cases%c[0m", 27, TEST_ID, 27);
		$finish_and_return(0);
    end
end

`endif