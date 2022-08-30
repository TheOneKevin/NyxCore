`ifdef VERILATOR_LINT
    `default_nettype none
`endif

module cache_ctrl_fsm #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter NUM_WAYS = 4
) (
    clk, reset,
    urdy_o, uvld_i, hit_i, we_i, flush_i, addr_i,
    drdy_i, dvld_o, ddat_o,
    ack_i, scan_o, qrdy_i, qvld_o, qdat_o
);
    localparam NUM_STATES   = 8;
    localparam STATE_IDLE   = 0;
    localparam STATE_LRU    = 1;
    localparam STATE_QUEUE  = 2;
    localparam STATE_WAIT   = 3;
    localparam STATE_WB     = 4;
    localparam STATE_DUMMY1 = 5;
    localparam STATE_DUMMY2 = 6;
    localparam STATE_DUMMY3 = 7;

    ////////////////////////////////////////////////////////////////////////////

    typedef struct packed {
        logic flush;
        logic[NUM_WAYS-1:0] way;
        logic[ADDR_WIDTH-1:0] addr;
    } ds_pkt;

    ////////////////////////////////////////////////////////////////////////////

    input wire clk;
    input wire reset;

    // Pipeline (us)
    output  logic                   urdy_o;
    input   wire                    uvld_i;
    input   wire                    hit_i;
    input   wire                    we_i;
    input   wire                    flush_i;
    input   wire[ADDR_WIDTH-1:0]    addr_i;

    // Pipeline (ds)
    output  reg                     dvld_o;
    input   wire                    drdy_i;
    output  reg [DATA_WIDTH-1:0]    ddat_o;

    // Async queue (ds)
    input   wire                    ack_i;
    output  reg                     scan_o;
    input   wire                    qrdy_i;
    output  reg                     qvld_o;
    output  reg [$bits(ds_pkt)-1:0] qdat_o;

    ////////////////////////////////////////////////////////////////////////////

    reg[$clog2(NUM_STATES)-1:0] state, nextstate;

    logic ubeat, qbeat, dbeat;
    assign ubeat = uvld_i & urdy_o;
    assign qbeat = qvld_o & qrdy_i;
    assign dbeat = dvld_o & drdy_i;

    reg[ADDR_WIDTH-1:0] addr_r;
    reg flush_r;

    ////////////////////////////////////////////////////////////////////////////

    always @(posedge clk)
    if(reset) begin
        state <= STATE_IDLE;
    end else begin
        state <= nextstate;
    end

    always @(*)
    case(state)
        STATE_IDLE:
            nextstate = ubeat && !(hit_i || we_i) ? STATE_LRU : STATE_IDLE;
        STATE_LRU:
            nextstate = STATE_QUEUE;
        STATE_QUEUE:
            nextstate = qbeat ? STATE_WAIT : STATE_QUEUE;
        STATE_WAIT:
            nextstate = ack_i ? STATE_WB : STATE_WAIT;
        STATE_WB:
            nextstate = dbeat ? STATE_IDLE : STATE_WB;
        default:
            nextstate = STATE_IDLE;
    endcase

    ////////////////////////////////////////////////////////////////////////////

    // Drives: addr_r, flush_r
    always @(posedge clk)
    if(reset) begin
        addr_r <= 0;
        flush_r <= 0;
    end else case(nextstate)
        STATE_LRU: begin
            addr_r <= addr_i;
            flush_r <= flush_i;
        end
    endcase

    // Drives: urdy_o
    always @(posedge clk)
    if(reset) begin
        urdy_o <= 1;
    end else case(nextstate)
        STATE_IDLE: urdy_o <= 1;
        STATE_LRU: urdy_o <= 0;
    endcase

    // TODO: dvld_o
    always @(posedge clk)
    if(reset) begin
        dvld_o <= 0;
    end else case(nextstate)
        STATE_WB: dvld_o <= 1;
        default: dvld_o <= 0;
    endcase

    // TODO: ddat_o
    always @(posedge clk)
    if(reset) begin
        ddat_o <= 0;
    end else case(nextstate)
        STATE_WB: ddat_o <= 0;
        default: ddat_o <= 'x;
    endcase

    // Drives: qvld_o
    always @(posedge clk)
    if(reset) begin
        qvld_o <= 1;
    end else case(nextstate)
        STATE_QUEUE: qvld_o <= 1;
        default: qvld_o <= 0;
    endcase

    // Drives: qdat_o
    always @(posedge clk)
    if(reset) begin
        qdat_o <= 0;
    end else case(nextstate)
        STATE_QUEUE: qdat_o <= ds_pkt'{ flush_r, {NUM_WAYS{1'b0}}, addr_r };
    endcase

    // Drives: scan_o
    always @(posedge clk)
    if(reset) begin
        scan_o <= 0;
    end else case(nextstate)
        STATE_IDLE: scan_o <= 0;
        STATE_LRU: scan_o <= 1;
    endcase
endmodule
