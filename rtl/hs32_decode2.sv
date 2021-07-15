`ifdef VERILATOR_LINT
    `default_nettype none
    `include "hs32_primitives.sv"
    `include "include/utils.svh"
    `include "include/types.svh"
`endif

module hs32_decode2 (
    // Regfile read port
    output  wire[3:0]   rp_addr_o,
    input   wire[31:0]  rp_data_i,

    // Pipeline data packets
    input   hs32_s1pkt  data_i,
    output  hs32_s2pkt  data_o,
    input   hs32_s3pkt  fwd_i,

    // Pipeline controls
    output  wire[3:0]   rd2_o,
    input   wire[3:0]   rd3_i,
    input   wire        stl3_i,
    output  wire        stall_o
);
    wire[31:0] shr_out;
    assign rp_addr_o = data_i.rm;

    logic op_isalu = data_i[4];
    logic op_issub = op_isalu & ~data_i.opc[2] & data_i.opc[1];
    logic op_iscen = op_isalu & ~data_i.opc[2] & data_i.opc[0];
    logic op_isbic = op_isalu & data_i.opc[2:0] == 3'b101;
    logic op_ismov = data_i.opc[4:2] == 3'b000;

    // Forwarded data
    logic[31:0] d2 = data_i.fwd ? fwd_i.res : data_i.d2;

    // Calculate data packet
    assign data_o.d1        = rp_data_i & bext32(~op_ismov);
    assign data_o.d2        =
        (shr_out & bext32(data_i.maskr)) |
        ((d2 << data_i.shl) & bext32(data_i.maskl));
    assign data_o.we1       = 1'b1;
    assign data_o.we2       = 1'b0;
    assign data_o.rd        = data_i.rd;

    // Calculate data stall signals
    assign rd2_o            = data_i.rd;
    assign data_o.fwd       = (rd3_i == data_i.rm) && stl3_i;
    assign stall_o          = 1'b0;

    // Compute ALU controls
    hs32_aluctl ctl;
    logic[1:0] opr;
    wire[2:0] opc = data_i.opc[2:0];
    assign ctl.neg          = op_isbic | op_issub;
    assign ctl.sub          = op_issub;
    assign ctl.cen          = op_iscen;
    assign ctl.opr          = opr & {2{op_ismov}};
    assign ctl.fwe          = data_i.opc[4];
    assign data_o.ctl       = ctl;
    always_comb casez(opc)
        3'b0??: opr = 0;
        3'b10?: opr = 1;
        3'b110: opr = 2;
        3'b111: opr = 3;
    endcase

    // Arithmetic/right shift hybrid
    shift_right #(.WIDTH(32), .DEPTH(5)) u0 (
        .a(d2),
        .b(data_i.shr),
        .c(data_i.sext & d2[31]),
        .out(shr_out)
    );
endmodule
