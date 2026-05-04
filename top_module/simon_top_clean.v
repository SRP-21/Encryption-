`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.04.2026 10:07:35
// Design Name: 
// Module Name: simon_top_clean
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

module simon_top_clean (
    input  wire        clk,
    input  wire        rst,       // ACTIVE HIGH
    input  wire        start,     // 1-cycle pulse
    input  wire [31:0] data_in,
    input  wire [63:0] key,
    output reg  [31:0] data_out,
    output reg         done
);

    // FSM states
    localparam IDLE  = 2'd0,
               LOAD  = 2'd1,
               ROUND = 2'd2,
               DONE  = 2'd3;

    reg [1:0] cs;
    reg [5:0] round_cnt;

    wire load     = (cs == LOAD);
    wire round_en = (cs == ROUND);

    // ================= FSM =================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cs        <= IDLE;
            round_cnt <= 0;
            done      <= 0;
        end else begin
            done <= 0;

            case (cs)

                IDLE: begin
                    if (start)
                        cs <= LOAD;
                end

                LOAD: begin
                    cs <= ROUND;
                    round_cnt <= 0;
                end

                ROUND: begin
                    round_cnt <= round_cnt + 1;
                    if (round_cnt == 6'd31)
                        cs <= DONE;
                end

                DONE: begin
                    done <= 1;      // 1-cycle pulse
                    cs   <= IDLE;
                end

            endcase
        end
    end

    // ================= CORE =================
    wire [15:0] round_key;
    wire [31:0] core_out;

    simon_key_schedule u_ks (
        .clk(clk),
        .rst(rst),
        .load(load),
        .round_en(round_en),
        .key_in(key),
        .round_key(round_key)
    );

    simon_datapath u_dp (
        .clk(clk),
        .rst(rst),
        .load(load),
        .round_en(round_en),
        .data_in(data_in),
        .round_key(round_key),
        .data_out(core_out)
    );

    // ================= OUTPUT =================
    always @(posedge clk or posedge rst) begin
        if (rst)
            data_out <= 0;
        else if (cs == DONE)
            data_out <= core_out;
    end

endmodule
