`timescale 1ns / 1ps

module aes_6round (
    input clk,
    input rst,
    input start,
    input [127:0] plaintext,
    input [127:0] key,
    output reg [127:0] ciphertext,
    output reg done
);

reg [127:0] state;
reg [3:0] round;
reg running;

// ===== Submodules =====
wire [127:0] sb_out, sr_out, mc_out;

subbytes sb(.in(state), .out(sb_out));
shiftrows sr(.in(sb_out), .out(sr_out));
mixcolumns mc(.in(sr_out), .out(mc_out));

// ===== KEY EXPANSION (6 ROUND) =====
wire [895:0] round_keys;

key_expansion_6round ke (
    .key(key),
    .round_keys(round_keys)
);

// ===== EXTRACT ROUND KEYS =====
wire [127:0] rk0 = round_keys[0   +:128];
wire [127:0] rk1 = round_keys[128 +:128];
wire [127:0] rk2 = round_keys[256 +:128];
wire [127:0] rk3 = round_keys[384 +:128];
wire [127:0] rk4 = round_keys[512 +:128];
wire [127:0] rk5 = round_keys[640 +:128];
wire [127:0] rk6 = round_keys[768 +:128];

// Select correct round key
wire [127:0] current_rk =
    (round==0) ? rk0 :
    (round==1) ? rk1 :
    (round==2) ? rk2 :
    (round==3) ? rk3 :
    (round==4) ? rk4 :
    (round==5) ? rk5 :
                 rk6;

// ===== CONTROL =====
always @(posedge clk or posedge rst) begin
    if(rst) begin
        state <= 0;
        round <= 0;
        running <= 0;
        done <= 0;
        ciphertext <= 0;
    end
    else begin

        // INITIAL ROUND
        if(start && !running) begin
            state <= plaintext ^ rk0;
            round <= 1;
            running <= 1;
            done <= 0;
        end

        // MAIN ROUNDS
        else if(running) begin
            if(round < 6) begin
                state <= mc_out ^ current_rk;
                round <= round + 1;
            end
            else begin
                // FINAL ROUND (NO MixColumns)
                ciphertext <= sr_out ^ rk6;
                running <= 0;
                done <= 1;
            end
        end
    end
end

endmodule
