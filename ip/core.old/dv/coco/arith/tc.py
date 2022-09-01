import cocotb
from tb import run_test

@cocotb.test()
async def test1(dut):
    await run_test(dut, [
        0x0010_0001,    # mov r1, 1
        0x2021_FFFE,    # add r2, r1, -2
        0x3022_1000,    # add r2, r2, r1
        0x2131_0001,    # adc r3, r1, 1
        0x3133_3000,    # adc r3, r3, r3
    ],{'onregwrite':[
        (1, 1), (2, 0xFFFFFFFF), (2, 0), (3, 3), (3, 6)
    ]})

@cocotb.test()
async def test2(dut):
    await run_test(dut, [
        0x0010_000F,    # mov r1, 15
        0x2221_FFFE,    # sub r2, r1, -2
        0x3220_2000,    # sub r2, r0, r2
        0x2231_000A,    # sub r3, r1, 10
        0x2331_0000,    # sbc r3, r1, 0
        0x3333_1000,    # sbc r3, r3, r1
    ],{'onregwrite':[
        (1, 15), (2, 17), (2, 0xFFFFFFEF), (3, 5), (3, 14), (3, 0xFFFFFFFE)
    ]})

@cocotb.test()
async def test3(dut):
    await run_test(dut, [
        0x0010_FFFF,    # mov r1, -1
        0x2421_7FFF,    # and r2, r1, 0x7FFF
        0x3422_1080,    # and r2, r2, r1 shl 16
        0x2531_00FF,    # bic r3, r1, 0x00FF
        0x3533_2000,    # bic r3, r3, r2
        0x2622_0012,    #  or r2, r2, 0x12
        0x3622_3078,    #  or r2, r2, r3 srx 7
        0x2722_FFFF,    # xor r2, r2, -1
        0x3722_2000,    # xor r2, r2, r2
    ],{'onregwrite':[
        (1, 0xFFFFFFFF),
        (2, 0x7FFF), (2, 0x7F00),
        (3, 0xFFFFFF00), (3, 0xFFFF8000),
        (2, 0x7F12), (2, 0xFFFFFF12),
        (2, 0xED), (2, 0)
    ]})
