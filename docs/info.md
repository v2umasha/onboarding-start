<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

Explain how your project works:
This project involves a SPI-controlled PWM peripheral. The design operates at 10 MHz and uses SPI communication at 100 KHz to configure registers that control output enables, PWM enables, and duty cycles.

## How to test

To test my project, there are testbenches that I will need to create a PWM tb that runs a duty cycle sweep, goes over all possible combinations of the output enable and pwm enable register, frequency verif, and pwm duty verification. 


