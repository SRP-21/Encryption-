`timescale 1ns / 1ps

module tb;

reg clk;
reg rst;
reg [127:0] plaintext;
reg [127:0] key;

wire [127:0] ciphertext;

aeslite_pipeline uut (
    .clk(clk),
    .rst(rst),
    .plaintext(plaintext),
    .key(key),
    .ciphertext(ciphertext)
);

// Clock generation
always #5 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    plaintext = 128'h00112233445566778899aabbccddeeff;
    key       = 128'h000102030405060708090a0b0c0d0e0f;

    #10 rst = 0;

    // Wait 8 cycles for pipeline to fill and produce valid output
    repeat(8) @(posedge clk);

    $display("=====================================");
    $display("Final Ciphertext = %h", ciphertext);
    $display("Expected 6-round = b6e3b9ede3d146f398a2c823ede4c224");
    $display("=====================================");

    // Second test vector
    plaintext = 128'h112233445566778899aabbccddeeff00;
    key       = 128'h000102030405060708090a0b0c0d0e0f;

    // Wait another 8 cycles
    repeat(8) @(posedge clk);

    $display("=====================================");
    $display("Second Ciphertext = %h", ciphertext);
    $display("Expected 6-round = 34aaa9beb19118b624f48bd0eb44c879");
    $display("=====================================");

    #50 $finish;
end

endmodule
