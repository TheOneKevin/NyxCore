`ifdef VERILATOR_LINT
    `default_nettype none
    `include "rtl/hs32_pipeline.sv"
`endif

`include "dv/tb/ahb3_dummy.sv"

// verilator lint_off STMTDLY
`timescale 1ns/1ns

module top();
    parameter TEST_ID = 1;
    localparam clkperiod = 10;
    localparam rstcycles = 3;
    localparam simcycles = 20;
    localparam memsize = 8;

    // Import clock/reset logic and monitors
    `include "dv/tb/lib.sv"

    // Generate test cases
    `include "dv/tb/pipeline/tc.sv"

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

    // TODO: Use interfaces (when supported)
    wire[31:0] hrdata, haddr, hwdata;
    wire hwrite, hready, hresp;
    wire[1:0] htrans;
    ahb3_dummy #(.ADDRSIZE(memsize), .tpd(7)) ahb3(
        .clk(clk), .resetn(!reset),
        .HREADY_o(hready), .HRESP_o(hresp), .HRDATA_o(hrdata),
        .HADDR_i(haddr), .HWRITE_i(hwrite),
        .HSIZE_i(), .HBURST_i(), .HPROT_i(),
        .HTRANS_i(htrans), .HMASTLOCK_i(), .HWDATA_i(hwdata)
    );

    // UUT
    hs32_pipeline uut(
        .clk(clk), .reset(reset),
        
        // Shift in instructions from array
        .valid_i(!reset && ip < numinstrs), .ready_o(ready),
        .op_i(ip == numinstrs ? 32'h0 : instr[(numinstrs-ip-1)*32+:32]),
        .banksel_i(1'b0),

        // Infinite sink
        .valid_o(), .ready_i(1'b1), .data_o(),

        // AHB3-lite
        .HREADY_i(hready), .HRESP_i(hresp), .HRDATA_i(hrdata),
        .HADDR_o(haddr), .HWRITE_o(hwrite),
        .HSIZE_o(), .HBURST_o(), .HPROT_o(),
        .HTRANS_o(htrans), .HMASTLOCK_o(), .HWDATA_o(hwdata)
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
            doevent();
            ->EventOnRegWrite;
            $display("%t: Write r%0d = %h", $time, addr, data);
        end
    end
    endgenerate

    event EventOnMemWrite;
    generate begin : OnMemWrite
        wire we = ahb3.hwrite;
        wire[31:0] addr = ahb3.haddr[memsize-1:0];
        wire[31:0] data = ahb3.HWDATA_i;
        always @(posedge clk)
        if(!reset && we) begin
            doevent();
            ->EventOnMemWrite;
            $display("%t: Write *%0d = %h", $time, addr, data);
        end
    end
    endgenerate

    event EventOnMemRead;
    generate begin : OnMemRead
        wire re = ahb3.active && !ahb3.hwrite;
        wire[31:0] addr = ahb3.haddr[memsize-1:0];
        wire[31:0] data = ahb3.mem[ahb3.haddr[memsize-1:0]];
        always @(posedge clk)
        if(!reset && re) begin
            doevent();
            ->EventOnMemRead;
            $display("%t: Read  *%0d = %h", $time, addr, data);
        end
    end
    endgenerate
endmodule
