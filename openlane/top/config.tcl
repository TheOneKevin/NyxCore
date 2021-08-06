set script_dir [file dirname [file normalize [info script]]]

set ::env(DESIGN_NAME) hs32_pipeline
set ::env(STD_CELL_LIBRARY) sky130_fd_sc_hd

set ::env(VERILOG_FILES) "$script_dir/../../build/top.v"

set ::env(RUN_KLAYOUT_XOR) 0

set ::env(SYNTH_MAX_FANOUT) 8
set ::env(SYNTH_STRATEGY) "DELAY 3"
set ::env(ROUTING_CORES) 6

set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_NET) "clk"
set ::env(CLOCK_PERIOD) "9.09"

set ::env(FP_SIZING) absolute
set ::env(FP_CORE_UTIL) 70
set ::env(PL_TARGET_DENSITY) 0.3
set ::env(PL_TIME_DRIVEN) 1
set ::env(DIE_AREA) "0 0 500 500"
set ::env(DESIGN_IS_CORE) 0

set ::env(SYNTH_BUFFERING) 1
set ::env(SYNTH_SIZING) 0

# We don't care about pin delays
set ::env(IO_PCT) 0.1

set ::env(VDD_NETS) [list {vccd1} {vccd2} {vdda1} {vdda2}]
set ::env(GND_NETS) [list {vssd1} {vssd2} {vssa1} {vssa2}]

# set ::env(FP_PIN_ORDER_CFG) $script_dir/pin_order.cfg

set ::env(PL_BASIC_PLACEMENT) 0
set ::env(PL_OPENPHYSYN_OPTIMIZATIONS) 1

# If you're going to use multiple power domains, then keep this disabled.
set ::env(RUN_CVC) 0