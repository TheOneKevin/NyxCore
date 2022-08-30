module tb_queue #(
    parameter DATA_WIDTH = 1,
    parameter DATA_COUNT = 1,
    parameter FILL_MODE = "FIRST_POSEDGE" // INITIAL, FIRST_POSEDGE
) (
    input  logic clk,
    input  logic reset,
    input  logic[DATA_WIDTH*DATA_COUNT-1:0] init_i,
    input  logic drdy_i,
    output logic dvld_o,
    output logic[DATA_WIDTH-1:0] ddat_o,
    output logic finish_o
);
    logic[DATA_WIDTH-1:0] buffer[DATA_COUNT-1:0];
    generate
        if(FILL_MODE == "FIRST_POSEDGE") begin
            initial @(posedge clk)
            for(integer i = 0; i < DATA_COUNT; i++) begin
                buffer[i] <= init_i[i*DATA_WIDTH+:DATA_WIDTH];
            end
        end else if(FILL_MODE == "INITIAL") begin
            initial
            for(integer i = 0; i < DATA_COUNT; i++) begin
                buffer[i] <= init_i[i*DATA_WIDTH+:DATA_WIDTH];
            end
        end else begin
            $error("%m ** Illegal Parameter ** FILL_MODE(%s) must be one of INITIAL, FIRST_POSEDGE", FILL_MODE);
        end
    endgenerate

    logic[$clog2(DATA_COUNT+1)-1:0] ptr;
    initial ptr = 0;
    initial finish_o = 0;

    assign ddat_o = buffer[ptr];
    assign dvld_o = !reset & buffer[ptr][DATA_WIDTH-1];
    
    always @(posedge clk)
    if(reset) begin
        ptr <= 0;
    end else begin
        if(drdy_i & !finish_o) begin
            ptr <= ptr + 1;
        end
        if(ptr + 1 == DATA_COUNT) begin
            finish_o <= 1;
        end
    end
endmodule
