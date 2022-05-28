package lib;
    typedef struct packed {
        logic       valid;
        logic[29:0] addr;
        logic       we;
        logic[31:0] wdat;
    } cache_pkt;

    function cache_pkt get_read_pkt(input bit[31:0] addr);
        get_read_pkt = { 1'b1, addr[29:0], 1'b0, 32'b0 };
    endfunction

    function cache_pkt get_write_pkt(input bit[31:0] addr, input bit[31:0] data);
        get_write_pkt = { 1'b1, addr[29:0], 1'b1, data };
    endfunction

    function cache_pkt get_null_pkt(input int k);
        get_null_pkt = { 1'b0, 30'b0, 1'b0, 32'b0 };
    endfunction
endpackage
