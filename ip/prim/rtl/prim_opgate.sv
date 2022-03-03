`ifdef VERILATOR_LINT
    `default_nettype none
`endif

module prim_opgate #(
    parameter DATA_WIDTH = 1,
    parameter IMPLEMENTATION = "AND" // AND, MUX
) (
    input wire en,
    input wire[DATA_WIDTH-1:0] data_i,
    output wire[DATA_WIDTH-1:0] data_o
);
    genvar i;
    generate
    for (i = 0; i < DATA_WIDTH; i++) begin
        if(IMPLEMENTATION == "AND") begin
            assign data_o[i] = data_i[i] & en;
        end else if(IMPLEMENTATION == "MUX") begin
            assign data_o[i] = en ? data_i[i] : 1'b0;
        end else begin
            $error("%m ** Illegal Parameter ** IMPLEMENTATION(%s) must be one of AND, MUX", IMPLEMENTATION);
        end
    end
    endgenerate
endmodule
