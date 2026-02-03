// Optimized ROM for XC9572XL
module timex_mainboard (
    input   cs,
    input   [6:0] addr,
    output  [7:0] data
);

// Use ROM memory initialization
reg [7:0] rom_mem [0:100];

// Initialize with your data
initial begin
    // Your 101 bytes of data go here
    rom_mem[0]  = 8'h12; rom_mem[1]  = 8'h34; rom_mem[2]  = 8'h56; rom_mem[3]  = 8'h78;
    rom_mem[4]  = 8'h9A; rom_mem[5]  = 8'hBC; rom_mem[6]  = 8'hDE; rom_mem[7]  = 8'hF0;
    rom_mem[8]  = 8'h11; rom_mem[9]  = 8'h22; rom_mem[10] = 8'h33; rom_mem[11] = 8'h44;
    rom_mem[12] = 8'h55; rom_mem[13] = 8'h66; rom_mem[14] = 8'h77; rom_mem[15] = 8'h88;
    rom_mem[16] = 8'h99; rom_mem[17] = 8'hAA; rom_mem[18] = 8'hBB; rom_mem[19] = 8'hCC;
    rom_mem[20] = 8'hDD; rom_mem[21] = 8'hEE; rom_mem[22] = 8'hFF; rom_mem[23] = 8'h00;
    rom_mem[24] = 8'h10; rom_mem[25] = 8'h20; rom_mem[26] = 8'h30; rom_mem[27] = 8'h40;
    rom_mem[28] = 8'h50; rom_mem[29] = 8'h60; rom_mem[30] = 8'h70; rom_mem[31] = 8'h80;
    rom_mem[32] = 8'h90; rom_mem[33] = 8'hA0; rom_mem[34] = 8'hB0; rom_mem[35] = 8'hC0;
    rom_mem[36] = 8'hD0; rom_mem[37] = 8'hE0; rom_mem[38] = 8'hF0; rom_mem[39] = 8'h01;
    rom_mem[40] = 8'h02; rom_mem[41] = 8'h03; rom_mem[42] = 8'h04; rom_mem[43] = 8'h05;
    rom_mem[44] = 8'h06; rom_mem[45] = 8'h07; rom_mem[46] = 8'h08; rom_mem[47] = 8'h09;
    rom_mem[48] = 8'h0A; rom_mem[49] = 8'h0B; rom_mem[50] = 8'h0C; rom_mem[51] = 8'h0D;
    rom_mem[52] = 8'h0E; rom_mem[53] = 8'h0F; rom_mem[54] = 8'h1F; rom_mem[55] = 8'h2F;
    rom_mem[56] = 8'h3F; rom_mem[57] = 8'h4F; rom_mem[58] = 8'h5F; rom_mem[59] = 8'h6F;
    rom_mem[60] = 8'h7F; rom_mem[61] = 8'h8F; rom_mem[62] = 8'h9F; rom_mem[63] = 8'hAF;
    rom_mem[64] = 8'hBF; rom_mem[65] = 8'hC0; rom_mem[66] = 8'hD0; rom_mem[67] = 8'hE0;
    rom_mem[68] = 8'hF0; rom_mem[69] = 8'h00; rom_mem[70] = 8'h01; rom_mem[71] = 8'h02;
    rom_mem[72] = 8'h03; rom_mem[73] = 8'h04; rom_mem[74] = 8'h05; rom_mem[75] = 8'h06;
    rom_mem[76] = 8'h07; rom_mem[77] = 8'h08; rom_mem[78] = 8'h09; rom_mem[79] = 8'h0A;
    rom_mem[80] = 8'h0B; rom_mem[81] = 8'h0C; rom_mem[82] = 8'h0D; rom_mem[83] = 8'h0E;
    rom_mem[84] = 8'h0F; rom_mem[85] = 8'h10; rom_mem[86] = 8'h20; rom_mem[87] = 8'h30;
    rom_mem[88] = 8'h40; rom_mem[89] = 8'h50; rom_mem[90] = 8'h60; rom_mem[91] = 8'h70;
    rom_mem[92] = 8'h80; rom_mem[93] = 8'h90; rom_mem[94] = 8'hA0; rom_mem[95] = 8'hB0;
    rom_mem[96] = 8'hC0; rom_mem[97] = 8'hD0; rom_mem[98] = 8'hE0; rom_mem[99] = 8'hF0;
    rom_mem[100] = 8'h00;
end

// Output with proper tri-state
assign data = cs ? 8'bz : rom_mem[addr];

endmodule
