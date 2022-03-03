`ifdef VERILATOR_LINT
    `default_nettype none
`endif

module prim_muxonehot #(
    parameter DATA_COUNT = 1,
    parameter DATA_WIDTH = 1,
    parameter OPERATION = "OR" // OR, AND
) (
    input wire[DATA_COUNT-1:0] mask_i,
    input wire[DATA_COUNT*DATA_WIDTH-1:0] data_i,
    output wire[DATA_WIDTH-1:0] data_o
);
    logic[DATA_COUNT-1:0] data_trans[DATA_WIDTH-1:0];
    logic[DATA_WIDTH-1:0] data_selected[DATA_COUNT-1:0];

    genvar i;
    genvar j;
    generate
        for(i = 0; i < DATA_COUNT; i++) begin
            prim_opgate #(
                .DATA_WIDTH(DATA_WIDTH),
                .IMPLEMENTATION("AND")
            ) gate (
                .en(mask_i[i]),
                .data_i(data_i[i*DATA_WIDTH+:DATA_WIDTH]),
                .data_o(data_selected[i])
            );
        end
        // Transpose
        for(i = 0; i < DATA_WIDTH; i++) begin
            for(j = 0; j < DATA_COUNT; j++) begin
                assign data_trans[i][j] = data_selected[j][i];
            end
        end
        // Reduce
        for(i = 0; i < DATA_WIDTH; i++) begin
            if(OPERATION == "OR") begin
                assign data_o[i] = | data_trans[i];
            end else if(OPERATION == "AND") begin
                assign data_o[i] = & data_trans[i];
            end else begin
                $error("%m ** Illegal Parameter ** OPERATION(%s) must be one of OR, AND", OPERATION);
            end
        end
    endgenerate
endmodule
