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

/*
    nreg = number of regions minus 1 (align pow2)
    size = 32 - nreg = region size (align pow2)
    mask = sext(1 << size)
         = ({ 1'b1, 32'h0 } >>> nreg) & 32'hFFFF_FFFF
         = 0 >>1 nreg where >>1 will shift in 1 instead of 0
    shft = ctz(mask) - 3
         = size - 3
         = 29 - nreg

    Example 8-bit address space layout with mask 1100_0000:
        addr = rrss_sxxx
        r is region bit to compare
        s is subregion bit to compare

    How regions are computed:
        nreg = 4
        mask = 1100_0000
            => 4 distinct regions
            => 0000_0000 to 0011_1111
            => 0100_0000 to 0111_1111
            => ...
        addr = 0111_1000
        mask & addr = 0100_0000
            => the region itself to compare
            => region will encoded permissions
            => describes 0100_0000 to 0111_1111

    How the 8 subregions are computed:
        match = 8'b0
        for i = [0..7]:
            match[i:i] = addr & (7 << shft) == i << shft;
        check match with "subregion enabled" bitmask
*/
