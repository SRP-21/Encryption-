
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.04.2026 01:49:19
// Design Name: 
// Module Name: selection_logic
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module selection_logic(
    input protocol,
    input [15:0] dst_port,
    input [7:0] length,
    input [7:0] pac_rate,
    input src_trust,
    input [7:0] anamoly_score,
    input [1:0] power_mode,
    input latency_req,
    input hw_sup,
    output reg [1:0] crypt_sel
    );

parameter [1:0] aes = 2'b00, simon = 2'b01, na = 2'b10;
parameter tcp = 1'b0 , udp = 1'b1;
parameter strict = 1'b1, relaxed = 1'b0;

parameter [1:0] low_sec = 2'b00, mid_sec = 2'b01, high_sec = 2'b10, error = 2'b11;
parameter [1:0] control = 2'b00, sensor = 2'b01, bulk = 2'b10;
parameter [1:0] len_low = 2'b00, len_mid = 2'b01, len_high = 2'b10;
parameter [1:0] low_freq = 2'b00, mid_freq = 2'b01, high_freq = 2'b10;
parameter [1:0] anam_low = 2'b00, anam_mid = 2'b01, anam_high = 2'b10;
parameter trusted = 1'b1, untrusted = 1'b0;
parameter [1:0] lp = 2'b00, mp = 2'b01, hp = 2'b10;
reg [1:0] pac_type, pay_length, freq, anamoly;
wire [1:0] security;
reg signed [4:0] aes_score, simon_score;

security_logic dut(.pac_type(pac_type), .pay_length(pay_length), .freq(freq), .anamoly(anamoly),
 .trust(src_trust), .security(security));


always@(*)
begin

    pac_type   = bulk;
    pay_length = len_low;
    freq       = low_freq;
    anamoly    = anam_low;
    crypt_sel  = na;
    aes_score  = 0;
    simon_score = 0;

if (protocol == tcp && dst_port == 16'd502) 
    begin
    pac_type = control;
    end
    
else if (protocol == udp)
    begin
    pac_type = sensor;
    end
else
    begin
    pac_type = bulk;
    end
    

if (length >= 8'd0 && length <= 8'd64)
    begin
    pay_length = len_low;
    end
    
else if (length > 8'd64 && length <= 8'd128)
    begin
    pay_length = len_mid;
    end
    
else
    begin
    pay_length = len_high;
    end
    
if (pac_rate >= 8'd0 && pac_rate <= 8'd10)
    begin
    freq = low_freq;
    end
    
else if (pac_rate > 8'd10 && pac_rate <= 8'd20)
    begin
    freq = mid_freq;
    end
    
else
    begin
    freq = high_freq;
    end

if (anamoly_score >= 8'd0 && anamoly_score <= 8'd80)
    begin
    anamoly = anam_low;
    end
    
else if (anamoly_score > 8'd80 && anamoly_score <= 8'd180)
    begin
    anamoly = anam_mid;
    end
    
else
    begin
    anamoly = anam_high;
    end

aes_score = 3*(security == high_sec) + 2*(pay_length == len_high) + 2*(hw_sup == 1) - 2*(power_mode == lp) - 1*(latency_req == 1);
simon_score = 3*(power_mode == lp) + 2*(hw_sup == 0) +2*(latency_req == 1) +1*(pay_length == len_low) +1*(pay_length == len_mid) -2*(security == high_sec) -1*(pay_length == len_high);

if (aes_score > simon_score)
    begin
    crypt_sel = aes;
    end
else if (aes_score < simon_score)
    begin
    crypt_sel = simon;
    end
    
else 
    begin
    crypt_sel = error;
    end
end
endmodule
