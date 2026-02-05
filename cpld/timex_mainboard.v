// ===========================================================================
// Timex FDD Mainboard CPLD Implementation
// Target: Xilinx XC9572XL-VQ64
// ===========================================================================
// Replaces: 2716 ROM (101 bytes), GAL30 address decoder, clock dividers,
//           LS244/LS273 interface buffers
// ===========================================================================

module timex_mainboard_cpld (
    // Clock input
    input wire clk_16mhz,
    
    // Z80 CPU signals
    input wire [15:0] addr,
    inout wire [7:0] data,
    input wire nMREQ,
    input wire nIORQ,
    input wire nRD,
    input wire nWR,
    input wire nM1,
    input wire nRESET,
    
    // Clock outputs
    output wire clk_4mhz,      // CPU clock
    output wire clk_8mhz,      // FDC clock
    
    // Chip select outputs
    output wire nRAM_CS,
    output wire nFDC_CS,
    output wire nTIIN,
    output wire nTIOUT,
    
    // FDC signals
    input wire INTRQ,
    output wire nINT,
    
    // External computer interface (LS244/LS273 replacement)
    inout wire [7:0] ext_data,
    input wire nEXT_RD,        // Other computer reads from us
    input wire nEXT_WR,        // Other computer writes to us
    
    // Serial port pins (reserved for future use)
    output wire nSERIAL_CS1,
    output wire nSERIAL_CS2,
    
    // 0xE0 Control Latch Outputs (LS273 replacement)
    // Only outputs for drives 0-1, side select, double density, and LED
    output wire [7:0] e0_latch_out,
    
    // Reset output (non-inverted)
    output wire RESET
);

// ===========================================================================
// Clock Generation
// ===========================================================================
reg [1:0] clk_div;

always @(posedge clk_16mhz or negedge nRESET) begin
    if (!nRESET)
        clk_div <= 2'b00;
    else
        clk_div <= clk_div + 1'b1;
end

assign clk_4mhz = clk_div[1];  // Divide by 4
assign clk_8mhz = clk_div[0];  // Divide by 2

// ===========================================================================
// Boot ROM - 101 bytes
// ===========================================================================
reg [7:0] rom [0:100];

initial begin
        rom[  0] = 8'hf3; rom[  1] = 8'h31; rom[  2] = 8'hff; rom[  3] = 8'h3e; rom[  4] = 8'h3e; rom[  5] = 8'h00; rom[  6] = 8'hd3; rom[  7] = 8'h20;
        rom[  8] = 8'h3e; rom[  9] = 8'hd0; rom[ 10] = 8'hd3; rom[ 11] = 8'hc0; rom[ 12] = 8'h3e; rom[ 13] = 8'h01; rom[ 14] = 8'hcd; rom[ 15] = 8'h59;
        rom[ 16] = 8'h00; rom[ 17] = 8'hdb; rom[ 18] = 8'hc0; rom[ 19] = 8'h3e; rom[ 20] = 8'h9f; rom[ 21] = 8'hd3; rom[ 22] = 8'he0; rom[ 23] = 8'h3e;
        rom[ 24] = 8'h97; rom[ 25] = 8'hd3; rom[ 26] = 8'he0; rom[ 27] = 8'h3e; rom[ 28] = 8'h9b; rom[ 29] = 8'hd3; rom[ 30] = 8'he0; rom[ 31] = 8'h3e;
        rom[ 32] = 8'h9d; rom[ 33] = 8'hd3; rom[ 34] = 8'he0; rom[ 35] = 8'h3e; rom[ 36] = 8'h1e; rom[ 37] = 8'hd3; rom[ 38] = 8'he0; rom[ 39] = 8'h3e;
        rom[ 40] = 8'h00; rom[ 41] = 8'hd3; rom[ 42] = 8'hc0; rom[ 43] = 8'h06; rom[ 44] = 8'h04; rom[ 45] = 8'haf; rom[ 46] = 8'hcd; rom[ 47] = 8'h59;
        rom[ 48] = 8'h00; rom[ 49] = 8'h10; rom[ 50] = 8'hfa; rom[ 51] = 8'h21; rom[ 52] = 8'h00; rom[ 53] = 8'h3f; rom[ 54] = 8'h0e; rom[ 55] = 8'hc3;
        rom[ 56] = 8'h06; rom[ 57] = 8'h00; rom[ 58] = 8'hdb; rom[ 59] = 8'hc0; rom[ 60] = 8'hcb; rom[ 61] = 8'h57; rom[ 62] = 8'h28; rom[ 63] = 8'hfa;
        rom[ 64] = 8'hcb; rom[ 65] = 8'h47; rom[ 66] = 8'h20; rom[ 67] = 8'hf6; rom[ 68] = 8'haf; rom[ 69] = 8'hd3; rom[ 70] = 8'hc2; rom[ 71] = 8'h3e;
        rom[ 72] = 8'h8c; rom[ 73] = 8'hd3; rom[ 74] = 8'hc0; rom[ 75] = 8'hdb; rom[ 76] = 8'h20; rom[ 77] = 8'h17; rom[ 78] = 8'h30; rom[ 79] = 8'hfb;
        rom[ 80] = 8'hed; rom[ 81] = 8'ha2; rom[ 82] = 8'h20; rom[ 83] = 8'hf7; rom[ 84] = 8'hdb; rom[ 85] = 8'hc0; rom[ 86] = 8'hc3; rom[ 87] = 8'h00;
        rom[ 88] = 8'h3f; rom[ 89] = 8'hc5; rom[ 90] = 8'h06; rom[ 91] = 8'h00; rom[ 92] = 8'h00; rom[ 93] = 8'h10; rom[ 94] = 8'hfd; rom[ 95] = 8'h3d;
        rom[ 96] = 8'h20; rom[ 97] = 8'hf8; rom[ 98] = 8'hc1; rom[ 99] = 8'hc9; rom[100] = 8'hff;
end

// ===========================================================================
// 0xE0 Control Latch (LS273 replacement) - FDD Control Register
// ===========================================================================
reg [7:0] e0_latch;

always @(posedge clk_4mhz or negedge nRESET) begin
    if (!nRESET)
        e0_latch <= 8'h00;
    else if (!nE0_LATCH)  // Active low write strobe
        e0_latch <= data;
end

// Output the latch contents
assign e0_latch_out = e0_latch;

// BOOT Control - bit 6 of E0 latch disables ROM
reg boot_latch;

always @(posedge clk_4mhz or negedge nRESET) begin
    if (!nRESET)
        boot_latch <= 1'b1;  // Boot mode active on reset
    else if (e0_latch[6])
        boot_latch <= 1'b0;  // Disable boot ROM when bit 6 is set
end

// ===========================================================================
// Reset Output - inverted nRESET for devices needing active-high reset
// ===========================================================================
assign RESET = ~nRESET;

// ===========================================================================
// Address Decoding Helper Signals (from GAL30)
// ===========================================================================
wire cx = addr[7] & addr[6];   // Active low when A7=1 AND A6=1 (0xC0-0xFF)
wire ox = ~addr[7] & ~addr[6]; // Active low when A7=0 AND A6=0 (0x00-0x3F)

// ===========================================================================
// Chip Select Signals
// ===========================================================================

// ROM CS - lower 2KB (A0-A10), only during boot
assign nROM_CS = ~(!nMREQ && !addr[15] && !addr[14] && !addr[13] && 
                   !addr[12] && !addr[11] && boot_latch && !nRD);

// RAM CS - Original GAL logic: /RAMSEL = (/A13 * /BOOT * /MREQ) + MREQ
// During boot: only upper memory (A13=1) is RAM
// After boot: all memory is RAM
assign nRAM_CS = ~(!nMREQ && (!boot_latch || addr[13]));

// FDC CS - 0xC0-0xDF (A7=1, A6=1, A5=0)
assign nFDC_CS = ~(!nIORQ && cx && !addr[5]);

// E0 Latch - 0xE0-0xFF write (A7=1, A6=1, A5=1, WR)
assign nE0_LATCH = ~(!nIORQ && !nWR && cx && addr[5]);

// Timex Interface - 0x20-0x3F
assign nTIIN = ~(!nIORQ && !nRD && ox && addr[5]);    // Read from 0x20
assign nTIOUT = ~(!nIORQ && !nWR && ox && addr[5]);   // Write to 0x20

// Serial ports (reserved)
assign nSERIAL_CS1 = ~(!nIORQ && ox && !addr[5] && addr[6]); // 0x40
assign nSERIAL_CS2 = ~(!nIORQ && addr[7] && !addr[6]);       // 0x80

// ===========================================================================
// Interrupt handling
// ===========================================================================
assign nINT = ~INTRQ;

// ===========================================================================
// External Computer Interface (LS244/LS273 replacement)
// ===========================================================================

// Output latch (LS273 equivalent) - Z80 writes to 0x20
reg [7:0] ext_output_latch;

always @(posedge clk_4mhz or negedge nRESET) begin
    if (!nRESET)
        ext_output_latch <= 8'h00;
    else if (!nTIOUT)
        ext_output_latch <= data;
end

// Input buffer (LS244 equivalent) - Z80 reads from 0x20
reg [7:0] ext_input_buffer;

always @(posedge clk_4mhz or negedge nRESET) begin
    if (!nRESET)
        ext_input_buffer <= 8'h00;
    else if (!nEXT_WR)
        ext_input_buffer <= ext_data;
end

// External data bus control
// When other computer reads (nEXT_RD=0), output our latch
// When other computer writes (nEXT_WR=0), it drives the bus
assign ext_data = (!nEXT_RD) ? ext_output_latch : 8'bz;

// ===========================================================================
// Z80 Data Bus Control
// ===========================================================================
reg [7:0] data_out;
wire data_oe;

// Data output multiplexer
always @(*) begin
    if (!nROM_CS && boot_latch) begin
        // Reading from ROM - only when boot mode active
        if (addr[10:0] <= 11'd100)
            data_out = rom[addr[6:0]];
        else
            data_out = 8'hFF;  // Beyond 101 bytes, return 0xFF
    end
    else if (!nTIIN) begin
        // Reading from interface input buffer
        // Bit 7 = FDC status (INTRQ), bits 6:0 from external interface
        data_out = {INTRQ, ext_input_buffer[6:0]};
    end
    else
        data_out = 8'hFF;
end

// Data output enable - active when reading from ROM (during boot) or interface
assign data_oe = (!nROM_CS && boot_latch) || !nTIIN;

// Tri-state data bus
assign data = data_oe ? data_out : 8'bz;

endmodule
