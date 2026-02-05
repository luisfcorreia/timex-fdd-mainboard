# Timex FDD Hardware description

* CPU Z80 microprocessor @4Mhz
* 2K ROM for IPL (101 bytes only)
* 64KB RAM fully paged in after TOS loading routine pages ROM _out_
* WD1770 Floppy Disc Controller
* WD2123 Dual Serial Port Controller
* GAL/ULA/ TTL Glue logic ICs

## I/O ports

 - 0x00 Serial Port baudrate setup

 - 0x2F Timex Interface for ZX Spectrum
 
    LS273/LS244 I/O buffer latch pair (same as in interface)

    * 6 bit I/O port
    * on RX side, D7 contains Data Ready signal from Floppy Disc Controller
    * (data bits don't match one to one from interface)

 - 0x40 Serial Port 1 control/data

 - 0x80 Serial Port 2 control/data

 - 0xC0 WD1770 Floppy Disk Controller

 - 0xE0 FDD control output latch

    * D0 - FDD Drive select 0
    * D1 - FDD Drive select 1
    * D2 - FDD Drive select 2
    * D3 - FDD Drive select 3
    * D4 - FDD Drive side select
    * D5 - Double Density, connects to WD1770 /DDEN input
    * D6 - Disables onboard ROM
    * D7 - FDD Drive in use LED




