`ifndef TYPES_SVH
`define TYPES_SVH

typedef struct packed {
    logic[3:0] rn;
    logic[4:0] sh;
    logic[1:0] dir;
    logic[1:0] bank;
    logic[2:0] reserved;
} hs32_enc_r;

typedef struct packed {
    logic[1:0] reserved;
    logic[5:0] opcode;
    logic[3:0] rd;
    logic[3:0] rm;
    union packed {
        logic[15:0] i;
        hs32_enc_r r;
    } enc;
} hs32_instr;

typedef struct packed {
    logic fwe;          // Flag write enable
    logic neg;          // Negate b
    logic sub;          // Subtract
    logic cen;          // Carry enable
    logic[1:0] opr;     // Operation
} hs32_aluctl;

typedef struct packed {
    logic[3:0] rd;      // rd address
    logic[3:0] rm;      // rm address
    logic[31:0] d2;     // Data bus 2
    logic[4:0] shl;     // Left shift
    logic[4:0] shr;     // Right shift/rotate right
    logic sext;         // Arithmetic shift
    logic maskl;        // Mask left shift when 0
    logic maskr;        // Mask right shift when 0
    logic[4:0] opc;     // Opcode without MSB
    logic fwd;
} hs32_s1pkt;

typedef struct packed {
    logic[31:0] d1;     // Data bus 1
    logic[31:0] d2;     // Data bus 2
    logic[5:0] ctl;     // ALU controls
    logic we1;          // Write enable
    logic we2;          //
    logic[3:0] rd;      // rd address (passthrough)
    logic fwd;
} hs32_s2pkt;

typedef struct packed {
    logic[31:0] res;    // Result for pipeline forwarding
} hs32_s3pkt;

`endif // TYPES_SVH
