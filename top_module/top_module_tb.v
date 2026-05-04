`timescale 1ns / 1ps

module tb_top_module;

    // ================= INPUTS =================
    reg clk;
    reg rst;

    reg [127:0] raw_data;

    reg protocol;
    reg [15:0] dst_port;
    reg [7:0] length;
    reg [7:0] pac_rate;
    reg src_trust;
    reg [7:0] anamoly_score;
    reg [1:0] power_mode;
    reg latency_req;
    reg hw_sup;

    reg [127:0] key_aes;
    reg [63:0]  key_simon;

    // ================= OUTPUTS =================
    wire idle, load, busy_aes, busy_simon;
    wire [127:0] data_out_aes;
    wire [31:0]  data_out_simon;

    // ================= DUT =================
    top_module dut (
        .clk(clk),
        .rst(rst),

        .raw_data(raw_data),

        .protocol(protocol),
        .dst_port(dst_port),
        .length(length),
        .pac_rate(pac_rate),
        .src_trust(src_trust),
        .anamoly_score(anamoly_score),
        .power_mode(power_mode),
        .latency_req(latency_req),
        .hw_sup(hw_sup),

        .key_aes(key_aes),
        .key_simon(key_simon),

        .idle(idle),
        .load(load),
        .busy_aes(busy_aes),
        .busy_simon(busy_simon),

        .data_out_aes(data_out_aes),
        .data_out_simon(data_out_simon)
    );

    // ================= CLOCK =================
    always #5 clk = ~clk;

    // ================= TEST =================
    initial begin
        clk = 0;

        // RESET
        rst = 1;
        #20;
        rst = 0;

        // COMMON KEYS
        key_aes   = 128'h000102030405060708090A0B0C0D0E0F;
        key_simon = 64'h1918111009080100;

        // ==================================================
        // 🔵 CASE 1 → AES
        // ==================================================
        raw_data = 128'h00112233445566778899AABBCCDDEEFF;

        protocol = 0;        // TCP
        dst_port = 16'd502;  // control → AES
        length = 8'd100;
        pac_rate = 8'd5;
        src_trust = 1;
        anamoly_score = 8'd10;
        power_mode = 2'b01;
        latency_req = 0;
        hw_sup = 1;


wait(busy_aes == 1);
wait(busy_aes == 0);
        // Wait for AES to complete


        $display("AES OUTPUT = %h", data_out_aes);

        #50;

        // ==================================================
        // 🟢 CASE 2 → SIMON
        // ==================================================
        raw_data = 128'h112233445566778899aabbccddeeff00;

        protocol = 1;        // UDP → SIMON
        dst_port = 16'd1000;
        length = 8'd40;
        pac_rate = 8'd25;
        src_trust = 0;
        anamoly_score = 8'd200;
        power_mode = 2'b00;  // low power
        latency_req = 1;
        hw_sup = 0;

        // Wait for SIMON to complete

wait(busy_simon == 1);
wait(busy_simon == 0);

        $display("SIMON OUTPUT = %h", data_out_simon);
#100
 raw_data = 128'h00112233445566778899AABBCCDDEEFF;

        protocol = 0;        // TCP
        dst_port = 16'd502;  // control → AES
        length = 8'd100;
        pac_rate = 8'd5;
        src_trust = 1;
        anamoly_score = 8'd10;
        power_mode = 2'b01;
        latency_req = 0;
        hw_sup = 1;


wait(busy_aes == 1);
wait(busy_aes == 0);
        // Wait for AES to complete


        $display("AES OUTPUT = %h", data_out_aes);

        #50;

       
        $finish;
    end

endmodule
