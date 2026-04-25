`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.04.2026 20:40:07
// Design Name: 
// Module Name: subbytes
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

module subbytes(input [127:0] in, output [127:0] out);

genvar i;
generate
    for(i=0;i<16;i=i+1) begin : sb
        sbox s(.in(in[8*i +:8]), .out(out[8*i +:8]));
    end
endgenerate

endmodule
