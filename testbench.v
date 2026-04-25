`timescale 1ns / 1ps

module tb;

reg clk;
reg rst;
reg start;
reg [127:0] plaintext;
reg [127:0] key;

wire [127:0] ciphertext;
wire done;

// 👉 FIXED: use aes_6round
 aes_6round uut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .plaintext(plaintext),
    .key(key),
    .ciphertext(ciphertext),
    .done(done)
);

// Clock
always #5 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    start = 0;

    plaintext = 128'h00112233445566778899aabbccddeeff;
    key       = 128'h000102030405060708090a0b0c0d0e0f;

    // Release reset
    #10 rst = 0;

    // Start
    #10 start = 1;
    #10 start = 0;

    // 👉 FIXED: safe wait
    repeat(50) @(posedge clk);

    $display("=====================================");
    $display("Final Ciphertext = %h", ciphertext);
    $display("=====================================");

    // 👉 Reset before next test
    #10 rst = 1;
    #10 rst = 0;

    // Second test
    plaintext = 128'h112233445566778899aabbccddeeff00;

    #10 start = 1;
    #10 start = 0;

    repeat(50) @(posedge clk);

    $display("=====================================");
    $display("Second Output = %h", ciphertext);
    $display("=====================================");

    #50 $finish;
end

// Monitor
initial begin
    $monitor("Time=%0t | start=%b | done=%b | CT=%h",
              $time, start, done, ciphertext);
end

endmodule