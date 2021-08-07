`ifdef VERILATOR_LINT
    `default_nettype none
`endif

`include "rtl/include/amba3.svh"

// Extremely basic AHB dummy memory
module ahb3_dummy (
    input wire clk,
    input wire resetn,

    // AHB-lite slave interface
    output  wire        HREADY_o,
    output  wire        HRESP_o,
    output  reg[31:0]   HRDATA_o,

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
    reg[31:0] mem[(1<<ADDRSIZE)-1:0];

    reg[31:0] haddr;
    reg hwrite;
    assign HREADY_o = 1'b1;
    assign HRESP_o = 1'b0;
    always @(posedge clk)
    if(!resetn) begin
        HRDATA_o <= 0;
        hwrite <= 0;
        haddr <= 0;
    end else if(HTRANS_i == `HTRANS_NOSEQ) begin
        hwrite <= HWRITE_i;
        if(HWRITE_i) begin
            haddr <= HADDR_i;
        end else begin
            HRDATA_o <= mem[HADDR_i[ADDRSIZE-1:0]];
        end
    end else begin
        HRDATA_o <= 0;
        hwrite <= 0;
    end

    always @(posedge clk)
    if(hwrite) begin
        mem[haddr[ADDRSIZE-1:0]] <= HWDATA_i;
    end
endmodule