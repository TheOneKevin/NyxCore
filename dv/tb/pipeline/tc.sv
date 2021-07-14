`ifndef VERILATOR_LINT
localparam numinstrs =
    TEST_ID == 1 ? 4 :
    TEST_ID == 2 ? 4 :
    TEST_ID == 3 ? 3 : 0;
wire[numinstrs*32-1:0] instr;
generate
if(TEST_ID == 1) begin
    assign instr = {
        { 32'h0010_0001 },  // mov r1, 1
        { 32'h0931_0000 },  // mov r3, r1
        { 32'h0020_0002 },  // mov r2, 2
        { 32'h3031_2000 }   // add r3, r1 + r2
    };
    initial begin
        @(EventOnRegWrite) `check(OnRegWrite.addr == 1 && OnRegWrite.data == 1);
        @(EventOnRegWrite) `check(OnRegWrite.addr == 3 && OnRegWrite.data == 1);
        @(EventOnRegWrite) `check(OnRegWrite.addr == 2 && OnRegWrite.data == 2);
        @(EventOnRegWrite) `check(OnRegWrite.addr == 3 && OnRegWrite.data == 3);
        finish = 1;
    end
end else if(TEST_ID == 2) begin
    assign instr = {
        { 32'h0010_0001 },  // mov r1, 1
        { 32'h0020_0002 },  // mov r2, 2
        { 32'h3031_2000 },  // add r3, r1 + r2
        { 32'h0040_0004 }   // mov r4, 4
    };
    initial begin
        @(EventOnRegWrite) assert(OnRegWrite.addr == 1 && OnRegWrite.data == 1);
        @(EventOnRegWrite) assert(OnRegWrite.addr == 2 && OnRegWrite.data == 2);
        @(EventOnRegWrite) assert(OnRegWrite.addr == 3 && OnRegWrite.data == 3);
        @(EventOnRegWrite) assert(OnRegWrite.addr == 4 && OnRegWrite.data == 4);
        finish = 1;
    end
end else if(TEST_ID == 3) begin
    assign instr = {
        { 32'h0010_0001 },  // mov r1, 1
        { 32'h0020_0002 },  // mov r2, 2
        { 32'h3032_1000 }   // add r3, r2 + r1
    };
    initial begin
        @(EventOnRegWrite) assert(OnRegWrite.addr == 1 && OnRegWrite.data == 1);
        @(EventOnRegWrite) assert(OnRegWrite.addr == 2 && OnRegWrite.data == 2);
        @(EventOnRegWrite) assert(OnRegWrite.addr == 3 && OnRegWrite.data == 3);
        finish = 1;
    end
end else initial begin
    $error("%c[1;31mTest %0d not found%c[0m", 27, TEST_ID, 27);
    $finish_and_return(1);
end
endgenerate

`endif