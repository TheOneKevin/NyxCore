package ahb3_package;
    parameter HTRANS_IDLE   = 0;
    parameter HTRANS_BUSY   = 1;
    parameter HTRANS_NONSEQ = 2;
    parameter HTRANS_SEQ    = 3;
endpackage

module cache_controller (
    input wire HCLK,
    input wire HRESETn,

    // AHB3 slave interface
    input   wire        HSEL,
    input   wire[31:0]  HADDR,
    input   wire[31:0]  HWDATA,
    output  reg [31:0]  HRDATA,
    input   wire        HWRITE,
    input   wire[2:0]   HSIZE,
    input   wire[2:0]   HBURST,
    input   wire[2:0]   HPROT,
    input   wire[2:0]   HTRANS,
    output  reg         HREADYOUT,
    output  reg         HRESP
);
    import ahb3_package::*;

    // address = tag, index, nibble
    localparam SZ_TAG = 19;
    localparam SZ_IDX = 11;
    localparam SZ_NIB = 2;

    typedef struct packed {
        logic       ahb_sel;
        logic       ahb_write;
        logic[31:0] HADDR;
    } pipeline_struct;

    pipeline_struct pipeline;
    reg[31:0] wdata;

    wire ahb_sel;
    wire ahb_write;
    wire[SZ_IDX-1:0] cache_index;
    wire[SZ_TAG-1:0] cache_tag;
    wire[SZ_IDX+SZ_NIB-1:0] cache_addr;

    assign ahb_sel      = HSEL && !(HTRANS == HTRANS_BUSY || HTRANS == HTRANS_IDLE);
    assign ahb_write    = ahb_sel && HWRITE;

    always_ff @(posedge HCLK)
    if(!HRESETn) begin
        pipeline <= 0;
    end else begin
        pipeline <= { ahb_sel, ahb_write, HADDR };
    end

    always_ff @(posedge HCLK)
    if(!HRESETn) begin
        wdata <= 0;
    end else begin
        wdata <= HWDATA;
    end

    assign cache_index  = pipeline.HADDR[SZ_NIB-1+:SZ_IDX];
    assign cache_tag    = pipeline.HADDR[31-:SZ_TAG];
    assign cache_addr   = pipeline.HADDR[0+:SZ_IDX+SZ_NIB];

    
endmodule