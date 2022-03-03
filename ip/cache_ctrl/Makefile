IPS_ROOT ?= $(shell realpath ../)

include filelist.mk
include $(IPS_ROOT)/prim/filelist.mk

EXTRA_FILES = \
	$(wildcard $(IPS_ROOT)/cache_ctrl/dv/tb/*.sv) \
	$(wildcard $(IPS_ROOT)/simlib/rtl/*.sv) \
	$(IPS_ROOT)/sky130_sram_macros/sky130_sram_1kbyte_1rw1r_32x256_8/sky130_sram_1kbyte_1rw1r_32x256_8.v \
	$(IPS_ROOT)/sky130_sram_macros/sky130_sram_2kbyte_1rw1r_32x512_8/sky130_sram_2kbyte_1rw1r_32x512_8.v

.PHONY: lint
lint:
	@verilator -sv -F $(IPS_ROOT)/../lint/filelist.f $(FILELIST) && echo "Lint OK"

.PHONY: sv2v
sv2v: lint
	@mkdir -p build
	@sv2v $(FILELIST) -w build/top.v -DSIMULATION
	@verilator -sv -lint-only --bbox-unsup -Wno-fatal lint/waiver.vlt $(EXTRA_FILES) build/top.v

TEST_NAME ?= tc1
.PHONY: tb
tb: sv2v
	@mkdir -p build/tb/$(TEST_NAME)
	@iverilog \
		-g2012 -Wno-anachronisms \
		-DSIMULATION -DCACHE_CTRL_TB \
		$(EXTRA_FILES) \
		dv/tb/$(TEST_NAME)/tb.sv \
		build/top.v -o build/tb/$(TEST_NAME)/tb.out
	@cd build/tb/$(TEST_NAME) && vvp tb.out -fst-speed
