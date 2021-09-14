// TEST_CASES=7
`ifndef VERILATOR_LINT
localparam numinstrs =
    TEST_ID == 1 ? 3 :
    TEST_ID == 2 ? 4 :
    TEST_ID == 3 ? 4 :
    TEST_ID == 4 ? 5 :
    TEST_ID == 5 ? 6 :
    TEST_ID == 6 ? 7 :
    TEST_ID == 7 ? 3 : 0;
wire[numinstrs*32-1:0] instr;
generate
if(TEST_ID == 1) begin
    initial $display("s1 waits s2 int");
    assign instr = {
        { 32'h0010_0003 },  // mov r1, 3
        { 32'h1120_1000 },  // mov r2, r1
        { 32'h3031_2000 }   // add r3, r1, r2
    };
    initial begin
        @(EventOnRegWrite) check(OnRegWrite.addr == 1 && OnRegWrite.data == 3);
        @(EventOnRegWrite) check(OnRegWrite.addr == 2 && OnRegWrite.data == 3);
        @(EventOnRegWrite) check(OnRegWrite.addr == 3 && OnRegWrite.data == 6);
        finish = 1;
    end
end else if(TEST_ID == 2) begin
    initial $display("s1 waits s2 mem");
    assign instr = {
        { 32'h0010_0003 },  // mov r1, 3
        { 32'h0911_0001 },  // str [r1+1], r1
        { 32'h0821_0001 },  // ldr r2, [r1+1]
        { 32'h3021_2000 }   // add r2, r1, r2
    };
    initial begin
        @(EventOnRegWrite) check(OnRegWrite.addr == 1 && OnRegWrite.data == 3);
        @(EventOnMemWrite) check(OnMemWrite.addr == 4 && OnMemWrite.data == 3);
        @(EventOnRegWrite) check(OnRegWrite.addr == 2 && OnRegWrite.data == 3);
        @(EventOnRegWrite) check(OnRegWrite.addr == 2 && OnRegWrite.data == 6);
        finish = 1;
    end
end else if(TEST_ID == 3) begin
    initial $display("s1 waits s3 int");
    assign instr = {
        { 32'h0010_0003 },  // mov r1, 3
        { 32'h1120_1000 },  // mov r2, r1
        { 32'h0010_0004 },  // mov r1, 4
        { 32'h3031_2000 }   // add r3, r1, r2
    };
    initial begin
        @(EventOnRegWrite) check(OnRegWrite.addr == 1 && OnRegWrite.data == 3);
        @(EventOnRegWrite) check(OnRegWrite.addr == 2 && OnRegWrite.data == 3);
        @(EventOnRegWrite) check(OnRegWrite.addr == 1 && OnRegWrite.data == 4);
        @(EventOnRegWrite) check(OnRegWrite.addr == 3 && OnRegWrite.data == 7);
        finish = 1;
    end
end else if(TEST_ID == 4) begin
    initial $display("s1 waits s3 mem");
    assign instr = {
        { 32'h0010_0003 },  // mov r1, 3
        { 32'h0911_0001 },  // str [r1+1], r1
        { 32'h0821_0001 },  // ldr r2, [r1+1]
        { 32'h0010_0004 },  // mov r1, 4
        { 32'h3031_2000 }   // add r3, r1, r2
    };
    initial begin
        @(EventOnRegWrite) check(OnRegWrite.addr == 1 && OnRegWrite.data == 3);
        @(EventOnMemWrite) check(OnMemWrite.addr == 4 && OnMemWrite.data == 3);
        @(EventOnRegWrite) check(OnRegWrite.addr == 2 && OnRegWrite.data == 3);
        @(EventOnRegWrite) check(OnRegWrite.addr == 1 && OnRegWrite.data == 4);
        @(EventOnRegWrite) check(OnRegWrite.addr == 3 && OnRegWrite.data == 7);
        finish = 1;
    end
end else if(TEST_ID == 5) begin
    initial $display("s1 waits l1 mem");
    assign instr = {
        { 32'h0010_0003 },  // mov r1, 3
        { 32'h0911_0001 },  // str [r1+1], r1
        { 32'h0821_0001 },  // ldr r2, [r1+1]
        { 32'h0010_0004 },  // mov r1, 4
        { 32'h0010_0005 },  // mov r1, 5
        { 32'h3031_2000 }   // add r3, r1, r2
    };
    initial begin
        @(EventOnRegWrite) check(OnRegWrite.addr == 1 && OnRegWrite.data == 3);
        @(EventOnMemWrite) check(OnMemWrite.addr == 4 && OnMemWrite.data == 3);
        @(EventOnRegWrite) check(OnRegWrite.addr == 2 && OnRegWrite.data == 3);
        @(EventOnRegWrite) check(OnRegWrite.addr == 1 && OnRegWrite.data == 4);
        @(EventOnRegWrite) check(OnRegWrite.addr == 1 && OnRegWrite.data == 5);
        @(EventOnRegWrite) check(OnRegWrite.addr == 3 && OnRegWrite.data == 8);
        finish = 1;
    end
end else if(TEST_ID == 6) begin
    initial $display("s1 waits l2 mem");
    assign instr = {
        { 32'h0010_0003 },  // mov r1, 3
        { 32'h0911_0001 },  // str [r1+1], r1
        { 32'h0821_0001 },  // ldr r2, [r1+1]
        { 32'h0010_0004 },  // mov r1, 4
        { 32'h0010_0005 },  // mov r1, 5
        { 32'h0010_0006 },  // mov r1, 6
        { 32'h3031_2000 }   // add r3, r1, r2
    };
    initial begin
        @(EventOnRegWrite) check(OnRegWrite.addr == 1 && OnRegWrite.data == 3);
        @(EventOnMemWrite) check(OnMemWrite.addr == 4 && OnMemWrite.data == 3);
        @(EventOnRegWrite) check(OnRegWrite.addr == 2 && OnRegWrite.data == 3);
        @(EventOnRegWrite) check(OnRegWrite.addr == 1 && OnRegWrite.data == 4);
        @(EventOnRegWrite) check(OnRegWrite.addr == 1 && OnRegWrite.data == 5);
        @(EventOnRegWrite) check(OnRegWrite.addr == 1 && OnRegWrite.data == 6);
        @(EventOnRegWrite) check(OnRegWrite.addr == 3 && OnRegWrite.data == 9);
        finish = 1;
    end
end else if(TEST_ID == 7) begin
    initial $display("s2 waits s3 int");
    assign instr = {
        { 32'h0010_0003 },  // mov r1, 3
        { 32'h1120_1000 },  // mov r2, r1
        { 32'h3022_1000 }   // add r2, r2, r1
    };
    initial begin
        @(EventOnRegWrite) check(OnRegWrite.addr == 1 && OnRegWrite.data == 3);
        @(EventOnRegWrite) check(OnRegWrite.addr == 2 && OnRegWrite.data == 3);
        @(EventOnRegWrite) check(OnRegWrite.addr == 2 && OnRegWrite.data == 6);
        finish = 1;
    end
end else initial begin
    $error("%c[1;31mTest %0d not found%c[0m", 27, TEST_ID, 27);
    $finish_and_return(1);
end
endgenerate

`endif
