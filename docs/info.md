## How it works

This project involves a SPI-controlled PWM peripheral. The design operates at 10 MHz and uses SPI communication at 100 KHz to configure registers that control output enables, PWM enables, and duty cycles.

## How to test

To test my project, there are testbenches that I will need to create a PWM tb that runs a duty cycle sweep, goes over all possible combinations of the output enable and pwm enable register, frequency verif, and pwm duty verification. 


