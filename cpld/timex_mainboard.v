// ===========================================================================
// Timex FDD Mainboard CPLD Implementation
// Target: Xilinx XC9572XL-VQ64
// ===========================================================================
// Replaces: 2716 ROM (101 bytes), GAL30 address decoder, clock dividers,
//           LS244/LS273 interface buffers
// ===========================================================================

module timex_mainboard (
    // Clock input
    input wire clk_16mhz,
    
    // Z80 CPU signals
    input wire [7:0] addr,  // Only A0-A7 needed
    inout wire [7:0] data,
    input wire nMREQ,
    input wire nIORQ,
    input wire nRD,
    input wire nWR,
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
    // Only 6 bits used: 0,1,2,3,6,7 (bits 4,5 unused)
    inout wire [7:0] ext_data,
    input wire nEXT_RD,        // Other computer reads from us
    input wire nEXT_WR,        // Other computer writes to us
    
    // Serial port pins (reserved for future use)
    output wire nSERIAL_CS1,
    output wire nSERIAL_CS2,
    
    // 0xE0 Control Latch Outputs (LS273 replacement)
    // Only expose bits 0,1,4,5,7 - bits 2,3,6 are internal only
    output wire e0_drive_sel0,    // bit 0
    output wire e0_drive_sel1,    // bit 1
    output wire e0_side_sel,      // bit 4
    output wire e0_dden,          // bit 5
    output wire e0_led,           // bit 7
    
    // Reset output (non-inverted)
    output wire RESET
);

// ===========================================================================
// Registers for everything
// ===========================================================================
reg [1:0] clk_div;
reg [7:0] rom [0:100];

// 0xE0 Control Latch (LS273 replacement) - FDD Control Register
reg [7:0] e0_latch;
reg boot_latch;

// Interface to external system
// Port 0x20
reg [7:0] ext_output_latch;
reg [6:0] ext_input_buffer;  // Only 7 bits needed (D0-D6, D7 is INTRQ)

// Z80 databus
reg [7:0] data_out;

// ===========================================================================
// Address Decoding Helper Signals (from GAL30)
// ===========================================================================
wire cx = addr[7] & addr[6];   // Active low when A7=1 AND A6=1 (0xC0-0xFF)
wire ox = ~addr[7] & ~addr[6]; // Active low when A7=0 AND A6=0 (0x00-0x3F)

// ROM CS - lower 2KB (A0-A10), only during boot
wire nROM_CS;

// E0 Latch - 0xE0-0xFF write (A7=1, A6=1, A5=1, WR)
wire nE0_LATCH;

wire data_oe;
wire [7:0] rom_data;

// ===========================================================================
// Clock Generation
// ===========================================================================

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

// ROM data output
assign rom_data = (addr[6:0] <= 7'd100) ? rom[addr[6:0]] : 8'hFF;

// ===========================================================================
// Chip Select Signals
// ===========================================================================

assign nROM_CS = ~(!nMREQ && boot_latch && !nRD);

// RAM CS - After boot: always active; During boot: disabled
assign nRAM_CS = ~(!nMREQ && !boot_latch);

// FDC CS - 0xC0-0xDF (A7=1, A6=1, A5=0)
assign nFDC_CS = ~(!nIORQ && cx && !addr[5]);

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

always @(posedge clk_4mhz or negedge nRESET) begin
    if (!nRESET) begin
        e0_latch <= 8'h00;
        boot_latch <= 1'b1;  // Boot mode active on reset
    end
    else begin
        if (!nE0_LATCH)  // Active low write strobe
            e0_latch <= data;
        
        // BOOT Control - bit 6 of E0 latch disables ROM (sticky)
        if (e0_latch[6])
            boot_latch <= 1'b0;  // Disable boot ROM when bit 6 is set
    end
end

// Mapping: FDD D0-D3,D4,D6 -> ext_data[0-3,7,6]

// Output the latch contents to external pins (only bits 0,1,4,5,7)
assign e0_drive_sel0 = e0_latch[0];
assign e0_drive_sel1 = e0_latch[1];
assign e0_side_sel   = e0_latch[4];
assign e0_dden       = e0_latch[5];
assign e0_led        = e0_latch[7];
// Bits 2,3,6 are internal only

// ===========================================================================
// Reset Output - inverted nRESET for devices needing active-high reset
// ===========================================================================
assign RESET = ~nRESET;

// ===========================================================================
// External Computer Interface (LS244/LS273 replacement)
// ===========================================================================
always @(posedge clk_4mhz or negedge nRESET) begin
    if (!nRESET)
        ext_output_latch <= 8'h00;
    else if (!nTIOUT) begin
        ext_output_latch[0] <= data[0];  // FDD D0 -> ext D0
        ext_output_latch[1] <= data[1];  // FDD D1 -> ext D1
        ext_output_latch[2] <= data[2];  // FDD D2 -> ext D2
        ext_output_latch[3] <= data[3];  // FDD D3 -> ext D3
        ext_output_latch[6] <= data[6];  // FDD D6 -> ext D6
        ext_output_latch[7] <= data[4];  // FDD D4 -> ext D7
        // ext bits 4,5 unused
    end
end

// Input buffer (LS244 equivalent) - External writes, Z80 reads from 0x20
// Mapping: ext_data[0-3,7,6] -> FDD D0-D3,D4,D6

always @(posedge clk_4mhz or negedge nRESET) begin
    if (!nRESET)
        ext_input_buffer <= 7'h00;
    else if (!nEXT_WR) begin
        ext_input_buffer[0] <= ext_data[0];  // ext D0 -> FDD D0
        ext_input_buffer[1] <= ext_data[1];  // ext D1 -> FDD D1
        ext_input_buffer[2] <= ext_data[2];  // ext D2 -> FDD D2
        ext_input_buffer[3] <= ext_data[3];  // ext D3 -> FDD D3
        ext_input_buffer[4] <= ext_data[7];  // ext D7 -> FDD D4
        ext_input_buffer[6] <= ext_data[6];  // ext D6 -> FDD D6
        // FDD D5 never used
    end
end

// External data bus control - only drive used bits
// When other computer reads (nEXT_RD=0), output our latch
// When other computer writes (nEXT_WR=0), it drives the bus
assign ext_data[0] = (!nEXT_RD) ? ext_output_latch[0] : 1'bz;
assign ext_data[1] = (!nEXT_RD) ? ext_output_latch[1] : 1'bz;
assign ext_data[2] = (!nEXT_RD) ? ext_output_latch[2] : 1'bz;
assign ext_data[3] = (!nEXT_RD) ? ext_output_latch[3] : 1'bz;
assign ext_data[4] = 1'bz;  // Unused
assign ext_data[5] = 1'bz;  // Unused
assign ext_data[6] = (!nEXT_RD) ? ext_output_latch[6] : 1'bz;
assign ext_data[7] = (!nEXT_RD) ? ext_output_latch[7] : 1'bz;

// ===========================================================================
// Z80 Data Bus Control
// ===========================================================================

// Data output multiplexer
always @(*) begin
    if (!nROM_CS && boot_latch) begin
        // Reading from ROM - only when boot mode active
        data_out = rom_data;
    end
    else if (!nTIIN) begin
        // Reading from interface input buffer
        // Bit 7 = FDC status (INTRQ), bits 0-6 from external interface (remapped)
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
