`ifndef AMBA3_SVH
`define AMBA3_SVH

`define HTRANS_IDLE     2'b00
`define HTRANS_BUSY     2'b01
`define HTRANS_NOSEQ    2'b10
`define HTRANS_SEQ      2'b11

`define HBURST_SINGLE   3'b000
`define HBURST_INCR     3'b001
`define HBURST_WRAP4    3'b010
`define HBURST_INCR4    3'b011
`define HBURST_WRAP8    3'b100
`define HBURST_INCR8    3'b101
`define HBURST_WRAP16   3'b110
`define HBURST_INCR16   3'b111

`define HPROT_CACHEABLE  4'b1000
`define HPROT_BUFFERABLE 4'b0100   
`define HPROT_PRIVILEGED 4'b0010
`define HPROT_DATA       4'b0001

`endif
