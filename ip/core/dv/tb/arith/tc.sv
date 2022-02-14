// TEST_CASES=1
`ifndef VERILATOR_LINT
localparam numinstrs =
    TEST_ID == 1 ? 5 : 0;
wire[numinstrs*32-1:0] instr;
generate
if(TEST_ID == 1) begin
    assign instr = {
        { 32'h0010_0001 },  // mov r1, 1
        { 32'h2021_FFFE },  // add r2, r1, -2
        { 32'h3022_1000 },  // add r2, r2, r1
        { 32'h2131_0001 },  // adc r3, r1, 1
        { 32'h3133_3000 }   // adc r3, r3, r3
    };
    initial begin
        @(EventOnRegWrite) check(OnRegWrite.addr == 1 && OnRegWrite.data == 1);
        @(EventOnRegWrite) check(OnRegWrite.addr == 2 && OnRegWrite.data == 32'hFFFF_FFFF);
        @(EventOnRegWrite) check(OnRegWrite.addr == 2 && OnRegWrite.data == 0);
        @(EventOnRegWrite) check(OnRegWrite.addr == 3 && OnRegWrite.data == 3);
        @(EventOnRegWrite) check(OnRegWrite.addr == 3 && OnRegWrite.data == 6);
        finish = 1;
    end
end else initial begin
    $error("%c[1;31mTest %0d not found%c[0m", 27, TEST_ID, 27);
    $finish_and_return(1);
end
endgenerate

`endif
