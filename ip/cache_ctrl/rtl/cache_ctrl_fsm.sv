`ifdef VERILATOR_LINT
    `default_nettype none
`endif

module cache_ctrl_fsm #(
    parameter ADDR_WIDTH = 32
) (
    input wire clk,
    input wire reset,

    output  logic                   urdy_o,
    input   wire                    uvld_i,
    input   wire                    hit_i,
    input   wire[ADDR_WIDTH-1:0]    addr_i,
    input   wire                    ack_i
);
    localparam NUM_STATES = 3;
    localparam STATE_IDLE = 0;
    localparam STATE_WAIT = 1;

    reg[$clog2(NUM_STATES)-1:0] state;

    logic ubeat;
    assign ubeat = uvld_i & urdy_o;
    assign urdy_o = state == STATE_IDLE;

    always @(posedge clk)
    if(reset) begin
        state <= STATE_IDLE;
    end else case(state)
        STATE_IDLE:
        if(ubeat) begin
            if(!hit_i) begin
                $display($time, " FSM cache miss at addr %X", addr_i);
                state <= STATE_WAIT;
            end
        end
        STATE_WAIT: begin

        end
    endcase
endmodule
