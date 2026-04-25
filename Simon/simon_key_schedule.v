// =============================================================================
// Module  : simon_key_schedule
// Purpose : SIMON-32/64 key schedule - generates one round key per clock cycle.
//
// KEY SCHEDULE SPEC (NSA paper, Algorithm 2, m=4):
//   k[i+4] = C ^ z0[i mod 62] ^ k[i] ^ (I ^ S^{-1})( S^{-3} k[i+3] ^ k[i+1] )
//   where  S^{-n} = right-rotate by n
//          C      = 16'hFFFC  (2^16 - 4)
// Round key for round i  ==  k[i]   (k[0] is used first)
// =============================================================================
module simon_key_schedule (
    input  wire        clk,
    input  wire        rst,      // active-low synchronous reset
    input  wire        load,     // load initial key (asserted for one cycle)
    input  wire        round_en, // advance key schedule by one step
    input  wire [63:0] key_in,   // 64-bit key:  key_in[15:0]  = k0 (LSW)
                                  //              key_in[63:48] = k3 (MSW)
    output wire [15:0] round_key // current round key = k0
);

    // -------------------------------------------------------------------------
    // z0 sequence (62 bits, period-62 LFSR output).
    // Source: NSA SIMON/SPECK paper (2013), Table 4, z_0.
    // String left-to-right:  z0[0]=1, z0[1]=1, ..., z0[61]=0
    // Because Verilog bit[n] of a literal is its (n)th character from the RIGHT,
    // we reverse the string so that z_seq[0] picks up z0[0]=1, etc.
    //   Original string : 11111010001001010110000111001101
    //                     11111010001001010110000111001101 10   (62 chars)
    //   Reversed        : 01100111000011010100100010111110
    //                     11011100010001010100100010111110 11   (62 chars)
    // -------------------------------------------------------------------------
    localparam [61:0] Z_SEQ =
        62'b01_1001_1100_0011_0101_0010_0010_1111_1011_0011_1000_0110_1010_0100_0101_1111;
    //        ^ bit[61] = z0[61]=0                            bit[0] = z0[0]=1 ^

    localparam [15:0] C = 16'hFFFC; // 2^16 - 4

    // Four 16-bit key registers: k0 is the OLDEST (output now),
    // k3 is the NEWEST (just computed).
    reg [15:0] k0, k1, k2, k3;
    reg [4:0]  round_idx; // counts 0..27 for z-sequence indexing (28 new keys)

    function [15:0] ror3;
        input [15:0] x;
        begin ror3 = {x[2:0], x[15:3]}; end
    endfunction

    function [15:0] ror1;
        input [15:0] x;
        begin ror1 = {x[0], x[15:1]}; end
    endfunction

    wire [15:0] tmp_a  = ror3(k3) ^ k1;
    wire [15:0] tmp_b  = tmp_a ^ ror1(tmp_a);
    wire [15:0] new_k0 = C ^ {11'b0, Z_SEQ[round_idx]} ^ k0 ^ tmp_b;
    //                          ^^ single-bit z-sequence element, zero-extended

    always @(posedge clk) begin
        if (!rst) begin
            k0        <= 16'd0;
            k1        <= 16'd0;
            k2        <= 16'd0;
            k3        <= 16'd0;
            round_idx <= 5'd0;
        end
        else if (load) begin
            // Load the four initial key words from the 64-bit key.
            // Convention: key_in[15:0] = k0 (first round key = round 0).
            k0        <= key_in[15:0];
            k1        <= key_in[31:16];
            k2        <= key_in[47:32];
            k3        <= key_in[63:48];
            round_idx <= 5'd0;
        end
        else if (round_en) begin
            // Shift: k1->k0, k2->k1, k3->k2, new_k0->k3
            // After the shift k0 holds what was k1 (next round key),
            // and k3 holds the newly computed word.
            k0        <= k1;
            k1        <= k2;
            k2        <= k3;
            k3        <= new_k0;
            round_idx <= round_idx + 5'd1;
        end
    end

    // k0 is always the current round key (oldest word in the pipeline)
    assign round_key = k0;

endmodule
