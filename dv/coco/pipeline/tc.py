import cocotb
from tb import run_test

@cocotb.test()
async def test1(dut):
    await run_test(dut, [
        0x0010_0001,    # mov r1, 1
        0x0931_0000,    # mov r3, r1
        0x0020_0002,    # mov r2, 2
        0x3031_2000,    # add r3, r1 + r2
    ],{'onregwrite':[
        (1, 1), (3, 1), (2, 2), (3, 3)
    ]})

@cocotb.test()
async def test2(dut):
    await run_test(dut, [
        0x0010_0001,    # mov r1, 1
        0x0020_0002,    # mov r2, 2
        0x3031_2000,    # add r3, r1 + r2
        0x0040_0004,    # mov r4, 4
    ],{'onregwrite':[
        (1, 1), (2, 2), (3, 3), (4, 4)
    ]})

@cocotb.test()
async def test3(dut):
    await run_test(dut, [
        0x0010_0001,    # mov r1, 1
        0x0020_0002,    # mov r2, 2
        0x3032_1000,    # add r3, r2 + r1
    ],{'onregwrite':[
        (1, 1), (2, 2), (3, 3)
    ]})
