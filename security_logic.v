`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.04.2026 00:00:27
// Design Name: 
// Module Name: security_logic
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


module security_logic(input [1:0] pac_type, pay_length, freq, anamoly,
 input trust, output reg [1:0] security);
parameter [1:0] low_sec = 2'b00, mid_sec = 2'b01, high_sec = 2'b10, error = 2'b11;
parameter [1:0] control = 2'b00, sensor = 2'b01, bulk = 2'b10;
parameter [1:0] len_low = 2'b00, len_mid = 2'b01, len_high = 2'b10;
parameter [1:0] low_freq = 2'b00, mid_freq = 2'b01, high_freq = 2'b10;
parameter [1:0] anam_low = 2'b00, anam_mid = 2'b01, anam_high = 2'b10;
parameter trusted = 1'b1, untrusted = 1'b0;

always@(*)
begin
if (pac_type == bulk)
    begin
    if (freq == mid_freq)
        begin
        if (pay_length == len_high)
            begin 
            security = low_sec;
            end
        else if (pay_length == len_mid) 
            begin
            security = mid_sec;
            end

         end 
     
     else if (freq == high_freq)
        begin
        if (trust == trusted)
            begin
            if (anamoly == anam_low)
                begin
                security = low_sec;
                end
            else if (anamoly == anam_mid)
                begin
                security = low_sec;
                end
            else if (anamoly == anam_high)
                begin
                security = high_sec;
                end
            end
            
        else if (trust == untrusted)
            begin
            security = high_sec;
            end
        

        end        
       
    else if (freq == low_freq)
        begin
        security = low_sec;
        end
    end
    
else if (pac_type == sensor)
    begin
    if (anamoly == anam_high)
        begin
        security = high_sec;
        end
    
    else if (anamoly == anam_low) 
        begin
        security = mid_sec;
        end
    
    else if (anamoly == anam_mid)
        begin
        if (freq == mid_freq)
            begin
            security = mid_sec;
            end
        
        else if (freq == low_freq)
            begin
            security = mid_sec;
            end
        
        else if (freq == high_freq)
            begin
            if (pay_length == len_low)
                begin
                security = low_sec;
                end
            
            else if (pay_length == len_mid)
                begin
                security = mid_sec;
                end
            end    
        end    
    end

else if (pac_type == control)
    begin
    security = high_sec;
    end
    
else 
    begin
    security = error;
    end

end        
endmodule
