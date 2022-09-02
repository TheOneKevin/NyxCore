`ifdef VERILATOR_LINT
    `default_nettype none
`endif

module gear_32b_8b(
    clkin50, reset, strobe, lo16b, din,
    clkin, oe, dout
);
    input   wire        clkin50;
    input   wire        reset;
    input   wire        strobe;
    input   wire        lo16b;
    input   wire[31:0]  din;
    input   wire        clkin;
    output  wire        oe;
    output  wire[7:0]   dout;

    ////////////////////////////////////////////////////////////////////////////

    reg[15:0] r1, r2;
    reg[7:0] r3;
    reg oe1, oe2, oe3;

    assign oe = oe3;
    assign dout = r3;

    always @(posedge clkin50)
    if(reset) begin
        r1 <= 0;
    end else if(strobe) begin
        r1 <= din[31:16];
    end

    always @(posedge clkin50)
    if(reset) begin
        r2 <= 0;
    end else if(strobe) begin
        r2 <= din[15:0];
    end else begin
        r2 <= r1;
    end

    always @(posedge clkin)
    if(reset) begin
        r3 <= 0;
    end else begin
        r3 <= clkin50 && oe2 ? r2[7:0] : r2[15:8];
    end

    always @(posedge clkin50)
    if(reset) begin
        oe1 <= 0;
        oe2 <= 0;
    end else if(strobe) begin
        oe1 <= ~lo16b;
        oe2 <= 1'b1;
    end else begin
        oe1 <= 0;
        oe2 <= oe1;
    end

    always @(posedge clkin)
    if(reset) begin
        oe3 <= 0;
    end else begin
        oe3 <= oe2;
    end

endmodule
