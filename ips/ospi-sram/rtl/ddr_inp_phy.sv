module ddr_inp_phy (
    input   wire        clk,
    input   wire        reset,
    output  reg[7:0]    dp_i,
    output  reg[7:0]    dn_i,
    input   wire[7:0]   pad_i
);
    always_ff @(posedge clk)
    if(reset) begin
        dp_i <= 8'b0;
    end else begin
        dp_i <= pad_i;
    end

    always_ff @(negedge clk)
    if(reset) begin
        dn_i <= 8'b0;
    end else begin
        dn_i <= pad_i;
    end
endmodule
