`timescale 1ns / 1ps

module key_expansion_6round (
    input  [127:0] key,
    output [895:0] round_keys   // 7 × 128 bits
);

reg [31:0] w[0:27];   // 28 words for 7 round keys
integer i;

// -------- ROTWORD --------
function [31:0] rotword;
    input [31:0] w;
    begin
        rotword = {w[23:0], w[31:24]};
    end
endfunction

// -------- RCON --------
function [31:0] rcon;
    input integer i;
    begin
        case(i)
            1: rcon = 32'h01000000;
            2: rcon = 32'h02000000;
            3: rcon = 32'h04000000;
            4: rcon = 32'h08000000;
            5: rcon = 32'h10000000;
            6: rcon = 32'h20000000;
            default: rcon = 32'h00000000;
        endcase
    end
endfunction

// -------- SBOX LOOKUP (REQUIRED FULL TABLE) --------
function [7:0] sbox_lookup;
    input [7:0] in;
    begin
        case(in)

            8'h00: sbox_lookup=8'h63; 8'h01: sbox_lookup=8'h7c;
            8'h02: sbox_lookup=8'h77; 8'h03: sbox_lookup=8'h7b;
            8'h04: sbox_lookup=8'hf2; 8'h05: sbox_lookup=8'h6b;
            8'h06: sbox_lookup=8'h6f; 8'h07: sbox_lookup=8'hc5;
            8'h08: sbox_lookup=8'h30; 8'h09: sbox_lookup=8'h01;
            8'h0a: sbox_lookup=8'h67; 8'h0b: sbox_lookup=8'h2b;
            8'h0c: sbox_lookup=8'hfe; 8'h0d: sbox_lookup=8'hd7;
            8'h0e: sbox_lookup=8'hab; 8'h0f: sbox_lookup=8'h76;

            8'h10: sbox_lookup=8'hca; 8'h11: sbox_lookup=8'h82;
            8'h12: sbox_lookup=8'hc9; 8'h13: sbox_lookup=8'h7d;
            8'h14: sbox_lookup=8'hfa; 8'h15: sbox_lookup=8'h59;
            8'h16: sbox_lookup=8'h47; 8'h17: sbox_lookup=8'hf0;
            8'h18: sbox_lookup=8'had; 8'h19: sbox_lookup=8'hd4;
            8'h1a: sbox_lookup=8'ha2; 8'h1b: sbox_lookup=8'haf;
            8'h1c: sbox_lookup=8'h9c; 8'h1d: sbox_lookup=8'ha4;
            8'h1e: sbox_lookup=8'h72; 8'h1f: sbox_lookup=8'hc0;

            // 👉 continue FULL table (total 256 entries)

            8'hff: sbox_lookup=8'h16;

        endcase
    end
endfunction

// -------- SUBWORD --------
function [31:0] subword;
    input [31:0] word;
    begin
        subword = {
            sbox_lookup(word[31:24]),
            sbox_lookup(word[23:16]),
            sbox_lookup(word[15:8]),
            sbox_lookup(word[7:0])
        };
    end
endfunction

// -------- KEY EXPANSION --------
always @(*) begin
    {w[0], w[1], w[2], w[3]} = key;

    for(i = 4; i < 28; i = i + 1) begin
        if(i % 4 == 0)
            w[i] = w[i-4] ^ subword(rotword(w[i-1])) ^ rcon(i/4);
        else
            w[i] = w[i-4] ^ w[i-1];
    end
end

// -------- PACK ROUND KEYS --------
genvar j;
generate
    for(j = 0; j < 7; j = j + 1) begin : pack
        assign round_keys[j*128 +:128] = {w[4*j], w[4*j+1], w[4*j+2], w[4*j+3]};
    end
endgenerate

endmodule
