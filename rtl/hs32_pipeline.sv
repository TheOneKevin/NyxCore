`ifdef VERILATOR_LINT
    `default_nettype none
    `include "hs32_primitives.sv"
    `include "hs32_decode1.sv"
    `include "hs32_decode2.sv"
    `include "hs32_execute.sv"
    `include "hs32_regfile4r1w.sv"
`endif

module hs32_pipeline (
    input wire clk,
    input wire reset,
    
    // Input pipeline
    input wire valid_i,
    output wire ready_o,
    input wire[31:0] op_i,
    input wire banksel_i,

    // Output pipeline
    output wire valid_o,
    input wire ready_i,
    output wire[31:0] data_o
);
    //--========================================================================
    // Register file
    //--========================================================================

    wire[3:0] reg_wp1_a, reg_rp1_a, reg_rp2_a, reg_rp3_a;
    wire[31:0] reg_wp1_d, reg_rp1_d, reg_rp2_d, reg_rp3_d;
    wire reg_wp1_we1, reg_wp1_we2;
    
    hs32_regfile4r1w #(
        .RESET(1), .DUPLICATE_FILE(0)
    ) regfile (
        .clk(clk), .reset(reset),
        .banksel_i(banksel_i),

        // Write port 1
        .wp1_addr_i(reg_wp1_a), .wp1_data_i(reg_wp1_d),
        .wp1_we1_i(reg_wp1_we1), .wp1_we2_i(reg_wp1_we2),
        .wp1_wel_i(1'b1),
        
        // Read port 1
        .rp1_addr_i(reg_rp1_a), .rp1_data_o(reg_rp1_d),
        
        // Read port 2
        .rp2_addr_i(reg_rp2_a), .rp2_data_o(reg_rp2_d),

        // Read port 3
        .rp3_addr_i(reg_rp3_a), .rp3_data_o(reg_rp3_d),

        // Read port 4
        .rp4_addr_i(4'b0), .rp4_data_o()
    );

    //--========================================================================
    // Pipeline stages and buffer
    //--========================================================================

    // StageN combinational (c) + latched (l) paths
    wire[31:0] opl;
    hs32_s1pkt data1c, data1l;
    hs32_s2pkt data2c, data2l;
    hs32_s3pkt data3c;

    wire s1rdy, s1vld, s2rdy, s2vld, s3rdy, s3vld;
    wire stall1, stall2;
    wire[3:0] rd2, rd3;

    // Pipeline buffers
    skid_buffer #(.WIDTH($bits(op_i))) skid0 (
        .clk(clk), .reset(reset),
        .stall_i(stall1),
        .rdy_o(ready_o), .val_i(valid_i), .d_i(op_i),
        .rdy_i(s1rdy), .val_o(s1vld), .d_o(opl)
    );
    skid_buffer #(.WIDTH($bits(data1c))) skid1 (
        .clk(clk), .reset(reset),
        .stall_i(stall2),
        .rdy_o(s1rdy), .val_i(s1vld), .d_i(data1c),
        .rdy_i(s2rdy), .val_o(s2vld), .d_o(data1l)
    );
    skid_buffer #(.WIDTH($bits(data2c))) skid2 (
        .clk(clk), .reset(reset),
        .stall_i(1'b0),
        .rdy_o(s2rdy), .val_i(s2vld), .d_i(data2c),
        .rdy_i(s3rdy), .val_o(s3vld), .d_o(data2l)
    );
    skid_buffer #(.WIDTH($bits(data3c.res))) skid3 (
        .clk(clk), .reset(reset),
        .stall_i(1'b0),
        .rdy_o(s3rdy), .val_i(s3vld), .d_i(data3c.res),
        .rdy_i(ready_i), .val_o(valid_o), .d_o(data_o)
    );

    // Combinational paths
    hs32_decode1 u1 (
        // Register read port 1
        .rp_addr_o(reg_rp1_a), .rp_data_i(reg_rp1_d),

        // Pipeline data
        .data_i(opl), .data_o(data1c),

        // Hazard detection
        .rd2_i(rd2), .stl2_i(s2vld),
        .rd3_i(rd3), .stl3_i(s3vld),
        .stall_o(stall1)
    );
    hs32_decode2 u2 (
        // Register read port 2
        .rp_addr_o(reg_rp2_a), .rp_data_i(reg_rp2_d),

        // Pipeline data
        .data_i(data1l), .data_o(data2c), .fwd_i(data_o),

        // Hazard detection
        .rd2_o(rd2), .rd3_i(rd3), .stl3_i(s3vld),
        .stall_o(stall2)
    );
    hs32_execute u3 (
        .clk(clk), .reset(reset), .valid_i(s3vld),

        // Register read port 3
        .rp_addr_o(reg_rp3_a), .rp_data_i(reg_rp3_d),

        // Register write port 1
        .wp_addr_o(reg_wp1_a), .wp_data_o(reg_wp1_d),
        .wp_we1_o(reg_wp1_we1), .wp_we2_o(reg_wp1_we2),

        // Pipeline data
        .data_i(data2l), .data_o(data3c), .fwd_i(data_o),

        // Hazard detection
        .rd3_o(rd3)
    );

    //--========================================================================
    // Load store unit
    //--========================================================================
    

endmodule