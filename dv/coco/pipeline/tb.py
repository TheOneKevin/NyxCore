import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Combine, Join, ReadWrite, RisingEdge, Timer

clkperiod = 10
rstcycles = 3
simcycles = 20

# Power On Reset
async def drive_reset(dut):
    dut.reset <= 1
    await Timer(rstcycles*clkperiod, units="ns")
    await RisingEdge(dut.clk)
    dut.reset <= 0
    dut._log.info("Reset done")

# Monitor a list of async functions
async def monitor(dut, triggers):
    def get_triggers():
        return Combine(*[ Join(cocotb.fork(f(dut))) for f in triggers ])
    await get_triggers()
    await RisingEdge(dut.clk)
    while True:
        await get_triggers()
        await RisingEdge(dut.clk)

# Run a list of instructions through the pipeline
async def run_test(dut, instrs):
    # OnRegWrite
    async def event_onregwrite(dut):
        while dut.reset.value or not (dut.regfile.wp1_we1_i.value or dut.regfile.wp1_we2_i.value):
            await RisingEdge(dut.clk)
        dut._log.info("Write r%d = %08X"%(dut.regfile.wp1_addr_i.value,dut.regfile.wp1_data_i.value))
    
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

    # Constant assignments
    dut.banksel_i <= 0
    dut.ready_i <= 1

    # Clock and reset
    dut._log.info("Starting simulation")
    cocotb.fork(drive_reset(dut))
    cocotb.fork(Clock(dut.clk, clkperiod, 'ns').start())
    
    # Monitor simulation
    cocotb.fork(monitor(dut, [ event_onregwrite ]))

    # Queue instructions
    cocotb.fork(drive_inst(dut, instrs))

    # Wait for simulation to complete
    await Timer(simcycles*clkperiod, units="ns")

@cocotb.test()
async def test1(dut):
    await run_test(dut, [
        0x0010_0001,    # mov r1, 1
        0x0931_0000,    # mov r3, r1
        0x0020_0002,    # mov r2, 2
        0x3031_2000,    # add r3, r1 + r2
    ])

@cocotb.test()
async def test2(dut):
    await run_test(dut, [
        0x0010_0001,    # mov r1, 1
        0x0020_0002,    # mov r2, 2
        0x3031_2000,    # add r3, r1 + r2
        0x0040_0004,    # mov r4, 4
    ])

@cocotb.test()
async def test3(dut):
    await run_test(dut, [
        0x0010_0001,    # mov r1, 1
        0x0020_0002,    # mov r2, 2
        0x3032_1000,    # add r3, r2 + r1
    ])
