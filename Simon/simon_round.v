// =============================================================================
// Module  : simon_round
// Purpose : One SIMON-32/64 Feistel round (combinational).
//   In our port names:  L == x_i ,  R == y_i
//   =>  L_out = R ^ f(L) ^ round_key      (f is applied to L, the LEFT word)
//       R_out = L
// =============================================================================
module simon_round (
    input  wire [15:0] L,
    input  wire [15:0] R,
    input  wire [15:0] round_key,
    output wire [15:0] L_out,
    output wire [15:0] R_out
);

    
    wire [15:0] f_out;

    // f is applied to L (the LEFT / x word) - paper convention
    simon_f_function u_f (
        .x    (L),        // <-- L goes in, NOT R
        .f_out(f_out)
    );

    assign L_out = R ^ f_out ^ round_key;   // new left  = R ^ f(L) ^ k
    assign R_out = L;                        // new right = L

endmodule
