# Makefile

# Defaults
SIM = verilator
EXTRA_ARGS += $(AARGS) --coverage
EXTRA_ARGS += --trace-fst --trace-structs
EXTRA_ARGS += -Wno-fatal -I$(PWD)/../../../ -I$(PWD)/../../../rtl/

# Use VHDL_SOURCES for VHDL files
TOPLEVEL_LANG = verilog
VERILOG_SOURCES += $(PWD)/../../../top.sv

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = hs32_pipeline

# MODULE is the basename of the Python test file
MODULE = tb

# Include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

clean:: myclean
myclean:
	@rm -rf __pycache__ *.dat *.fst results.xml
