`ifdef VERILATOR_LINT
    `default_nettype none
`endif

module tb();

    logic clkin, reset, reset_gate;
    initial reset_gate = 0;
    tb_por #(10, 4) por (.clk(clkin), .reset, .reset_gate);

    logic clkin50;
    initial clkin50 = 0;
    always @(posedge clkin) clkin50 <= ~clkin50;

    initial begin
        $dumpfile({ "dump.fst" });
    	$dumpvars(0, tb);
    end

    logic strobe;
    logic lo16b;
    logic oe;
    logic[31:0] din;
    logic[7:0] dout;

    initial lo16b = 0;
    initial strobe = 0;

    gear_32b_8b dut(.*);

    initial begin
        @(negedge reset);
        @(posedge clkin50) begin
            strobe <= 1;
            din <= 32'hAABBCCDD;
        end
        @(posedge clkin50) begin
            strobe <= 0;
            din <= 32'hx;
        end
        @(posedge clkin50) begin
            strobe <= 1;
            din <= 32'h11223344;
        end
        @(posedge clkin50) begin
            strobe <= 0;
            din <= 32'hx;
        end
        @(posedge clkin50) begin
            strobe <= 1;
            lo16b <= 1;
            din <= 32'h33445566;
        end
        @(posedge clkin50) begin
            strobe <= 0;
            lo16b <= 0;
            din <= 32'hx;
        end
        repeat (4) @(posedge clkin50);
        $finish();
    end

endmodule
