`ifdef VERILATOR_LINT
    `default_nettype none
`endif

module prim_stall (
    input   logic stall_i,
    output  logic urdy_o,
    input   logic uvld_i,
    input   logic drdy_i,
    output  logic dvld_o
);
    assign dvld_o = uvld_i & !stall_i;
    assign urdy_o = drdy_i & !stall_i;
endmodule
