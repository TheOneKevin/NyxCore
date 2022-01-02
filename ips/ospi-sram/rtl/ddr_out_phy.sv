module ddr_out_phy (
    input   wire        clk,
    input   wire        reset,
    input   wire[7:0]   dp_i,
    input   wire[7:0]   dn_i,
    output  wire[7:0]   pad_o
);
    // Modified dual edge FF design
    reg[7:0] r1, r2, rn;
    assign pad_o = rn ^ r1;

    always_ff @(posedge clk)
    if(reset) begin
        r1 <= 8'b0;
    end else begin
        r1 <= dp_i ^ rn;
    end

    always_ff @(posedge clk)
    if(reset) begin
        r2 <= 8'b0;
    end else begin
        r2 <= dn_i ^ dp_i ^ rn;
    end

    always_ff @(negedge clk)
    if(reset) begin
        rn <= 8'b0;
    end else begin
        rn <= r2;
    end
endmodule
