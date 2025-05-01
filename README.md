# FPGA_Demo_Projects

<p align="center"><br>
  <img src="Photos/Rotating_Hex.gif" width="600" alt="GIF">
</p>

## Description
A small collection of Verilog projects developed for the [DE10-Lite FPGA development board](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=234&No=1021), produced by Intel. These were created for a third-year university project where we used an SPI driver to communicate with the ADXL345 accelerometer present on the board.

## Projects
### 1. DE10L_basix_hex_movement
This was the first project, aimed at familiarizing the student with the Quartus environment and the FPGA board. It functions by moving a square, drawn across the six 7-segment displays, in a circular pattern. It introduces pin constraints on the board and basic Verilog syntax.

### 2. DE10L_basic_spi
In this project, we successfully communicated with the accelerometer sensor and retrieved the device ID from the first register of the IC. It uses a rudimentary SPI driver that translates the SPI interface into a request-acknowledge protocol, making it easier to use.

### 3. DE10L_spi_comm
A more advanced SPI project. I developed a robust, state-machine-based SPI driver that works at any clock speed and decouples the system from the SPI frequency. It translates the SPI interface into a FIFO-based input/output system and offers bulk read/write capabilities. This driver is used to retrieve the X and Y orientation in degrees from the accelerometer and map them to the 7-segment displays. A square moves around on the displays based on board inclination, similar to a digital spirit level.

### 4. DE10L_vga_display
A project designed to test the provided VGA driver and display accelerometer data. The `vga_driver` reads values from a separate module, `vga_feeder`, which handles various patterns and colors. It also receives orientation data and draws a circle on the screen that moves around, similar to a phone gyroscope app.

### 5. DE10L_final_project
The final project, designed to combine all the previous phases into one cohesive system.

## Photos
Phase 2: Device ID shown on the LEDs.

<img align="center" src="Photos/DEVID.png" width="800" alt="Devid">
<br><br>

Simulation of the Phase 3 and 4 SPI driver.

<img align="center" src="Photos/SPI_Frame.png" width="800" alt="Waveforms">
<br><br>

Phase 4 result: The ball moves based on the tilt angle of the board.

<img align="center" src="Photos/VGA_Demo.png" width="800" alt="VGA">
