# Servo Peripheral in VHDL

A four-channel PWM servo controller implemented as a custom FPGA peripheral in VHDL. This project demonstrates hardware/software co-design by integrating a hobby servo pulse generator (HSPG) with the SCOMP 16-bit microprocessor on an Intel DE10-Lite FPGA board.

## Overview

This project implements a memory-mapped peripheral that generates precise PWM signals to control up to four hobby RC servos. The VHDL-based controller operates autonomously once configured by the CPU, producing stable 50 Hz pulse trains with sub-microsecond accuracy. Each servo can be positioned with 7-bit resolution (128 positions) across a 0.6–2.4 ms pulse width range.

**Key Features:**
- **4 independent servo channels** with simultaneous operation
- **7-bit position control** (0-127) mapping to pulse widths of 0.6–2.4 ms
- **50 Hz PWM frequency** (20 ms period) for standard RC servos
- **Sub-microsecond timing accuracy** using PLL-derived 71 kHz clock
- **Glitch-free operation** via double-buffered position updates
- **Memory-mapped I/O** interface with SCOMP processor
- **Hardware-based pulse generation** offloads CPU from timing tasks

## Hardware Architecture

### System Components

**HSPG Module (Hobby Servo Pulse Generator)**
- Custom VHDL peripheral for generating servo PWM signals
- 71 kHz clock derived from PLL (14 µs tick period)
- Frame counter: 1428 ticks ≈ 20 ms period
- Position range: 43-170 ticks (0.6–2.4 ms pulse width)
- Double-buffered to prevent glitches during position updates

**SCOMP Processor**
- 16-bit simple computer architecture
- Memory-mapped I/O for peripheral access
- Executes assembly programs from internal memory
- Controls servos via OUT instructions to I/O addresses 0x50-0x53

**PLL and Clock Management**
- PLL_main generates 71 kHz servo clock from 50 MHz system clock
- Separate clock domains for CPU and servo timing

**I/O Decoder**
- Routes I/O operations to appropriate peripherals
- Servo channels mapped to addresses 0x50-0x53

### Block Diagram

```
┌─────────────────────────────────────────────────────────────┐
│  SCOMP_System (Top Level)                                   │
│                                                              │
│  ┌──────────┐      ┌────────────┐                          │
│  │  SCOMP   │─────▶│ IO_DECODER │                          │
│  │  CPU     │      └─────┬──────┘                          │
│  └──────────┘            │                                  │
│       │                  │                                  │
│       │                  ├─────┐                            │
│  ┌────▼────┐        ┌────▼──┐  │  ┌──────┐  ┌──────┐      │
│  │   PLL   │        │ HSPG  │  │  │ HSPG │  │ HSPG │      │
│  │  Main   │───────▶│   0   │──┼─▶│   1  │─▶│  2/3 │      │
│  └─────────┘ 71kHz  └───┬───┘  │  └───┬──┘  └───┬──┘      │
│                         │      │      │         │          │
└─────────────────────────┼──────┼──────┼─────────┼──────────┘
                          │      │      │         │
                         TP1    TP2    TP3       TP4
                      (Servo0) (Servo1) (Servo2) (Servo3)
```

## Repository Structure

```
.
├── src/                          # Source files
│   ├── cpu/                      # SCOMP processor
│   │   └── SCOMP.vhd            # 16-bit SCOMP CPU implementation
│   ├── peripherals/              # Peripheral modules
│   │   ├── HSPG.vhd             # Hobby servo pulse generator
│   │   ├── TIMER.vhd            # 10 Hz timer peripheral
│   │   ├── IO_DECODER.vhd       # I/O address decoder
│   │   ├── DIG_IN.vhd           # Digital input peripheral
│   │   ├── DIG_OUT.vhd          # Digital output peripheral
│   │   ├── HEX_DISP.vhd         # 7-segment display driver
│   │   ├── SafePulse.vhd        # Pulse cleanup utility
│   │   ├── clk_div.vhd          # Clock divider
│   │   └── *.bsf                # Block symbol files
│   └── top_level/                # Top-level designs
│       ├── SCOMP_System.bdf     # Main system block diagram
│       └── HEX_DISP_6.bdf       # 6-digit hex display block
├── quartus_project/              # Quartus project files
│   ├── SCOMP.qpf                # Quartus project file
│   ├── SCOMP.qsf                # Quartus settings file
│   ├── SCOMP.sdc                # Timing constraints
│   ├── stp1.stp                 # SignalTap debug config
│   ├── PLL_main.vhd             # PLL for 71 kHz clock
│   ├── PLL_main.qip             # PLL Quartus IP file
│   ├── PLL_main/                # PLL IP core files
│   └── PLL_main_sim/            # PLL simulation files
├── test_programs/                # Test programs
│   ├── HSPG_test.asm            # Multi-servo test (4 servos)
│   ├── HSPG_test.mif            # Compiled test program
│   ├── HSPG_test2.mif           # Alternative test program
│   └── scasm.cfg                # Assembler configuration
├── simulation/                   # ModelSim simulation files
└── README.md                     # This file
```

## Technical Details

### PWM Timing Specifications

| Parameter | Value | Calculation |
|-----------|-------|-------------|
| Base Clock | 71 kHz | 50 MHz / PLL divisor |
| Tick Period | 14.08 µs | 1 / 71 kHz |
| Frame Period | 20 ms | 1428 ticks × 14 µs |
| PWM Frequency | 50 Hz | 1 / 20 ms |
| Min Pulse Width | 0.60 ms | 43 ticks × 14 µs |
| Max Pulse Width | 2.40 ms | 170 ticks × 14 µs |
| Position Resolution | ~14 µs | 1 tick = 0.7° for 180° servo |

### Memory Map

| Address | Device | Access | Description |
|---------|--------|--------|-------------|
| 0x000 | Switches | Read | Read switch inputs |
| 0x001 | LEDs | Write | Control LED outputs |
| 0x002 | Timer | R/W | 10 Hz timer peripheral |
| 0x004 | Hex0 | Write | 7-segment display |
| 0x050 | Servo0 | Write | Servo channel 0 (TP1) |
| 0x051 | Servo1 | Write | Servo channel 1 (TP2) |
| 0x052 | Servo2 | Write | Servo channel 2 (TP3) |
| 0x053 | Servo3 | Write | Servo channel 3 (TP4) |

### HSPG Interface

**Inputs:**
- `CS` - Chip select (I/O address decoder)
- `IO_WRITE` - Write enable signal
- `IO_DATA[15:0]` - 16-bit data bus (only lower 7 bits used)
- `CLOCK` - 71 kHz servo timing clock
- `RESETN` - Active-low reset

**Outputs:**
- `PULSE` - PWM output signal to servo
- `OVER` - Overflow flag (position > 127)

**Position Encoding:**
- Input value: 0-127 (7-bit unsigned)
- Values > 127 are clamped to maximum (OVER flag set)
- Position 0 → 0.60 ms pulse (0° servo position)
- Position 127 → 2.40 ms pulse (180° servo position)

## Software Examples

### Example 1: Single Servo Control

```assembly
; Set servo to middle position (90 degrees)
LOADI   64          ; Load value 64 (approx 90°)
OUT     Servo0      ; Write to servo channel 0
```

### Example 2: Four-Servo Multi-Rate Demo

The included `HSPG_test.asm` program demonstrates independent control of all four servos:
- **Servo 0** (TP1): Updates every 0.1s → completes sweep in ~12.7s
- **Servo 1** (TP2): Updates every 0.4s → completes sweep in ~50.8s
- **Servo 2** (TP3): Updates every 0.8s → completes sweep in ~101.6s
- **Servo 3** (TP4): Updates every 1.0s → completes sweep in ~127s

Each servo continuously sweeps from 0° to 180° and back.

## Getting Started

### Prerequisites

1. **Intel Quartus Prime Lite Edition** (tested with v18.1)
   - Download from [Intel FPGA website](https://www.intel.com/content/www/us/en/software/programmable/quartus-prime/download.html)
   - Ensure MAX 10 device support is installed

2. **Terasic DE10-Lite FPGA Board**
   - Intel MAX 10 10M50DAF484C7G FPGA
   - DE10 daughterboard with TP1-TP4 test points for servo connections

3. **USB-Blaster Cable** (included with DE10-Lite)

4. **Standard RC Servos** (1-4 servos for testing)

### Build and Program

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/Servo-Peripheral-designed-in-VHDL.git
   cd Servo-Peripheral-designed-in-VHDL
   ```

2. **Open in Quartus:**
   - Launch Quartus Prime
   - Open project: `quartus_project/SCOMP.qpf`
   - Verify target device: Intel MAX 10 10M50DAF484C7G

3. **Compile the design:**
   - Click Processing → Start Compilation
   - Or press Ctrl+L
   - Wait for compilation to complete (~2-5 minutes)

4. **Program the FPGA:**
   - Connect DE10-Lite via USB
   - Open Tools → Programmer
   - Click Hardware Setup → Select USB-Blaster
   - Click Start to program the device

5. **Connect servos:**
   - Connect servo signal wires to TP1-TP4 on DE10 daughterboard
   - Connect servo power (5V) and ground to appropriate power supply
   - **Warning:** Do not power servos directly from FPGA board

### Testing

After programming:
1. The SCOMP processor begins executing the loaded program (HSPG_test2.mif by default)
2. All four servos should start sweeping at different rates
3. Observe smooth, glitch-free motion across full 180° range

### Modifying the Test Program

To change the SCOMP firmware:

1. Edit the assembly file in `test_programs/` directory
2. Assemble using SCOMP assembler (scasm) to generate .mif file
3. Update the .mif file reference in `src/cpu/SCOMP.vhd` line 75:
   ```vhdl
   init_file => "../test_programs/HSPG_test2.mif",  -- Change to your .mif file
   ```
4. Recompile and reprogram the FPGA

## Design Highlights

### Glitch-Free Position Updates

The HSPG module uses double-buffering to prevent pulse glitches:
- `next_cmd` register: Captures new position from CPU write
- `cmd` register: Active position used for pulse generation
- Transfer occurs only at frame boundary (count = 0)
- Ensures clean transitions without mid-pulse position changes

### Timing Analysis

The design meets all timing constraints for:
- 50 MHz system clock
- 71 kHz servo clock
- I/O write setup/hold times
- Cross-domain clock transfers

### Resource Utilization

Typical resource usage on MAX 10 10M50DAF484C7G:
- Logic elements: ~2,500 / 50,000 (5%)
- Memory bits: ~32,000 / 1,677,312 (2%)
- PLLs: 1 / 4 (25%)

## Academic Context

This project was developed for **ECE 2031 - Digital Design Laboratory** and demonstrates:

1. **VHDL proficiency**: Complex state machines, counters, and synchronous design
2. **FPGA development**: IP integration (PLL), constraint management, synthesis
3. **Hardware/software co-design**: Custom peripheral with CPU interface
4. **Timing analysis**: Clock domain crossing, setup/hold requirements
5. **Real-world interfacing**: PWM generation for physical actuators

## Known Issues and Limitations

- Servo power must be supplied externally (FPGA I/O cannot source sufficient current)
- Position resolution limited to 7 bits (128 positions) for simplicity
- No feedback mechanism (open-loop control only)
- Test programs stored in FPGA memory (no runtime programming via JTAG)

## Future Enhancements

Potential improvements:
- Add serial interface for runtime servo position updates
- Implement position feedback using potentiometer ADC
- Expand to 8-16 servo channels
- Add programmable PWM frequency/pulse width ranges
- Integrate with Nios II soft processor for C programming

## License

This project is available for educational and reference purposes.

## Author

Created as part of ECE 2031 coursework. Demonstrates FPGA-based embedded system design and VHDL programming skills.

## Acknowledgments

- SCOMP processor design based on ECE 2031 teaching materials
- DE10-Lite board and reference designs from Terasic
- Intel Quartus Prime FPGA development tools
