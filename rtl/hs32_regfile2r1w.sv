`ifdef VERILATOR_LINT
    `default_nettype none
`endif

module hs32_regfile2r1w (
    input wire clk,
    input wire reset,

    // Read ports bank select
    input wire          banksel_i,

    // Write port 1
    input wire [3:0]    wp1_addr_i,
    input wire [31:0]   wp1_data_i,
    input wire          wp1_we1_i,
    input wire          wp1_we2_i,

    // Read port 1
    input wire [3:0]    rp1_addr_i,
    output wire [31:0]  rp1_data_o,

    // Read port 2
    input wire [3:0]    rp2_addr_i,
    output wire [31:0]  rp2_data_o
);
    reg[31:0] mem1[15:0];
    reg[31:0] mem2[7:0];

    // Read port assignments
    assign rp1_data_o = banksel_i ? mem2[rp1_addr_i[2:0]] : mem1[rp1_addr_i];
    assign rp2_data_o = banksel_i ? mem2[rp2_addr_i[2:0]] : mem1[rp2_addr_i];

    // Drives: mem1
    always_ff @(posedge clk) begin
        if(wp1_we1_i) begin
            mem1[wp1_addr_i] <= wp1_data_i;
        end
    end

    // Drives: mem2
    always_ff @(posedge clk) begin
        if(wp1_we2_i) begin
            mem2[wp1_addr_i[2:0]] <= wp1_data_i;
        end
    end
endmodule