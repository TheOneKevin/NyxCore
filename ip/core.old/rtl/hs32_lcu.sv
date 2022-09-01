`ifdef VERILATOR_LINT
    `default_nettype none
`endif

// Adapted from YOSYS techlibs/common/techmap.v
module lcu (P, G, CI, CO);
    parameter WIDTH = 2;
    
    input wire [WIDTH-1:0] P, G;
    input wire CI;
    output wire [WIDTH-1:0] CO;

    integer i, j;
    reg [WIDTH-1:0] p, g;

    always @(*) begin
        p = P;
        g = G;

        // in almost all cases CI will be constant zero
        g[0] = g[0] | (p[0] & CI);

        // [[CITE]] Brent Kung Adder
        // R. P. Brent and H. T. Kung, "A Regular Layout for Parallel Adders",
        // IEEE Transaction on Computers, Vol. C-31, No. 3, p. 260-264, March, 1982

        // Main tree
        for (i = 1; i <= $clog2(WIDTH); i = i+1) begin
            for (j = 2**i - 1; j < WIDTH; j = j + 2**i) begin
                g[j] = g[j] | p[j] & g[j - 2**(i-1)];
                p[j] = p[j] & p[j - 2**(i-1)];
            end
        end

        // Inverse tree
        for (i = $clog2(WIDTH); i > 0; i = i-1) begin
            for (j = 2**i + 2**(i-1) - 1; j < WIDTH; j = j + 2**i) begin
                g[j] = g[j] | p[j] & g[j - 2**(i-1)];
                p[j] = p[j] & p[j - 2**(i-1)];
            end
        end
    end

    assign CO = g;
endmodule
