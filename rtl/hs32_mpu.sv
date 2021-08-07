module hs32_mpu #(
    parameter NUM_REGNS = 8
) (
    input   wire[31:0] mask_i,
    input   wire[31:0] addr_i,
    input   wire[$clog2(NUM_REGNS)-1:0] tag_i,
    output  wire valid_o
);
    localparam ADDR_ALGN = $clog2(NUM_REGNS);

    // Store region table
    reg[31:0] regions[NUM_REGNS-1:0];
    
    // Force aligned mask
    wire[31:0] maskalgn = mask_i | {{(32-ADDR_ALGN){1'b0}},{ADDR_ALGN{1'b1}}};

    // Generate comparison circuitry
    reg[NUM_REGNS-1:0] tag_match, adr_match;
    assign valid_o = |(tag_match & adr_match);
    genvar i;
    generate
        for (i = 0; i < NUM_REGNS; i++) begin
            always_comb begin
                adr_match[i] = |(
                    (regions[i][31:ADDR_ALGN] ^ addr_i[31:ADDR_ALGN])
                        & (~maskalgn[31:ADDR_ALGN])
                );
                tag_match[i] = regions[i][ADDR_ALGN-1:0] == tag_i;
            end
        end
    endgenerate
endmodule