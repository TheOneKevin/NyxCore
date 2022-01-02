`ifdef VERILATOR_LINT
    `default_nettype none
`endif

module skid_buffer #(
    parameter WIDTH = 32,
    parameter ZERO_ON_INVALID = 0
) (
    input wire clk,
    input wire reset,

    input wire stall_i,

    output wire rdy_o,
    input wire val_i,
    input wire[WIDTH-1:0] d_i,

    input wire rdy_i,
    output wire val_o,
    output reg[WIDTH-1:0] d_o
);
    reg val_r;
    assign rdy_o = (rdy_i | !val_o) & !stall_i;
    assign val_o = val_r & !stall_i;

    // Drives: d_o
    generate
    always @(posedge clk)
    if(reset) begin
        d_o <= 0;
    end else if(rdy_o) begin
        if(ZERO_ON_INVALID == 1) begin
            d_o <= val_i ? d_i : { WIDTH{1'b0} };
        end else begin
            d_o <= d_i;
        end
    end
    endgenerate

    // Drives: val_o
    always @(posedge clk)
    if(reset) begin
        val_r <= 0;
    end else if(rdy_o) begin
        val_r <= val_i;
    end
endmodule
