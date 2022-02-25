module cache_ctrl_fsm #(
    parameter ADDR_WIDTH = 32
) (
    input wire clk,
    input wire reset,

    output logic dpipe_urdy_o,
    input wire dpipe_uvld_i,
    input wire dpipe_hit_i,
    input wire[ADDR_WIDTH-1:0] dpipe_addr_i,

    input wire ipipe_urdy_o,
    input wire ipipe_uvld_i,
    input wire ipipe_hit_i,
    input wire[ADDR_WIDTH-1:0] ipipe_addr_i
);
    // TODO: This is a purely BFM of the FSM
    always @(posedge clk)
    if(reset) dpipe_urdy_o <= 1'b0;
    else begin
        if(dpipe_uvld_i & !dpipe_hit_i) begin
            dpipe_urdy_o <= 1'b0;
            $display($time, " DPIPE cache miss at addr %X", dpipe_addr_i);
        end else begin
            dpipe_urdy_o <= 1'b1;
        end
    end
endmodule
