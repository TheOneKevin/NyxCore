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
    input   wire[3:0]   rd2_i,
    input   wire        stl2_i,
    input   wire[3:0]   rd3_i,
    input   wire        stl3_i,
    output  wire        stall_o
);
    hs32_instr op;
    assign op           = data_i;
    wire op_renc        = op.opcode[4];
    wire op_ror         = &op.enc.r.dir[1:0];
    wire[31:0] imm      = sext32(op.enc.i);
    assign rp_addr_o    = op.enc.r.rn;

    // Calculate data packet
    assign data_o.rd    = op.rd;
    assign data_o.rm    = op.rm;
    assign data_o.d2    = op_renc ? rp_data_i : imm;
    assign data_o.shl   = op.enc.r.sh;
    assign data_o.shr   = op_ror ? ~op.enc.r.sh[4:0] + 1 : op.enc.r.sh[4:0];
    assign data_o.sext  = op.enc.r.dir == 2'b10;
    assign data_o.maskl = ~op_ror;
    assign data_o.maskr = |op.enc.r.dir[1:0];
    assign data_o.opc   = { op.opcode[5], op.opcode[3:0] };

    // Calculate data stall signals
    assign data_o.fwd   = op.enc.r.rn == rd3_i && stl3_i && op_renc;
    assign stall_o      = op.enc.r.rn == rd2_i && stl2_i && op_renc;

    // Valid opcode map
    reg ud;
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
