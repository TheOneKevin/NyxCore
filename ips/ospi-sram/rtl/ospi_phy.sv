module opsi_phy #(
    
) (
    input wire clk,
    input wire reset,

    //
    

    // DQS/DQM
    input   wire        dqs_i,
    output  wire        dm_o,

    // DDR I/O
    input   wire[7:0]   dp_i,
    input   wire[7:0]   dn_i,
    output  wire[7:0]   dp_o,
    output  wire[7:0]   dn_o,

    // Output enable control (active low)
    output  wire        oeb_o
);
    reg[7:0] inst;
    reg[31:0] addr;


endmodule