UART Transmitter and Receiver in Verilog
<p align="center">
  <strong>UART 8N1 Communication • RTL Design • Functional Verification</strong>
</p>

<p align="center">
  <img alt="Language" src="https://img.shields.io/badge/HDL-Verilog-blue">
  <img alt="Simulation" src="https://img.shields.io/badge/Simulation-Icarus%20Verilog-orange">
  <img alt="Waveforms" src="https://img.shields.io/badge/Waveforms-GTKWave-green">
  <img alt="Status" src="https://img.shields.io/badge/Status-Simulation%20Verified-brightgreen">
</p>

A beginner-friendly RTL project that implements a UART (Universal Asynchronous Receiver/Transmitter) transmitter and receiver in Verilog HDL. It includes a top-level integration module and testbenches for testing transmission, reception, loopback communication, invalid stop-bit detection, and the complete integrated design.
The project is designed to run on a Windows PC using VS Code, Icarus Verilog, and GTKWave. No FPGA board is required to run the included simulations.
Scope: This repository demonstrates and verifies the RTL in simulation. It does not, by itself, claim that the design has been synthesized, implemented on an FPGA, or validated on physical hardware.

Table of Contents
- 1. Project Overview
- 2. What Is UART?
- 3. UART Frame Format
- 4. Features
- 5. Project Architecture
- 6. Repository Structure
- 7. Tools and Requirements
- 8. Windows Setup
- 9. Open the Project in VS Code
- 10. Compile and Run the Testbenches
- 11. Testbench Details and Expected Results
- 12. View Waveforms in GTKWave
- 13. Design Parameters and Timing
- 14. Understanding the RTL
- 15. Troubleshooting
- 16. Limitations and Future Improvements
- 17. Learning Outcomes
- 18. Contributing
- 19. License
- 20. Author
1. Project Overview
UART is a widely used serial communication protocol found in microcontrollers, embedded systems, development boards, and many digital devices. This project builds a basic UART communication path using synthesizable-style Verilog RTL and simulation testbenches.
The design contains:
- UART Transmitter (uart_tx.v) — serializes an 8-bit parallel data byte and transmits it on the tx output.
- UART Receiver (uart_rx.v) — detects a start bit, samples the incoming serial stream, reconstructs the 8-bit byte, and reports valid data.
- Top-Level Module (uart_top.v) — connects the transmitter and receiver and exposes the main status signals.
- Testbenches — verify individual blocks and the integrated design.
- VCD waveform files — capture signal activity for inspection in GTKWave.
High-level data flow
                8-bit parallel data
                         |
                         v
                  +-------------+
                  |  UART TX    |
                  | Transmitter |
                  +-------------+
                         |
                     tx serial
                         |
                         v
                  +-------------+
                  |  UART RX    |
                  |  Receiver   |
                  +-------------+
                         |
                         v
               8-bit received data
                  + rx_valid
               + framing_error
In the loopback testbench, the transmitter's serial output is connected directly to the receiver's serial input. This makes it possible to test the complete transmit/receive path without external hardware.
2. What Is UART?
UART stands for Universal Asynchronous Receiver/Transmitter. It is a hardware communication method that sends data one bit at a time over a serial line.
UART is asynchronous: the communicating endpoints do not share a separate clock signal on the serial connection. Instead, both sides must agree on communication settings such as the bit rate and frame format. In this project, the internal design uses a clock to time its state machines and sampling.
Common UART applications include:
- Microcontroller-to-PC serial communication
- Debug messages from embedded systems
- Communication between development boards and sensors
- Serial interfaces in electronics and robotics projects
Important UART terms
Term	Meaning
TX	Transmit data
RX	Receive data
Baud rate	Number of signalling symbols per second; for ordinary binary UART, commonly equal to bits per second
Start bit	LOW bit that indicates the beginning of a frame
Data bits	Payload bits, sent least-significant bit first in this design
Stop bit	HIGH bit indicating the end of a frame
tx_busy	Indicates that the transmitter is currently transmitting
rx_valid	Pulses HIGH when a valid received byte is available
framing_error	Pulses HIGH when the receiver detects an invalid LOW stop bit


3. UART Frame Format
This project uses 8N1 framing:
- 8 data bits
- N parity bits — no parity bit
- 1 stop bit
The line is normally idle HIGH. A frame starts with a LOW start bit, followed by eight data bits, and ends with a HIGH stop bit.
Idle     Start       8 data bits (LSB first)           Stop     Idle
 HIGH      LOW      D0 D1 D2 D3 D4 D5 D6 D7            HIGH     HIGH
───────┐        ┌───┬───┬───┬───┬───┬───┬───┬───┐        ┌────────
       └────────┘   │   │   │   │   │   │   │   └────────┘
A normal 8N1 frame contains 10 bit periods: one start bit, eight data bits, and one stop bit.
Example: transmitting 8'hA5
8'hA5 is hexadecimal A5, which is 10100101 in the usual MSB-to-LSB binary notation. UART transmits the least-significant bit first, so the order on the serial line is:
Start | D0 D1 D2 D3 D4 D5 D6 D7 | Stop
  0   |  1  0  1  0  0  1  0  1 |  1
The bit order on the line is not the same as writing the byte from left to right in conventional binary notation. This is a common point of confusion when inspecting UART waveforms.
4. Features
- UART transmitter with 8-bit payload support
- UART receiver with start-bit detection and data sampling
- 8N1 frame format
- Configurable clock cycles per bit through CLKS_PER_BIT
- Least-significant-bit-first data transfer
- Transmitter busy status
- Receiver valid-data pulse
- Basic receive-input synchronization
- Framing-error indication when the stop bit is LOW
- Separate testbenches for TX, RX, loopback, framing error, and top-level integration
- VCD waveform generation for GTKWave
- Command-line simulation using Icarus Verilog
- No FPGA board required for simulation
5. Project Architecture
Transmitter
The transmitter accepts a parallel 8-bit input byte and sends a serial frame. Its control logic typically progresses through idle, start-bit, data-bit, and stop-bit phases. It uses CLKS_PER_BIT to determine how many clock cycles to hold each transmitted bit.
Main interface signals in the current design:
Signal	Direction	Purpose
clk	Input	Internal design clock
rst	Input	Reset input; confirm polarity in the RTL
tx_start	Input	Requests transmission of the supplied byte
tx_data[7:0]	Input	Byte to transmit
tx	Output	Serial TX line
tx_busy	Output	Indicates active transmission


Check rtl/uart_tx.v for the exact port declaration and reset polarity before connecting the module to another design.
Receiver
The receiver monitors the serial input, detects a possible LOW start bit, checks it around the middle of the bit period, and samples the data bits at the configured timing. It assembles the bits into a byte and checks the stop bit.
Main interface signals in the current design:
Signal	Direction	Purpose
clk	Input	Internal design clock
rst	Input	Reset input; confirm polarity in the RTL
rx	Input	Incoming serial line
rx_data[7:0]	Output	Reconstructed byte
rx_valid	Output	One-clock pulse for a valid frame
framing_error	Output	One-clock pulse when the stop bit is invalid


The receiver uses input synchronization to reduce the chance of metastability propagating into the internal sampling logic. A digital simulation can verify logic behaviour, but it cannot fully model physical metastability.
Top-level integration
rtl/uart_top.v connects the TX and RX modules and exposes the main signals for an integrated test. The top-level testbench feeds the transmitted serial line back into the receiver, then checks the received bytes.
6. Repository Structure
The project is organized into RTL source, testbench source, and generated simulation output:
UART_Project/
├── rtl/
│   ├── uart_tx.v
│   ├── uart_rx.v
│   └── uart_top.v
├── tb/
│   ├── uart_tx_tb.v
│   ├── uart_rx_tb.v
│   ├── uart_loopback_tb.v
│   ├── uart_rx_error_tb.v
│   └── uart_top_tb.v
├── sim/
│   ├── uart_tx.vcd
│   ├── uart_rx.vcd
│   ├── uart_loopback.vcd
│   ├── uart_rx_error.vcd
│   ├── uart_top.vcd
│   └── simulation executables (generated)
└── README.md
The exact contents of sim/ depend on which tests have been run. Executable files and VCD files are generated outputs; they do not need to be committed unless you specifically want to publish simulation artifacts.
File descriptions
File	Responsibility
rtl/uart_tx.v	UART transmitter RTL
rtl/uart_rx.v	UART receiver RTL
rtl/uart_top.v	Top-level TX/RX integration
tb/uart_tx_tb.v	Tests the transmitter independently
tb/uart_rx_tb.v	Tests the receiver with serial stimulus
tb/uart_loopback_tb.v	Checks communication through TX-to-RX loopback
tb/uart_rx_error_tb.v	Checks invalid stop-bit/framing-error handling
tb/uart_top_tb.v	Checks the integrated top-level design
sim/*.vcd	Waveforms generated by testbenches


7. Tools and Requirements
Required software
Tool	Why it is used	Official resource
Visual Studio Code	Edit Verilog and run terminal commands	code.visualstudio.com
Icarus Verilog	Compile and simulate Verilog	iverilog.fandom.com/wiki/Installation_Guide
GTKWave	View VCD simulation waveforms	gtkwave.sourceforge.net
Windows PowerShell	Run compile and simulation commands	Included with Windows


A Verilog syntax-highlighting extension for VS Code is helpful but not required.
Hardware requirement
No physical hardware is required to run the simulation testbenches. An FPGA board is only needed if you later want to synthesize the RTL, assign FPGA pins, and test it on a device.
8. Windows Setup
These instructions assume Windows and PowerShell, with the project folder named UART_Project.
Step 1 — Install VS Code
Install Visual Studio Code from the official website.
Step 2 — Install Icarus Verilog
Install a Windows build of Icarus Verilog. During installation, note the installation directory and make sure the directory containing iverilog.exe and vvp.exe is available in your Windows PATH.
Open a new PowerShell terminal and run:
iverilog -V
vvp -V
If the commands print version information, the tools are available. If PowerShell says the command is not recognized, add the correct Icarus Verilog bin directory to PATH, then open a new terminal.
Step 3 — Install GTKWave
Install or extract GTKWave for Windows. Note the location of gtkwave.exe.
For example, the GTKWave executable used during development was located at:
C:\Users\dell\Downloads\gtkwave-3.3.100-bin-win64\gtkwave64\bin\gtkwave.exe
This is only an example from the development setup. Your username and installation directory may be different.
Check that the executable exists before using the path in the commands below.
Step 4 — Confirm the project files
Your project directory should contain rtl, tb, and sim folders. If the sim folder does not exist, create it:
New-Item -ItemType Directory -Force sim
Run this command from the root of UART_Project.
9. Open the Project in VS Code
Open PowerShell and navigate to the project directory. For the development location used for this project:
cd "$HOME\Desktop\VLSI PROJECTS\VERILOG\UART_Project"
Open the current directory in VS Code:
code .
If code is not recognized, open VS Code manually and select File → Open Folder, then choose the UART_Project folder.
Important: Run the compile commands from the project root, UART_Project. The relative paths in the commands expect the rtl, tb, and sim folders to be directly inside that directory.

10. Compile and Run the Testbenches
The workflow for every test is:
1. Open the VS Code terminal at the project root.
2. Compile the required RTL files and the selected testbench using iverilog.
3. Run the generated simulation using vvp.
4. Check the console output for PASS messages or errors.
5. Open the generated .vcd waveform in GTKWave if needed.
The commands below use the -g2012 option for SystemVerilog-compatible language support and -Wall for warnings. They explicitly select the testbench top module with -s.
Test 1 — Transmitter
Compile:
iverilog -g2012 -Wall -s uart_tx_tb -o sim\uart_tx_test rtl\uart_tx.v tb\uart_tx_tb.v
Run:
vvp sim\uart_tx_test
Expected outcome: the transmitter testbench should finish and report its checks as passed. The exact console messages depend on the contents of tb/uart_tx_tb.v.
Test 2 — Receiver
Compile:
iverilog -g2012 -Wall -s uart_rx_tb -o sim\uart_rx_test rtl\uart_rx.v tb\uart_rx_tb.v
Run:
vvp sim\uart_rx_test
Expected outcome: the receiver reconstructs the bytes supplied by the testbench and reports the expected checks as passed.
Test 3 — TX-to-RX loopback
Compile:
iverilog -g2012 -Wall -s uart_loopback_tb -o sim\uart_loopback_test rtl\uart_tx.v rtl\uart_rx.v tb\uart_loopback_tb.v
Run:
vvp sim\uart_loopback_test
Expected outcome: bytes transmitted by the TX module are received by the RX module and match the testbench's expected data.
Test 4 — Receiver framing-error detection
Compile:
iverilog -g2012 -Wall -s uart_rx_error_tb -o sim\uart_rx_error_test rtl\uart_rx.v tb\uart_rx_error_tb.v
Run:
vvp sim\uart_rx_error_test
The testbench checks that a LOW stop bit is detected as a framing error and is not reported as a valid received frame. In the development run, the console included:
UART RX Framing Error Test Started
PASS: Framing error detected
PASS: Invalid stop bit was rejected
ALL FRAMING ERROR TESTS PASSED
Test 5 — Top-level integration
Compile:
iverilog -g2012 -Wall -s uart_top_tb -o sim\uart_top_test rtl\uart_tx.v rtl\uart_rx.v rtl\uart_top.v tb\uart_top_tb.v
Run:
vvp sim\uart_top_test
The integration testbench checks these four bytes:
- 8'hA5
- 8'h3C
- 8'h55
- 8'hFF
In a previously completed development run, the output was:
UART Top-Level Test Started
PASS: Received a5
PASS: Received 3c
PASS: Received 55
PASS: Received ff
ALL UART TOP-LEVEL TESTS PASSED
Your output may include a VCD information line and a $finish called message as well. The key result is that all expected bytes are received correctly.
Run the tests individually
Run each compile/run pair separately. If a test fails, inspect that test's output before moving on. A passing testbench only verifies the scenarios that it actually exercises; it is not proof that every possible UART condition has been tested.
11. Testbench Details and Expected Results
Testbench	What it checks	Expected result
uart_tx_tb.v	TX frame timing, start/data/stop sequence, and busy behaviour as covered by the test	Transmitted bits match the stimulus
uart_rx_tb.v	Start-bit detection, data sampling, byte reconstruction, and valid-data indication as covered by the test	Received byte matches expected byte
uart_loopback_tb.v	End-to-end transfer through TX and RX	Received bytes match transmitted bytes
uart_rx_error_tb.v	LOW stop-bit/framing-error handling	Error is detected and invalid frame is rejected
uart_top_tb.v	Top-level integration and multiple-byte transfer	A5, 3C, 55, and FF are received correctly


What does “PASS” mean?
A PASS message means that the specific assertion or comparison in the testbench succeeded. The complete test is successful when its expected checks pass and the simulator exits normally without unexpected errors or timeouts.
12. View Waveforms in GTKWave
Waveforms help you see how signals change over time and are especially useful for debugging digital logic.
Each testbench writes a VCD file under sim/, assuming its $dumpfile path points there.
Open a waveform
For the top-level integration waveform, run:
& "$HOME\Downloads\gtkwave-3.3.100-bin-win64\gtkwave64\bin\gtkwave.exe" "sim\uart_top.vcd"
For another test, replace uart_top.vcd with the relevant filename, such as uart_tx.vcd, uart_rx.vcd, uart_loopback.vcd, or uart_rx_error.vcd.
If your GTKWave installation is in a different location, change the executable path. You can also launch GTKWave from the Start menu and open the VCD file using File → Open New Tab or the equivalent file-opening menu in your version.
Signals to inspect
Signal names depend on the testbench hierarchy, but look for signals equivalent to:
- clk
- rst
- tx_start
- tx_data
- tx
- tx_busy
- rx
- rx_data
- rx_valid
- framing_error
What should you see?
1. Clock (clk) — a repeating square wave.
2. Reset (rst) — the reset level changes according to the testbench's reset sequence.
3. TX start request (tx_start) — triggers a transmission when the transmitter is ready.
4. TX line (tx) — normally HIGH when idle, LOW for the start bit, followed by the eight data bits LSB-first and a HIGH stop bit.
5. Busy (tx_busy) — indicates that the transmitter is working on a frame.
6. RX valid (rx_valid) — pulses when a valid frame has been received.
7. Received data (rx_data) — shows the reconstructed byte. Set GTKWave's display radix to hexadecimal to read values such as a5, 3c, 55, and ff.
8. Framing error (framing_error) — pulses when the receiver detects an invalid stop bit in the framing-error test.
Useful GTKWave tips
- Add signals from the left-hand signal list to the waveform pane.
- Use hexadecimal radix for 8-bit data buses.
- Zoom in to inspect a single frame and zoom out to see several frames.
- Compare the TX line with RX input during loopback.
- Check the VCD filename and simulator output if GTKWave opens without signals.
13. Design Parameters and Timing
CLKS_PER_BIT
CLKS_PER_BIT controls the number of internal clock cycles assigned to one UART bit. The design and testbenches currently use:
CLKS_PER_BIT = 16
The testbench clock toggles every 5 ns, giving a 10 ns clock period.
Therefore:
\[
T_{\text{clk}} = 10\text{ ns}
\]
\[
T_{\text{bit}} = CLKS\_PER\_BIT \times T_{\text{clk}}
\]
For CLKS_PER_BIT = 16:
\[
T_{\text{bit}} = 16 \times 10\text{ ns} = 160\text{ ns}
\]
\[
f_{\text{bit}} = \frac{1}{160\text{ ns}} = 6.25\text{ Mbit/s}
\]
This is the simulation bit rate implied by the testbench clock and parameter, not a claim that a physical board has been configured or verified at that rate. A real implementation must use a clock and CLKS_PER_BIT value appropriate for the intended baud rate.
For a target baud rate, a common starting calculation is:
\[
CLKS\_PER\_BIT \approx \frac{f_{\text{clk}}}{f_{\text{baud}}}
\]
The ratio generally needs to be an appropriate integer for a simple counter-based implementation. If the ratio is not an integer, a more advanced baud-rate generator may be needed.
Approximate frame duration
An 8N1 frame has 10 bit periods. With 160 ns per bit:
\[
T_{\text{frame}} = 10 \times 160\text{ ns} = 1.6\text{ µs}
\]
This excludes additional idle time between frames and any implementation-specific scheduling details.
14. Understanding the RTL
Transmit sequence
At a conceptual level, the transmitter performs these steps:
1. Wait for a transmit request while idle.
2. Latch the input byte.
3. Drive the TX line LOW for the start bit.
4. Send data bits D0 through D7, one bit period each.
5. Drive the TX line HIGH for the stop bit.
6. Return to idle and clear the busy status.
Receive sequence
At a conceptual level, the receiver performs these steps:
1. Synchronize the asynchronous RX input to the internal clock.
2. Detect a possible LOW start bit.
3. Sample near the middle of the start bit to reject a short LOW glitch.
4. Sample the eight data bits at the configured intervals, least-significant bit first.
5. Check the stop bit.
6. Pulse rx_valid for a valid frame, or pulse framing_error when the stop bit is LOW.
These steps describe the design's intended behaviour. For exact state names, counter behaviour, reset details, and signal timing, refer to the actual source in rtl/uart_tx.v and rtl/uart_rx.v.
Why sample near the middle of a bit?
Sampling near the centre of a bit gives the receiver more tolerance to small timing differences and edge transitions than sampling right at a boundary. The transmitter and receiver still need compatible timing; centre sampling does not remove the need for a suitable baud-rate configuration.
15. Troubleshooting
iverilog is not recognized
Cause: Icarus Verilog is not installed, or its executable directory is not in PATH.
Try:
- Confirm that iverilog.exe and vvp.exe exist in the installation directory.
- Add that directory to the Windows PATH.
- Open a new PowerShell terminal and retry iverilog -V.
vvp is not recognized
Cause: The Icarus Verilog runtime executable is missing from PATH.
Try: Confirm that the same Icarus Verilog installation directory containing vvp.exe is included in PATH.
Unable to open input file or source file not found
Cause: The terminal is not in the project root, or a filename/folder name differs.
Try:
Get-Location
Get-ChildItem
Get-ChildItem rtl
Get-ChildItem tb
The current directory should be UART_Project, with rtl and tb subdirectories.
Unable to open output file
Cause: The sim folder may not exist.
Try:
New-Item -ItemType Directory -Force sim
Then repeat the compile command.
GTKWave does not open
Cause: The executable path is incorrect, or GTKWave is installed in a different directory.
Try: Confirm the path to gtkwave.exe. Update the path in the PowerShell command to match your installation.
GTKWave opens, but no waveform appears
Cause: The VCD file may not have been generated, may be empty, or may not contain the expected signals.
Try:
1. Run the simulation again.
2. Check that the console mentions the expected VCD filename.
3. Confirm that the file exists in sim/.
4. Open that exact file in GTKWave.
5. Add signals to the waveform pane.
Simulation stops responding or waits indefinitely
Cause: A testbench may be waiting for a signal that never arrives, or a timeout may be missing.
Try:
- Check compile warnings and errors.
- Confirm the intended top module was selected with -s.
- Inspect tx_busy, rx_valid, and the serial line in the waveform.
- Confirm the transmitter and receiver use compatible CLKS_PER_BIT settings.
- Check reset polarity and timing.
- Add a finite timeout to any testbench that waits for a completion event.
Receiver gets the wrong byte
Possible causes:
- Data bits are sampled in the wrong order.
- TX and RX timing parameters do not match.
- The start-bit check or bit counter is off by a clock cycle.
- Reset is not applied or released as expected.
- The testbench changes stimulus too close to a sampling edge.
Inspect the serial waveform one bit at a time and verify the expected order D0 through D7.
Framing error is not detected
Check that the framing-error testbench actually holds the stop bit LOW during the receiver's stop-bit sampling interval. A LOW level outside the sampling interval may not trigger the error.
16. Limitations and Future Improvements
This is a learning and simulation project. Possible improvements include:
- Add configurable data width, parity, and stop-bit settings.
- Add a baud-rate parameter or baud-rate tick generator for common baud rates.
- Add more tests for back-to-back frames and idle gaps.
- Test reset assertion during transmission or reception.
- Add tests for short start-bit glitches and malformed frames.
- Test receiver behaviour when the stop bit is valid but timing is close to the tolerance limit.
- Add assertions or a self-checking regression script that runs every testbench.
- Add synthesis checks and FPGA constraints for a selected board.
- Validate the design on hardware using a USB-to-UART adapter or two compatible UART endpoints.
- Add a CI workflow to compile and run the testbenches automatically.
Hardware note: Before connecting a physical UART, verify logic voltage levels, pin assignments, clock frequency, and baud-rate compatibility. Do not connect RS-232 voltage levels directly to FPGA or microcontroller logic pins; RS-232 requires suitable level conversion.
17. Learning Outcomes
By studying and running this project, you can practise:
- Writing RTL modules in Verilog HDL
- Designing counter-based timing logic and finite-state machines
- Understanding UART 8N1 framing
- Transmitting and receiving bytes serially
- Building testbenches and driving test stimulus
- Using self-checking comparisons in simulation
- Compiling Verilog with Icarus Verilog
- Debugging signals through VCD waveforms in GTKWave
- Verifying individual modules and integrated logic
- Understanding why a passing simulation is different from hardware validation
18. Contributing
Suggestions and improvements are welcome. A useful contribution should include:
1. A clear description of the change.
2. Updated RTL or testbench files where applicable.
3. A reproducible compile/run command.
4. Expected results and actual test output.
5. A waveform or explanation when the change affects timing.
Please keep generated executables and large temporary simulation files out of version control unless they are intentionally included as examples.
19. License
No license has been specified for this project yet. Before publishing the repository publicly, add a LICENSE file that reflects how you want others to use, modify, and distribute your work. Do not assume that the repository is open-source merely because it is public.
20. Author
Sumit Kumar
B.Tech — Electrical and Electronics Engineering
Interests: VLSI, RTL Design, Digital Electronics, Embedded Systems
- GitHub: sumitraj7766
- Portfolio: sumitraj7766.github.io/portfolio
Quick Start
From the UART_Project root directory, compile and run the top-level integration test:
iverilog -g2012 -Wall -s uart_top_tb -o sim\uart_top_test rtl\uart_tx.v rtl\uart_rx.v rtl\uart_top.v tb\uart_top_tb.v
vvp sim\uart_top_test
Then open the waveform:
& "$HOME\Downloads\gtkwave-3.3.100-bin-win64\gtkwave64\bin\gtkwave.exe" "sim\uart_top.vcd"
If the testbench reports all expected bytes as received, the integrated UART simulation passed for those test cases.