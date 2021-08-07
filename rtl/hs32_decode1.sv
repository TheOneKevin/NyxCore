`ifdef VERILATOR_LINT
    `default_nettype none
    `include "include/utils.svh"
    `include "include/types.svh"
`endif

module hs32_decode1 (
    // Regfile read port
    output  wire[3:0]   rp_addr_o,
    input   wire[31:0]  rp_data_i,

    // Pipeline data packets
    input   hs32_instr  data_i,
    output  hs32_s1pkt  data_o,

    // Pipeline controls
    input   hs32_stall  s2_i,
    input   hs32_stall  s3_i,
    input   hs32_stall  l1_i,
    input   hs32_stall  l2_i,
    output  wire        stall_o
);
    hs32_instr op;
    assign op           = data_i;
    wire[4:0] opc       = { op.opcode[5], op.opcode[3:0] };
    assign rp_addr_o    = op.enc.r.rn;
    wire[31:0] imm      = sext32(op.enc.i);
    wire op_renc        = op.opcode[4];
    wire op_ror         = &op.enc.r.dir[1:0];

    // Calculate data packet
    assign data_o.rd    = op.rd;
    assign data_o.rm    = op.rm;
    assign data_o.d2    = op_renc ? rp_data_i : imm;
    assign data_o.shl   = op_renc ? op.enc.r.sh : 0;
    assign data_o.shr   = op_renc ? op_ror ? ~op.enc.r.sh[4:0] + 1 : op.enc.r.sh[4:0] : 0;
    assign data_o.sext  = op.enc.r.dir == 2'b10;
    assign data_o.maskl = op_renc ? ~op_ror : 1'b1;
    assign data_o.maskr = op_renc ? |op.enc.r.dir[1:0] : 1'b0;
    assign data_o.opc   = opc;

    // Calculate data stall signals
    assign data_o.fwd   = op.enc.r.rn == s3_i.rd && s3_i.vld && op_renc && !s3_i.lsu;
    assign stall_o      = op.enc.r.rn == s2_i.rd && s2_i.vld && op_renc ||
                          op.enc.r.rn == s3_i.rd && s3_i.vld && op_renc && s3_i.lsu ||
                          op.enc.r.rn == l1_i.rd && l1_i.vld && op_renc ||
                          op.enc.r.rn == l2_i.rd && l2_i.vld && op_renc;

    // Valid opcode map
    reg ud;
    assign data_o.xud   = ud;
    always_comb casez(op.opcode)
        6'b0?_10??,
        6'b00_000?,
        6'b1?_0???,
        6'b1?_1010,
        6'b1?_1100: ud = 0;
        6'b01_00??: ud = op.opcode == 6'b01_0000;
        default: ud = 1;
    endcase
endmodule
