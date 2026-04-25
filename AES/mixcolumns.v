`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.04.2026 20:44:54
// Design Name: 
// Module Name: mixcolumns
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


module mixcolumns(input [127:0] in, output [127:0] out);

function [7:0] xtime;
    input [7:0] b;
    xtime = (b<<1) ^ (8'h1b & {8{b[7]}});
endfunction

function [7:0] mul2;
    input [7:0] b;
    mul2 = xtime(b);
endfunction

function [7:0] mul3;
    input [7:0] b;
    mul3 = xtime(b) ^ b;
endfunction

genvar i;
generate
    for(i=0;i<4;i=i+1) begin : col
        wire [7:0] s0 = in[i*32 +:8];
        wire [7:0] s1 = in[i*32+8 +:8];
        wire [7:0] s2 = in[i*32+16 +:8];
        wire [7:0] s3 = in[i*32+24 +:8];

        assign out[i*32 +:8]      = mul2(s0)^mul3(s1)^s2^s3;
        assign out[i*32+8 +:8]    = s0^mul2(s1)^mul3(s2)^s3;
        assign out[i*32+16 +:8]   = s0^s1^mul2(s2)^mul3(s3);
        assign out[i*32+24 +:8]   = mul3(s0)^s1^s2^mul2(s3);
    end
endgenerate

endmodule
