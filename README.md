# Servo-Peripheral-designed-in-VHDL

This project implements a four-channel PWM controller for hobby servo motors as a custom peripheral on an FPGA. The controller is written in VHDL and integrates with the 16-bit SCOMP microprocessor on a Terasic DE10-Lite FPGA board. Through memory-mapped I/O registers, the SCOMP CPU can command up to four RC servos by writing position values that the hardware translates into PWM signals. Each servo output generates a stable 50 Hz pulse train (20 ms period). 

 The FPGA design generates such pulses with sub-microsecond accuracy, leveraging hardware counters and a PLL-derived clock to meet servo timing requirements. Once the CPU sets a servo position, the custom hardware module autonomously produces the corresponding PWM waveform, freeing the CPU from continuous timing tasks. his project showcases skills in digital design (VHDL), FPGA development, and hardware/software co-design – including timing analysis to ensure correct pulse widths, use of FPGA IP for clock generation, and interfacing a custom peripheral with a CPU’s bus. The system was tested on real hardware with four servos, confirming that the FPGA and VHDL logic can accurately control servo movements as programmed in the SCOMP assembly code.

 
