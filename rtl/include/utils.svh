`ifndef UTILS_SVH
`define UTILS_SVH

function [31:0] sext32(input[15:0] x);
    sext32 = { {16{x[15]}}, x };
endfunction

function [31:0] bext32(input x);
    bext32 = { 32{x} };
endfunction

`endif // UTILS_SVH
