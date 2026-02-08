# Timex FDD Mainboard CPLD Implementation

Complete CPLD-based replacement for the Timex FDD (Floppy Disk Drive) mainboard, consolidating multiple discrete ICs into a single Xilinx XC9572XL CPLD.

## Overview

This design replaces the following components:
- 2716 EPROM (2KB, only 101 bytes used for IPL bootloader)
- GAL30 address decoder
- Clock divider circuitry
- LS244/LS273 interface buffer pair
- Discrete glue logic

**Target Device:** Xilinx XC9572XL-10-VQ64 (72 macrocells, 64-pin VQFP)

## System Architecture

### Core Components (External to CPLD)
- **CPU:** Z80 @ 4MHz
- **RAM:** 64KB SRAM
- **FDC:** WD1770 Floppy Disk Controller @ 8MHz
- **Serial:** WD2123 Dual Serial Port Controller (optional, pins reserved)

### CPLD Functions

#### 1. Boot ROM (101 bytes)
- Contains Initial Program Loader (IPL)
- Loads 256 bytes from floppy track 0, sector 1 to RAM address 0x3F00
- Self-disables via E0 latch bit 6
- Implemented as embedded lookup tables

#### 2. Clock Generation
- **Input:** 16MHz crystal oscillator
- **Outputs:**
  - 4MHz for Z80 CPU (÷4)
  - 8MHz for WD1770 FDC (÷2)

#### 3. Address Decoding
Uses only **A0-A7** (8-bit address bus):
- **A0-A6:** ROM byte selection (101 bytes)
- **A5-A7:** I/O port decoding
- **Memory mapping:**
  - Boot mode: ROM at 0x0000-0x00FF, RAM disabled
  - Normal mode: Full 64KB RAM after ROM page-out

#### 4. I/O Port Map

| Port | Function | Direction | Details |
|------|----------|-----------|---------|
| 0x20 | External Interface | RD/WR | LS244/LS273 replacement, bit 7 = FDC status |
| 0x40 | Serial Port 1 | RD/WR | Reserved (chip select only) |
| 0x80 | Serial Port 2 | RD/WR | Reserved (chip select only) |
| 0xC0 | FDC Registers | RD/WR | WD1770 command/data |
| 0xE0 | FDD Control Latch | WR | Drive select, side, density, ROM disable |

**0xE0 Control Latch Bits:**
```
D7 - FDD Drive in use LED
D6 - ROM Disable (write 1 to page out ROM, sticky)
D5 - Double Density (/DDEN to WD1770)
D4 - FDD Drive side select
D3 - Drive select 3 (internal only)
D2 - Drive select 2 (internal only)
D1 - Drive select 1 (output pin)
D0 - Drive select 0 (output pin)
```

#### 5. External Computer Interface
Replaces LS244/LS273 buffer pair for inter-computer communication:
- **6 data bits used:** 0, 1, 2, 3, 6, 7 (bits 4, 5 unused)
- **Bit remapping:** FDD D0-D3,D4,D6 ↔ EXT D0-D3,D7,D6
- **Port 0x20 Read:** Bit 7 = INTRQ (FDC status), bits 6-0 = external data
- **Control signals:**
  - `nEXT_RD` - External computer reads from FDD
  - `nEXT_WR` - External computer writes to FDD

## Pin Assignment (VQ64)

### Forbidden Pins
- **VCC:** P3, P26, P37, P55
- **GND:** P14, P21, P41, P54
- **JTAG:** P28, P29, P30, P53

### Signal Mapping

| Signal Group | Pins | Count |
|--------------|------|-------|
| Clock Input (16MHz) | P1 | 1 |
| Clock Outputs (4/8MHz) | P62, P64 | 2 |
| Address Bus (A0-A7) | P2, P4-P10 | 8 |
| Data Bus (D0-D7) | P11-P13, P15-P19 | 8 |
| Control Signals | P22-P25, P27 | 5 |
| Chip Selects | P31-P34 | 4 |
| FDC Interface | P36, P38 | 2 |
| External Data (6 bits) | P39-P40, P42-P43, P45-P46 | 6 |
| External Control | P48, P51 | 2 |
| Serial CS (reserved) | P52, P56 | 2 |
| E0 Latch Outputs | P57-P61 | 5 |
| Reset Output | P63 | 1 |

**Total: 46 pins used** (48 available after power/ground/JTAG)

## Boot Sequence

1. **Power-On Reset:** `boot_latch = 1`, ROM active at 0x0000
2. **IPL Execution:** Z80 fetches and executes 101-byte bootloader from ROM
3. **Hardware Init:** IPL configures FDC via port 0xE0 and 0xC0
4. **Sector Load:** IPL reads 256 bytes from floppy to RAM at 0x3F00
5. **ROM Page-Out:** IPL writes value ≥0x40 to port 0xE0 (sets bit 6)
6. **Jump to RAM:** IPL executes `JP 0x3F00` (now points to RAM)
7. **Normal Operation:** Full 64KB RAM accessible, ROM disabled permanently until reset

## Resource Utilization

Estimated macrocell usage (out of 72 available):
- **Boot ROM:** ~30 macrocells (101 × 8 bits as LUT)
- **Address Decode:** ~8 macrocells
- **Clock Dividers:** 2 macrocells
- **E0 Control Latch:** 9 macrocells (8 bits + boot control)
- **External Interface:** ~16 macrocells (input/output latches)
- **Control Logic:** ~5 macrocells

**Total: ~70 macrocells** (97% utilization)

## Memory Map

### Boot Mode (BOOT=1)
```
0x0000-0x0064  ROM (101 bytes, actual bootloader)
0x0065-0x00FF  ROM (returns 0xFF, unused)
0x0100-0xFFFF  RAM disabled
```

### Normal Mode (BOOT=0, after bit 6 of 0xE0 set)
```
0x0000-0xFFFF  RAM (full 64KB accessible)
```

## Design Features

### Advantages
- **Single chip** replaces 5+ discrete ICs
- **Embedded bootloader** - no external EPROM needed
- **Flexible** - bootloader can be updated by recompiling
- **Clean design** - all glue logic consolidated
- **Modern toolchain** - uses Xilinx ISE (free WebPACK)

### Constraints
- **8-bit address bus** - sufficient for ROM (7 bits) and I/O decode (A5-A7)
- **Tight pin count** - uses 46 of 48 available I/O pins
- **High macrocell usage** - ~97% utilization leaves little room for expansion

## Building

### Prerequisites
- Xilinx ISE WebPACK 14.7 (last version supporting XC9500XL)
- Command-line tools: `xst`, `ngdbuild`, `cpldfit`, `hprep6`

### Build Process
```bash
./build.sh
```

Generates:
- `timex_mainboard.jed` - JEDEC programming file
- `timex_mainboard.rpt` - Fitting report
- `timex_mainboard.vm6` - Verilog simulation model

### Programming
Use any JTAG programmer compatible with XC9572XL:
- Xilinx Platform Cable USB
- Digilent JTAG-HS2/HS3
- Generic FT2232H-based programmers

## Files

- `timex_mainboard.v` - Complete Verilog RTL design
- `timex_mainboard.ucf` - Pin constraints for VQ64 package
- `timex_mainboard.prj` - ISE project file
- `timex_mainboard.xst` - Synthesis options
- `build.sh` - Automated build script
- `README.md` - This file

## Technical Notes

### Clock Distribution
- 16MHz input on P1 (dedicated GCK - global clock pin)
- Internal dividers create 4MHz and 8MHz synchronous clocks
- All sequential logic clocked by 4MHz (E0 latch, external interface)
- Boot latch is sticky - once cleared, stays cleared until reset

### ROM Implementation
- Stored as `reg [7:0] rom [0:100]` initialized array
- Synthesizes to distributed RAM/LUT
- Address range check: `(addr[6:0] <= 7'd100)`
- Returns 0xFF for addresses beyond 101 bytes

### Data Bus Arbitration
- ROM drives bus when: `!nROM_CS && boot_latch && !nRD`
- Interface drives bus when: `!nTIIN && !nRD`
- Tri-stated otherwise
- No bus conflicts - ROM and interface never active simultaneously

### Address Decode Logic
Helper signals:
- `cx = A7 & A6` - true when address is 0xC0-0xFF
- `ox = ~A7 & ~A6` - true when address is 0x00-0x3F

Simplified from original GAL30 to work with 8-bit address bus.

## Compatibility

### Original Hardware
Based on Timex FDD Interface using:
- GAL chip for address decode (GAL30 equations preserved)
- 2716 EPROM for bootloader
- LS273/LS244 for ZX Spectrum interface

### Modifications from Original
- Reduced from 16-bit to 8-bit address bus (A14-A15 unused, A8-A13 unused)
- Simplified RAM chip select (no A13 checking)
- ROM mirrors every 256 bytes instead of occupying discrete 2KB region
- External interface uses only 6 of 8 data bits with custom bit remapping

## License

[Specify license here]

## Credits

- Original Timex FDD hardware design
- GAL30 logic equations from original interface
- CPLD implementation and bootloader integration: [Your name/org]

## References

- WD1770 Datasheet - Floppy Disk Controller
- WD2123 Datasheet - Dual Serial Port Controller
- Xilinx XC9572XL Datasheet
- Z80 CPU Technical Manual
