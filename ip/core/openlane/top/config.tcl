# ./flow.tcl -design /project/openlane/top/ -tag run -overwrite

set script_dir [file dirname [file normalize [info script]]]

set ::env(DESIGN_NAME) hs32_pipeline
set ::env(STD_CELL_LIBRARY) sky130_fd_sc_hd

set ::env(VERILOG_FILES) "$script_dir/../../build/top.v"

set ::env(GLB_RT_MAXLAYER) 5
set ::env(RUN_KLAYOUT_XOR) 0

set ::env(SYNTH_MAX_FANOUT) 8
set ::env(SYNTH_STRATEGY) "DELAY 3"
set ::env(SYNTH_DRIVING_CELL) "sky130_fd_sc_hd__inv_8"
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

set ::env(VDD_NETS) [list {vccd1}]
set ::env(GND_NETS) [list {vssd1}]

# set ::env(FP_PIN_ORDER_CFG) $script_dir/pin_order.cfg

set ::env(PL_BASIC_PLACEMENT) 0
set ::env(PL_OPENPHYSYN_OPTIMIZATIONS) 1

# If you're going to use multiple power domains, then keep this disabled.
set ::env(RUN_CVC) 1
