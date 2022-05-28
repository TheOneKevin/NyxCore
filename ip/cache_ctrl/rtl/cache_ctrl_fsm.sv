`ifdef VERILATOR_LINT
    `default_nettype none
`endif

module cache_ctrl_fsm #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input wire clk,
    input wire reset,

    // Pipeline (us)
    output  logic                   urdy_o,
    input   wire                    uvld_i,
    input   wire                    hit_i,
    input   wire                    we_i,
    input   wire                    flush_i,
    input   wire[ADDR_WIDTH-1:0]    addr_i,
    input   wire                    ack_i,

    // Async queue (ds)
    output  wire                    dscan_o,
    input   wire                    drdy_i,
    output  reg                     dvld_o,
    output  reg [DATA_WIDTH-1:0]    ddat_o
);
    localparam NUM_STATES   = 8;
    localparam STATE_IDLE   = 0;
    localparam STATE_LRU    = 1;
    localparam STATE_WRITE1 = 2;
    localparam STATE_WRITE2 = 3;
    localparam STATE_READ   = 4;
    localparam STATE_WAIT   = 5;
    localparam STATE_DUMMY1 = 6;
    localparam STATE_DUMMY2 = 7;

    ////////////////////////////////////////////////////////////////////////////

    reg[$clog2(NUM_STATES)-1:0] state;

    logic ubeat, dbeat;
    assign ubeat = uvld_i & urdy_o;
    assign dbeat = dvld_o & drdy_i;

    reg rvld;

    ////////////////////////////////////////////////////////////////////////////

    always @(posedge clk)
    if(reset) begin
        state <= STATE_IDLE;
    end else case(state)
        STATE_IDLE: begin
            state <= ubeat && !hit_i && !we_i ? STATE_LRU
                   : ubeat && hit_i && flush_i ? STATE_WRITE2
                   : STATE_IDLE;
        end
        STATE_LRU: begin
            state <= STATE_WRITE1;
        end
        STATE_WRITE1: begin
            state <= dbeat ? STATE_READ : STATE_WRITE1;
        end
        STATE_READ: begin
            state <= dbeat ? STATE_WAIT : STATE_READ;
        end
        STATE_WAIT: begin
            state <= STATE_IDLE;
        end
    endcase

    ////////////////////////////////////////////////////////////////////////////

    always @(posedge clk)
    if(reset) begin
    end else case(state)
        STATE_IDLE: begin

        end
    endcase
endmodule
