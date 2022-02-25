`ifdef VERILATOR_LINT
    `default_nettype none
`endif

module prim_skidbuf #(
    parameter WIDTH = 32,
    parameter ZERO_ON_INVALID = 0
) (
    input wire clk,
    input wire reset,
    // Upstream ports
    output  wire            urdy_o,
    input   wire            uvld_i,
    input   wire[WIDTH-1:0] udat_i,
    // Downstream ports
    input   wire            dstall_i,
    input   wire            drdy_i,
    output  wire            dvld_o,
    output  reg [WIDTH-1:0] ddat_o
);
    reg val_r;
    assign urdy_o = (drdy_i & !dstall_i) | !val_r;
    assign dvld_o = val_r & !dstall_i;

    // Drives: d_o
    generate
    always @(posedge clk)
    if(reset) begin
        ddat_o <= 0;
    end else if(urdy_o) begin
        if(ZERO_ON_INVALID == 1) begin
            ddat_o <= uvld_i ? udat_i : { WIDTH{1'b0} };
        end else begin
            ddat_o <= udat_i;
        end
    end
    endgenerate

    // Drives: val_o
    always @(posedge clk)
    if(reset) begin
        val_r <= 0;
    end else if(urdy_o) begin
        val_r <= uvld_i;
    end
endmodule
