`ifdef VERILATOR_LINT
    `include "rtl/hs32_pipeline.sv"
`endif

// verilator lint_off STMTDLY
`timescale 1ns/1ns

module top();
    localparam clkperiod = 10;
    localparam rstcycles = 3;
    localparam simcycles = 20;

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

    // Instruction list
    localparam numinstrs = 4;
    wire[numinstrs*32-1:0] instr = {
        { 32'h0010_0001 },  // mov r1, 1
        { 32'h0020_0002 },  // mov r2, 2
        { 32'h0931_0000 },  // mov r3, r1
        { 32'h3031_2000 }   // add r3, r1 + r2
    };
    /*wire[numinstrs*32-1:0] instr = {
        { 32'h0020_0002 },  // mov r2, 2
        { 32'h0010_0001 },  // mov r1, 1
        { 32'h0040_0004 },  // mov r4, 4
        { 32'h3031_2000 }   // add r3, r1 + r2
    };*/

    // Pipeline input signals
    reg[$clog2(numinstrs+1):0] ip = 0;
    wire ready;

    // Increment instruction pointer
    always @(posedge clk)
    if(reset) begin
        ip <= 0;
    end else if(ready && ip < numinstrs) begin
        ip <= ip + 1;
    end

    // UUT
    hs32_pipeline uut(
        .clk(clk), .reset(reset),
        
        // Shift in instructions from array
        .valid_i(!reset && ip < numinstrs), .ready_o(ready),
        .op_i(ip == numinstrs ? 32'h0 : instr[(numinstrs-ip-1)*32+:32]),

        // TODO: bank select
        .banksel_i(1'b0),

        // Infinite sink
        .valid_o(), .ready_i(1'b1), .data_o()
    );

    // Monitor and logging
    initial begin
        $dumpfile("dump.vcd");
		$dumpvars(0,top);
        repeat (simcycles) @(posedge clk);
		$finish;
    end

    //--========================================================================
    // Pipeline event triggers
    //--========================================================================
    
    generate begin : TriggerOnRegWrite
        wire we1 = uut.regfile.wp1_we1_i;
        wire we2 = uut.regfile.wp1_we2_i;
        always @(posedge clk) begin
            if(!reset && (we1 || we2))
                $display("%t: Write r%0d = %h",
                    $time, uut.regfile.wp1_addr_i, uut.regfile.wp1_data_i);
        end
    end
    endgenerate
endmodule
