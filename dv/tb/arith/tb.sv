`ifdef VERILATOR_LINT
    `include "rtl/hs32_pipeline.sv"
`endif

// verilator lint_off STMTDLY
`timescale 1ns/1ns

module top();
    parameter TEST_ID = 1;
    localparam clkperiod = 10;
    localparam rstcycles = 3;
    localparam simcycles = 20;

    // Import clock/reset logic and monitors
    `include "dv/tb/lib.sv"

    // Generate test cases
    `include "dv/tb/arith/tc.sv"

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
        .banksel_i(1'b0),

        // Infinite sink
        .valid_o(), .ready_i(1'b1), .data_o()
    );

    //--========================================================================
    // Pipeline event triggers
    //--========================================================================
    
    event EventOnRegWrite;
    generate begin : OnRegWrite
        wire we1 = uut.regfile.wp1_we1_i;
        wire we2 = uut.regfile.wp1_we2_i;
        wire[3:0] addr = uut.regfile.wp1_addr_i;
        wire[31:0] data = uut.regfile.wp1_data_i;
        always @(posedge clk)
        if(!reset && (we1 || we2)) begin
            ->EventOnRegWrite;
            $display("%t: Write r%0d = %h", $time, addr, data);
        end
    end
    endgenerate
endmodule
