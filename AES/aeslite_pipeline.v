`timescale 1ns / 1ps

module aeslite_pipeline (
    input clk,
    input rst,
    input [127:0] plaintext,
    input [127:0] key,
    output reg [127:0] ciphertext
);

// ===== KEY EXPANSION (6 ROUND) =====
wire [895:0] round_keys;

key_expansion_6round ke (
    .key(key),
    .round_keys(round_keys)
);

// Use first expanded key (rk1)
wire [127:0] round_key1;
assign round_key1 = round_keys[128 +: 128];

// ===== PIPELINE REGISTERS =====
reg [127:0] stage1, stage2, stage3, stage4;

// Stage1
always @(posedge clk or posedge rst)
    if (rst) stage1 <= 0;
    else stage1 <= plaintext ^ key;

// Stage2
wire [127:0] sb_out;
subbytes sb (.in(stage1), .out(sb_out));

always @(posedge clk or posedge rst)
    if (rst) stage2 <= 0;
    else stage2 <= sb_out;

// Stage3
wire [127:0] sr_out;
shiftrows sr (.in(stage2), .out(sr_out));

always @(posedge clk or posedge rst)
    if (rst) stage3 <= 0;
    else stage3 <= sr_out;

// Stage4
wire [127:0] mc_out;
mixcolumns mc (.in(stage3), .out(mc_out));

always @(posedge clk or posedge rst)
    if (rst) stage4 <= 0;
    else stage4 <= mc_out;

// Final
always @(posedge clk or posedge rst)
    if (rst) ciphertext <= 0;
    else ciphertext <= stage4 ^ round_key1;

endmodule
