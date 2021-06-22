CURRENT_DIR	?= $(shell pwd)
IMAGE_NAME 	?= efabless/openlane:current
OPENLANE_BASIC_COMMAND = "cd /project/openlane && flow.tcl -design ./ -save_path .. -save -tag build -overwrite"

.PHONY: mount
mount:
	cd $(CURRENT_DIR) && docker run -it --rm 	\
		-v $(OPENLANE_ROOT):/openLANE_flow 		\
		-v $(CURRENT_DIR):/project				\
		-v $(PDK_ROOT):$(PDK_ROOT)				\
		-e PDK_ROOT=$(PDK_ROOT)					\
		-u $(shell id -u $(USER)):$(shell id -g $(USER)) $(IMAGE_NAME)

.PHONY: lint
lint:
	verilator -sv -lint-only top.sv -Wall -Wno-MULTITOP -Wno-DECLFILENAME -Wno-fatal

.PHONY: sv2v
sv2v: lint
	sv2v top.sv -w build/top.v
	verilator -sv -lint-only build/top.v -Wno-MULTITOP -Wno-DECLFILENAME -Wno-UNOPTFLAT -Wno-fatal

.PHONY: synth
synth: sv2v
	yosys -p "synth_ice40" build/top.v
