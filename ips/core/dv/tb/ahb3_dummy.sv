`ifdef VERILATOR_LINT
    `default_nettype none
`endif

`timescale 1ns/1ns
`include "rtl/include/amba3.svh"

// Extremely basic AHB dummy memory
// TODO: Very incomplete
module ahb3_dummy (
    input wire clk,
    input wire resetn,

    // AHB-lite slave interface
    output  wire        HREADY_o,
    output  wire        HRESP_o,
    output  wire[31:0]  HRDATA_o,

    // AHB-lite master interface
    input   wire[31:0]  HADDR_i,
    input   wire        HWRITE_i,
    input   wire[2:0]   HSIZE_i,
    input   wire[2:0]   HBURST_i,
    input   wire[3:0]   HPROT_i,
    input   wire[1:0]   HTRANS_i,
    input   wire        HMASTLOCK_i,
    input   wire[31:0]  HWDATA_i
);
    parameter ADDRSIZE = 8;
    parameter tpd = 0;

    reg[31:0] mem[(1<<ADDRSIZE)-1:0];
    reg[31:0] haddr;
    reg hwrite;
    reg active;
    assign HREADY_o = 1'b1;
    assign HRESP_o = 1'b0;
    assign #tpd HRDATA_o = active && !hwrite ? mem[haddr[ADDRSIZE-1:0]] : 32'h0;
    
    always @(posedge clk)
    if(!resetn) begin
        hwrite <= 0;
        haddr <= 0;
    end else if(HTRANS_i == `HTRANS_NOSEQ) begin
        hwrite <= HWRITE_i;
        haddr <= HADDR_i;
        active <= 1;
    end else begin
        hwrite <= 0;
        haddr <= 0;
        active <= 0;
    end

    always @(posedge clk)
    if(hwrite && active) begin
        mem[haddr[ADDRSIZE-1:0]] <= HWDATA_i;
    end
endmodule