`timescale 1ns / 1ps 
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.04.2026 11:44:32
// Design Name: 
// Module Name: top_module
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


module top_module( 
    input clk, rst,
    input [127:0] raw_data,
    input [8:0] payload_len,
    input protocol,
    input [15:0] dst_port,
    input [7:0] length,
    input [7:0] pac_rate,
    input src_trust,
    input [7:0] anamoly_score,
    input [1:0] power_mode,
    input latency_req,
    input hw_sup,
    input [127:0] key_aes,
    input [63:0] key_simon,
    output reg idle,
    output reg load,
    output reg busy_aes , busy_simon,
    output reg [127:0] data_out_aes,
    output reg [31:0] data_out_simon
    
    );
    parameter IDLE = 2'b00,
 LOAD = 2'b01,
 BUSY = 2'b10,
 DONE = 2'b11;

    reg [1:0] CS, NS;

    parameter [1:0] aes = 2'b00, simon = 2'b01, na = 2'b10;
    parameter tcp = 1'b0 , udp = 1'b1;
    parameter strict = 1'b1, relaxed = 1'b0;
    parameter aes_rounds = 6'd6, simon_rounds = 6'd32;
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
    
    reg [127:0] d_in_aes;
    reg [31:0]  d_in_simon;
    reg [31:0] data_batch;
    wire [127:0] stagereg_aes;
    wire [31:0] stagereg_simon;
    wire [1:0] crypt_sel;
    reg [127:0] simon_fifo;
    reg [255:0] aes_fifo;
    reg [5:0] count, round_count;
    reg start_aes , start_simon;
    wire done_aes_core;
    wire done_simon_core;
    reg start_global;
    integer n = 0;
    
    
    selection_logic sl1(
    .protocol(protocol),
    .dst_port(dst_port),
    .length(length),
    .pac_rate(pac_rate),
    .src_trust(src_trust),
    .anamoly_score(anamoly_score),
    .power_mode(power_mode),
    .latency_req(latency_req),
    .hw_sup(hw_sup),
    .crypt_sel(crypt_sel)
    );
    
aes_6round a1 (
    .clk(clk),
    .rst(rst),
    .start(start_aes),
    .plaintext(d_in_aes),
    .key(key_aes),
    .ciphertext(stagereg_aes),
    .done(done_aes_core)
);

simon_top_clean sm (
    .clk(clk),
    .rst(rst),
    .start(start_simon),
    .data_in(d_in_simon),
    .key(key_simon),
    .data_out(stagereg_simon),
    .done(done_simon_core)
);
    
     always @(posedge clk or posedge rst) begin
        if (rst)
            CS <= IDLE;
        else
            CS <= NS;
    end

    always @(*) begin
        NS = CS;
        case (CS)
         IDLE:
        NS = LOAD;
        LOAD:
            NS = BUSY;
        
        BUSY:
begin
    NS = BUSY;   

    if (crypt_sel == aes && done_aes_core)
        NS = DONE;

    else if (crypt_sel == simon && done_simon_core)
        NS = DONE;
end
        
       DONE: begin
    NS = IDLE; 
     if (crypt_sel == simon && raw_data[(n-1)*32 +: 32] != 0) NS = LOAD;
     
    end 
        endcase
    end

    always @(*) begin
        idle = 0; load = 0; busy_aes = 0; busy_simon = 0; 
        case (CS)
            IDLE: idle = 1;
            LOAD: load = 1;
            BUSY:
            begin
            if (crypt_sel == aes) busy_aes = 1;
            else if (crypt_sel == simon) busy_simon = 1;
            
            
            end
        endcase
    end
   
  always @(posedge clk or posedge rst)
begin
    if (rst)
    begin
        start_aes   <= 0;
        start_simon <= 0;
    end
    else
    begin
        case (CS)

            LOAD:
            begin
                if (crypt_sel == aes)
                begin
                    start_aes   <= 1;
                    start_simon <= 0;
                end
                else if (crypt_sel == simon)
                begin
                    start_simon <= 1;
                    start_aes   <= 0;
                end
            end

            default:
            begin
                start_aes   <= 0;
                start_simon <= 0;
            end

        endcase
    end
end
   
    
    always @(posedge clk or posedge rst) begin
        
        if (rst) begin
            d_in_aes    <= 0;
            d_in_simon <= 0;
            data_out_aes  <= 0;
            data_out_simon <= 0;
         
        end
            
            case(n)  
            1: data_batch = raw_data[31:0];
            2: data_batch = raw_data[63:32];
            3: data_batch = raw_data[95:64];
            4: data_batch = raw_data[127:96];
            endcase   
                
                
            case (CS)
                
                LOAD: begin
                    if (crypt_sel == aes) begin
                        d_in_aes <= raw_data;
                    end
                    else begin
                            
                        d_in_simon <= data_batch;
                    end
                end
                
                DONE: 
                begin
                
                if (crypt_sel == aes)
                    begin
                    data_out_aes   <= stagereg_aes;
                    data_out_simon   <= 0;
                    
  
                     
                     
                    end
                    
                else if (crypt_sel == simon)
                    begin
                    data_out_simon  <= stagereg_simon ;
                    data_out_aes    <= 0;
                    n <= n+1;
                    
                    end                 
                end
                              
            endcase         
end                    
endmodule
