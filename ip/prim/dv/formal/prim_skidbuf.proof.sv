`ifdef VERILATOR_LINT
    `default_nettype none
`endif

module top #(
    parameter WIDTH = 32,
    parameter ZERO_ON_INVALID = 0
) (
    input wire clk,
    input wire reset,
    input   wire            dstall_i,
    output  wire            urdy_o,
    input   wire            uvld_i,
    input   wire[WIDTH-1:0] udat_i,
    input   wire            drdy_i,
    output  wire            dvld_o,
    output  reg [WIDTH-1:0] ddat_o
);
    // Instantiate module
    prim_skidbuf dut(.*);

    // 0. $past gaurd
    reg f_past_valid;
    initial f_past_valid = 0;
    always @(posedge clk) begin
        f_past_valid <= 1;
        assume(f_past_valid ? !reset : reset);
    end

    wire ubeat = urdy_o & uvld_i;
    wire dbeat = drdy_i & dvld_o;

    // 1. Uniqueness assumption
    // - Without loss of generality, assume 2 data
    //   packets are unique amongst all data packets
    (* anyconst *) reg[WIDTH-1:0] f_data1;
    (* anyconst *) reg[WIDTH-1:0] f_data2;
    reg f_unique_data1, f_unique_data2;
    initial f_unique_data1 = 0;
    initial f_unique_data2 = 0;
    always @(posedge clk)
    if(!reset) begin
        if(udat_i == f_data1) f_unique_data1 <= 1;
        if(udat_i == f_data2) f_unique_data2 <= 1;
        if(f_unique_data1) assume(udat_i != f_data1);
        if(f_unique_data2) assume(udat_i != f_data2);
    end
    
    // 2.1. Formal Contract (1)
    // - If data1 and data2 go in adjacent, they should come out in-order.
    // - NB: Downstream stall signal should HAVE NO IMPACT on this.
    reg[1:0] f_st1, f_st2;
    initial f_st1 = 0;
    initial f_st2 = 0;
    // - Wait until we observe f_data1, then check for f_data2 to be the next ubeat
    always @(posedge clk)
    if(!reset && ubeat) case(f_st1)
        0: if(udat_i == f_data1) f_st1 <= 1;
        1: if(udat_i == f_data2) f_st1 <= 2; else f_st1 <= 0;
        2: begin end
    endcase
    // - Wait until we observe a dbeat, then check for f_data2 on the next dbeat
    always @(posedge clk)
    if(!reset && dbeat && f_st1 != 0)
    case(f_st2)
        0: if(ddat_o == f_data1) f_st2 <= 1;
        1: begin
            assert(ddat_o == f_data2);
            f_st2 <= 2;
        end
        2: begin end
    endcase
    // - If we do not stall, dbeat should occur within x cycles
    // NB: Typically, x is the depth of the FIFO
    localparam dbeat_timeout_cyc = 1;
    reg [$clog2(dbeat_timeout_cyc):0] dbeat_counter;
    initial dbeat_counter = 0;
    always @(posedge clk)
    if(f_st1 != 0 && f_st2 == 0) begin
        if(dbeat_counter >= dbeat_timeout_cyc) begin
            assert(f_st2 == 2);
        end else if(!dstall_i && drdy_i) begin
            dbeat_counter <= dbeat_counter + 1;
        end
    end

    // 2.2. Formal Contract (2)
    // - No downstream transactions can happen during a stall
    always @(posedge clk)
    if(!reset && dstall_i) assert(!dbeat);
    // - If we're not ready yet and downstream data was valid, data should not change
    always @(posedge clk)
    if(f_past_valid && !$past(reset) && !drdy_i && $past(!drdy_i && dvld_o)) begin
        assert($past(ddat_o) == ddat_o);
        // Either the data is still valid or we are stalling
        assert(dvld_o | dstall_i);
    end

    // 3. Cover
    // - Perform 1 transaction
    reg[1:0] cover_trans_state;
    initial cover_trans_state = 0;
    always @(posedge clk) if(!reset)
    case(cover_trans_state)
        0: if(ubeat && udat_i == f_data1) cover_trans_state <= 1;
        1: if(dbeat && ddat_o == f_data1) cover_trans_state <= 2;
    endcase
    always @(posedge clk) cover(cover_trans_state == 2);
endmodule