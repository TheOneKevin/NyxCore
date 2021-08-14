`ifdef VERILATOR_LINT
    `default_nettype none
    `include "hs32_decode1.sv"
    `include "hs32_decode2.sv"
    `include "hs32_execute.sv"
    `include "hs32_regfile4r1w.sv"
    `include "primitives/skid_buffer.svh"
`endif

module hs32_pipeline (
    input   wire        clk,
    input   wire        reset,
    
    // Input pipeline
    input   wire        valid_i,
    output  wire        ready_o,
    input   wire[31:0]  op_i,
    input   wire        banksel_i,

    // Output pipeline
    output  wire        valid_o,
    input   wire        ready_i,
    output  hs32_s3pkt  data_o,

    // AHB-lite slave interface
    input   wire        HREADY_i,
    input   wire        HRESP_i,
    input   wire[31:0]  HRDATA_i,

    // AHB-lite master interface
    output  wire[31:0]  HADDR_o,
    output  wire        HWRITE_o,
    output  wire[2:0]   HSIZE_o,
    output  wire[2:0]   HBURST_o,
    output  wire[3:0]   HPROT_o,
    output  wire[1:0]   HTRANS_o,
    output  wire        HMASTLOCK_o,
    output  wire[31:0]  HWDATA_o
);
    parameter USE_TECHMAP = 0;
    parameter REGFILE_RESET = 1;
    parameter REGFILE_DUPLICATE = 0;
    parameter SIM_DEBUG_SKID_BUFFERS = 1;
    parameter SIM_DEBUG_MESSAGES = 0;
    
    //--========================================================================
    // Register file
    //--========================================================================

    wire[3:0] reg_wp1_a, reg_wp2_a, reg_rp1_a, reg_rp2_a, reg_rp3_a;
    wire[31:0] reg_wp1_d, reg_wp2_d, reg_rp1_d, reg_rp2_d, reg_rp3_d;
    wire reg_wp1_we1, reg_wp1_we2, reg_wp2_we1;
    
    hs32_regfile4r1w #(
        .RESET(REGFILE_RESET), .DUPLICATE_FILE(REGFILE_DUPLICATE)
    ) regfile (
        .clk(clk), .reset(reset),
        .banksel_i(banksel_i),

        // Write port 1
        .wp1_addr_i(s3vld ? reg_wp1_a : reg_wp2_a),
        .wp1_data_i(s3vld ? reg_wp1_d : reg_wp2_d),
        .wp1_we1_i (s3vld ? reg_wp1_we1 : reg_wp2_we1),
        .wp1_we2_i (s3vld ? reg_wp1_we2 : 1'b0),
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

    // Stage N combinational (c) and latched (l) paths
    wire[31:0] opl;
    hs32_s1pkt data1c, data1l;
    hs32_s2pkt data2c, data2l;
    hs32_s3pkt data3c;
    hs32_stall s2, s3, l1, l2;

    wire s1rdy, s1vld, s2rdy, s2vld, s3rdy, s3vld, l1rdy, l1vld;
    wire stall1, stall2, stall3;
    wire[3:0] rd2, rd3;
    wire[31:0] lfwd;

    // TODO: Remove
    assign valid_o = l1vld;

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
        .stall_i(stall3),
        .rdy_o(s2rdy), .val_i(s2vld), .d_i(data2c),
        .rdy_i(s3rdy), .val_o(s3vld), .d_o(data2l)
    );
    skid_buffer #(.WIDTH($bits(data3c))) skid3 (
        .clk(clk), .reset(reset),
        .stall_i(1'b0),
        .rdy_o(), .val_i(s3vld), .d_i(data3c),
        .rdy_i(s3rdy), .val_o(l1vld), .d_o(data_o)
    );

    // Combinational paths
    hs32_decode1 u1 (
        // Register read port 1
        .rp_addr_o(reg_rp1_a), .rp_data_i(reg_rp1_d),

        // Pipeline data
        .data_i(opl), .data_o(data1c),

        // Hazard detection
        .s2_i(s2), .s3_i(s3), .l1_i(l1), .l2_i(l2),
        .stall_o(stall1)
    );
    hs32_decode2 u2 (
        .valid_i(s2vld),
        
        // Register read port 2
        .rp_addr_o(reg_rp2_a), .rp_data_i(reg_rp2_d),

        // Pipeline data
        .data_i(data1l), .data_o(data2c), .fwd_i(data_o.res),

        // Hazard detection
        .s2_o(s2), .s3_i(s3), .l1_i(l1), .l2_i(l2),
        .stall_o(stall2)
    );
    hs32_execute #(
        .USE_TECHMAP(USE_TECHMAP)
    ) u3 (
        .clk(clk), .reset(reset), .valid_i(s3vld),

        // Register read port 3
        .rp_addr_o(reg_rp3_a), .rp_data_i(reg_rp3_d),

        // Register write port 1
        .wp_addr_o(reg_wp1_a), .wp_data_o(reg_wp1_d),
        .wp_we1_o(reg_wp1_we1), .wp_we2_o(reg_wp1_we2),

        // Pipeline data
        .data_i(data2l), .data_o(data3c), .fwd_i(data_o.res),

        // Hazard detection
        .s3_o(s3), .l1_i(l1), .l2_i(l2),
        .stall_o(stall3)
    );

    //--========================================================================
    // Load store unit
    //--========================================================================
    
    hs32_lsu lsu (
        .clk(clk), .resetn(!reset),

        // Pipeline data
        .valid_i(s3vld & data3c.islsu),
        .ready_o(s3rdy), .data_i(data3c),

        // Hazard detection
        .l1_o(l1), .l2_o(l2), .fwd_o(lfwd),

        // Register write port 2
        .wp_addr_o(reg_wp2_a), .wp_data_o(reg_wp2_d), .wp_we_o(reg_wp2_we1),

        // AHB3-lite
        .HREADY_i, .HRESP_i, .HRDATA_i,
        .HADDR_o, .HWRITE_o,
        .HSIZE_o, .HBURST_o, .HPROT_o,
        .HTRANS_o, .HMASTLOCK_o, .HWDATA_o
    );

    //--========================================================================
    // Debug trace
    //--========================================================================

    generate
        if(SIM_DEBUG_SKID_BUFFERS == 1) begin
            wire[31:0] ds1, ds2, ds3;
            skid_buffer #(.WIDTH($bits(op_i))) debugskid0 (
                .clk(clk), .reset(reset), .stall_i(stall1),
                .rdy_o(ready_o), .val_i(valid_i), .d_i(op_i),
                .rdy_i(s1rdy), .val_o(s1vld), .d_o(ds1)
            );
            skid_buffer #(.WIDTH($bits(op_i))) debugskid1 (
                .clk(clk), .reset(reset), .stall_i(stall2),
                .rdy_o(s1rdy), .val_i(s1vld), .d_i(ds1),
                .rdy_i(s2rdy), .val_o(s2vld), .d_o(ds2)
            );
            skid_buffer #(.WIDTH($bits(op_i))) debugskid2 (
                .clk(clk), .reset(reset), .stall_i(stall3),
                .rdy_o(s2rdy), .val_i(s2vld), .d_i(ds2),
                .rdy_i(s3rdy), .val_o(s3vld), .d_o(ds3)
            );
            if(SIM_DEBUG_MESSAGES == 1) begin
                always @(posedge clk)
                if(!reset) begin
                    $display("%X %X %X", ds1, ds2, ds3);
                    if(reg_wp2_we1) begin
                        $display("r%X = %X", reg_wp2_a, reg_wp2_d);
                    end
                end
            end
        end
    endgenerate
endmodule