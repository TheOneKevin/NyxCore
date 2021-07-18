import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ReadWrite, RisingEdge, Timer

# Import library
import sys
sys.path.append('../')
import lib

# Parameter definitions
clkperiod = 10
rstcycles = 3
simcycles = 20

# Drive pipeline inputs
async def drive_inst(dut, instrs):
    dut.valid_i <= 0
    await RisingEdge(dut.reset or dut.clk)
    i = 0
    while i < len(instrs):
        # Sequential logic
        dut.op_i <= instrs[i]
        if (not dut.reset.value) and dut.ready_o.value:
            dut._log.info("IP = %d"%(i))
            i += 1
        await RisingEdge(dut.clk)
        # Combinational logic
        await ReadWrite()
        dut.valid_i = (not dut.reset.value) and dut.ready_o.value
    dut.valid_i <= 0
    dut.op_i <= 0

# OnRegWrite
async def event_onregwrite(dut, expect):
    while dut.reset.value or not (dut.regfile.wp1_we1_i.value or dut.regfile.wp1_we2_i.value):
        await RisingEdge(dut.clk)
    dut._log.info("Write r%d = %08X"%(dut.regfile.wp1_addr_i.value,dut.regfile.wp1_data_i.value))
    if expect is None: return
    assert(expect[0] == dut.regfile.wp1_addr_i.value and expect[1] == dut.regfile.wp1_data_i.value)

event_list = { 'onregwrite': event_onregwrite }

# Run a list of instructions through the pipeline
async def run_test(dut, instrs, expects = None):
    dut.banksel_i <= 0
    dut.ready_i <= 1
    # Clock and reset
    dut._log.info("Starting simulation")
    cocotb.fork(lib.drive_reset(dut, clkperiod, rstcycles))
    cocotb.fork(Clock(dut.clk, clkperiod, 'ns').start())
    # Monitor simulation
    cocotb.fork(lib.monitor(dut, event_list, expects))
    cocotb.fork(drive_inst(dut, instrs))
    await Timer(simcycles*clkperiod, units="ns")
    # Check expects
    lib.check_expects(dut, expects)
