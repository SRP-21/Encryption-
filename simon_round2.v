`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.04.2026 16:34:22
// Design Name: 
// Module Name: simon_round2
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


module simon_round2(input [31:0] text, input [15:0] key , input clk, rst, output reg [31:0] round_out);
wire [15:0]  L = text[31:16];
wire [15:0] R = text [15:0];

wire [15:0] f_r = (({R[14:0] , R[15]} & {R[7:0], R[15:8]}) ^ {R[13:0] , R[15:14]});
wire [15:0] R1 = L ^ f_r ^ key;
wire [15:0] L1 = R;

always @(posedge clk or posedge rst)
begin
if (rst) round_out <= 32'b0;
else round_out <= {L1,R1};
end


endmodule
