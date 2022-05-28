`default_nettype none

module cache_tag_waysel #(
    // TODO: Specify parameter constraints
    parameter NUM_WAYS = 1,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter CLINE_SIZE_WORD = 4,
    parameter CLINE_ADDR_WIDTH = 7
) (
    addr_i, tagways_i, dataways_i, data_o, way_miss_o, hit_o
);
    localparam tagOffset = $clog2(CLINE_SIZE_WORD) + CLINE_ADDR_WIDTH;
    // Actual tag width = tagWidth - 1, extra bit is for tag enable
    localparam tagWidth = ADDR_WIDTH - tagOffset + 1;

    // verilator lint_off UNUSED
    input   wire[ADDR_WIDTH-1:0]            addr_i;
    // verilator lint_on UNUSED
    input   wire[tagWidth*NUM_WAYS-1:0]     tagways_i;
    input   wire[DATA_WIDTH*NUM_WAYS-1:0]   dataways_i;
    output  wire[DATA_WIDTH-1:0]            data_o;
    output  wire[NUM_WAYS-1:0]              way_miss_o;
    output  wire                            hit_o;

    wire[NUM_WAYS-1:0] way_hit;

    genvar i;
    generate
        for(i = 0; i < NUM_WAYS; i++) begin
            // Compare addr_i tag with tagways_i tag, then AND with enable bit
            assign way_hit[i] = !(
                |(
                    addr_i[tagOffset+:tagWidth-1]
                    ^ tagways_i[tagWidth*i+:tagWidth-1]
                )
            ) & tagways_i[tagWidth*i + (tagWidth-1)+:1];
        end
    endgenerate

    prim_muxonehot #(
        .DATA_COUNT(NUM_WAYS),
        .DATA_WIDTH(DATA_WIDTH),
        .OPERATION("OR")
    ) mux (
        .mask_i(way_hit),
        .data_i(dataways_i),
        .data_o(data_o)
    );
    
    assign hit_o = | way_hit;
    assign way_miss_o = ~way_hit;
endmodule
