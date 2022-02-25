IPS_ROOT ?= $(shell realpath ../)

include filelist.mk
include $(IPS_ROOT)/prim/filelist.mk

EXTRA_FILES = \
	dv/tb/top.sv dv/tb/power_on_reset.sv dv/tb/monitor.sv \
	$(IPS_ROOT)/sky130_sram_macros/sky130_sram_1kbyte_1rw1r_32x256_8/sky130_sram_1kbyte_1rw1r_32x256_8.v \
	$(IPS_ROOT)/sky130_sram_macros/sky130_sram_2kbyte_1rw1r_32x512_8/sky130_sram_2kbyte_1rw1r_32x512_8.v

.PHONY: sv2v
sv2v:
	@mkdir -p build
	@sv2v $(FILELIST) -w build/top.v

TEST_NAME ?= test1_read
.PHONY: tb
tb: sv2v
	@mkdir -p build/tb/$(TEST_NAME)
	@iverilog -g2012 -Wno-anachronisms \
		dv/tb/$(TEST_NAME)/tb.sv \
		$(EXTRA_FILES) \
		build/top.v -o build/tb/$(TEST_NAME)/tb.out
	@cd build/tb/$(TEST_NAME) && vvp tb.out -fst-speed
