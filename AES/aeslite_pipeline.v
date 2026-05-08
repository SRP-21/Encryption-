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

wire [127:0] rk0 = round_keys[   0 +: 128];
wire [127:0] rk1 = round_keys[ 128 +: 128];
wire [127:0] rk2 = round_keys[ 256 +: 128];
wire [127:0] rk3 = round_keys[ 384 +: 128];
wire [127:0] rk4 = round_keys[ 512 +: 128];
wire [127:0] rk5 = round_keys[ 640 +: 128];
wire [127:0] rk6 = round_keys[ 768 +: 128];

// ===== PIPELINE STAGES =====
reg [127:0] stage0, stage1, stage2, stage3, stage4, stage5, stage6;

wire [127:0] sb0, sr0, mc0;
wire [127:0] sb1, sr1, mc1;
wire [127:0] sb2, sr2, mc2;
wire [127:0] sb3, sr3, mc3;
wire [127:0] sb4, sr4, mc4;
wire [127:0] sb5, sr5;

subbytes sb0_inst (.in(stage0), .out(sb0));
shiftrows sr0_inst (.in(sb0), .out(sr0));
mixcolumns mc0_inst (.in(sr0), .out(mc0));

subbytes sb1_inst (.in(stage1), .out(sb1));
shiftrows sr1_inst (.in(sb1), .out(sr1));
mixcolumns mc1_inst (.in(sr1), .out(mc1));

subbytes sb2_inst (.in(stage2), .out(sb2));
shiftrows sr2_inst (.in(sb2), .out(sr2));
mixcolumns mc2_inst (.in(sr2), .out(mc2));

subbytes sb3_inst (.in(stage3), .out(sb3));
shiftrows sr3_inst (.in(sb3), .out(sr3));
mixcolumns mc3_inst (.in(sr3), .out(mc3));

subbytes sb4_inst (.in(stage4), .out(sb4));
shiftrows sr4_inst (.in(sb4), .out(sr4));
mixcolumns mc4_inst (.in(sr4), .out(mc4));

subbytes sb5_inst (.in(stage5), .out(sb5));
shiftrows sr5_inst (.in(sb5), .out(sr5));

always @(posedge clk or posedge rst) begin
    if (rst) begin
        stage0 <= 0;
        stage1 <= 0;
        stage2 <= 0;
        stage3 <= 0;
        stage4 <= 0;
        stage5 <= 0;
        stage6 <= 0;
        ciphertext <= 0;
    end else begin
        stage0 <= plaintext ^ rk0;
        stage1 <= mc0 ^ rk1;
        stage2 <= mc1 ^ rk2;
        stage3 <= mc2 ^ rk3;
        stage4 <= mc3 ^ rk4;
        stage5 <= mc4 ^ rk5;
        stage6 <= sr5 ^ rk6;  // final round: SubBytes + ShiftRows + AddRoundKey
        ciphertext <= stage6;
    end
end

endmodule
