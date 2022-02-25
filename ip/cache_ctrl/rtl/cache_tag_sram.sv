module cache_tag_sram #(
    parameter SRAM_TYPE = "SKY130",
    parameter ADDR_WIDTH = 8,
    parameter NUM_WAYS = 1,
    parameter DATA_WIDTH = 32
) (
    // Port 0: RW
    input  wire                 p0_clk,
    input  wire[ADDR_WIDTH-1:0] p0_addr,
    input  wire[NUM_WAYS-1:0]   p0_web,
    input  wire[DATA_WIDTH-1:0] p0_wdat,
    output wire[DATA_WIDTH-1:0] p0_rdat,
    // Port 1: RO
    input  wire                 p1_clk,
    input  wire[ADDR_WIDTH-1:0] p1_addr,
    output wire[DATA_WIDTH-1:0] p1_rdat
);
    localparam NUM_WMASKS = 4;
    generate
        genvar i;
        if(SRAM_TYPE == "SKY130") begin: gen_sram
            for(i = 0; i < NUM_WAYS; i++) begin
                sky130_sram_1kbyte_1rw1r_32x256_8 sram(
                    .clk0(p0_clk),
                    .csb0(1'b0),
                    .web0(p0_web[i]),
                    .wmask0({NUM_WMASKS{1'b1}}),
                    .addr0(p0_addr),
                    .din0(p0_wdat),
                    .dout0(p0_rdat),

                    .clk1(p1_clk),
                    .csb1(1'b1),
                    .addr1(p1_addr),
                    .dout1(p1_rdat)
                );
            end
        end else begin
            $error("Unknown SRAM_TYPE: \"%s\"", SRAM_TYPE);
        end
    endgenerate
endmodule
