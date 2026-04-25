// =============================================================================
// Module  : simon_top
// Purpose : Top-level integration of the SIMON-32/64 block cipher.
//           Connects FSM, key schedule, and datapath.
// Interface
//   clk      : system clock
//   rst      : active-low synchronous reset
//   start    : pulse high for one cycle to start an encryption operation
//   data_in  : 32-bit plaintext  {left_word[31:16], right_word[15:0]}
//   key      : 64-bit key        {k3[63:48], k2[47:32], k1[31:16], k0[15:0]}
//              k0 = key[15:0] is the first round key (used in round 0)
//   data_out : 32-bit ciphertext {L[31:16], R[15:0]}  valid when done==1
//   done     : asserted for one cycle when encryption is complete
//
// Latency  : 1 (LOAD) + 32 (ROUND) + 1 (DONE) = 34 clock cycles after start.
// Throughput: one new encryption can start every 34 cycles (non-pipelined).
// =============================================================================
module simon_top (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [31:0] data_in,
    input  wire [63:0] key,
    output wire [31:0] data_out,
    output wire        done
);

    wire        load;
    wire        round_en;
    wire [15:0] round_key;

    simon_fsm u_fsm (
        .clk     (clk),
        .rst     (rst),
        .start   (start),
        .load    (load),
        .round_en(round_en),
        .done    (done)
    );

    simon_key_schedule u_ks (
        .clk      (clk),
        .rst      (rst),
        .load     (load),
        .round_en (round_en),
        .key_in   (key),
        .round_key(round_key)
    );


    simon_datapath u_dp (
        .clk      (clk),
        .rst      (rst),
        .load     (load),
        .round_en (round_en),
        .data_in  (data_in),
        .round_key(round_key),
        .data_out (data_out)
    );

endmodule
