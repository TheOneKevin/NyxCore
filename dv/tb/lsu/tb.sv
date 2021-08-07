`ifdef VERILATOR_LINT
    `default_nettype none
    `include "rtl/hs32_lsu.sv"
`endif

// verilator lint_off STMTDLY
`timescale 1ns/1ns

module top();
    parameter TEST_ID = 1;
    localparam clkperiod = 10;
    localparam rstcycles = 3;
    localparam simcycles = 20;

    typedef struct packed {
        logic ready;
        logic valid;
        hs32_s3pkt data;
    } packet_t;
    packet_t curpkt;

    // Import clock/reset logic and monitors
    `include "dv/tb/lib.sv"

    // Generate test cases
    `include "dv/tb/lsu/tc.sv"

    // Input array
    wire ready;
    reg[$clog2(numpackets+1):0] ptr = 0;
    assign curpkt = ptr == numpackets ?
        0 : packets[(numpackets-ptr-1)*$bits(curpkt)+:$bits(curpkt)];
    always @(posedge clk)
    if(reset) begin
        ptr <= 0;
    end else if(ptr < numpackets) begin
        ptr <= ptr + 1;
    end

    // UUT
    wire[31:0] hwdata, haddr;
    wire[1:0] htrans;
    wire hwrite;
    hs32_lsu uut (
        .clk(clk), .resetn(!reset),

        .valid_i(curpkt.valid),
        .ready_o(ready),
        .data_i(curpkt.data),

        .l1_o(), .l2_o(), .fwd_o(),

        .wp_addr_o(), .wp_data_o(), .wp_we_o(),

        .HREADY_i(curpkt.ready), .HRESP_i(1'b0), .HRDATA_i(32'hDEADBEEF),

        .HADDR_o(haddr), .HWRITE_o(hwrite),
        .HSIZE_o(), .HBURST_o(), .HPROT_o(),
        .HTRANS_o(htrans), .HMASTLOCK_o(), .HWDATA_o(hwdata)
    );
endmodule
