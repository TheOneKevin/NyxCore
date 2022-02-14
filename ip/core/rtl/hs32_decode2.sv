`ifdef VERILATOR_LINT
    `default_nettype none
    `include "include/utils.svh"
    `include "include/types.svh"
    `include "primitives/shift_right.svh"
`endif

module hs32_decode2 (
    input   wire        valid_i,

    // Regfile read port
    output  wire[3:0]   rp_addr_o,
    input   wire[31:0]  rp_data_i,

    // Pipeline data packets
    input   hs32_s1pkt  data_i,
    output  hs32_s2pkt  data_o,
    input   wire[31:0]  fwd_i,

    // Pipeline controls
    output  hs32_stall  s2_o,
    input   hs32_stall  s3_i,
    input   hs32_stall  l1_i,
    input   hs32_stall  l2_i,
    output  wire        stall_o
);
    wire[31:0] shr_out;
    assign rp_addr_o = data_i.rm;

    // Opcode decode
    wire op_isalu = data_i.opc[4];
    wire op_issub = op_isalu & ~data_i.opc[2] & data_i.opc[1];
    wire op_iscen = op_isalu & ~data_i.opc[2] & data_i.opc[0];
    wire op_isbic = op_isalu & data_i.opc[2:0] == 3'b101;
    wire op_ismov = data_i.opc[4:2] == 3'b000;
    wire op_isldr = data_i.opc == 5'b01000;
    wire op_isstr = data_i.opc == 5'b01001;
    wire op_islsu = op_isldr || op_isstr;

    // Forwarded data
    wire[31:0] d2 = data_i.fwd ? fwd_i : data_i.d2;
    
    // Calculate data packet
    assign data_o.d1        = rp_data_i & bext32(~op_ismov);    // clear d1 if is move
    assign data_o.d2        =                                   // compute d2 shifts
        (shr_out & bext32(data_i.maskr)) |
        ((d2 << data_i.shl) & bext32(data_i.maskl));
    assign data_o.we1       = !op_islsu;
    assign data_o.we2       = 1'b0;
    assign data_o.rd        = data_i.rd;
    assign data_o.xud       = data_i.xud;
    assign data_o.isldr     = op_isldr;
    assign data_o.isstr     = op_isstr;

    // Calculate data stall signals
    wire stall_rn3          = s3_i.vld && data_i.rm == s3_i.rd && !s3_i.lsu;
    wire stall_rn3_lsu      = s3_i.vld && data_i.rm == s3_i.rd &&  s3_i.lsu;
    wire stall_l1           = l1_i.vld && data_i.rm == l1_i.rd;
    wire stall_l2           = l2_i.vld && data_i.rm == l2_i.rd;
    assign data_o.fwd       = stall_rn3;
    assign data_o.fwd2      = data_i.fwd2;
    assign stall_o          = stall_rn3_lsu || stall_l1 || stall_l2;

    assign s2_o.rd          = data_i.rd;
    assign s2_o.vld         = valid_i && !op_isstr;
    assign s2_o.lsu         = !op_islsu && (|data_i.shl) == 1'b0 && (|data_i.shr) == 1'b0;
    
    // Compute ALU controls
    hs32_aluctl ctl;
    reg[1:0] opr;
    wire[2:0] opc = data_i.opc[2:0];
    assign ctl.neg          = op_isbic | op_issub;              // negation happens on bic/sub
    assign ctl.sub          = op_issub;                         // special sub flag
    assign ctl.cen          = op_iscen;                         // carry-in enable
    assign ctl.opr          = opr & ~{2{op_ismov | op_islsu}};  // opr is add (0) for mov/lsu
    assign ctl.fwe          = data_i.opc[4];                    // flag write enable
    assign data_o.ctl       = ctl;

    // Compute opc from opr where op_isalu is set
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
