## How it works

This project involves a SPI-controlled PWM peripheral. The design operates at 10 MHz and uses SPI communication at 100 KHz to configure control registers. These registers feed a PWM Peripheral, which generates a ~3 kHz waveform and drives each of the 16 output bits independently: output-enable=0 forces that bit low, enable=1 with PWM off holds it static high, and enable=1 with PWM on makes it follow the shared PWM signal at the configured duty cycle.


## How to test

To test my project, I use cocotb testbenches. `test_spi` drives SPI write transactions (valid and invalid addresses, valid and invalid R/W bits) and checks that `uo_out`/`uio_out` reflect the correct register state. `test_pwm_freq` and `test_pwm_duty` configure output/PWM enable and a duty cycle over SPI, then measure the resulting waveform directly on the output pins catching consecutive edges to compute period, frequency, and high-time. Frequency is checked against the 2970–3030 Hz tolerance band, and duty cycle is swept across values (including 0x00 and 0xFF as edge cases) and checked within ±1% of the commanded value. A separate case confirms output-enable=0 overrides PWM mode, per the register priority rule above.


