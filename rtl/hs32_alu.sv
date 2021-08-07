`ifdef VERILATOR_LINT
    `default_nettype none
    `include "hs32_adder.sv"
    `include "include/types.svh"
`endif

module hs32_alu #(
    parameter USE_TECHMAP = 1
) (
    input wire clk,
    input wire reset,
    input wire valid_i,

    // Input data port
    input wire [31:0] a_i,
    input wire [31:0] b_i,

    // ALU control
    input hs32_aluctl ctl_i,

    // NZCV flags
    output reg [3:0] flags_o,

    // Output data port
    output wire [31:0] out
);
    // Inputs
    wire ci;
    wire [31:0] b_xor_op0;

    // Outputs
    logic co;
    logic [31:0] r;

    // Negate b
    assign b_xor_op0 = b_i ^ { 32{ctl_i.neg} };

    // Compute carry in
    assign ci = (flags_o[1] & ctl_i.cen) ^ ctl_i.sub;
    
    // Compute sum
    wire [32:0] sum;
    generate
        if(USE_TECHMAP == 1) begin
            assign sum = { 1'b0, a_i } + { 1'b0, b_xor_op0 } + { 32'b0, ci };
        end else begin
            hs32_adder #(.WIDTH(32)) u0 (
                .A(a_i), .B(b_xor_op0),
                .CI(ci), .OUT(sum), .CO()
            );
        end
    endgenerate

    // Compute output
    assign out = r;
    wire[1:0] opr = ctl_i.opr;
    always_comb case(opr)
        2'b00: begin
            { co, r } = sum;
        end
        2'b01: begin
            co = 0;
            r = a_i & b_xor_op0;
        end
        2'b10: begin
            co = 0;
            r = a_i | b_xor_op0;
        end
        2'b11: begin
            co = 0;
            r = a_i ^ b_xor_op0;
        end
    endcase

    // Drives: flags
    always_ff @(posedge clk)
    if(reset) begin
        flags_o <= 0;
    end else if(ctl_i.fwe && valid_i) begin
        flags_o <= { r[31], ~(|r), co, (~co) & r[31] };
    end
endmodule
