`ifndef VERILATOR_LINT
localparam numpackets =
    TEST_ID == 1 ? 3 :
    TEST_ID == 2 ? 4 : 0;
wire[numpackets*$bits(curpkt)-1:0] packets;
generate
if(TEST_ID == 1) begin
    assign packets = {
        { 1'b1, 1'b1, { 4'h1, 32'hA, 32'hAA, 1'b1, 1'b1 } },
        { 1'b1, 1'b1, { 4'h2, 32'hB, 32'hBB, 1'b1, 1'b1 } },
        { 1'b1, 1'b0, 70'b0 }
    };
    initial begin
        finish = 1;
    end
end if(TEST_ID == 2) begin
    assign packets = {
        { 1'b1, 1'b1, { 4'h1, 32'hA, 32'hAA, 1'b1, 1'b1 } },
        { 1'b0, 1'b1, { 4'h1, 32'hA, 32'hAA, 1'b1, 1'b1 } },
        { 1'b1, 1'b1, { 4'h2, 32'hB, 32'hBB, 1'b1, 1'b1 } },
        { 1'b1, 1'b0, 70'b0 }
    };
    initial begin
        finish = 1;
    end
end else initial begin
    $error("%c[1;31mTest %0d not found%c[0m", 27, TEST_ID, 27);
    $finish_and_return(1);
end
endgenerate

`endif