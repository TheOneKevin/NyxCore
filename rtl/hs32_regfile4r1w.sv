`ifdef VERILATOR_LINT
    `default_nettype none
`endif

module hs32_regfile4r1w #(
    parameter RESET = 1,            // Generate reset if 1
    parameter DUPLICATE_FILE = 0    // Generate a duplicate file if 1
) (
    input wire clk,
    input wire reset,

    // Read ports bank select
    input wire          banksel_i,  // 0: bank 0, 1: bank 1

    // Write port 1
    input wire [3:0]    wp1_addr_i, // Write port 1 address
    input wire [31:0]   wp1_data_i, // Write port 1 data
    input wire          wp1_we1_i,  // Write port 1 write enable (bank 0)
    input wire          wp1_we2_i,  // Write port 1 write enable (bank 1)
    input wire          wp1_wel_i,  // Write port 1 write enable (low)

    // Read port 1
    input wire [3:0]    rp1_addr_i,
    output wire [31:0]  rp1_data_o,

    // Read port 2
    input wire [3:0]    rp2_addr_i,
    output wire [31:0]  rp2_data_o,

    // Read port 3
    input wire [3:0]    rp3_addr_i,
    output wire [31:0]  rp3_data_o,

    // Read port 4
    input wire [3:0]    rp4_addr_i,
    output wire [31:0]  rp4_data_o
);
    // File A
    reg[31:0] memA1[15:0];
    reg[31:0] memA2[7:0];

    // File B
    reg[31:0] memB1[15:0];
    reg[31:0] memB2[7:0];

    // Generate logic to read/write memory
    generate
        // Read port assignments
        assign rp1_data_o = banksel_i ? memA2[rp1_addr_i[2:0]] : memA1[rp1_addr_i];
        assign rp2_data_o = banksel_i ? memA2[rp2_addr_i[2:0]] : memA1[rp2_addr_i];
        if(DUPLICATE_FILE == 0) begin
            assign rp3_data_o = banksel_i ? memA2[rp3_addr_i[2:0]] : memA1[rp3_addr_i];
            assign rp4_data_o = banksel_i ? memA2[rp4_addr_i[2:0]] : memA1[rp4_addr_i];
        end else begin
            assign rp3_data_o = banksel_i ? memB2[rp3_addr_i[2:0]] : memB1[rp3_addr_i];
            assign rp4_data_o = banksel_i ? memB2[rp4_addr_i[2:0]] : memB1[rp4_addr_i];
        end
    
        // Drives: mem1
        always_ff @(posedge clk)
        if(reset) begin
            if(RESET == 1) begin
                for(integer i = 0; i < 16; i = i + 1) begin
                    memA1[i] <= 0;
                    memB1[i] <= 0;
                end
            end
        end else if(wp1_we1_i) begin
            // Write hi
            memA1[wp1_addr_i][31:16] <= wp1_data_i[31:16];
            if(DUPLICATE_FILE != 0) begin
                memB1[wp1_addr_i][31:16] <= wp1_data_i[31:16];
            end
            // Write lo
            if(wp1_wel_i) begin
                memA1[wp1_addr_i][15:0] <= wp1_data_i[15:0];
                if(DUPLICATE_FILE != 0) begin
                    memB1[wp1_addr_i][15:0] <= wp1_data_i[15:0];
                end
            end
        end

        // Drives: mem2
        always_ff @(posedge clk)
        if(reset) begin
            if(RESET == 1) begin
                for(integer i = 0; i < 8; i = i + 1) begin
                    memA2[i] <= 0;
                    memB2[i] <= 0;
                end
            end
        end else if(wp1_we2_i) begin
            // Write hi
            memA2[wp1_addr_i[2:0]][31:16] <= wp1_data_i[31:16];
            if(DUPLICATE_FILE != 0) begin
                memB2[wp1_addr_i[2:0]][31:16] <= wp1_data_i[31:16];
            end
            // Write lo
            if(wp1_wel_i) begin
                memA2[wp1_addr_i[2:0]][15:0] <= wp1_data_i[15:0];
                if(DUPLICATE_FILE != 0) begin
                    memB2[wp1_addr_i[2:0]][15:0] <= wp1_data_i[15:0];
                end
            end
        end
    endgenerate
endmodule
