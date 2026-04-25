`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.04.2026 20:43:37
// Design Name: 
// Module Name: shiftrows
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


module shiftrows(input [127:0] in, output [127:0] out);

assign out = {
    in[127:120], in[87:80],  in[47:40],  in[7:0],
    in[95:88],   in[55:48],  in[15:8],   in[103:96],
    in[63:56],   in[23:16],  in[111:104],in[71:64],
    in[31:24],   in[119:112],in[79:72],  in[39:32]
};

endmodule
