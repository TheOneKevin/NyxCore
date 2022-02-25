module power_on_reset(clk, reset, reset_gate);
    input  logic reset_gate;
    output logic clk;
    output logic reset;
    parameter clkperiod = 10;
    parameter rstcycles = 1;
    // Clock logic
    initial clk = 1;
    initial reset = 1;
    always #(clkperiod/2) clk = ~clk;
    generate
        reg[$clog2(rstcycles):0] counter = 0;
        always @(posedge clk)
        if(counter == rstcycles - 1 && !reset_gate) begin
            reset <= 0;
        end else begin
            reset <= 1;
            if(!reset_gate)
                counter <= counter + 1;
        end
    endgenerate
endmodule
