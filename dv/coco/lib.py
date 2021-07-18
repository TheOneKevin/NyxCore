# Power On Reset
import cocotb
from cocotb.triggers import Combine, Join, RisingEdge, Timer

async def drive_reset(dut, clkperiod, rstcycles):
    dut.reset <= 1
    await Timer(rstcycles*clkperiod, units="ns")
    await RisingEdge(dut.clk)
    dut.reset <= 0
    dut._log.info("Reset done")

# Monitor a list of async functions
async def monitor(dut, triggers, expects = None):
    async def fire(f, k):
        arr = expects.get(k, None) if expects else []
        item = arr[0] if len(arr) > 0 else None
        await f(dut, item)
        if len(arr) > 0: arr.pop(0)
    def get_triggers():
        return Combine(*[
            Join(cocotb.fork(fire(v, k)))
        for k,v in triggers.items() ])
    
    await get_triggers()
    await RisingEdge(dut.clk)
    while True:
        await get_triggers()
        await RisingEdge(dut.clk)

def check_expects(dut, expects):
    if expects:
        for _,v in expects.items():
            assert(len(v if v else []) == 0)
    else:
        dut._log.warning("No expects specified")
