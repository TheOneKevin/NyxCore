CURRENT_DIR	:= $(shell pwd)
IMAGE_NAME := efabless/openlane:2021.10.25_20.35.00
OPENLANE_BASIC_COMMAND := "cd /project/openlane && flow.tcl -design ./ -save_path .. -save -tag build -overwrite"

.PHONY: mount
mount:
	cd $(CURRENT_DIR) && docker run -it --rm	\
		-v $(OPENLANE_ROOT):/openLANE_flow		\
		-v $(CURRENT_DIR):/project				\
		-v $(PDK_ROOT):$(PDK_ROOT)				\
		-e PDK_ROOT=$(PDK_ROOT)					\
		-u $(shell id -u $(USER)):$(shell id -g $(USER)) $(IMAGE_NAME)

.PHONY: lint
lint:
ifneq ($(NO_LINT),1)
	verilator -sv -Irtl -lint-only -Wall -Wno-fatal -Wno-context lint/waiver.vlt top.sv
endif

.PHONY: sv2v
sv2v: lint
	sv2v top.sv -w build/top.v -Irtl
	verilator -sv -lint-only -Wno-fatal lint/waiver.vlt build/top.v

.PHONY: synth
synth: sv2v
	yosys -p "synth_ice40" build/top.v

.PHONY: tb
tb: sv2v
	mkdir -p build/tb/$(TEST_NAME)
	iverilog -g2012 -Wno-anachronisms -P top.TEST_ID=$(TEST_ID) \
		rtl/include/types.svh \
		dv/tb/$(TEST_NAME)/tb.sv \
		build/top.v -o build/tb/$(TEST_NAME)/tb.out
	cd build/tb/$(TEST_NAME) && vvp tb.out -fst-speed
