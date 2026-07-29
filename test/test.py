# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge
from cocotb.triggers import ClockCycles
from cocotb.types import Logic
from cocotb.types import LogicArray

async def await_half_sclk(dut):
    """Wait for the SCLK signal to go high or low."""
    start_time = cocotb.utils.get_sim_time(units="ns")
    while True:
        await ClockCycles(dut.clk, 1)
        # Wait for half of the SCLK period (10 us)
        if (start_time + 100*100*0.5) < cocotb.utils.get_sim_time(units="ns"):
            break
    return

def ui_in_logicarray(ncs, bit, sclk):
    """Setup the ui_in value as a LogicArray."""
    return LogicArray(f"00000{ncs}{bit}{sclk}")

async def send_spi_transaction(dut, r_w, address, data):
    """
    Send an SPI transaction with format:
    - 1 bit for Read/Write
    - 7 bits for address
    - 8 bits for data
    
    Parameters:
    - r_w: boolean, True for write, False for read
    - address: int, 7-bit address (0-127)
    - data: LogicArray or int, 8-bit data
    """
    # Convert data to int if it's a LogicArray
    if isinstance(data, LogicArray):
        data_int = int(data)
    else:
        data_int = data
    # Validate inputs
    if address < 0 or address > 127:
        raise ValueError("Address must be 7-bit (0-127)")
    if data_int < 0 or data_int > 255:
        raise ValueError("Data must be 8-bit (0-255)")
    # Combine RW and address into first byte
    first_byte = (int(r_w) << 7) | address
    # Start transaction - pull CS low
    sclk = 0
    ncs = 0
    bit = 0
    # Set initial state with CS low
    dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
    await ClockCycles(dut.clk, 1)
    # Send first byte (RW + Address)
    for i in range(8):
        bit = (first_byte >> (7-i)) & 0x1
        # SCLK low, set COPI
        sclk = 0
        dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
        await await_half_sclk(dut)
        # SCLK high, keep COPI
        sclk = 1
        dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
        await await_half_sclk(dut)
    # Send second byte (Data)
    for i in range(8):
        bit = (data_int >> (7-i)) & 0x1
        # SCLK low, set COPI
        sclk = 0
        dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
        await await_half_sclk(dut)
        # SCLK high, keep COPI
        sclk = 1
        dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
        await await_half_sclk(dut)
    # End transaction - return CS high
    sclk = 0
    ncs = 1
    bit = 0
    dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
    await ClockCycles(dut.clk, 600)
    return ui_in_logicarray(ncs, bit, sclk)

@cocotb.test()
async def test_spi(dut):
    dut._log.info("Start SPI test")

    # Set the clock period to 100 ns (10 MHz)
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    ncs = 1
    bit = 0
    sclk = 0
    dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)

    dut._log.info("Test project behavior")
    dut._log.info("Write transaction, address 0x00, data 0xF0")
    ui_in_val = await send_spi_transaction(dut, 1, 0x00, 0xF0)  # Write transaction
    assert dut.uo_out.value == 0xF0, f"Expected 0xF0, got {dut.uo_out.value}"
    await ClockCycles(dut.clk, 1000) 

    dut._log.info("Write transaction, address 0x01, data 0xCC")
    ui_in_val = await send_spi_transaction(dut, 1, 0x01, 0xCC)  # Write transaction
    assert dut.uio_out.value == 0xCC, f"Expected 0xCC, got {dut.uio_out.value}"
    await ClockCycles(dut.clk, 100)

    dut._log.info("Write transaction, address 0x30 (invalid), data 0xAA")
    ui_in_val = await send_spi_transaction(dut, 1, 0x30, 0xAA)
    await ClockCycles(dut.clk, 100)

    dut._log.info("Read transaction (invalid), address 0x00, data 0xBE")
    ui_in_val = await send_spi_transaction(dut, 0, 0x30, 0xBE)
    assert dut.uo_out.value == 0xF0, f"Expected 0xF0, got {dut.uo_out.value}"
    await ClockCycles(dut.clk, 100)
    
    dut._log.info("Read transaction (invalid), address 0x41 (invalid), data 0xEF")
    ui_in_val = await send_spi_transaction(dut, 0, 0x41, 0xEF)
    await ClockCycles(dut.clk, 100)

    dut._log.info("Write transaction, address 0x02, data 0xFF")
    ui_in_val = await send_spi_transaction(dut, 1, 0x02, 0xFF)  # Write transaction
    await ClockCycles(dut.clk, 100)

    dut._log.info("Write transaction, address 0x04, data 0xCF")
    ui_in_val = await send_spi_transaction(dut, 1, 0x04, 0xCF)  # Write transaction
    await ClockCycles(dut.clk, 30000)

    dut._log.info("Write transaction, address 0x04, data 0xFF")
    ui_in_val = await send_spi_transaction(dut, 1, 0x04, 0xFF)  # Write transaction
    await ClockCycles(dut.clk, 30000)

    dut._log.info("Write transaction, address 0x04, data 0x00")
    ui_in_val = await send_spi_transaction(dut, 1, 0x04, 0x00)  # Write transaction
    await ClockCycles(dut.clk, 30000)

    dut._log.info("Write transaction, address 0x04, data 0x01")
    ui_in_val = await send_spi_transaction(dut, 1, 0x04, 0x01)  # Write transaction
    await ClockCycles(dut.clk, 30000)

    dut._log.info("SPI test completed successfully")

async def wait_for_bit_edge(dut, signal, bit, rising=True):
    #Poll one bit of a vector signal for an edge, once per clk cycle
    prev = (int(signal.value) >> bit) & 1
    while True:
        await RisingEdge(dut.clk)
        curr = (int(signal.value) >> bit) & 1
        if rising and prev == 0 and curr == 1:
            return
        if not rising and prev == 1 and curr == 0:
            return
        prev = curr
        
@cocotb.test()
async def test_pwm_freq(dut):
    # Write your test here
    # Set the clock period to 100 ns (10 MHz)
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    ncs = 1
    bit = 0
    sclk = 0
    dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)

    # output enable  
    dut._log.info("Write transaction, address 0x00, data 0x01")
    await send_spi_transaction(dut, 1, 0x00, 0x01)

    #pwm mode enable
    dut._log.info("Write transaction, address 0x02, data 0x01")
    await send_spi_transaction(dut, 1, 0x02, 0x01)

    #pwm duty cycle
    dut._log.info("Write transaction, address 0x04, data 0x80")
    await send_spi_transaction(dut, 1, 0x04, 0x80)

    # Measure period between two rising edges
    await wait_for_bit_edge(dut, dut.uo_out, 0, rising=True)
    x = cocotb.utils.get_sim_time(units="sec")
    await wait_for_bit_edge(dut, dut.uo_out, 0, rising=True)
    x1 = cocotb.utils.get_sim_time(units="sec")

    f = 1 / (x1 - x)
    dut._log.info(f"Measured frequency: {f} Hz")
    assert 2970 <= f <= 3030, f"Expected 2970-3030 Hz, got {f} Hz"

    dut._log.info("PWM Frequency test completed successfully")


@cocotb.test()
async def test_pwm_duty(dut):
    # Write your test here
    
    # Set the clock period to 100 ns (10 MHz)
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    ncs = 1
    bit = 0
    sclk = 0
    dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)


    # Enable output + PWM mode on bit 0
    await send_spi_transaction(dut, 1, 0x00, 0x01)
    await send_spi_transaction(dut, 1, 0x02, 0x01)

    # Edge case: 0x00 -> always low, never toggles, so check level not edges 
    dut._log.info("duty_cycle = 0x00 (always low)")
    await send_spi_transaction(dut, 1, 0x04, 0x00)
    await ClockCycles(dut.clk, 5000)
    bit0 = (int(dut.uo_out.value) >> 0) & 1
    assert bit0 == 0, f"Expected uo_out[0] low at duty=0x00, got {bit0}"

    # Edge case: 0xFF -> forced always high, never toggles 
    dut._log.info("duty_cycle = 0xFF (always high)")
    await send_spi_transaction(dut, 1, 0x04, 0xFF)
    await ClockCycles(dut.clk, 5000)
    bit0 = (int(dut.uo_out.value) >> 0) & 1
    assert bit0 == 1, f"Expected uo_out[0] high at duty=0xFF, got {bit0}"

    # Sweep mid-range values 
    for duty_val in [0x20, 0x40, 0x80, 0xC0, 0xE0]:
        await send_spi_transaction(dut, 1, 0x04, duty_val)
        await ClockCycles(dut.clk, 1000)  # let old duty's tail clear before measuring

        await wait_for_bit_edge(dut, dut.uo_out, 0, rising=True)
        t_rise1 = cocotb.utils.get_sim_time(units="sec")
        await wait_for_bit_edge(dut, dut.uo_out, 0, rising=False)
        t_fall = cocotb.utils.get_sim_time(units="sec")
        await wait_for_bit_edge(dut, dut.uo_out, 0, rising=True)
        t_rise2 = cocotb.utils.get_sim_time(units="sec")

        period = t_rise2 - t_rise1
        high_time = t_fall - t_rise1
        duty_measured = (high_time / period) * 100
        duty_expected = (duty_val / 256) * 100

        dut._log.info(f"duty_cycle={hex(duty_val)}: expected {duty_expected:.2f}%, measured {duty_measured:.2f}%")
        assert abs(duty_measured - duty_expected) <= 1, \
            f"duty_cycle={hex(duty_val)}: expected ~{duty_expected:.2f}%, got {duty_measured:.2f}%"

    #  Enable/PWM-mode interaction: output-enable=0 must force output low
    # regardless of PWM mode or duty cycle (enable takes precedence)
    dut._log.info("Testing output-enable=0 overrides PWM")
    await send_spi_transaction(dut, 1, 0x00, 0x00)  # disable output on bit 0
    await ClockCycles(dut.clk, 5000)
    bit0 = (int(dut.uo_out.value) >> 0) & 1
    assert bit0 == 0, f"Expected uo_out[0] low when output-enable=0, got {bit0}"

    dut._log.info("PWM Duty Cycle test completed successfully")
