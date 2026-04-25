// =============================================================================
// Module  : simon_datapath
// Purpose : SIMON-32/64 datapath - stores (L, R) state registers and applies
//           one Feistel round per clock cycle when round_en is asserted.
// Conventions
//   data_in[31:16] = left  word (x / high half)
//   data_in[15: 0] = right word (y / low  half)
//   data_out       = {L, R} after all rounds
// =============================================================================
module simon_datapath (
    input  wire        clk,
    input  wire        rst,       // active-low synchronous reset
    input  wire        load,     
    input  wire        round_en, 
    input  wire [31:0] data_in,   // plaintext {L, R}
    input  wire [15:0] round_key, // current round key from key schedule
    output wire [31:0] data_out   // ciphertext {L, R}
);

    reg  [15:0] L, R;
    wire [15:0] L_next, R_next;

    simon_round u_round (
        .L        (L),
        .R        (R),
        .round_key(round_key),
        .L_out    (L_next),
        .R_out    (R_next)
    );

    always @(posedge clk) begin
        if (!rst) begin
            L <= 16'd0;
            R <= 16'd0;
        end
        else if (load) begin
            L <= data_in[31:16];
            R <= data_in[15:0];
        end
        else if (round_en) begin
            L <= L_next;
            R <= R_next;
        end
        // else: hold (implicit - no latch because every reg has a reset path)
    end

    assign data_out = {L, R};

endmodule
